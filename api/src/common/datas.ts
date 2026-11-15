/** Utilidades de data civil (AAAA-MM-DD), sem fuso: o "hoje" vem do ClockService em America/Sao_Paulo. */

const DATA_ISO = /^(\d{4})-(\d{2})-(\d{2})$/;

export function dataIsoValida(valor: string): boolean {
  const m = DATA_ISO.exec(valor);
  if (!m) return false;
  const [ano, mes, dia] = [Number(m[1]), Number(m[2]), Number(m[3])];
  const d = new Date(Date.UTC(ano, mes - 1, dia));
  return d.getUTCFullYear() === ano && d.getUTCMonth() === mes - 1 && d.getUTCDate() === dia;
}

/** Idade completa em anos na data `hoje` (ambas AAAA-MM-DD). Aniversário conta no próprio dia. */
export function idadeEm(nascimento: string, hoje: string): number {
  const [an, mn, dn] = nascimento.split('-').map(Number);
  const [ah, mh, dh] = hoje.split('-').map(Number);
  let idade = ah - an;
  if (mh < mn || (mh === mn && dh < dn)) idade--;
  return idade;
}

/** Converte AAAA-MM-DD para Date à meia-noite UTC (formato que o Prisma grava em @db.Date). */
export function dataIsoParaDate(valor: string): Date {
  return new Date(`${valor}T00:00:00.000Z`);
}

/** Inverso de dataIsoParaDate. */
export function dateParaDataIso(valor: Date): string {
  return valor.toISOString().slice(0, 10);
}
