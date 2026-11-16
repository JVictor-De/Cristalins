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

/** SEG10: e-mail mascarado nos logs (a***@dominio). */
export function mascararEmail(email: string): string {
  const [usuario, dominio] = email.split('@');
  if (!dominio) return '***';
  return `${usuario.slice(0, 1)}***@${dominio}`;
}

/** Token de push mascarado nos logs. */
export function mascararToken(token: string): string {
  return token.length <= 8 ? '***' : `${token.slice(0, 4)}…${token.slice(-4)}`;
}
