import { HttpStatus, Injectable } from '@nestjs/common';
import { PrismaService } from '../common/prisma.service';
import { RegraNegocioException } from '../common/regra-negocio.exception';
import { PESO_MAXIMO_KG, PrecoService, UE_MAXIMA } from '../precos/preco.service';
import { dec, Dec, ItemCesta, ProdutoPreco } from '../precos/preco.tipos';
import { Frequencia, ObjetivoKit, Plano } from '../../prisma/generated/prisma/client';
import { CriarRecomendacaoDto, DIAS_POR_FAIXA, PESSOAS_POR_FAIXA } from './dto/criar-recomendacao.dto';
import { RecomendacaoResponse } from './dto/recomendacao.response';

/** Contato comercial do Anexo (perfil Empresa). Não inventar outro. */
export const CONTATO_COMERCIAL = { email: 'contato@cristalins.com.br', telefone: '(14) 3523-1001' };

const SEMANAS_POR_CICLO: Record<Frequencia, number> = {
  [Frequencia.SEMANAL]: 1,
  [Frequencia.QUINZENAL]: 2,
  [Frequencia.MENSAL]: 4,
};
const GARRAFAS_POR_KIT = 12;
const FARDO_GAS = 12;

type ProdutoQuiz = ProdutoPreco & { ativo: boolean; estoque: number | null };

/** Linha gravada em `Recomendacao` (com o kit incluído). */
interface RecomendacaoGravada {
  id: string;
  clienteId: string;
  kit: { codigo: string } | null;
  multiplicador: number | null;
  frequencia: Frequencia | null;
  itens: unknown;
  ue: { toString(): string };
  valorEstimado: { toString(): string } | null;
  perfilEmpresa: boolean;
  criadoEm: Date;
}

