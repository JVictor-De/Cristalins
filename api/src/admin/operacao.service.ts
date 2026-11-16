import { HttpStatus, Injectable } from '@nestjs/common';
import { ApiProperty } from '@nestjs/swagger';
import { IsIn } from 'class-validator';
import { SolucaoOcorrencia, StatusCiclo, StatusOcorrencia } from '../../prisma/generated/prisma/client';
import { MaquinaEstadosService } from '../assinaturas/maquina-estados.service';
import { dataCorte, dataIso, proximaDataDaZona, somarDias } from '../ciclos/agenda';
import { PrismaService } from '../common/prisma.service';
import { RegraNegocioException } from '../common/regra-negocio.exception';
import { MENSAGENS, NotificacoesService } from '../notificacoes/notificacoes.service';
import { avisoDaDecisao, EstoqueService, planejarSeparacao, ProdutoEstoque } from './estoque.service';

export const STATUS_ENTREGA = [StatusCiclo.SEPARADO, StatusCiclo.EM_ROTA, StatusCiclo.ENTREGUE, StatusCiclo.FALHOU] as const;
type StatusEntrega = (typeof STATUS_ENTREGA)[number];

/** RN17: depois desta falha, a reentrega deixa de ser grátis (nova taxa ou retirada). */
export const REENTREGAS_GRATIS = 1;

export class AtualizarStatusCicloDto {
  @ApiProperty({ enum: STATUS_ENTREGA })
  @IsIn(STATUS_ENTREGA, { message: 'Use SEPARADO, EM_ROTA, ENTREGUE ou FALHOU.' })
  status: StatusEntrega;
}

export class StatusCicloResponse {
  @ApiProperty() id: string;
  @ApiProperty({ enum: StatusCiclo }) status: StatusCiclo;
  @ApiProperty({ example: '2026-11-30' }) dataEntrega: string;
  @ApiProperty({ example: 0 }) tentativasEntrega: number;
  @ApiProperty({ type: [String], description: 'Avisos enviados ao cliente (trocas, créditos, reentrega)' }) avisos: string[];
}

const erro = (codigo: string, mensagem: string, status: HttpStatus, campo?: string) =>
  new RegraNegocioException(codigo, mensagem, status, campo);

/**
 * Separação (RF29) e status da entrega (RF31, RN17) por endpoints admin. O status só muda pela
 * máquina de estados; a entrega só sai paga (PAGO → SEPARADO, RN16). Cada mudança avisa o
 * cliente (RF32/RF51: separação e entrega).
 */
