import { Injectable, Logger, Inject } from '@nestjs/common';
import { FormaPagamento, StatusAssinatura, StatusPagamento } from '../../prisma/generated/prisma/client';
import { MaquinaEstadosService } from '../assinaturas/maquina-estados.service';
import { somarDias } from '../ciclos/agenda';
import { ClockService } from '../common/clock.service';
import { PrismaService } from '../common/prisma.service';
import { CobrancaService } from './cobranca.service';
import { PAGAMENTO_GATEWAY, PagamentoGateway } from './pagamento.gateway';

/** Régua de inadimplência do Anexo (dias depois do vencimento). */
export const REGUA = { lembrete: 1, suspensao: 7, cancelamento: 30 };

export interface ResultadoRegua {
  tentativasCartao: number;
  lembretes: number;
  suspensas: number;
  canceladas: number;
}

/**
 * Régua completa (job das 00:05, São Paulo):
 * - nova tentativa no cartão agendada para hoje (CT18);
 * - vencimento +1: lembrete; +7: assinatura SUSPENSA; +30: CANCELADA e cobrança encerrada.
 * Pagar depois da suspensão reativa (`CobrancaService.confirmarPagamentoDoCiclo`).
 */
@Injectable()
export class ReguaService {
  private readonly log = new Logger(ReguaService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly clock: ClockService,
    private readonly maquina: MaquinaEstadosService,
    private readonly cobranca: CobrancaService,
    @Inject(PAGAMENTO_GATEWAY) private readonly gateway: PagamentoGateway,
  ) {}

  async executar(): Promise<ResultadoRegua> {
    const hoje = this.clock.hoje();
    const r: ResultadoRegua = { tentativasCartao: 0, lembretes: 0, suspensas: 0, canceladas: 0 };

    // CT18: tentativas no cartão agendadas (sem cobrança no Asaas ainda) com vencimento até hoje.
    const agendadas = await this.prisma.pagamento.findMany({
      where: {
        forma: FormaPagamento.CARTAO,
        status: StatusPagamento.PENDENTE,
        asaasPaymentId: null,
        vencimento: { lte: new Date(`${hoje}T00:00:00.000Z`) },
      },
    });
    for (const p of agendadas) {
      try {
        if (await this.cobranca.cobrarTentativaCartao(p.id)) r.tentativasCartao++;
      } catch (e) {
        this.log.warn(`Nova tentativa no cartão falhou pagamento=${p.id}: ${e instanceof Error ? e.message : e}`);
      }
    }

    const emAberto = await this.prisma.pagamento.findMany({
      where: { status: { in: [StatusPagamento.PENDENTE, StatusPagamento.VENCIDO] }, asaasPaymentId: { not: null } },
      include: { ciclo: { include: { assinatura: true } } },
    });
    for (const p of emAberto) {
      const venc = p.vencimento.toISOString().slice(0, 10);
      const assinatura = p.ciclo.assinatura;
      if (hoje >= somarDias(venc, REGUA.cancelamento)) {
        if (assinatura.status === StatusAssinatura.SUSPENSA || assinatura.status === StatusAssinatura.ATIVA) {
          await this.prisma.$transaction(async (tx) => {
            const a = await tx.assinatura.findUnique({ where: { id: assinatura.id } });
            if (a && a.status !== StatusAssinatura.CANCELADA) await this.maquina.assinatura(tx, a, StatusAssinatura.CANCELADA);
            await tx.pagamento.update({ where: { id: p.id }, data: { status: StatusPagamento.CANCELADO } });
          });
          try {
            await this.gateway.cancelarCobranca(p.asaasPaymentId!);
          } catch (e) {
            this.log.warn(`Cobrança ${p.asaasPaymentId} não encerrada no Asaas: ${e instanceof Error ? e.message : e}`);
          }
          r.canceladas++;
          this.log.log(`Régua +30: assinatura=${assinatura.id} cancelada, cobrança encerrada`);
        }
        continue;
      }
      if (hoje >= somarDias(venc, REGUA.suspensao)) {
        if (assinatura.status === StatusAssinatura.ATIVA) {
          await this.prisma.$transaction(async (tx) => {
            const a = await tx.assinatura.findUnique({ where: { id: assinatura.id } });
            if (a?.status === StatusAssinatura.ATIVA) await this.maquina.assinatura(tx, a, StatusAssinatura.SUSPENSA);
          });
          r.suspensas++;
          this.log.log(`Régua +7: assinatura=${assinatura.id} suspensa`);
        }
        continue;
      }
      if (hoje === somarDias(venc, REGUA.lembrete)) {
        r.lembretes++;
        this.log.log(`Régua +1: lembrete pagamento=${p.id} ciclo=${p.cicloId} (push/e-mail na cr-6)`);
      }
    }
    return r;
  }
}
