import { DiaSemana, Frequencia } from '../../prisma/generated/prisma/client';

/**
 * Datas de ciclo (CONTEXTO, "Ciclo"). Tudo em data civil AAAA-MM-DD de São Paulo.
 * São Paulo está em UTC−3 sem horário de verão desde 2019; o corte usa esse deslocamento fixo.
 */

const DIAS: DiaSemana[] = [
  DiaSemana.DOM,
  DiaSemana.SEG,
  DiaSemana.TER,
  DiaSemana.QUA,
  DiaSemana.QUI,
  DiaSemana.SEX,
  DiaSemana.SAB,
];

export const DIAS_POR_FREQUENCIA: Record<Frequencia, number> = {
  [Frequencia.SEMANAL]: 7,
  [Frequencia.QUINZENAL]: 14,
  [Frequencia.MENSAL]: 28,
};

/** RN08: a primeira entrega é pelo menos 2 dias depois (do pagamento; na criação, de hoje). */
export const DIAS_MINIMOS_PRIMEIRA_ENTREGA = 2;
/** RN07: corte às 23h59 de D-2. */
export const DIAS_CORTE = 2;
const OFFSET_SAO_PAULO = '-03:00';

const utc = (data: string) => new Date(`${data}T00:00:00.000Z`);

export function diaDaSemana(data: string): DiaSemana {
  return DIAS[utc(data).getUTCDay()];
}

export function somarDias(data: string, dias: number): string {
  const d = utc(data);
  d.setUTCDate(d.getUTCDate() + dias);
  return d.toISOString().slice(0, 10);
}

/** Soma meses na data civil; dia que não existe no mês de destino vai para o último dia (31/01 + 1 = 28/02). */
export function somarMeses(data: string, meses: number): string {
  const [ano, mes, dia] = data.split('-').map(Number);
  const alvo = new Date(Date.UTC(ano, mes - 1 + meses, 1));
  const ultimoDia = new Date(Date.UTC(alvo.getUTCFullYear(), alvo.getUTCMonth() + 1, 0)).getUTCDate();
  alvo.setUTCDate(Math.min(dia, ultimoDia));
  return alvo.toISOString().slice(0, 10);
}

/** Primeira data ≥ `minima` em que a zona entrega. */
export function proximaDataDaZona(minima: string, dias: DiaSemana[]): string {
  if (!dias.length) throw new Error('Zona sem dias de entrega configurados.');
  for (let i = 0; i < 7; i++) {
    const candidata = somarDias(minima, i);
    if (dias.includes(diaDaSemana(candidata))) return candidata;
  }
  throw new Error('inalcançável');
}

/** Estimativa da primeira entrega a partir de `hoje` (recalculada na confirmação do pagamento, `cr-3`). */
export function primeiraEntrega(hoje: string, dias: DiaSemana[]): string {
  return proximaDataDaZona(somarDias(hoje, DIAS_MINIMOS_PRIMEIRA_ENTREGA), dias);
}

/** Entrega anterior + 7/14/28, ajustada ao próximo dia da zona. */
export function proximaEntrega(anterior: string, frequencia: Frequencia, dias: DiaSemana[]): string {
  return proximaDataDaZona(somarDias(anterior, DIAS_POR_FREQUENCIA[frequencia]), dias);
}

/** Instante do corte: 23:59:59.999 de (entrega − 2 dias) em São Paulo. */
export function dataCorte(entrega: string): Date {
  return new Date(`${somarDias(entrega, -DIAS_CORTE)}T23:59:59.999${OFFSET_SAO_PAULO}`);
}

export function dataIso(d: Date): string {
  return d.toISOString().slice(0, 10);
}
