import { HttpStatus, Inject, Injectable } from '@nestjs/common';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Transform, Type } from 'class-transformer';
import { IsEnum, IsInt, IsString, IsUUID, Max, Min } from 'class-validator';
import Decimal from 'decimal.js';
import { randomUUID } from 'node:crypto';
import { SolucaoOcorrencia, StatusCiclo, StatusOcorrencia, TipoOcorrencia } from '../../prisma/generated/prisma/client';
import { ClockService } from '../common/clock.service';
import { PrismaService } from '../common/prisma.service';
import { RegraNegocioException } from '../common/regra-negocio.exception';
import { CreditosService } from '../creditos/creditos.service';
import { ARMAZENAMENTO_FOTOS, ArmazenamentoFotos } from './armazenamento-fotos';

/** RN15: avaria ou falta informada em até 24 h da entrega. */
export const PRAZO_OCORRENCIA_HORAS = 24;
export const TAMANHO_MAXIMO_FOTO = 5 * 1024 * 1024;
export const TIPOS_FOTO: Record<string, string> = { 'image/jpeg': 'jpg', 'image/png': 'png', 'image/webp': 'webp', 'image/heic': 'heic' };

/** Arquivo do multer (só os campos usados). */
export interface FotoEnviada {
  buffer: Buffer;
  mimetype: string;
  size: number;
}

export class CriarOcorrenciaDto {
  @ApiProperty({ description: 'Entrega (ciclo) já entregue' })
  @IsUUID('all', { message: 'Entrega inválida.' })
  cicloId: string;

  @ApiProperty({ enum: TipoOcorrencia })
  @IsEnum(TipoOcorrencia, { message: 'Escolha avaria ou falta.' })
  tipo: TipoOcorrencia;

  @ApiProperty({ example: 'WP500', description: 'Código do produto avariado ou faltante' })
  @Transform(({ value }: { value: unknown }) => (typeof value === 'string' ? value.trim().toUpperCase() : value))
  @IsString()
  produto: string;

  @ApiProperty({ example: 2 })
  @Type(() => Number)
  @IsInt({ message: 'Informe a quantidade.' })
  @Min(1, { message: 'Informe ao menos 1 unidade.' })
  @Max(1000)
  quantidade: number;

  @ApiProperty({ enum: SolucaoOcorrencia, description: 'Reposição na próxima entrega ou crédito' })
  @IsEnum(SolucaoOcorrencia, { message: 'Escolha reposição ou crédito.' })
  solucao: SolucaoOcorrencia;
}

export class OcorrenciaResponse {
  @ApiProperty() id: string;
  @ApiProperty() cicloId: string;
  @ApiProperty({ enum: TipoOcorrencia }) tipo: TipoOcorrencia;
  @ApiProperty({ example: 'WP500' }) produto: string;
  @ApiProperty({ example: 2 }) quantidade: number;
  @ApiProperty({ enum: SolucaoOcorrencia }) solucao: SolucaoOcorrencia;
  @ApiProperty({ enum: StatusOcorrencia }) status: StatusOcorrencia;
  @ApiProperty({ description: 'Foto guardada no armazenamento privado (sem URL pública)' }) temFoto: boolean;
  @ApiPropertyOptional({ nullable: true, type: Number, example: 16.94, description: 'Crédito concedido (solução CREDITO)' })
  credito: number | null;
  @ApiProperty() criadoEm: string;
}

const erro = (codigo: string, mensagem: string, status: HttpStatus, campo?: string) =>
  new RegraNegocioException(codigo, mensagem, status, campo);

/**
 * RN15/RF49: avaria ou falta com foto em até 24 h da entrega. Crédito: na hora, no valor pago do
 * item (90 dias, RN20). Reposição: fica aberta e vai na próxima separação da assinatura.
 */
