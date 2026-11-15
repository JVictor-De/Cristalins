import Decimal from 'decimal.js';
import type { Plano, TipoProduto } from '../../prisma/generated/prisma/client';

/** Decimal do domínio: meio para cima, precisão folgada (arredonda só o total final). */
export const Dec = Decimal.clone({ precision: 40, rounding: Decimal.ROUND_HALF_UP });
export type Dec = Decimal;

/** Aceita Decimal do Prisma, decimal.js, string ou número inteiro de contagem. */
export type DecimalEntrada = { toString(): string } | string | number;
export const dec = (v: DecimalEntrada): Dec => new Dec(v.toString());

/** Dados do produto que o cálculo usa (subconjunto de `Produto`). */
export interface ProdutoPreco {
  id: string;
  codigo: string;
  tipo: TipoProduto;
  ue: DecimalEntrada;
  embalagemQtd: number;
  precoBase: DecimalEntrada;
  precoPiso: DecimalEntrada;
  pesoKg: DecimalEntrada;
}

export interface ItemCesta {
  produto: ProdutoPreco;
  quantidade: number;
}

/** Percentuais (frações) vindos de `FatorPreco` vigente na data da entrega. */
export interface ParametrosPreco {
  volume24a47: Dec;
  volume48mais: Dec;
  compromissoTrimestral: Dec;
  compromissoEmpresa: Dec;
  fidelidadePorCiclo: Dec;
  fidelidadeMaxima: Dec;
  /** Soma dos fatores DEMANDA_* vigentes, limitada a −5%…+8%. */
  demanda: Dec;
}

export interface EntradaCalculo {
  itens: ItemCesta[];
  plano: Plano;
  parametros: ParametrosPreco;
  ciclosPagosEmDia: number;
  /** Fração (0.10 = 10%); ausente = sem cupom. */
  cupom?: Dec;
  /** Taxa da zona; nulo = zona ainda não informada (frete 0 na simulação). */
  taxaZona: Dec | null;
  creditos: Dec;
  /** produtoId → preço unitário do ciclo anterior (ItemCiclo). */
  precosAnteriores: Map<string, Dec>;
}

export type RegraAplicada = 'PISO' | 'TRAVA_MAXIMA' | 'TRAVA_MINIMA' | 'ADDON' | null;

export interface ItemCalculado {
  produto: ProdutoPreco;
  quantidade: number;
  precoBase: Dec;
  /** Sem arredondamento: o total é que arredonda. */
  precoUnitario: Dec;
  regra: RegraAplicada;
}

export interface FatoresAplicados {
  volume: Dec;
  compromisso: Dec;
  fidelidade: Dec;
  demanda: Dec;
  cupom: Dec;
  /** Produto dos fatores: (1−vol)(1−comp)(1−fid)(1+dem)(1−cupom). */
  fator: Dec;
}

export interface ResultadoCalculo {
  itens: ItemCalculado[];
  /** UE da cesta sem add-ons (base do desconto de volume e da cesta mínima). */
  ueSemAddon: Dec;
  ueTotal: Dec;
  pesoKg: Dec;
  fatores: FatoresAplicados;
  subtotal: Dec;
  frete: Dec;
  creditos: Dec;
  /** Arredondado a 2 casas, meio para cima. */
  total: Dec;
}
