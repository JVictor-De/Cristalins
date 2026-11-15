import { HttpStatus, Injectable } from '@nestjs/common';
import {
  dataCorte,
  dataIso,
  DIAS_POR_FREQUENCIA,
  primeiraEntrega,
  proximaDataDaZona,
  proximaEntrega,
  somarDias,
  somarMeses,
} from '../ciclos/agenda';
import { ClockService } from '../common/clock.service';
import { PrismaService } from '../common/prisma.service';
import { RegraNegocioException } from '../common/regra-negocio.exception';
import { dinheiro, PrecoService } from '../precos/preco.service';
import { dec, Dec } from '../precos/preco.tipos';
import { SimulacaoResponse } from '../precos/dto/simulacao.response';
import {
  DiaSemana,
  Frequencia,
  Janela,
  Plano,
  Prisma,
  StatusAssinatura,
  StatusCiclo,
  StatusPagamento,
} from '../../prisma/generated/prisma/client';
import { AlterarAssinaturaDto, CriarAssinaturaDto } from './dto/assinatura.dto';
import {
  AssinaturaAlteradaResponse,
  AssinaturaCanceladaResponse,
  AssinaturaCriadaResponse,
  AssinaturaResponse,
  CicloResponse,
  EntregaPuladaResponse,
} from './dto/assinatura.response';
import { CICLOS_EM_ABERTO, CICLOS_PAGOS } from './maquina-estados';
import { Db, MaquinaEstadosService } from './maquina-estados.service';

/** Meses de compromisso por plano (RN13). */
const MESES_COMPROMISSO: Partial<Record<Plano, number>> = { [Plano.TRIMESTRAL]: 3, [Plano.EMPRESA]: 6 };
/** RN10: pulos seguidos. RN11: pausas seguidas e por ano. */
export const LIMITES = { pulosSeguidos: 2, pausasSeguidas: 2, pausasPorAno: 4 };

/**
 * Motivo de um ciclo não entregue. O schema não tem coluna para isso; fica em `CalculoPreco.fatores`
 * (`motivoPulo`), com valor 0 quando o ciclo não chegou a ser precificado. Ver relatório da cr-1-ciclo.
 */
export type MotivoPulo = 'PULO' | 'PAUSA' | 'CANCELAMENTO';

const INCLUDE_ASSINATURA = {
  itens: { include: { produto: true } },
  cupom: true,
  endereco: { include: { zona: true } },
} satisfies Prisma.AssinaturaInclude;
const INCLUDE_CICLO = {
  itens: { include: { produto: true } },
  calculoPreco: true,
  pagamentos: { orderBy: { criadoEm: 'desc' as const } },
} satisfies Prisma.CicloInclude;

type AssinaturaCompleta = Prisma.AssinaturaGetPayload<{ include: typeof INCLUDE_ASSINATURA }>;
type CicloCompleto = Prisma.CicloGetPayload<{ include: typeof INCLUDE_CICLO }>;

/** Ciclo existente ou ainda só planejado (criado ao gravar). */
interface CicloPlanejado {
  existente?: CicloCompleto;
  numero: number;
  dataEntrega: string;
}

const erro = (codigo: string, mensagem: string, status: HttpStatus, campo?: string) =>
  new RegraNegocioException(codigo, mensagem, status, campo);