@Injectable()
export class OcorrenciasService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly clock: ClockService,
    private readonly creditos: CreditosService,
    @Inject(ARMAZENAMENTO_FOTOS) private readonly fotos: ArmazenamentoFotos,
  ) {}

  async criar(clienteId: string, dto: CriarOcorrenciaDto, foto: FotoEnviada | undefined): Promise<OcorrenciaResponse> {
    if (!foto?.buffer?.length) throw erro('DADOS_INVALIDOS', 'Envie uma foto do problema.', HttpStatus.BAD_REQUEST, 'foto');
    const extensao = TIPOS_FOTO[foto.mimetype];
    if (!extensao) throw erro('DADOS_INVALIDOS', 'A foto precisa ser JPG, PNG, WEBP ou HEIC.', HttpStatus.BAD_REQUEST, 'foto');
    if (foto.size > TAMANHO_MAXIMO_FOTO) throw erro('DADOS_INVALIDOS', 'A foto pode ter até 5 MB.', HttpStatus.BAD_REQUEST, 'foto');

    const ciclo = await this.prisma.ciclo.findUnique({
      where: { id: dto.cicloId },
      include: { assinatura: true, itens: { include: { produto: true } }, ocorrencias: true },
    });
    if (!ciclo) throw erro('NAO_ENCONTRADO', 'Entrega não encontrada.', HttpStatus.NOT_FOUND, 'cicloId');
    if (ciclo.assinatura.clienteId !== clienteId) throw erro('SEM_PERMISSAO', 'Você não tem permissão para esta ação.', HttpStatus.FORBIDDEN);
    if (ciclo.status !== StatusCiclo.ENTREGUE) {
      throw erro('OCORRENCIA_INVALIDA', 'Só dá para informar avaria ou falta de uma entrega já feita.', HttpStatus.UNPROCESSABLE_ENTITY);
    }
    // A entrega é o último status do ciclo: `atualizadoEm` marca o momento em que virou ENTREGUE.
    const limite = ciclo.atualizadoEm.getTime() + PRAZO_OCORRENCIA_HORAS * 60 * 60 * 1000;
    if (this.clock.agora().getTime() > limite) {
      throw erro(
        'PRAZO_OCORRENCIA_ENCERRADO',
        'Avarias e faltas devem ser informadas em até 24 horas da entrega. Fale com o suporte.',
        HttpStatus.UNPROCESSABLE_ENTITY,
      );
    }
    const item = ciclo.itens.find((i) => i.produto.codigo === dto.produto);
    if (!item) throw erro('DADOS_INVALIDOS', 'Esse produto não veio nesta entrega.', HttpStatus.BAD_REQUEST, 'produto');
    const jaInformado = ciclo.ocorrencias
      .filter((o) => o.produtoId === item.produtoId)
      .reduce((s, o) => s + (o.quantidade ?? 0), 0);
    if (dto.quantidade + jaInformado > item.quantidade) {
      throw erro(
        'DADOS_INVALIDOS',
        `Nesta entrega vieram ${item.quantidade} unidades${jaInformado ? ` e ${jaInformado} já foram informadas` : ''}.`,
        HttpStatus.BAD_REQUEST,
        'quantidade',
      );
    }

    const id = randomUUID();
    const fotoUrl = await this.fotos.salvar(`ocorrencias/${ciclo.id}/${id}.${extensao}`, foto.buffer, foto.mimetype);
    const credito =
      dto.solucao === SolucaoOcorrencia.CREDITO
        ? new Decimal(item.precoUnitario.toString()).times(dto.quantidade).toDecimalPlaces(2, Decimal.ROUND_HALF_UP)
        : null;

    const criada = await this.prisma.$transaction(async (tx) => {
      const o = await tx.ocorrencia.create({
        data: {
          id,
          cicloId: ciclo.id,
          tipo: dto.tipo,
          fotoUrl,
          produtoId: item.produtoId,
          quantidade: dto.quantidade,
          solucao: dto.solucao,
          status: credito ? StatusOcorrencia.RESOLVIDA : StatusOcorrencia.ABERTA,
        },
      });
      if (credito) await this.creditos.conceder(tx, clienteId, credito.toFixed(2), `OCORRENCIA:${o.id}`);
      return o;
    });
    return this.resposta(criada, dto.produto, credito ? credito.toNumber() : null);
  }

  async listar(clienteId: string): Promise<OcorrenciaResponse[]> {
    const lista = await this.prisma.ocorrencia.findMany({
      where: { ciclo: { assinatura: { clienteId } } },
      orderBy: { criadoEm: 'desc' },
    });
    const produtos = new Map((await this.prisma.produto.findMany({})).map((p) => [p.id, p.codigo]));
    const creditos = await this.prisma.credito.findMany({ where: { clienteId, motivo: { startsWith: 'OCORRENCIA:' } } });
    const valorDe = new Map(creditos.map((c) => [c.motivo.slice('OCORRENCIA:'.length), Number(c.valor.toString())]));
    return lista.map((o) => this.resposta(o, produtos.get(o.produtoId ?? '') ?? '', valorDe.get(o.id) ?? null));
  }

  private resposta(
    o: { id: string; cicloId: string; tipo: TipoOcorrencia; quantidade: number | null; solucao: SolucaoOcorrencia | null; status: StatusOcorrencia; fotoUrl: string | null; criadoEm: Date },
    produto: string,
    credito: number | null,
  ): OcorrenciaResponse {
    return {
      id: o.id,
      cicloId: o.cicloId,
      tipo: o.tipo,
      produto,
      quantidade: o.quantidade ?? 0,
      solucao: o.solucao ?? SolucaoOcorrencia.CREDITO,
      status: o.status,
      temFoto: !!o.fotoUrl,
      credito,
      criadoEm: o.criadoEm.toISOString(),
    };
  }
}
