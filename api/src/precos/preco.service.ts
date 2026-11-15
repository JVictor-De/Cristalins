import { HttpStatus, Injectable } from '@nestjs/common';
import { ClockService } from '../common/clock.service';
import { PrismaService } from '../common/prisma.service';
import { RegraNegocioException } from '../common/regra-negocio.exception';
import { Plano, TipoProduto } from '../../prisma/generated/prisma/client';
import {
  Dec,
  dec,
  EntradaCalculo,
  FatoresAplicados,
  ItemCalculado,
  ItemCesta,
  ParametrosPreco,
  ResultadoCalculo,
} from './preco.tipos';
import { LinhaDetalhePreco, SimulacaoResponse } from './dto/simulacao.response';
import { SimularPrecoDto } from './dto/simular-preco.dto';

export interface FatorVigencia {
  chave: string;
  valor: { toString(): string };
  ativoDe: Date;
  ativoAte: Date | null;
}

/** Limites da cesta (RN02, RN03) e do plano Empresa. */
export const UE_MINIMA = 12;
export const UE_MINIMA_EMPRESA = 48;
export const UE_MAXIMA = 120;
export const PESO_MAXIMO_KG = 60;
/** RN18: frete grátis quando o subtotal passa deste valor. */
export const FRETE_GRATIS_ACIMA = 250;
/** RN04: produtos que podem dividir a mesma caixa de 6. */
export const CAIXA_MISTA = { codigos: ['WP500', 'FF500'], tamanho: 6 };
/** Trava entre ciclos: ±10% do unitário anterior. */
const TRAVA = { minima: dec('0.90'), maxima: dec('1.10') };
/** Limite do ajuste de demanda (tabela do Anexo). */
const DEMANDA = { minima: dec('-0.05'), maxima: dec('0.08') };

/** Percentuais do CONTEXTO, usados quando a chave não estiver vigente em `FatorPreco`. */
const PADRAO: Record<string, string> = {
  VOLUME_24_47: '0.08',
  VOLUME_48_MAIS: '0.12',
  COMPROMISSO_TRIMESTRAL: '0.07',
  COMPROMISSO_EMPRESA: '0.10',
  FIDELIDADE_POR_CICLO: '0.01',
  FIDELIDADE_MAXIMO: '0.05',
};
const PREFIXO_DEMANDA = 'DEMANDA_';

const ehAddon = (tipo: TipoProduto) => tipo === TipoProduto.ADDON;
const dataIso = (d: Date) => d.toISOString().slice(0, 10);

function erro(codigo: string, mensagem: string, campo = 'itens'): RegraNegocioException {
  return new RegraNegocioException(codigo, mensagem, HttpStatus.UNPROCESSABLE_ENTITY, campo);
}

function naoEncontrado(mensagem: string, campo: string): RegraNegocioException {
  return new RegraNegocioException('NAO_ENCONTRADO', mensagem, HttpStatus.NOT_FOUND, campo);
}

function semPermissao(): RegraNegocioException {
  return new RegraNegocioException('SEM_PERMISSAO', 'Você não tem permissão para esta ação.', HttpStatus.FORBIDDEN);
}

/** Dinheiro no JSON: número com 2 casas (meio para cima). */
export const dinheiro = (v: Dec): number => v.toDecimalPlaces(2, Dec.ROUND_HALF_UP).toNumber();
/** Fração → percentual (0,08 → 8). */
const pct = (v: Dec): number => v.times(100).toDecimalPlaces(4).toNumber();

/**
 * Preço dinâmico (CONTEXTO, "Preço"). Núcleo puro e determinístico: recebe produtos, parâmetros
 * e histórico já carregados (`calcular`). `simular` carrega do banco e chama o núcleo.
 */
