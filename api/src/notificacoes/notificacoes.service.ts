import { Inject, Injectable, Logger } from '@nestjs/common';
import { ApiProperty } from '@nestjs/swagger';
import { IsString, Length } from 'class-validator';
import { PrismaService } from '../common/prisma.service';
import { CanalEmail, CanalPush, CANAL_EMAIL, CANAL_PUSH, EventoNotificacao, Mensagem, mascararEmail } from './notificacoes.tipos';

export class PushTokenDto {
  @ApiProperty({ description: 'Token do Firebase Cloud Messaging do aparelho' })
  @IsString()
  @Length(10, 4096, { message: 'Token de push inválido.' })
  token: string;
}

const moeda = (v: number) => v.toLocaleString('pt-BR', { style: 'currency', currency: 'BRL' });
const dia = (iso: string) => `${iso.slice(8, 10)}/${iso.slice(5, 7)}`;

/** Textos curtos, em segunda pessoa (voz do Anexo). Sem promessa de saúde. */
export const MENSAGENS = {
  cobranca: (entrega: string, valor: number, vencimento: string): Mensagem => ({
    titulo: 'Cobrança da sua entrega',
    corpo: `A cobrança da entrega de ${dia(entrega)} é de ${moeda(valor)} e vence em ${dia(vencimento)}.`,
  }),
  aumento: (entrega: string, valor: number, anterior: number, corte: string): Mensagem => ({
    titulo: 'Sua próxima entrega ficou mais cara',
    corpo:
      `A entrega de ${dia(entrega)} ficou em ${moeda(valor)} (antes ${moeda(anterior)}). ` +
      `Você pode pular ou alterar a cesta até ${dia(corte)} às 23:59.`,
  }),
  pagamento: (entrega: string): Mensagem => ({
    titulo: 'Pagamento confirmado',
    corpo: `Recebemos o pagamento. Sua entrega de ${dia(entrega)} está confirmada.`,
  }),
  separacao: (entrega: string, avisos: string[]): Mensagem => ({
    titulo: 'Pedido em separação',
    corpo: [`Estamos separando sua entrega de ${dia(entrega)}.`, ...avisos].join(' '),
  }),
  emRota: (): Mensagem => ({ titulo: 'Saiu para entrega', corpo: 'Seu pedido saiu para entrega hoje.' }),
  entregue: (): Mensagem => ({
    titulo: 'Pedido entregue',
    corpo: 'Seu pedido foi entregue. Se algo veio avariado ou faltando, avise pelo app em até 24 horas.',
  }),
  falhou: (reentrega: string | null): Mensagem => ({
    titulo: 'Não conseguimos entregar',
    corpo: reentrega
      ? `Não conseguimos entregar hoje. Vamos tentar de novo, sem custo, em ${dia(reentrega)}.`
      : 'Não conseguimos entregar de novo. A próxima tentativa tem nova taxa de entrega, ou você pode retirar no centro de distribuição. Fale com o suporte.',
  }),
};

/**
 * Push (FCM) e e-mail (SMTP) ao cliente. Falha de envio nunca quebra o fluxo de negócio: registra
 * no log (mascarado, SEG10) e segue.
 */
@Injectable()
export class NotificacoesService {
  private readonly log = new Logger(NotificacoesService.name);

  constructor(
    private readonly prisma: PrismaService,
    @Inject(CANAL_PUSH) private readonly push: CanalPush,
    @Inject(CANAL_EMAIL) private readonly email: CanalEmail,
  ) {}

  async notificar(clienteId: string, evento: EventoNotificacao, m: Mensagem, dados: Record<string, string> = {}): Promise<void> {
    const cliente = await this.prisma.cliente.findUnique({ where: { id: clienteId } });
    if (!cliente || cliente.excluidoEm) return;
    const extras = { evento, ...dados };
    if (cliente.pushToken) {
      try {
        await this.push.enviar(cliente.pushToken, m, extras);
      } catch (e) {
        this.log.warn(`Push ${evento} falhou: ${(e as Error).message}`);
      }
    }
    await this.enviarEmail(cliente.email, m.titulo, m.corpo, evento);
  }

  /** E-mail avulso (RF52). Devolve `false` se o envio falhar. */
  async enviarEmail(para: string, assunto: string, texto: string, contexto = 'EMAIL'): Promise<boolean> {
    try {
      await this.email.enviar(para, assunto, `${texto}\n\nCristalins`);
      return true;
    } catch (e) {
      this.log.warn(`E-mail ${contexto} para ${mascararEmail(para)} falhou: ${(e as Error).message}`);
      return false;
    }
  }

  async registrarPushToken(clienteId: string, token: string): Promise<void> {
    await this.prisma.cliente.update({ where: { id: clienteId }, data: { pushToken: token } });
  }
}
