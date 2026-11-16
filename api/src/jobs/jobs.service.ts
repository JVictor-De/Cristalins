import { Injectable, Logger, Optional } from '@nestjs/common';
import { StatusAssinatura, StatusCiclo, StatusPagamento } from '../../prisma/generated/prisma/client';
import { AssinaturasService } from '../assinaturas/assinaturas.service';
import { MaquinaEstadosService } from '../assinaturas/maquina-estados.service';
import { CobrancaService } from '../asaas/cobranca.service';
import { ConciliacaoService } from '../asaas/conciliacao.service';
import { ReguaService } from '../asaas/regua.service';
import { dataIso, somarDias } from '../ciclos/agenda';
import { ClockService } from '../common/clock.service';
import { PrismaService } from '../common/prisma.service';
import { WebhooksService } from '../webhooks/webhooks.service';

/**
 * Lógica dos jobs (sem decorators de schedule — ver `jobs.scheduler.ts`).
 * Régua mínima AP2: lembrete (log) e retenção. Régua +7/+30 em cr-5.
 */
@Injectable()
export class JobsService {
  private readonly log = new Logger(JobsService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly clock: ClockService,
    private readonly assinaturas: AssinaturasService,
    private readonly maquina: MaquinaEstadosService,
    private readonly cobranca: CobrancaService,
    private readonly webhooks: WebhooksService,
    @Optional() private readonly regua?: ReguaService,
    @Optional() private readonly conciliacao?: ConciliacaoService,
  ) {}

  /** 06:00 / admin — cobranças dos ciclos com entrega em D+5 (RN19). */
  async gerarCobrancas(): Promise<{ geradas: number }> {
    const alvo = somarDias(this.clock.hoje(), 5);
    const ativas = await this.prisma.assinatura.findMany({
      where: { status: StatusAssinatura.ATIVA },
      select: { id: true },
    });
    let geradas = 0;
    for (const a of ativas) {
      try {
        const ciclo = await this.assinaturas.proximoCicloAberto(a.id);
        if (dataIso(ciclo.dataEntrega) !== alvo) continue;
        if (ciclo.status !== StatusCiclo.AGENDADO) continue;
        const fatores = ciclo.calculoPreco?.fatores as { motivoPulo?: string } | null | undefined;
        if (fatores?.motivoPulo) continue;

        await this.assinaturas.congelarCiclo(ciclo.id);
        await this.prisma.$transaction(async (tx) => {
          const c = await tx.ciclo.findUnique({ where: { id: ciclo.id } });
          if (c && c.status === StatusCiclo.AGENDADO) {
            await this.maquina.ciclo(tx, c, StatusCiclo.COBRADO);
          }
        });
        // cr-5: Pix, boleto (vence em D-5, RN25) ou cartão, conforme a assinatura; abate créditos.
        await this.cobranca.cobrarCiclo(ciclo.id);
        geradas++;
        this.log.log(`Cobrança gerada ciclo=${ciclo.id} entrega=${alvo}`);
      } catch (e) {
        this.log.warn(`Falha cobrança assinatura=${a.id}: ${e instanceof Error ? e.message : e}`);
      }
    }
    return { geradas };
  }

  /** 00:05 — corte CT22 + AGUARDANDO+3 + régua mínima. */
  async corteERegua(): Promise<void> {
    await this.cancelarCobradoAposCorte();
    await this.cancelarAguardandoSemPagamento();
    await this.reguaMinima();
    // cr-5: régua completa (+7 suspensão, +30 cancelamento, nova tentativa no cartão) e conciliação.
    await this.regua?.executar();
    await this.conciliacao?.executar();
  }

  /** CT22: COBRADO sem pagamento até o corte → CANCELADO. */
  async cancelarCobradoAposCorte(): Promise<number> {
    const agora = this.clock.agora();
    const cobrados = await this.prisma.ciclo.findMany({
      where: { status: StatusCiclo.COBRADO },
      include: { pagamentos: true },
    });
    let n = 0;
    for (const c of cobrados) {
      if (agora <= c.dataCorte) continue;
      if (c.pagamentos.some((p) => p.status === StatusPagamento.PAGO)) continue;
      await this.prisma.$transaction(async (tx) => {
        const ciclo = await tx.ciclo.findUnique({ where: { id: c.id } });
        if (ciclo?.status === StatusCiclo.COBRADO) {
          await this.maquina.ciclo(tx, ciclo, StatusCiclo.CANCELADO);
          const calc = await tx.calculoPreco.findUnique({ where: { cicloId: c.id } });
          if (calc) {
            const fatores = { ...((calc.fatores as object) ?? {}), motivoPulo: 'CANCELAMENTO' };
            await tx.calculoPreco.update({ where: { cicloId: c.id }, data: { fatores } });
          }
        }
      });
      n++;
    }
    return n;
  }

  /** AGUARDANDO_PAGAMENTO com vencimento do 1º pagamento + 3 dias → CANCELADA. */
  async cancelarAguardandoSemPagamento(): Promise<number> {
    const hoje = this.clock.hoje();
    const lista = await this.prisma.assinatura.findMany({
      where: { status: StatusAssinatura.AGUARDANDO_PAGAMENTO },
      include: {
        ciclos: { where: { numero: 1 }, include: { pagamentos: true }, take: 1 },
      },
    });
    let n = 0;
    for (const a of lista) {
      const pag = a.ciclos[0]?.pagamentos[0];
      if (!pag || pag.status === StatusPagamento.PAGO) continue;
      const limite = somarDias(pag.vencimento.toISOString().slice(0, 10), 3);
      if (hoje <= limite) continue;
      await this.prisma.$transaction(async (tx) => {
        const ass = await tx.assinatura.findUnique({ where: { id: a.id } });
        if (ass?.status === StatusAssinatura.AGUARDANDO_PAGAMENTO) {
          await this.maquina.assinatura(tx, ass, StatusAssinatura.CANCELADA);
        }
      });
      n++;
    }
    return n;
  }

  async reguaMinima(): Promise<void> {
    const ontem = somarDias(this.clock.hoje(), -1);
    const vencidos = await this.prisma.pagamento.findMany({
      where: {
        status: StatusPagamento.PENDENTE,
        vencimento: { lte: new Date(`${ontem}T00:00:00.000Z`) },
      },
    });
    for (const p of vencidos) {
      this.log.log(
        `Régua lembrete: pagamento=${p.id} ciclo=${p.cicloId} — retenção da separação até regularizar`,
      );
    }
  }

  async processarFilaWebhook(): Promise<number> {
    return this.webhooks.processarPendentes();
  }
}