@Injectable()
export class PrecoService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly clock: ClockService,
  ) {}

  /** Ordem: quantidade → cesta mínima (RN02) → máxima (RN03) → embalagem (RN04). */
  validarCesta(itens: ItemCesta[], plano: Plano): void {
    for (const { quantidade } of itens) {
      if (!Number.isInteger(quantidade) || quantidade <= 0) {
        throw new RegraNegocioException(
          'DADOS_INVALIDOS',
          'Cada item precisa de uma quantidade inteira maior que zero.',
          HttpStatus.BAD_REQUEST,
          'itens',
        );
      }
    }
    const ueSemAddon = this.somar(itens.filter((i) => !ehAddon(i.produto.tipo)), (i) => dec(i.produto.ue));
    const ueTotal = this.somar(itens, (i) => dec(i.produto.ue));
    const peso = this.somar(itens, (i) => dec(i.produto.pesoKg));

    const minimo = plano === Plano.EMPRESA ? UE_MINIMA_EMPRESA : UE_MINIMA;
    if (ueSemAddon.lessThan(minimo)) {
      throw erro('CESTA_ABAIXO_MINIMO', `A cesta precisa ter pelo menos ${minimo} UE por entrega (sem contar o Guaraná).`);
    }
    // Acima do teto, só plano Empresa com atendimento comercial (RN03).
    if (plano !== Plano.EMPRESA && (ueTotal.greaterThan(UE_MAXIMA) || peso.greaterThan(PESO_MAXIMO_KG))) {
      throw erro(
        'CESTA_ACIMA_MAXIMO',
        `A cesta passa de ${UE_MAXIMA} UE ou ${PESO_MAXIMO_KG} kg por entrega. Para volumes maiores, fale com o comercial.`,
      );
    }

    let caixaMista = 0;
    for (const { produto, quantidade } of itens) {
      if (CAIXA_MISTA.codigos.includes(produto.codigo)) {
        caixaMista += quantidade;
      } else if (quantidade % produto.embalagemQtd !== 0) {
        throw erro('EMBALAGEM_INVALIDA', `${produto.codigo} é vendido em múltiplos de ${produto.embalagemQtd}.`);
      }
    }
    if (caixaMista % CAIXA_MISTA.tamanho !== 0) {
      throw erro(
        'EMBALAGEM_INVALIDA',
        `Water Protein e Flow Fiber vêm em caixas de ${CAIXA_MISTA.tamanho}; a soma dos dois precisa ser múltiplo de ${CAIXA_MISTA.tamanho}.`,
      );
    }
  }

  /** Fatores vigentes na `data` (AAAA-MM-DD). Mesma chave em duas vigências: vale a mais recente. */
  parametrosDe(fatores: FatorVigencia[], data: string): ParametrosPreco {
    const vigentes = new Map<string, FatorVigencia>();
    for (const f of fatores) {
      const ativo = dataIso(f.ativoDe) <= data && (!f.ativoAte || data <= dataIso(f.ativoAte));
      const atual = vigentes.get(f.chave);
      if (ativo && (!atual || f.ativoDe > atual.ativoDe)) vigentes.set(f.chave, f);
    }
    const valor = (chave: string) => dec(vigentes.get(chave)?.valor ?? PADRAO[chave]);

    let demanda = dec(0);
    for (const [chave, f] of vigentes) {
      if (chave.startsWith(PREFIXO_DEMANDA)) demanda = demanda.plus(dec(f.valor));
    }
    demanda = Dec.min(Dec.max(demanda, DEMANDA.minima), DEMANDA.maxima);

    return {
      volume24a47: valor('VOLUME_24_47'),
      volume48mais: valor('VOLUME_48_MAIS'),
      compromissoTrimestral: valor('COMPROMISSO_TRIMESTRAL'),
      compromissoEmpresa: valor('COMPROMISSO_EMPRESA'),
      fidelidadePorCiclo: valor('FIDELIDADE_POR_CICLO'),
      fidelidadeMaxima: valor('FIDELIDADE_MAXIMO'),
      demanda,
    };
  }

  /** Lê `FatorPreco` e devolve os parâmetros vigentes na data da entrega. */
  async carregarParametros(dataEntrega: string): Promise<ParametrosPreco> {
    const fatores = await this.prisma.fatorPreco.findMany({
      where: { ativoDe: { lte: new Date(`${dataEntrega}T00:00:00.000Z`) } },
    });
    return this.parametrosDe(fatores, dataEntrega);
  }

  /** Data de hoje em America/Sao_Paulo (padrão da data de entrega/cálculo). */
  hoje(): string {
    return this.clock.hoje();
  }

  /**
   * POST /precos/simular: carrega produtos, fatores da data de entrega, zona, cupom e ciclo
   * anterior; valida a cesta e calcula. Não grava nada (CalculoPreco/ItemCiclo nascem no ciclo).
   */
  async simular(clienteId: string, dto: SimularPrecoDto): Promise<SimulacaoResponse> {
    const dataEntrega = dto.dataEntrega ?? this.hoje();
    const itens = await this.carregarCesta(dto.itens);
    this.validarCesta(itens, dto.plano);

    const [parametros, zona, cupom, anterior] = await Promise.all([
      this.carregarParametros(dataEntrega),
      this.carregarZona(clienteId, dto.zonaId, dto.enderecoId),
      this.carregarCupom(dto.cupom, dataEntrega),
      this.carregarCicloAnterior(clienteId, dto.cicloAnteriorId),
    ]);

    const r = this.calcular({
      itens,
      plano: dto.plano,
      parametros,
      ciclosPagosEmDia: anterior.ciclosPagosEmDia,
      cupom,
      taxaZona: zona ? dec(zona.taxaEntrega) : null,
      // Créditos (RN20) abatem só a cobrança real, fora da AP2 (cr-5-cobranca).
      creditos: dec(0),
      precosAnteriores: anterior.precos,
    });

    return {
      dataEntrega,
      plano: dto.plano,
      frequencia: dto.frequencia,
      itens: r.itens.map((i) => ({
        produto: i.produto.codigo,
        quantidade: i.quantidade,
        precoBase: dinheiro(i.precoBase),
        precoUnitario: dinheiro(i.precoUnitario),
        regra: i.regra,
      })),
      ue: r.ueSemAddon.toNumber(),
      pesoKg: r.pesoKg.toDecimalPlaces(2).toNumber(),
      subtotal: dinheiro(r.subtotal),
      frete: dinheiro(r.frete),
      creditos: dinheiro(r.creditos),
      total: dinheiro(r.total),
      fatores: {
        volume: pct(r.fatores.volume),
        compromisso: pct(r.fatores.compromisso),
        fidelidade: pct(r.fatores.fidelidade),
        demanda: pct(r.fatores.demanda),
        cupom: pct(r.fatores.cupom),
      },
      detalhePreco: this.detalhe(r, zona !== null),
      zona: zona ? { id: zona.id, nome: zona.nome } : null,
    };
  }

  /** Linhas no formato do exemplo de POST /assinaturas: descontos negativos, frete em reais. */
  detalhe(r: ResultadoCalculo, comFrete: boolean): LinhaDetalhePreco[] {
    const f = r.fatores;
    const linhas: LinhaDetalhePreco[] = [
      { fator: 'VOLUME', percentual: -pct(f.volume) },
      { fator: 'COMPROMISSO', percentual: -pct(f.compromisso) },
      { fator: 'FIDELIDADE', percentual: -pct(f.fidelidade) },
      { fator: 'DEMANDA', percentual: pct(f.demanda) },
      { fator: 'CUPOM', percentual: -pct(f.cupom) },
    ].filter((l) => l.percentual !== 0);
    if (comFrete) linhas.push({ fator: 'FRETE', valor: dinheiro(r.frete) });
    return linhas;
  }

  /** Junta itens repetidos e troca código por produto ativo do catálogo. */
  private async carregarCesta(itens: SimularPrecoDto['itens']): Promise<ItemCesta[]> {
    const quantidades = new Map<string, number>();
    for (const i of itens) quantidades.set(i.produto, (quantidades.get(i.produto) ?? 0) + i.quantidade);
    const produtos = await this.prisma.produto.findMany({
      where: { ativo: true, codigo: { in: [...quantidades.keys()] } },
    });
    const porCodigo = new Map(produtos.map((p) => [p.codigo, p]));
    return [...quantidades].map(([codigo, quantidade]) => {
      const produto = porCodigo.get(codigo);
      if (!produto) {
        throw new RegraNegocioException(
          'NAO_ENCONTRADO',
          `Produto ${codigo} não existe ou não está disponível.`,
          HttpStatus.NOT_FOUND,
          'itens',
        );
      }
      return { produto, quantidade };
    });
  }

  private async carregarZona(clienteId: string, zonaId?: string, enderecoId?: string) {
    if (enderecoId) {
      const endereco = await this.prisma.endereco.findUnique({ where: { id: enderecoId }, include: { zona: true } });
      if (!endereco) throw naoEncontrado('Endereço não encontrado.', 'enderecoId');
      if (endereco.clienteId !== clienteId) throw semPermissao();
      return endereco.zona;
    }
    if (zonaId) {
      const zona = await this.prisma.zona.findUnique({ where: { id: zonaId } });
      if (!zona) throw naoEncontrado('Zona não encontrada.', 'zonaId');
      return zona;
    }
    return null;
  }

  /** RN21: um cupom, válido na data da entrega e com usos disponíveis. Fração (10% → 0,10). */
  private async carregarCupom(codigo: string | undefined, dataEntrega: string): Promise<Dec | undefined> {
    if (!codigo) return undefined;
    const cupom = await this.prisma.cupom.findUnique({ where: { codigo: codigo.trim().toUpperCase() } });
    const valido =
      cupom &&
      (!cupom.validade || dataEntrega <= dataIso(cupom.validade)) &&
      (cupom.usosMax === null || cupom.usos < cupom.usosMax);
    if (!valido) {
      throw new RegraNegocioException('CUPOM_INVALIDO', 'Cupom inválido ou expirado.', HttpStatus.UNPROCESSABLE_ENTITY, 'cupom');
    }
    return dec(cupom.percentual).div(100);
  }

  /** Preços do ciclo anterior (trava ±10%) e ciclos da assinatura pagos até o vencimento (fidelidade). */
  private async carregarCicloAnterior(clienteId: string, cicloId?: string) {
    const vazio = { precos: new Map<string, Dec>(), ciclosPagosEmDia: 0 };
    if (!cicloId) return vazio;
    const ciclo = await this.prisma.ciclo.findUnique({
      where: { id: cicloId },
      include: { itens: true, assinatura: true },
    });
    if (!ciclo) throw naoEncontrado('Ciclo anterior não encontrado.', 'cicloAnteriorId');
    if (ciclo.assinatura.clienteId !== clienteId) throw semPermissao();

    const pagamentos = await this.prisma.pagamento.findMany({
      where: { status: 'PAGO', ciclo: { assinaturaId: ciclo.assinaturaId, numero: { lte: ciclo.numero } } },
    });
    const emDia = new Set(
      pagamentos
        .filter((p) => p.pagoEm && this.clock.dataNoFuso(p.pagoEm) <= dataIso(p.vencimento))
        .map((p) => p.cicloId),
    );
    return {
      precos: new Map(ciclo.itens.map((i) => [i.produtoId, dec(i.precoUnitario)])),
      ciclosPagosEmDia: emDia.size,
    };
  }

  /**
   * Passos 1–7 do CONTEXTO, item a item, sem arredondar; só o total vai a 2 casas (meio para cima).
   */
  calcular(entrada: EntradaCalculo): ResultadoCalculo {
    const { itens } = entrada;
    const ueSemAddon = this.somar(itens.filter((i) => !ehAddon(i.produto.tipo)), (i) => dec(i.produto.ue));
    const ueTotal = this.somar(itens, (i) => dec(i.produto.ue));
    const pesoKg = this.somar(itens, (i) => dec(i.produto.pesoKg));
    const fatores = this.fatores(entrada, ueSemAddon);

    const calculados: ItemCalculado[] = itens.map(({ produto, quantidade }) => {
      const precoBase = dec(produto.precoBase);
      if (ehAddon(produto.tipo)) {
        return { produto, quantidade, precoBase, precoUnitario: precoBase, regra: 'ADDON' };
      }
      const piso = dec(produto.precoPiso);
      let unitario = precoBase.times(fatores.fator);
      let regra: ItemCalculado['regra'] = null;
      if (unitario.lessThan(piso)) {
        unitario = piso;
        regra = 'PISO';
      }
      const anterior = entrada.precosAnteriores.get(produto.id);
      if (anterior) {
        const teto = anterior.times(TRAVA.maxima);
        const chao = anterior.times(TRAVA.minima);
        if (unitario.greaterThan(teto)) {
          unitario = teto;
          regra = 'TRAVA_MAXIMA';
        } else if (unitario.lessThan(chao)) {
          unitario = chao;
          regra = 'TRAVA_MINIMA';
        }
        // O piso sempre vence.
        if (unitario.lessThan(piso)) {
          unitario = piso;
          regra = 'PISO';
        }
      }
      return { produto, quantidade, precoBase, precoUnitario: unitario, regra };
    });

    const subtotal = this.somar(calculados, (i) => i.precoUnitario.times(i.quantidade), false);
    const frete =
      entrada.taxaZona === null || subtotal.greaterThan(FRETE_GRATIS_ACIMA) ? dec(0) : entrada.taxaZona;
    const bruto = subtotal.plus(frete).minus(entrada.creditos);
    const total = Dec.max(bruto, 0).toDecimalPlaces(2, Dec.ROUND_HALF_UP);

    return {
      itens: calculados,
      ueSemAddon,
      ueTotal,
      pesoKg,
      fatores,
      subtotal,
      frete,
      creditos: entrada.creditos,
      total,
    };
  }

  private fatores(entrada: EntradaCalculo, ueSemAddon: Dec): FatoresAplicados {
    const p = entrada.parametros;
    const volume = ueSemAddon.greaterThanOrEqualTo(48)
      ? p.volume48mais
      : ueSemAddon.greaterThanOrEqualTo(24)
        ? p.volume24a47
        : dec(0);
    const compromisso =
      entrada.plano === Plano.TRIMESTRAL
        ? p.compromissoTrimestral
        : entrada.plano === Plano.EMPRESA
          ? p.compromissoEmpresa
          : dec(0);
    const fidelidade = Dec.min(p.fidelidadePorCiclo.times(Math.max(0, entrada.ciclosPagosEmDia)), p.fidelidadeMaxima);
    const cupom = entrada.cupom ?? dec(0);
    const fator = dec(1)
      .minus(volume)
      .times(dec(1).minus(compromisso))
      .times(dec(1).minus(fidelidade))
      .times(dec(1).plus(p.demanda))
      .times(dec(1).minus(cupom));
    return { volume, compromisso, fidelidade, demanda: p.demanda, cupom, fator };
  }

  /** Soma `valor(item) × quantidade` (ou só `valor(item)` quando `porQuantidade` é falso). */
  private somar<T extends { quantidade: number }>(itens: T[], valor: (i: T) => Dec, porQuantidade = true): Dec {
    return itens.reduce((acc, i) => acc.plus(porQuantidade ? valor(i).times(i.quantidade) : valor(i)), dec(0));
  }
}
