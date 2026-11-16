import { Injectable } from '@nestjs/common';
import Decimal from 'decimal.js';
import { Prisma, TipoProduto } from '../../prisma/generated/prisma/client';
import { CreditosService } from '../creditos/creditos.service';

type Db = Prisma.TransactionClient;
type Valor = Decimal | { toString(): string };

export interface ProdutoEstoque {
  id: string;
  codigo: string;
  nome: string;
  tipo: TipoProduto;
  volumeMl: number;
  precoBase: Valor;
  estoque: number | null;
  ativo: boolean;
}

export interface ItemParaSeparar {
  produto: ProdutoEstoque;
  quantidade: number;
  /** Preço unitário cobrado no ciclo (base do crédito). */
  precoUnitario: Valor;
}

export type Decisao =
  | { acao: 'MANTIDO'; produto: ProdutoEstoque; quantidade: number }
  | { acao: 'SUBSTITUIDO'; produto: ProdutoEstoque; por: ProdutoEstoque; quantidade: number }
  | { acao: 'PULADO'; produto: ProdutoEstoque; quantidade: number; credito: string };

const d = (v: Valor) => new Decimal(v.toString());

/** `estoque = null` é produto sem controle de estoque (sempre disponível). */
function disponivel(p: ProdutoEstoque, quantidade: number, reservado: Map<string, number>): boolean {
  if (p.estoque === null) return true;
  return p.estoque - (reservado.get(p.id) ?? 0) >= quantidade;
}

function reservar(p: ProdutoEstoque, quantidade: number, reservado: Map<string, number>): void {
  reservado.set(p.id, (reservado.get(p.id) ?? 0) + quantidade);
}

/**
 * RN06 (CT21), função pura. Item sem estoque suficiente troca por produto ativo do mesmo tipo e
 * volume, com preço base igual ou menor e estoque para a quantidade inteira. Entre os elegíveis,
 * o de maior preço base (o mais próximo do original). Sem substituto, o item é pulado e vira
 * crédito do valor cobrado (`precoUnitario × quantidade`). `reservado` acumula o que os ciclos
 * anteriores do mesmo dia já separaram.
 */
export function planejarSeparacao(
  itens: ItemParaSeparar[],
  catalogo: ProdutoEstoque[],
  reservado = new Map<string, number>(),
): Decisao[] {
  return itens.map((item) => {
    const { produto, quantidade } = item;
    if (disponivel(produto, quantidade, reservado)) {
      reservar(produto, quantidade, reservado);
      return { acao: 'MANTIDO', produto, quantidade };
    }
    const por = catalogo
      .filter(
        (c) =>
          c.id !== produto.id &&
          c.ativo &&
          c.tipo === produto.tipo &&
          c.volumeMl === produto.volumeMl &&
          d(c.precoBase).lte(d(produto.precoBase)) &&
          disponivel(c, quantidade, reservado),
      )
      .sort((a, b) => d(b.precoBase).cmp(d(a.precoBase)) || a.codigo.localeCompare(b.codigo))[0];
    if (por) {
      reservar(por, quantidade, reservado);
      return { acao: 'SUBSTITUIDO', produto, por, quantidade };
    }
    return {
      acao: 'PULADO',
      produto,
      quantidade,
      credito: d(item.precoUnitario).times(quantidade).toDecimalPlaces(2, Decimal.ROUND_HALF_UP).toFixed(2),
    };
  });
}

/** Aviso ao cliente (RN06: "com aviso ao cliente"). */
export function avisoDaDecisao(x: Decisao): string | null {
  if (x.acao === 'SUBSTITUIDO') {
    return `Sem estoque de ${x.produto.nome}: enviamos ${x.por.nome}, do mesmo tipo e volume, sem custo a mais.`;
  }
  if (x.acao === 'PULADO') {
    const valor = Number(x.credito).toLocaleString('pt-BR', { style: 'currency', currency: 'BRL' });
    return `Sem estoque de ${x.produto.nome}: o item fica fora desta entrega e virou crédito de ${valor}.`;
  }
  return null;
}

/** Aplica o RN06 na separação (PAGO → SEPARADO), dentro da transação do status. */
@Injectable()
export class EstoqueService {
  constructor(private readonly creditos: CreditosService) {}

  async separar(tx: Db, cicloId: string, clienteId: string): Promise<Decisao[]> {
    const itens = await tx.itemCiclo.findMany({ where: { cicloId }, include: { produto: true } });
    const catalogo = await tx.produto.findMany({});
    const decisoes = planejarSeparacao(
      itens.map((i) => ({ produto: i.produto, quantidade: i.quantidade, precoUnitario: i.precoUnitario })),
      catalogo,
    );

    for (const [i, x] of decisoes.entries()) {
      const original = itens[i];
      if (x.acao === 'MANTIDO') {
        await this.baixar(tx, x.produto, x.quantidade);
        continue;
      }
      await tx.itemCiclo.delete({ where: { cicloId_produtoId: { cicloId, produtoId: original.produtoId } } });
      if (x.acao === 'SUBSTITUIDO') {
        // Mantém o preço cobrado (o substituto vale igual ou menos): o registro do ciclo bate com o pagamento.
        const existente = await tx.itemCiclo.findUnique({ where: { cicloId_produtoId: { cicloId, produtoId: x.por.id } } });
        if (existente) {
          await tx.itemCiclo.update({
            where: { cicloId_produtoId: { cicloId, produtoId: x.por.id } },
            data: { quantidade: { increment: x.quantidade } },
          });
        } else {
          await tx.itemCiclo.create({
            data: { cicloId, produtoId: x.por.id, quantidade: x.quantidade, precoUnitario: original.precoUnitario },
          });
        }
        await this.baixar(tx, x.por, x.quantidade);
      } else {
        await this.creditos.conceder(tx, clienteId, x.credito, `ESTOQUE:${cicloId}:${x.produto.codigo}`);
      }
    }

    const alteracoes = decisoes.filter((x) => x.acao !== 'MANTIDO');
    if (alteracoes.length) {
      const calculo = await tx.calculoPreco.findUnique({ where: { cicloId } });
      if (calculo) {
        const fatores = (calculo.fatores ?? {}) as Record<string, unknown>;
        await tx.calculoPreco.update({
          where: { cicloId },
          data: {
            fatores: {
              ...fatores,
              estoque: alteracoes.map((x) => ({
                produto: x.produto.codigo,
                quantidade: x.quantidade,
                acao: x.acao,
                ...(x.acao === 'SUBSTITUIDO' && { por: x.por.codigo }),
                ...(x.acao === 'PULADO' && { credito: x.credito }),
              })),
            } as Prisma.InputJsonValue,
          },
        });
      }
    }
    return decisoes;
  }

  /** Baixa do estoque de reposição (RN15) com a mesma regra do RN06. */
  async baixar(tx: Db, produto: ProdutoEstoque, quantidade: number): Promise<void> {
    if (produto.estoque === null) return;
    await tx.produto.update({ where: { id: produto.id }, data: { estoque: { decrement: quantidade } } });
  }
}