/** Quiz (CONTEXTO, "Quiz" — 11 passos do Anexo). A regra fica toda aqui, nunca no app. */
@Injectable()
export class RecomendacaoService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly preco: PrecoService,
  ) {}

  async recomendar(clienteId: string, dto: CriarRecomendacaoDto): Promise<RecomendacaoResponse> {
    // 1–4: consumo semanal, frequência, garrafas por entrega e multiplicador.
    const s = DIAS_POR_FAIXA[dto.diasSemana] * PESSOAS_POR_FAIXA[dto.pessoas];
    const frequencia = s >= 12 ? Frequencia.SEMANAL : s >= 6 ? Frequencia.QUINZENAL : Frequencia.MENSAL;
    const g = s * SEMANAS_POR_CICLO[frequencia];
    const multiplicador = Math.max(1, Math.ceil(g / GARRAFAS_POR_KIT));

    // 5–6: kit pelo objetivo, composição × m.
    const kit = await this.prisma.kit.findUnique({
      where: { objetivo: dto.objetivo },
      include: { itens: { include: { produto: true } } },
    });
    if (!kit) throw new Error(`Kit do objetivo ${dto.objetivo} não está no catálogo (rode o seed).`);
    const quantidades = new Map<string, number>();
    for (const item of kit.itens) quantidades.set(item.produto.codigo, item.quantidade * multiplicador);

    const extras = await this.prisma.produto.findMany({
      where: { codigo: { in: ['WP500', 'FF500', 'AMC510', 'AMS500'] } },
    });
    const produtos = new Map<string, ProdutoQuiz>([
      ...extras.map((p) => [p.codigo, p] as const),
      ...kit.itens.map((i) => [i.produto.codigo, i.produto] as const),
    ]);

    // 7: Flow Fiber.
    const wp = quantidades.get('WP500') ?? 0;
    const ff = quantidades.get('FF500') ?? 0;
    if (dto.flowFiber && dto.objetivo !== ObjetivoKit.EQUILIBRIO) {
      const troca = Math.floor(wp / 2);
      quantidades.set('WP500', wp - troca);
      quantidades.set('FF500', ff + troca);
    } else if (!dto.flowFiber && dto.objetivo === ObjetivoKit.EQUILIBRIO) {
      quantidades.set('WP500', wp + ff);
      quantidades.delete('FF500');
    }

    // 8: água com gás (indisponível → sem gás).
    if (dto.comGas) {
      const codigo = this.disponivel(produtos.get('AMC510')) ? 'AMC510' : 'AMS500';
      if (this.disponivel(produtos.get(codigo))) {
        quantidades.set(codigo, (quantidades.get(codigo) ?? 0) + FARDO_GAS);
      }
    }

    const cesta: ItemCesta[] = [...quantidades]
      .filter(([, q]) => q > 0)
      .map(([codigo, quantidade]) => {
        const produto = produtos.get(codigo);
        if (!produto) throw new Error(`Produto ${codigo} não está no catálogo (rode o seed).`);
        return { produto, quantidade };
      });

    // 9: limites → perfil Empresa (sem kit e sem preço).
    const ue = cesta.reduce((acc, i) => acc.plus(dec(i.produto.ue).times(i.quantidade)), dec(0));
    const peso = cesta.reduce((acc, i) => acc.plus(dec(i.produto.pesoKg).times(i.quantidade)), dec(0));
    const perfilEmpresa = ue.greaterThan(UE_MAXIMA) || peso.greaterThan(PESO_MAXIMO_KG);

    // 10: preço estimado — Flex, sem fidelidade, sem frete, sem ciclo anterior, demanda de hoje.
    let valorEstimado: Dec | null = null;
    if (!perfilEmpresa) {
      const calculo = this.preco.calcular({
        itens: cesta,
        plano: Plano.FLEX,
        parametros: await this.preco.carregarParametros(this.preco.hoje()),
        ciclosPagosEmDia: 0,
        taxaZona: null,
        creditos: dec(0),
        precosAnteriores: new Map(),
      });
      valorEstimado = calculo.total;
    }

    // 11: grava e devolve.
    const gravada = await this.prisma.recomendacao.create({
      data: {
        clienteId,
        respostas: { ...dto },
        kitId: perfilEmpresa ? null : kit.id,
        multiplicador,
        frequencia,
        itens: cesta.map((i) => ({ produto: i.produto.codigo, quantidade: i.quantidade })),
        ue: ue.toString(),
        valorEstimado: valorEstimado?.toString() ?? null,
        perfilEmpresa,
      },
      include: { kit: true },
    });
    return this.paraResposta(gravada);
  }

  /** RF45: recomendações anteriores do próprio cliente, mais recentes primeiro. */
  async listar(clienteId: string): Promise<RecomendacaoResponse[]> {
    const lista = await this.prisma.recomendacao.findMany({
      where: { clienteId },
      orderBy: { criadoEm: 'desc' },
      include: { kit: true },
    });
    return lista.map((r) => this.paraResposta(r));
  }

  async buscar(clienteId: string, id: string): Promise<RecomendacaoResponse> {
    const r = await this.prisma.recomendacao.findUnique({ where: { id }, include: { kit: true } });
    if (!r) {
      throw new RegraNegocioException('NAO_ENCONTRADO', 'Recomendação não encontrada.', HttpStatus.NOT_FOUND);
    }
    if (r.clienteId !== clienteId) {
      throw new RegraNegocioException(
        'SEM_PERMISSAO',
        'Você não tem permissão para esta ação.',
        HttpStatus.FORBIDDEN,
      );
    }
    return this.paraResposta(r);
  }

  private disponivel(p: ProdutoQuiz | undefined): boolean {
    return !!p && p.ativo && p.estoque !== 0;
  }

  private paraResposta(r: RecomendacaoGravada): RecomendacaoResponse {
    return {
      id: r.id,
      kit: r.kit?.codigo ?? null,
      multiplicador: r.multiplicador ?? 1,
      frequencia: r.frequencia ?? Frequencia.MENSAL,
      itens: r.itens as RecomendacaoResponse['itens'],
      ue: dec(r.ue).toNumber(),
      valorEstimado: r.valorEstimado === null ? null : dec(r.valorEstimado).toDecimalPlaces(2).toNumber(),
      perfilEmpresa: r.perfilEmpresa,
      ...(r.perfilEmpresa && { contatoComercial: CONTATO_COMERCIAL }),
      criadoEm: r.criadoEm.toISOString(),
    };
  }
}
