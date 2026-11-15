import Decimal from 'decimal.js';
import type { ObjetivoKit, TipoProduto } from '../../prisma/generated/prisma/client';

/**
 * Catálogo igual ao `prisma/seed.ts` (valores de exemplo do Anexo), para testes sem banco.
 * Os ids são fixos para facilitar asserções.
 */
export interface ProdutoTeste {
  id: string;
  codigo: string;
  nome: string;
  tipo: TipoProduto;
  volumeMl: number;
  ue: Decimal;
  embalagemQtd: number;
  precoBase: Decimal;
  precoPiso: Decimal;
  pesoKg: Decimal;
  estoque: number | null;
  validadeDias: number | null;
  ativo: boolean;
}

function p(
  codigo: string,
  nome: string,
  tipo: TipoProduto,
  volumeMl: number,
  ue: string,
  embalagemQtd: number,
  precoBase: string,
  precoPiso: string,
  pesoKg: string,
): ProdutoTeste {
  return {
    id: `prod-${codigo}`,
    codigo,
    nome,
    tipo,
    volumeMl,
    ue: new Decimal(ue),
    embalagemQtd,
    precoBase: new Decimal(precoBase),
    precoPiso: new Decimal(precoPiso),
    pesoKg: new Decimal(pesoKg),
    estoque: null,
    validadeDias: null,
    ativo: true,
  };
}

export function produtosSeed(): ProdutoTeste[] {
  return [
    p('WP500', 'Water Protein (água com colágeno)', 'PRINCIPAL', 500, '1', 6, '9.90', '7.50', '0.53'),
    p('FF500', 'Flow Fiber', 'PRINCIPAL', 500, '1', 6, '8.90', '6.70', '0.53'),
    p('AMS500', 'Água mineral sem gás', 'COMPLEMENTO', 500, '1', 12, '2.20', '1.50', '0.52'),
    p('AMC510', 'Água mineral com gás', 'COMPLEMENTO', 510, '1.02', 12, '2.90', '2.00', '0.53'),
    p('AMN1500', 'Água mineral natural', 'COMPLEMENTO', 1500, '3', 6, '3.90', '2.70', '1.55'),
    p('AMN5000', 'Água mineral natural (galão)', 'COMPLEMENTO', 5000, '10', 1, '9.90', '7.00', '5.20'),
    p('AMC200', 'Água mineral no copo', 'B2B', 200, '0.4', 48, '0.90', '0.60', '0.21'),
    p('GUA2000', 'Guaraná Cristalins', 'ADDON', 2000, '4', 1, '7.90', '5.50', '2.10'),
  ];
}

export function porCodigo(produtos: ProdutoTeste[]): Record<string, ProdutoTeste> {
  return Object.fromEntries(produtos.map((x) => [x.codigo, x]));
}

export interface KitTeste {
  id: string;
  codigo: string;
  nome: string;
  objetivo: ObjetivoKit;
  itens: { kitId: string; produtoId: string; quantidade: number; produto: ProdutoTeste }[];
}

export function kitsSeed(produtos = produtosSeed()): KitTeste[] {
  const prod = porCodigo(produtos);
  const kit = (codigo: string, nome: string, objetivo: ObjetivoKit, itens: Record<string, number>): KitTeste => ({
    id: `kit-${codigo}`,
    codigo,
    nome,
    objetivo,
    itens: Object.entries(itens).map(([c, quantidade]) => ({
      kitId: `kit-${codigo}`,
      produtoId: prod[c].id,
      quantidade,
      produto: prod[c],
    })),
  });
  return [
    kit('KIT-TREINO', 'Kit Treino', 'TREINO', { WP500: 12 }),
    kit('KIT-EQUILIBRIO', 'Kit Equilíbrio', 'EQUILIBRIO', { WP500: 6, FF500: 6 }),
    kit('KIT-CASA', 'Kit Casa', 'CASA', { WP500: 6, AMN5000: 2 }),
    kit('KIT-ESCRITORIO', 'Kit Escritório', 'ESCRITORIO', { WP500: 12, AMC200: 48 }),
  ];
}

export interface FatorTeste {
  id: string;
  chave: string;
  valor: Decimal;
  ativoDe: Date;
  ativoAte: Date | null;
}

const d = (iso: string) => new Date(`${iso}T00:00:00.000Z`);

export function fatoresSeed(): FatorTeste[] {
  const f = (chave: string, valor: string, de: string, ate: string | null): FatorTeste => ({
    id: `fator-${chave}`,
    chave,
    valor: new Decimal(valor),
    ativoDe: d(de),
    ativoAte: ate ? d(ate) : null,
  });
  return [
    f('VOLUME_24_47', '0.08', '2026-01-01', null),
    f('VOLUME_48_MAIS', '0.12', '2026-01-01', null),
    f('COMPROMISSO_TRIMESTRAL', '0.07', '2026-01-01', null),
    f('COMPROMISSO_EMPRESA', '0.10', '2026-01-01', null),
    f('FIDELIDADE_POR_CICLO', '0.01', '2026-01-01', null),
    f('FIDELIDADE_MAXIMO', '0.05', '2026-01-01', null),
    f('DEMANDA_VERAO', '0.05', '2026-12-01', '2027-03-31'),
  ];
}

export function zonasSeed() {
  const z = (nome: string, bairros: string[], taxa: string) => ({
    id: `zona-${nome.replace(/\s/g, '-')}`,
    nome,
    bairros,
    taxaEntrega: new Decimal(taxa),
    diasEntrega: [] as string[],
    ativa: true,
  });
  return [
    z('Centro', ['Centro', 'Lapa', 'Santa Teresa'], '9.90'),
    z('Zona Sul', ['Copacabana', 'Ipanema', 'Leblon', 'Botafogo', 'Flamengo'], '9.90'),
    z('Barra e Recreio', ['Barra da Tijuca', 'Recreio', 'Jacarepaguá'], '12.90'),
    z('Zona Norte', ['Tijuca', 'Méier', 'Vila Isabel', 'Ilha do Governador'], '12.90'),
    z('Zona Oeste', ['Campo Grande', 'Bangu', 'Santa Cruz'], '19.90'),
  ];
}

export function cupomSeed() {
  return {
    id: 'cupom-BEMVINDO10',
    codigo: 'BEMVINDO10',
    percentual: new Decimal('10.00'),
    validade: d('2027-12-31'),
    usosMax: 100 as number | null,
    usos: 0,
  };
}
