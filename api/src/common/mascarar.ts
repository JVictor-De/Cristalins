/** SEG10: nunca gravar CPF, e-mail ou telefone completos em log. */

export function mascararEmail(email: string): string {
  const [usuario, dominio] = email.split('@');
  if (!dominio) return '***';
  return `${usuario.slice(0, 1)}***@${dominio}`;
}

export function mascararCpf(cpfCnpj: string): string {
  const d = cpfCnpj.replace(/\D/g, '');
  if (d.length < 4) return '***';
  return `***${d.slice(-4)}`;
}

export function mascararTelefone(tel: string): string {
  const d = tel.replace(/\D/g, '');
  if (d.length < 4) return '***';
  return `***${d.slice(-4)}`;
}

export function mascararToken(token: string): string {
  return token.length <= 8 ? '***' : `${token.slice(0, 4)}…${token.slice(-4)}`;
}

/** Remove PII óbvio de uma linha de log (stack, mensagem). */
export function mascararPii(texto: string): string {
  return texto
    .replace(/[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}/g, (m) => mascararEmail(m))
    .replace(/\b\d{11}\b/g, (m) => mascararCpf(m))
    .replace(/\b\d{14}\b/g, (m) => mascararCpf(m))
    .replace(/\b(?:\+?55)?\s*\(?\d{2}\)?\s*9?\d{4}[-.\s]?\d{4}\b/g, (m) => mascararTelefone(m));
}
