import { Injectable, Logger, UnauthorizedException } from '@nestjs/common';
import { Prisma } from '../../prisma/generated/prisma/client';
import { CobrancaService } from '../asaas/cobranca.service';
import { PrismaService } from '../common/prisma.service';

/**
 * Recebe eventos Asaas: valida token, grava `id_evento` único e responde 200.
 * O processamento fica no job de 1 minuto (idempotente).
 */
@Injectable()
export class WebhooksService {
  private readonly log = new Logger(WebhooksService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly cobranca: CobrancaService,
  ) {}

  /** CT15: token inválido → 401 e nada gravado. */
  validarToken(header: string | undefined): void {
    const esperado = process.env.ASAAS_WEBHOOK_TOKEN ?? '';
    if (!esperado || header !== esperado) {
      throw new UnauthorizedException({ codigo: 'NAO_AUTENTICADO', mensagem: 'Token do webhook inválido.' });
    }
  }

  /**
   * Grava o evento. Duplicata do mesmo `id_evento` (P2002) é ignorada — CT14.
   * Sempre responde sucesso ao controller depois desta chamada (ou 401 antes).
   */
  async receber(idEvento: string, tipo: string, payload: unknown): Promise<{ gravado: boolean }> {
    try {
      await this.prisma.eventoWebhook.create({
        data: {
          idEvento,
          tipo,
          payload: payload as Prisma.InputJsonValue,
        },
      });
      return { gravado: true };
    } catch (e) {
      if (e instanceof Prisma.PrismaClientKnownRequestError && e.code === 'P2002') {
        return { gravado: false };
      }
      // PrismaFake usa ErroUnicidade com code P2002
      if (e && typeof e === 'object' && 'code' in e && (e as { code: string }).code === 'P2002') {
        return { gravado: false };
      }
      throw e;
    }
  }

  /** Processa pendentes (job a cada minuto). */
  async processarPendentes(): Promise<number> {
    const pendentes = await this.prisma.eventoWebhook.findMany({
      where: { processadoEm: null },
      orderBy: { recebidoEm: 'asc' },
      take: 50,
    });
    let n = 0;
    for (const ev of pendentes) {
      try {
        await this.processarUm(ev.idEvento, ev.tipo, ev.payload);
        await this.prisma.eventoWebhook.update({
          where: { id: ev.id },
          data: { processadoEm: new Date(), erro: null },
        });
        n++;
      } catch (e) {
        const msg = e instanceof Error ? e.message : String(e);
        this.log.warn(`Evento ${ev.idEvento}: ${msg}`);
        await this.prisma.eventoWebhook.update({
          where: { id: ev.id },
          data: { processadoEm: new Date(), erro: msg.slice(0, 500) },
        });
      }
    }
    return n;
  }

  private async processarUm(idEvento: string, tipo: string, payload: unknown): Promise<void> {
    const corpo = payload as {
      payment?: { id?: string; externalReference?: string };
      id?: string;
    };
    const paymentId = corpo.payment?.id ?? corpo.id;
    const cicloId = corpo.payment?.externalReference;

    if (tipo === 'PAYMENT_CONFIRMED' || tipo === 'PAYMENT_RECEIVED') {
      if (cicloId) {
        await this.cobranca.confirmarPagamentoDoCiclo(cicloId, paymentId);
        return;
      }
      if (paymentId) {
        const pag = await this.prisma.pagamento.findFirst({ where: { asaasPaymentId: paymentId } });
        if (pag) await this.cobranca.confirmarPagamentoDoCiclo(pag.cicloId, paymentId);
      }
      return;
    }
    // cr-5: recusa no cartão (CT18), vencido, estornado e removido.
    this.log.debug(`Evento ${tipo} ${idEvento}`);
    await this.cobranca.processarEvento(tipo, paymentId);
  }
}