@Injectable()
export class AssinaturasService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly preco: PrecoService,
    private readonly maquina: MaquinaEstadosService,
    private readonly clock: ClockService,
  ) {}

  // ---------- Criar e consultar ----------

  /** POST /assinaturas: grava AGUARDANDO_PAGAMENTO, o 1º ciclo e o cálculo. A cobrança Pix nasce em cr-3. */
  async criar(clienteId: string, dto: CriarAssinaturaDto): Promise<AssinaturaCriadaResponse> {
    await this.garantirSemCobrancaVencida(clienteId);
    const endereco = await this.enderecoDoCliente(clienteId, dto.enderecoId);
    if (dto.recomendacaoId) await this.garantirRecomendacao(clienteId, dto.recomendacaoId);

    const hoje = this.clock.hoje();
    const dataEntrega = primeiraEntrega(hoje, endereco.zona.diasEntrega);
    const simulacao = await this.preco.simular(clienteId, {
      itens: dto.itens,
      frequencia: dto.frequencia,
      plano: dto.plano,
      enderecoId: dto.enderecoId,
      cupom: dto.cupom,
      dataEntrega,
    });
    const produtos = await this.idsDosProdutos(simulacao.itens.map((i) => i.produto));
    const cupom = dto.cupom ? await this.prisma.cupom.findUnique({ where: { codigo: dto.cupom.trim().toUpperCase() } }) : null;
    const meses = MESES_COMPROMISSO[dto.plano];

    const { assinaturaId, cicloId } = await this.prisma.$transaction(async (tx) => {
      const assinatura = await tx.assinatura.create({
        data: {
          clienteId,
          enderecoId: dto.enderecoId,
          plano: dto.plano,
          frequencia: dto.frequencia,
          janela: dto.janela,
          formaPagamento: dto.formaPagamento,
          cupomId: cupom?.id ?? null,
          inicio: new Date(`${dataEntrega}T00:00:00.000Z`),
          fimCompromisso: meses ? new Date(`${somarMeses(dataEntrega, meses)}T00:00:00.000Z`) : null,
        },
      });
      await tx.itemAssinatura.createMany({
        data: simulacao.itens.map((i) => ({ assinaturaId: assinatura.id, produtoId: produtos.get(i.produto)!, quantidade: i.quantidade })),
      });
      const ciclo = await this.criarCiclo(tx, assinatura.id, 1, dataEntrega, dto.enderecoId, dto.janela);
      await this.gravarCalculo(tx, ciclo.id, simulacao, produtos);
      if (cupom) await tx.cupom.update({ where: { id: cupom.id }, data: { usos: { increment: 1 } } });
      return { assinaturaId: assinatura.id, cicloId: ciclo.id };
    });

    const resposta = await this.buscar(clienteId, assinaturaId);
    const ciclo = await this.prisma.ciclo.findUnique({ where: { id: cicloId } });
    return {
      ...resposta,
      ciclo: {
        id: cicloId,
        numero: 1,
        valor: simulacao.total,
        vencimento: hoje,
        dataEntrega,
        dataCorte: ciclo!.dataCorte.toISOString(),
      },
      detalhePreco: simulacao.detalhePreco,
    };
  }

  async listar(clienteId: string): Promise<AssinaturaResponse[]> {
    const lista = await this.prisma.assinatura.findMany({
      where: { clienteId },
      include: INCLUDE_ASSINATURA,
      orderBy: { criadoEm: 'desc' },
    });
    return Promise.all(lista.map((a) => this.paraResposta(a)));
  }

  async buscar(clienteId: string, id: string): Promise<AssinaturaResponse> {
    return this.paraResposta(await this.carregar(clienteId, id));
  }

  async ciclos(clienteId: string, id: string): Promise<CicloResponse[]> {
    await this.carregar(clienteId, id);
    return (await this.ciclosDa(id)).map((c) => this.cicloParaResposta(c));
  }

  // ---------- Pular, pausar e retomar ----------

  /** RN10: pula a próxima entrega até o corte, no máximo 2 seguidas. */
  async pularEntrega(clienteId: string, id: string): Promise<EntregaPuladaResponse> {
    const assinatura = await this.carregar(clienteId, id);
    if (assinatura.status !== StatusAssinatura.ATIVA) {
      throw erro('TRANSICAO_INVALIDA', 'Só dá para pular entrega de assinatura ativa.', HttpStatus.CONFLICT);
    }
    const ciclos = await this.ciclosDa(id);
    const alvo = this.proximoEmAberto(ciclos) ?? this.planejarSeguinte(assinatura, ciclos);
    if (this.clock.agora() > dataCorte(alvo.dataEntrega)) {
      throw erro('APOS_CORTE', 'O prazo para pular esta entrega já passou (23h59 de 2 dias antes).', HttpStatus.CONFLICT);
    }
    if (this.seguidosAntes(ciclos, alvo.numero, 'PULO') >= LIMITES.pulosSeguidos) {
      throw erro('LIMITE_PULOS', `Você já pulou ${LIMITES.pulosSeguidos} entregas seguidas.`, HttpStatus.UNPROCESSABLE_ENTITY);
    }

    const puladaId = await this.prisma.$transaction(async (tx) => {
      const ciclo = await this.materializar(tx, assinatura, alvo);
      await this.naoEntregar(tx, ciclo, 'PULO');
      await this.garantirSeguinte(tx, assinatura, ciclo);
      return ciclo.id;
    });
    const pulada = (await this.ciclosDa(id)).find((c) => c.id === puladaId)!;
    return { ...(await this.buscar(clienteId, id)), pulada: this.cicloParaResposta(pulada) };
  }

  /** RN11: pausa 1 ou 2 ciclos; até 2 seguidos e 4 por ano civil; no compromisso, adia o fim. */
  async pausar(clienteId: string, id: string, quantidade: number): Promise<AssinaturaResponse> {
    const assinatura = await this.carregar(clienteId, id);
    // Valida antes de criar qualquer ciclo.
    if (assinatura.status !== StatusAssinatura.ATIVA) {
      throw erro('TRANSICAO_INVALIDA', 'Só dá para pausar assinatura ativa.', HttpStatus.CONFLICT);
    }
    const ciclos = await this.ciclosDa(id);
    let inicio = this.proximoEmAberto(ciclos) ?? this.planejarSeguinte(assinatura, ciclos);
    const podePausar = (c: CicloPlanejado) =>
      (!c.existente || c.existente.status === StatusCiclo.AGENDADO || c.existente.status === StatusCiclo.COBRADO) &&
      this.clock.agora() <= dataCorte(c.dataEntrega);
    // Depois do corte (ou já paga), a próxima entrega acontece e a pausa começa na seguinte (RN09).
    while (!podePausar(inicio)) inicio = this.planejarDepoisDe(assinatura, ciclos, inicio);

    const alvos: CicloPlanejado[] = [inicio];
    while (alvos.length < quantidade) alvos.push(this.planejarDepoisDe(assinatura, ciclos, alvos[alvos.length - 1]));

    if (this.seguidosAntes(ciclos, inicio.numero, 'PAUSA') + quantidade > LIMITES.pausasSeguidas) {
      throw erro('LIMITE_PAUSAS', `A pausa pode ter no máximo ${LIMITES.pausasSeguidas} entregas seguidas.`, HttpStatus.UNPROCESSABLE_ENTITY);
    }
    for (const ano of new Set(alvos.map((a) => a.dataEntrega.slice(0, 4)))) {
      const noAno =
        ciclos.filter((c) => this.motivo(c) === 'PAUSA' && dataIso(c.dataEntrega).startsWith(ano)).length +
        alvos.filter((a) => a.dataEntrega.startsWith(ano)).length;
      if (noAno > LIMITES.pausasPorAno) {
        throw erro('LIMITE_PAUSAS', `São no máximo ${LIMITES.pausasPorAno} entregas pausadas por ano.`, HttpStatus.UNPROCESSABLE_ENTITY);
      }
    }

    await this.prisma.$transaction(async (tx) => {
      let ultimo: CicloCompleto | null = null;
      for (const alvo of alvos) {
        ultimo = await this.materializar(tx, assinatura, alvo);
        await this.naoEntregar(tx, ultimo, 'PAUSA');
      }
      await this.garantirSeguinte(tx, assinatura, ultimo!);
      await this.maquina.assinatura(tx, assinatura, StatusAssinatura.PAUSADA);
      await this.moverFimCompromisso(tx, assinatura, quantidade);
    });
    return this.buscar(clienteId, id);
  }

  /**
   * Retoma a assinatura pausada. Entregas pausadas cujo corte ainda não passou voltam a acontecer:
   * os ciclos reservados (nunca cobrados) são removidos e a agenda recomeça na primeira data pausada.
   * Não há transição PULADO → AGENDADO no diagrama do Anexo; por isso a remoção, e não a troca de status.
   */
  async retomar(clienteId: string, id: string): Promise<AssinaturaResponse> {
    const assinatura = await this.carregar(clienteId, id);
    if (assinatura.status !== StatusAssinatura.PAUSADA) {
      throw erro('TRANSICAO_INVALIDA', 'Só dá para retomar assinatura pausada.', HttpStatus.CONFLICT);
    }
    const ciclos = await this.ciclosDa(id);
    const agora = this.clock.agora();
    const reservados = ciclos.filter(
      (c) => c.status === StatusCiclo.PULADO && this.motivo(c) === 'PAUSA' && c.dataCorte > agora && c.pagamentos.length === 0,
    );

    await this.prisma.$transaction(async (tx) => {
      if (reservados.length) {
        const primeiro = reservados[0];
        // Remove os reservados e a cauda ainda sem preço (o ciclo agendado depois da pausa).
        const remover = ciclos.filter(
          (c) =>
            c.numero >= primeiro.numero &&
            ((c.status === StatusCiclo.PULADO && this.motivo(c) === 'PAUSA') ||
              (c.status === StatusCiclo.AGENDADO && !c.itens.length)),
        );
        await tx.ciclo.deleteMany({ where: { id: { in: remover.map((c) => c.id) } } });
        const restante = ciclos.filter((c) => !remover.includes(c));
        const numero = Math.max(0, ...restante.map((c) => c.numero)) + 1;
        await this.criarCiclo(tx, assinatura.id, numero, dataIso(primeiro.dataEntrega), assinatura.enderecoId, assinatura.janela);
        await this.moverFimCompromisso(tx, assinatura, -reservados.length);
      }
      await this.maquina.assinatura(tx, assinatura, StatusAssinatura.ATIVA);
    });
    return this.buscar(clienteId, id);
  }

  // ---------- Alterar ----------

  /**
   * RN09: até o corte, a alteração vale para a próxima entrega; depois, para a seguinte
   * (a próxima fica travada com a cesta antiga). RN26: cobrança vencida bloqueia mudar a cesta.
   */
  async alterar(clienteId: string, id: string, dto: AlterarAssinaturaDto): Promise<AssinaturaAlteradaResponse> {
    const assinatura = await this.carregar(clienteId, id);
    if (assinatura.status === StatusAssinatura.CANCELADA) {
      throw erro('TRANSICAO_INVALIDA', 'Assinatura cancelada não pode ser alterada.', HttpStatus.CONFLICT);
    }
    if (dto.itens) await this.garantirSemCobrancaVencida(clienteId);

    const hoje = this.clock.hoje();
    const compromissoVigente =
      assinatura.status !== StatusAssinatura.AGUARDANDO_PAGAMENTO &&
      assinatura.fimCompromisso !== null &&
      dataIso(assinatura.fimCompromisso) > hoje;
    if (dto.plano === Plano.FLEX && assinatura.plano !== Plano.FLEX && compromissoVigente) {
      throw erro(
        'COMPROMISSO_VIGENTE',
        `O compromisso vai até ${dataIso(assinatura.fimCompromisso!)}. Para sair antes, cancele (RN13).`,
        HttpStatus.UNPROCESSABLE_ENTITY,
        'plano',
      );
    }
    if (dto.cupom && assinatura.cupom && assinatura.cupom.codigo !== dto.cupom) {
      throw erro('CUPOM_INVALIDO', 'A assinatura já usa um cupom (um por assinatura).', HttpStatus.UNPROCESSABLE_ENTITY, 'cupom');
    }
    const endereco = dto.enderecoId ? await this.enderecoDoCliente(clienteId, dto.enderecoId) : assinatura.endereco;

    const ciclos = await this.ciclosDa(id);
    let alvo = this.proximoAgendado(ciclos) ?? this.planejarSeguinte(assinatura, ciclos);
    let travar: CicloCompleto | null = null;
    if (this.clock.agora() > dataCorte(alvo.dataEntrega)) {
      travar = alvo.existente && !alvo.existente.itens.length ? alvo.existente : null;
      alvo = this.planejarDepoisDe(assinatura, ciclos, alvo);
    }
    const dataAlvo = dto.enderecoId ? proximaDataDaZona(alvo.dataEntrega, endereco.zona.diasEntrega) : alvo.dataEntrega;

    const plano = dto.plano ?? assinatura.plano;
    const novaConfig = {
      itens: dto.itens ?? this.itensDa(assinatura),
      frequencia: dto.frequencia ?? assinatura.frequencia,
      plano,
      enderecoId: endereco.id,
      cupom: dto.cupom ?? assinatura.cupom?.codigo,
    };
    // Valida cesta e cupom no PrecoService (e precifica, se o ciclo alvo já estiver travado).
    const simulacao = await this.preco.simular(clienteId, { ...novaConfig, dataEntrega: dataAlvo });
    if (travar) await this.congelarCiclo(travar.id);

    const novoCupom =
      dto.cupom && !assinatura.cupom
        ? await this.prisma.cupom.findUnique({ where: { codigo: dto.cupom.trim().toUpperCase() } })
        : null;
    const meses = MESES_COMPROMISSO[plano];
    const fimCompromisso =
      dto.plano === undefined || dto.plano === assinatura.plano
        ? assinatura.fimCompromisso
        : meses
          ? new Date(`${somarMeses(dataAlvo, meses)}T00:00:00.000Z`)
          : null;

    const aplicada = await this.prisma.$transaction(async (tx) => {
      await tx.assinatura.update({
        where: { id },
        data: {
          plano,
          frequencia: novaConfig.frequencia,
          janela: dto.janela ?? assinatura.janela,
          formaPagamento: dto.formaPagamento ?? assinatura.formaPagamento,
          enderecoId: endereco.id,
          fimCompromisso,
          ...(novoCupom && { cupomId: novoCupom.id }),
        },
      });
      if (novoCupom) await tx.cupom.update({ where: { id: novoCupom.id }, data: { usos: { increment: 1 } } });
      if (dto.itens) {
        const produtos = await this.idsDosProdutos(simulacao.itens.map((i) => i.produto));
        await tx.itemAssinatura.deleteMany({ where: { assinaturaId: id } });
        await tx.itemAssinatura.createMany({
          data: simulacao.itens.map((i) => ({ assinaturaId: id, produtoId: produtos.get(i.produto)!, quantidade: i.quantidade })),
        });
      }
      const janela = dto.janela ?? assinatura.janela;
      if (alvo.existente) {
        await tx.ciclo.update({
          where: { id: alvo.existente.id },
          data: {
            enderecoId: endereco.id,
            janela,
            dataEntrega: new Date(`${dataAlvo}T00:00:00.000Z`),
            dataCorte: dataCorte(dataAlvo),
          },
        });
        // Ciclo já precificado (ex.: 1º ciclo aguardando pagamento): recalcula com a nova configuração.
        if (alvo.existente.itens.length) {
          const produtos = await this.idsDosProdutos(simulacao.itens.map((i) => i.produto));
          await this.gravarCalculo(tx, alvo.existente.id, simulacao, produtos);
        }
      } else {
        await this.criarCiclo(tx, id, alvo.numero, dataAlvo, endereco.id, janela);
      }
      return { numero: alvo.numero, dataEntrega: dataAlvo };
    });

    return { ...(await this.buscar(clienteId, id)), aplicadaAPartirDe: aplicada };
  }

  // ---------- Cancelar ----------

  /**
   * RN12: Flex sem multa; entregas ainda não pagas não acontecem; ciclo já pago é entregue.
   * RN13: Trimestral (7%, 3 meses) e Empresa (10%, 6 meses) cancelados antes do fim pagam a diferença
   * do desconto de compromisso sobre os ciclos pagos. O valor é calculado aqui e cobrado em `cr-5`.
   */
  async cancelar(clienteId: string, id: string): Promise<AssinaturaCanceladaResponse> {
    const assinatura = await this.carregar(clienteId, id);
    const ciclos = await this.ciclosDa(id);
    const pagos = ciclos.filter((c) => CICLOS_PAGOS.includes(c.status));
    const antesDoFim = assinatura.fimCompromisso !== null && this.clock.hoje() < dataIso(assinatura.fimCompromisso);
    const diferenca = assinatura.plano !== Plano.FLEX && antesDoFim ? this.diferencaCompromisso(pagos) : dec(0);

    await this.prisma.$transaction(async (tx) => {
      await this.maquina.assinatura(tx, assinatura, StatusAssinatura.CANCELADA);
      for (const ciclo of ciclos) {
        if (ciclo.status === StatusCiclo.AGENDADO || ciclo.status === StatusCiclo.COBRADO) {
          await this.naoEntregar(tx, ciclo, 'CANCELAMENTO');
        }
      }
    });
    return {
      ...(await this.buscar(clienteId, id)),
      diferencaCompromisso: dinheiro(diferenca),
      ciclosPagos: pagos.length,
    };
  }

  /** Σ subtotal × c/(1 − c): o que cada ciclo pago custaria sem o desconto de compromisso, menos o que custou. */
  private diferencaCompromisso(pagos: CicloCompleto[]): Dec {
    return pagos.reduce((acc, c) => {
      const calculo = c.calculoPreco;
      const percentual = Number((calculo?.fatores as { compromisso?: number } | null)?.compromisso ?? 0);
      if (!calculo || !percentual) return acc;
      const fracao = dec(percentual).div(100);
      return acc.plus(dec(calculo.subtotal).times(fracao).div(dec(1).minus(fracao)));
    }, dec(0));
  }

  // ---------- Ciclos: travar a cesta e agenda ----------

  /**
   * Trava a cesta e o preço do ciclo (CalculoPreco + ItemCiclo), com o ciclo anterior para a trava de
   * ±10% e a fidelidade. Usado aqui depois do corte e, em `cr-3-gateway`, pelo job de D-5 (RN19).
   */
  async congelarCiclo(cicloId: string): Promise<void> {
    const ciclo = await this.prisma.ciclo.findUnique({ where: { id: cicloId } });
    if (!ciclo) throw erro('NAO_ENCONTRADO', 'Ciclo não encontrado.', HttpStatus.NOT_FOUND);
    const assinatura = await this.prisma.assinatura.findUnique({ where: { id: ciclo.assinaturaId }, include: INCLUDE_ASSINATURA });
    const anterior = (await this.ciclosDa(ciclo.assinaturaId))
      .filter((c) => c.numero < ciclo.numero && c.itens.length)
      .pop();
    const base = {
      itens: this.itensDa(assinatura!),
      frequencia: assinatura!.frequencia,
      plano: assinatura!.plano,
      enderecoId: ciclo.enderecoId,
      dataEntrega: dataIso(ciclo.dataEntrega),
      cicloAnteriorId: anterior?.id,
    };
    let simulacao: SimulacaoResponse;
    try {
      simulacao = await this.preco.simular(assinatura!.clienteId, { ...base, cupom: assinatura!.cupom?.codigo });
    } catch (e) {
      // Cupom vencido ou esgotado deixa de valer nos ciclos seguintes; o resto do preço segue.
      if (!(e instanceof RegraNegocioException && e.codigo === 'CUPOM_INVALIDO')) throw e;
      simulacao = await this.preco.simular(assinatura!.clienteId, base);
    }
    const produtos = await this.idsDosProdutos(simulacao.itens.map((i) => i.produto));
    await this.prisma.$transaction((tx) => this.gravarCalculo(tx, cicloId, simulacao, produtos));
  }

  /** Próximo ciclo AGENDADO (cria o seguinte se não houver). Usado pelo job de D-5 em `cr-3`. */
  async proximoCicloAberto(assinaturaId: string): Promise<CicloCompleto> {
    const assinatura = await this.prisma.assinatura.findUnique({ where: { id: assinaturaId }, include: INCLUDE_ASSINATURA });
    if (!assinatura) throw erro('NAO_ENCONTRADO', 'Assinatura não encontrada.', HttpStatus.NOT_FOUND);
    const ciclos = await this.ciclosDa(assinaturaId);
    const plano = this.proximoAgendado(ciclos) ?? this.planejarSeguinte(assinatura, ciclos);
    return this.prisma.$transaction((tx) => this.materializar(tx, assinatura, plano));
  }

  private async gravarCalculo(db: Db, cicloId: string, s: SimulacaoResponse, produtos: Map<string, string>): Promise<void> {
    const fatores = { ...s.fatores, detalhePreco: s.detalhePreco, dataEntrega: s.dataEntrega } as unknown as Prisma.InputJsonValue;
    const valores = {
      subtotal: String(s.subtotal),
      frete: String(s.frete),
      creditos: String(s.creditos),
      valorFinal: String(s.total),
      fatores,
    };
    await db.calculoPreco.upsert({ where: { cicloId }, create: { cicloId, ...valores }, update: valores });
    await db.itemCiclo.deleteMany({ where: { cicloId } });
    await db.itemCiclo.createMany({
      data: s.itens.map((i) => ({
        cicloId,
        produtoId: produtos.get(i.produto)!,
        quantidade: i.quantidade,
        precoUnitario: String(i.precoUnitario),
      })),
    });
  }

  private async criarCiclo(db: Db, assinaturaId: string, numero: number, dataEntrega: string, enderecoId: string, janela: Janela) {
    return db.ciclo.create({
      data: {
        assinaturaId,
        numero,
        enderecoId,
        janela,
        dataEntrega: new Date(`${dataEntrega}T00:00:00.000Z`),
        dataCorte: dataCorte(dataEntrega),
      },
      include: INCLUDE_CICLO,
    });
  }

  /** Grava o ciclo planejado (se ainda não existir) e devolve o registro. */
  private async materializar(db: Db, assinatura: AssinaturaCompleta, plano: CicloPlanejado): Promise<CicloCompleto> {
    if (plano.existente) return plano.existente;
    return this.criarCiclo(db, assinatura.id, plano.numero, plano.dataEntrega, assinatura.enderecoId, assinatura.janela);
  }

  /** Garante um ciclo AGENDADO depois de `ciclo` (a agenda sempre mostra a próxima entrega). */
  private async garantirSeguinte(db: Db, assinatura: AssinaturaCompleta, ciclo: CicloCompleto): Promise<void> {
    const existe = await db.ciclo.findFirst({ where: { assinaturaId: assinatura.id, numero: ciclo.numero + 1 } });
    if (existe) return;
    const data = this.depoisDe(assinatura, dataIso(ciclo.dataEntrega));
    await this.criarCiclo(db, assinatura.id, ciclo.numero + 1, data, assinatura.enderecoId, assinatura.janela);
  }

  /** AGENDADO → PULADO ou COBRADO → CANCELADO, com o motivo registrado. */
  private async naoEntregar(db: Db, ciclo: CicloCompleto, motivo: MotivoPulo): Promise<void> {
    const para = ciclo.status === StatusCiclo.COBRADO ? StatusCiclo.CANCELADO : StatusCiclo.PULADO;
    await this.maquina.ciclo(db, ciclo, para);
    if (ciclo.calculoPreco) {
      const fatores = { ...((ciclo.calculoPreco.fatores as object | null) ?? {}), motivoPulo: motivo };
      await db.calculoPreco.update({ where: { cicloId: ciclo.id }, data: { fatores } });
    } else {
      await db.calculoPreco.create({
        data: { cicloId: ciclo.id, subtotal: '0', frete: '0', creditos: '0', valorFinal: '0', fatores: { motivoPulo: motivo } },
      });
    }
  }

  /** Data seguinte na agenda: anterior + frequência, no dia da zona, nunca no passado. */
  private depoisDe(assinatura: AssinaturaCompleta, anterior: string): string {
    const dias = assinatura.endereco.zona.diasEntrega as DiaSemana[];
    let data = proximaEntrega(anterior, assinatura.frequencia as Frequencia, dias);
    const hoje = this.clock.hoje();
    while (data < hoje) data = proximaEntrega(data, assinatura.frequencia as Frequencia, dias);
    return data;
  }

  private planejarSeguinte(assinatura: AssinaturaCompleta, ciclos: CicloCompleto[]): CicloPlanejado {
    const ultimo = ciclos[ciclos.length - 1];
    if (!ultimo) {
      return { numero: 1, dataEntrega: primeiraEntrega(this.clock.hoje(), assinatura.endereco.zona.diasEntrega) };
    }
    return { numero: ultimo.numero + 1, dataEntrega: this.depoisDe(assinatura, dataIso(ultimo.dataEntrega)) };
  }

  private planejarDepoisDe(assinatura: AssinaturaCompleta, ciclos: CicloCompleto[], atual: CicloPlanejado): CicloPlanejado {
    const existente = ciclos.find((c) => c.numero === atual.numero + 1);
    if (existente) return { existente, numero: existente.numero, dataEntrega: dataIso(existente.dataEntrega) };
    return { numero: atual.numero + 1, dataEntrega: this.depoisDe(assinatura, atual.dataEntrega) };
  }

  /** Próxima entrega ainda em aberto, a partir de hoje. */
  private proximoEmAberto(ciclos: CicloCompleto[]): CicloPlanejado | null {
    const hoje = this.clock.hoje();
    const c = ciclos.find((x) => CICLOS_EM_ABERTO.includes(x.status) && dataIso(x.dataEntrega) >= hoje);
    return c ? { existente: c, numero: c.numero, dataEntrega: dataIso(c.dataEntrega) } : null;
  }

  /** Próximo ciclo ainda não cobrado (o que pode receber alterações). */
  private proximoAgendado(ciclos: CicloCompleto[]): CicloPlanejado | null {
    const hoje = this.clock.hoje();
    const c = ciclos.find((x) => x.status === StatusCiclo.AGENDADO && dataIso(x.dataEntrega) >= hoje);
    return c ? { existente: c, numero: c.numero, dataEntrega: dataIso(c.dataEntrega) } : null;
  }

  /** Quantos ciclos imediatamente antes de `numero` não foram entregues pelo `motivo`. */
  private seguidosAntes(ciclos: CicloCompleto[], numero: number, motivo: MotivoPulo): number {
    let n = 0;
    for (const c of [...ciclos].reverse()) {
      if (c.numero >= numero) continue;
      if (this.motivo(c) !== motivo) break;
      n++;
    }
    return n;
  }

  private motivo(c: CicloCompleto): MotivoPulo | undefined {
    return (c.calculoPreco?.fatores as { motivoPulo?: MotivoPulo } | null)?.motivoPulo;
  }

  private async moverFimCompromisso(db: Db, assinatura: AssinaturaCompleta, ciclos: number): Promise<void> {
    if (!assinatura.fimCompromisso || !ciclos) return;
    const dias = DIAS_POR_FREQUENCIA[assinatura.frequencia] * ciclos;
    const novo = somarDias(dataIso(assinatura.fimCompromisso), dias);
    await db.assinatura.update({ where: { id: assinatura.id }, data: { fimCompromisso: new Date(`${novo}T00:00:00.000Z`) } });
  }

  // ---------- Leitura e permissões ----------

  /** CT16 / SEG04: a assinatura precisa ser do cliente do token. */
  private async carregar(clienteId: string, id: string): Promise<AssinaturaCompleta> {
    const assinatura = await this.prisma.assinatura.findUnique({ where: { id }, include: INCLUDE_ASSINATURA });
    if (!assinatura) throw erro('NAO_ENCONTRADO', 'Assinatura não encontrada.', HttpStatus.NOT_FOUND);
    if (assinatura.clienteId !== clienteId) {
      throw erro('SEM_PERMISSAO', 'Você não tem permissão para esta ação.', HttpStatus.FORBIDDEN);
    }
    return assinatura;
  }

  private ciclosDa(assinaturaId: string): Promise<CicloCompleto[]> {
    return this.prisma.ciclo.findMany({ where: { assinaturaId }, include: INCLUDE_CICLO, orderBy: { numero: 'asc' } });
  }

  private async enderecoDoCliente(clienteId: string, enderecoId: string) {
    const endereco = await this.prisma.endereco.findUnique({ where: { id: enderecoId }, include: { zona: true } });
    if (!endereco) throw erro('NAO_ENCONTRADO', 'Endereço não encontrado.', HttpStatus.NOT_FOUND, 'enderecoId');
    if (endereco.clienteId !== clienteId) throw erro('SEM_PERMISSAO', 'Você não tem permissão para esta ação.', HttpStatus.FORBIDDEN);
    return endereco;
  }

  private async garantirRecomendacao(clienteId: string, id: string): Promise<void> {
    const r = await this.prisma.recomendacao.findUnique({ where: { id } });
    if (!r) throw erro('NAO_ENCONTRADO', 'Recomendação não encontrada.', HttpStatus.NOT_FOUND, 'recomendacaoId');
    if (r.clienteId !== clienteId) throw erro('SEM_PERMISSAO', 'Você não tem permissão para esta ação.', HttpStatus.FORBIDDEN);
  }

  /** RN26: cobrança vencida (VENCIDO, ou PENDENTE com vencimento antes de hoje) bloqueia. */
  private async garantirSemCobrancaVencida(clienteId: string): Promise<void> {
    const hoje = new Date(`${this.clock.hoje()}T00:00:00.000Z`);
    const vencida = await this.prisma.pagamento.findFirst({
      where: {
        ciclo: { assinatura: { clienteId } },
        OR: [{ status: StatusPagamento.VENCIDO }, { status: StatusPagamento.PENDENTE, vencimento: { lt: hoje } }],
      },
    });
    if (vencida) {
      throw erro(
        'COBRANCA_VENCIDA',
        'Você tem uma cobrança vencida. Regularize para alterar a cesta ou assinar de novo.',
        HttpStatus.UNPROCESSABLE_ENTITY,
      );
    }
  }

  private async idsDosProdutos(codigos: string[]): Promise<Map<string, string>> {
    const produtos = await this.prisma.produto.findMany({ where: { codigo: { in: codigos } } });
    return new Map(produtos.map((p) => [p.codigo, p.id]));
  }

  private itensDa(a: AssinaturaCompleta) {
    return a.itens.map((i) => ({ produto: i.produto.codigo, quantidade: i.quantidade }));
  }

  private async paraResposta(a: AssinaturaCompleta): Promise<AssinaturaResponse> {
    const ciclos = await this.ciclosDa(a.id);
    return {
      id: a.id,
      status: a.status,
      plano: a.plano,
      frequencia: a.frequencia,
      janela: a.janela,
      formaPagamento: a.formaPagamento,
      cupom: a.cupom?.codigo ?? null,
      endereco: { id: a.endereco.id, apelido: a.endereco.apelido ?? null, bairro: a.endereco.bairro, zona: a.endereco.zona.nome },
      itens: this.itensDa(a).sort((x, y) => x.produto.localeCompare(y.produto)),
      proximaEntrega: this.proximoEmAberto(ciclos)?.dataEntrega ?? null,
      inicio: a.inicio ? dataIso(a.inicio) : null,
      fimCompromisso: a.fimCompromisso ? dataIso(a.fimCompromisso) : null,
    };
  }

  private cicloParaResposta(c: CicloCompleto): CicloResponse {
    const motivo = this.motivo(c);
    const pagamento = c.pagamentos[0];
    return {
      id: c.id,
      numero: c.numero,
      dataEntrega: dataIso(c.dataEntrega),
      dataCorte: c.dataCorte.toISOString(),
      status: c.status,
      janela: c.janela,
      enderecoId: c.enderecoId,
      valor: c.calculoPreco && c.itens.length ? dinheiro(dec(c.calculoPreco.valorFinal)) : null,
      itens: c.itens
        .map((i) => ({ produto: i.produto.codigo, quantidade: i.quantidade, precoUnitario: dinheiro(dec(i.precoUnitario)) }))
        .sort((x, y) => x.produto.localeCompare(y.produto)),
      ...(motivo && { motivoPulo: motivo }),
      pagamento: pagamento
        ? { status: pagamento.status, valor: dinheiro(dec(pagamento.valor)), vencimento: dataIso(pagamento.vencimento) }
        : null,
    };
  }
}