@Injectable()
export class OperacaoService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly maquina: MaquinaEstadosService,
    private readonly estoque: EstoqueService,
    private readonly notificacoes: NotificacoesService,
  ) {}

  /** Lista de separação do dia, por zona, com a prévia do RN06 e as reposições do RN15. */
  async separacao(data: string) {
    if (!/^\d{4}-\d{2}-\d{2}$/.test(data ?? '')) {
      throw erro('DADOS_INVALIDOS', 'Informe a data no formato AAAA-MM-DD.', HttpStatus.BAD_REQUEST, 'data');
    }
    const ciclos = await this.prisma.ciclo.findMany({
      where: { dataEntrega: new Date(`${data}T00:00:00.000Z`), status: { in: [StatusCiclo.PAGO, StatusCiclo.SEPARADO] } },
      include: {
        itens: { include: { produto: true } },
        endereco: { include: { zona: true } },
        assinatura: { include: { cliente: true } },
      },
      orderBy: { numero: 'asc' },
    });
    const catalogo: ProdutoEstoque[] = await this.prisma.produto.findMany({});
    const porId = new Map(catalogo.map((p) => [p.id, p]));
    const reservado = new Map<string, number>();
    const totais = new Map<string, number>();
    const zonas = new Map<string, unknown[]>();

    const ordenados = [...ciclos].sort(
      (a, b) =>
        a.endereco.zona.nome.localeCompare(b.endereco.zona.nome) || a.janela.localeCompare(b.janela) || a.numero - b.numero,
    );
    for (const c of ordenados) {
      const itens =
        c.status === StatusCiclo.PAGO
          ? planejarSeparacao(
              c.itens.map((i) => ({ produto: i.produto, quantidade: i.quantidade, precoUnitario: i.precoUnitario })),
              catalogo,
              reservado,
            ).map((x) => ({
              produto: (x.acao === 'SUBSTITUIDO' ? x.por : x.produto).codigo,
              nome: (x.acao === 'SUBSTITUIDO' ? x.por : x.produto).nome,
              quantidade: x.acao === 'PULADO' ? 0 : x.quantidade,
              acao: x.acao,
              ...(x.acao === 'SUBSTITUIDO' && { substitui: x.produto.codigo }),
              ...(x.acao === 'PULADO' && { credito: Number(x.credito) }),
            }))
          : c.itens.map((i) => ({ produto: i.produto.codigo, nome: i.produto.nome, quantidade: i.quantidade, acao: 'SEPARADO' }));
      const reposicoes = (await this.reposicoesPendentes(c.assinaturaId, c.numero)).map((o) => {
        const p = porId.get(o.produtoId ?? '');
        return { ocorrenciaId: o.id, produto: p?.codigo ?? null, nome: p?.nome ?? null, quantidade: o.quantidade ?? 0 };
      });
      for (const i of [...itens, ...reposicoes]) {
        if (i.produto && i.quantidade) totais.set(i.produto, (totais.get(i.produto) ?? 0) + i.quantidade);
      }
      const e = c.endereco;
      const lista = zonas.get(e.zona.nome) ?? [];
      lista.push({
        cicloId: c.id,
        numero: c.numero,
        status: c.status,
        janela: c.janela,
        cliente: c.assinatura.cliente.nome,
        endereco: {
          logradouro: e.logradouro,
          numero: e.numero,
          complemento: e.complemento ?? null,
          bairro: e.bairro,
          cep: e.cep,
          referencia: e.referencia ?? null,
          instrucoes: e.instrucoes ?? null,
        },
        itens,
        reposicoes,
      });
      zonas.set(e.zona.nome, lista);
    }
    return {
      data,
      zonas: [...zonas.entries()].map(([zona, cs]) => ({ zona, ciclos: cs })),
      totais: [...totais.entries()].map(([produto, quantidade]) => ({ produto, quantidade })).sort((a, b) => a.produto.localeCompare(b.produto)),
    };
  }

  private reposicoesPendentes(assinaturaId: string, antesDoNumero: number) {
    return this.prisma.ocorrencia.findMany({
      where: {
        solucao: SolucaoOcorrencia.REPOSICAO,
        status: StatusOcorrencia.ABERTA,
        ciclo: { assinaturaId, numero: { lt: antesDoNumero } },
      },
      orderBy: { criadoEm: 'asc' },
    });
  }

  async atualizarStatus(id: string, para: StatusEntrega): Promise<StatusCicloResponse> {
    const avisos: string[] = [];
    const resultado = await this.prisma.$transaction(async (tx) => {
      const ciclo = await tx.ciclo.findUnique({
        where: { id },
        include: { endereco: { include: { zona: true } }, assinatura: true },
      });
      if (!ciclo) throw erro('NAO_ENCONTRADO', 'Ciclo não encontrado.', HttpStatus.NOT_FOUND);
      await this.maquina.ciclo(tx, ciclo, para);

      if (para === StatusCiclo.SEPARADO) {
        const decisoes = await this.estoque.separar(tx, ciclo.id, ciclo.assinatura.clienteId);
        avisos.push(...decisoes.map(avisoDaDecisao).filter((a): a is string => !!a));
        // RN15: reposições pendentes da assinatura vão nesta entrega (mesmo produto, se houver estoque).
        const pendentes = await tx.ocorrencia.findMany({
          where: {
            solucao: SolucaoOcorrencia.REPOSICAO,
            status: StatusOcorrencia.ABERTA,
            ciclo: { assinaturaId: ciclo.assinaturaId, numero: { lt: ciclo.numero } },
          },
        });
        for (const o of pendentes) {
          const produto = o.produtoId ? await tx.produto.findUnique({ where: { id: o.produtoId } }) : null;
          const q = o.quantidade ?? 0;
          if (!produto || (produto.estoque !== null && produto.estoque < q)) continue; // fica para a próxima
          await this.estoque.baixar(tx, produto, q);
          await tx.ocorrencia.update({ where: { id: o.id }, data: { status: StatusOcorrencia.RESOLVIDA } });
          avisos.push(`A reposição de ${q} ${produto.nome} vai nesta entrega.`);
        }
      }

      let reentrega: string | null = null;
      if (para === StatusCiclo.FALHOU) {
        const tentativas = ciclo.tentativasEntrega + 1;
        const data: { tentativasEntrega: number; dataEntrega?: Date; dataCorte?: Date } = { tentativasEntrega: tentativas };
        if (tentativas <= REENTREGAS_GRATIS) {
          reentrega = proximaDataDaZona(somarDias(dataIso(ciclo.dataEntrega), 1), ciclo.endereco.zona.diasEntrega);
          data.dataEntrega = new Date(`${reentrega}T00:00:00.000Z`);
          data.dataCorte = dataCorte(reentrega);
        }
        await tx.ciclo.update({ where: { id: ciclo.id }, data });
        ciclo.tentativasEntrega = tentativas;
        if (data.dataEntrega) ciclo.dataEntrega = data.dataEntrega;
      }
      return { ciclo, reentrega };
    });

    const { ciclo, reentrega } = resultado;
    const entrega = dataIso(ciclo.dataEntrega);
    const clienteId = ciclo.assinatura.clienteId;
    const dados = { cicloId: ciclo.id, status: para };
    if (para === StatusCiclo.SEPARADO) {
      await this.notificacoes.notificar(clienteId, 'SEPARACAO', MENSAGENS.separacao(entrega, avisos), dados);
    } else if (para === StatusCiclo.EM_ROTA) {
      await this.notificacoes.notificar(clienteId, 'ENTREGA', MENSAGENS.emRota(), dados);
    } else if (para === StatusCiclo.ENTREGUE) {
      await this.notificacoes.notificar(clienteId, 'ENTREGA', MENSAGENS.entregue(), dados);
    } else {
      const m = MENSAGENS.falhou(reentrega);
      avisos.push(m.corpo);
      await this.notificacoes.notificar(clienteId, 'ENTREGA', m, dados);
    }
    return { id: ciclo.id, status: ciclo.status, dataEntrega: entrega, tentativasEntrega: ciclo.tentativasEntrega, avisos };
  }
}
