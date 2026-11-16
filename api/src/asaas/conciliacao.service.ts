import { Inject, Injectable, Logger } from '@nestjs/common';
import { Prisma, StatusCiclo, StatusPagamento } from '../../prisma/generated/prisma/client';
import { somarDias } from '../ciclos/agenda';
import { ClockService } from '../common/clock.service';
import { PrismaService } from '../common/prisma.service';
import { PAGAMENTO_GATEWAY, PagamentoGateway } from './pagamento.gateway';

/** Janela da conciliação diária (dias para trás). */
export const JANELA_CONCILIACAO_DIAS = 35;

export type TipoDivergencia = 'COBRANCA_SEM_CICLO' | 'COBRANCA_SEM_PAGAMENTO_LOCAL' | 'CICLO_SEM_COBRANCA' | 'STATUS_DIVERGENTE';

export interface Divergencia {
  tipo: TipoDivergencia;
  referencia: string;
  detalhe: string;
}

const PAGO_NO_ASAAS = ['RECEIVED', 'CONFIRMED', 'RECEIVED_IN_CASH'];

/**
 * Conciliação diária com o Asaas. Cada divergência vira um registro em `EventoWebhook`
 * (`tipo = CONCILIACAO_<tipo>`, já marcado como processado para a fila de webhooks não tocar),
 * único por dia e referência. O schema não tem tabela própria (fase sem migração).
 */
@Injectable()
export class ConciliacaoService {
  private readonly log = new Logger(ConciliacaoService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly clock: ClockService,
    @Inject(PAGAMENTO_GATEWAY) private readonly gateway: PagamentoGateway,
  ) {}

  async executar(): Promise<Divergencia[]> {
    const hoje = this.clock.hoje();
    const desde = somarDias(hoje, -JANELA_CONCILIACAO_DIAS);
    const divergencias: Divergencia[] = [];

    const remotas = await this.gateway.listarCobrancas(desde);
    const locais = await this.prisma.pagamento.findMany({ where: { asaasPaymentId: { not: null } } });
    const porId = new Map(locais.map((p) => [p.asaasPaymentId!, p]));

    for (const c of remotas) {
      const ciclo = c.externalReference ? await this.prisma.ciclo.findUnique({ where: { id: c.externalReference } }) : null;
      if (!ciclo) {
        divergencias.push({ tipo: 'COBRANCA_SEM_CICLO', referencia: c.id, detalhe: `externalReference=${c.externalReference ?? '—'}` });
        continue;
      }
      const local = porId.get(c.id);
      if (!local) {
        divergencias.push({ tipo: 'COBRANCA_SEM_PAGAMENTO_LOCAL', referencia: c.id, detalhe: `ciclo=${ciclo.id}` });
        continue;
      }
      if (PAGO_NO_ASAAS.includes(c.status) && local.status !== StatusPagamento.PAGO) {
        divergencias.push({ tipo: 'STATUS_DIVERGENTE', referencia: c.id, detalhe: `asaas=${c.status} local=${local.status}` });
      }
    }

    const cobrados = await this.prisma.ciclo.findMany({ where: { status: StatusCiclo.COBRADO }, include: { pagamentos: true } });
    for (const ciclo of cobrados) {
      if (!ciclo.pagamentos.some((p) => p.asaasPaymentId)) {
        divergencias.push({ tipo: 'CICLO_SEM_COBRANCA', referencia: ciclo.id, detalhe: `numero=${ciclo.numero}` });
      }
    }

    for (const d of divergencias) {
      try {
        await this.prisma.eventoWebhook.create({
          data: {
            idEvento: `conciliacao:${hoje}:${d.tipo}:${d.referencia}`,
            tipo: `CONCILIACAO_${d.tipo}`,
            payload: d as unknown as Prisma.InputJsonValue,
            processadoEm: this.clock.agora(),
          },
        });
      } catch (e) {
        if ((e as { code?: string }).code !== 'P2002') throw e; // já registrada hoje
      }
    }
    if (divergencias.length) this.log.warn(`Conciliação ${hoje}: ${divergencias.length} divergência(s)`);
    return divergencias;
  }
}
