/**
 * RF51/RF22: push e e-mail só nestes eventos (cobrança, pagamento, separação, entrega e aumento
 * de preço). A recuperação de senha (RF52) é só e-mail e não usa esta lista.
 */
export const EVENTOS_NOTIFICACAO = ['COBRANCA', 'PAGAMENTO', 'SEPARACAO', 'ENTREGA', 'AUMENTO_PRECO'] as const;
export type EventoNotificacao = (typeof EVENTOS_NOTIFICACAO)[number];

export interface Mensagem {
  titulo: string;
  corpo: string;
}

/** Canal de push (FCM HTTP v1 em produção). */
export interface CanalPush {
  enviar(token: string, mensagem: Mensagem, dados: Record<string, string>): Promise<void>;
}

/** Canal de e-mail (SMTP em produção). */
export interface CanalEmail {
  enviar(para: string, assunto: string, texto: string): Promise<void>;
}

export const CANAL_PUSH = Symbol('CANAL_PUSH');
export const CANAL_EMAIL = Symbol('CANAL_EMAIL');

export { mascararEmail, mascararToken } from '../common/mascarar';
