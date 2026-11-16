import { HttpStatus, Injectable } from '@nestjs/common';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { ClockService } from '../common/clock.service';
import { PrismaService } from '../common/prisma.service';
import { RegraNegocioException } from '../common/regra-negocio.exception';
import { StatusAssinatura, StatusCiclo } from '../../prisma/generated/prisma/client';
import { CepService, ZonaDoCep } from './cep.service';
import { AtualizarEnderecoDto, CriarEnderecoDto } from './dto/endereco.dto';

export class EnderecoResponse {
  @ApiProperty() id: string;
  @ApiPropertyOptional({ nullable: true, type: String, example: 'Casa' }) apelido: string | null;
  @ApiProperty({ example: '22041001' }) cep: string;
  @ApiProperty({ example: 'Avenida Nossa Senhora de Copacabana' }) logradouro: string;
  @ApiProperty({ example: '100' }) numero: string;
  @ApiPropertyOptional({ nullable: true, type: String }) complemento: string | null;
  @ApiProperty({ example: 'Copacabana' }) bairro: string;
  @ApiProperty({ example: 'Rio de Janeiro' }) cidade: string;
  @ApiProperty({ example: 'RJ' }) uf: string;
  @ApiPropertyOptional({ nullable: true, type: String }) referencia: string | null;
  @ApiPropertyOptional({ nullable: true, type: String }) instrucoes: string | null;
  @ApiPropertyOptional({ nullable: true, type: Number, description: 'Sem provedor de geocodificação: permanece nulo (docs/DECISOES.md)' }) lat: number | null;
  @ApiPropertyOptional({ nullable: true, type: Number }) lng: number | null;
  @ApiProperty() principal: boolean;
  @ApiProperty({ example: { id: '…', nome: 'Zona Sul', taxaEntrega: 9.9, diasEntrega: ['SEG', 'QUA', 'SEX'] } })
  zona: ZonaDoCep;
}

/** Ciclos ainda não entregues: o endereço deles não pode mudar depois do corte. */
const CICLOS_PENDENTES: StatusCiclo[] = [
  StatusCiclo.AGENDADO,
  StatusCiclo.COBRADO,
  StatusCiclo.PAGO,
  StatusCiclo.SEPARADO,
  StatusCiclo.EM_ROTA,
  StatusCiclo.FALHOU,
];

type EnderecoComZona = Awaited<ReturnType<EnderecosService['buscarDoCliente']>>;

@Injectable()
export class EnderecosService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly cep: CepService,
    private readonly clock: ClockService,
  ) {}

  async criar(clienteId: string, dto: CriarEnderecoDto): Promise<EnderecoResponse> {
    const consulta = await this.cep.consultar(dto.cep);
    const existentes = await this.prisma.endereco.count({ where: { clienteId } });
    const principal = existentes === 0 || dto.principal === true;

    return this.prisma.$transaction(async (tx) => {
      if (principal) await tx.endereco.updateMany({ where: { clienteId, principal: true }, data: { principal: false } });
      const criado = await tx.endereco.create({
        data: {
          clienteId,
          apelido: dto.apelido ?? null,
          cep: consulta.cep,
          logradouro: consulta.logradouro,
          numero: dto.numero,
          complemento: dto.complemento ?? null,
          bairro: consulta.bairro,
          zonaId: consulta.zona.id,
          referencia: dto.referencia ?? null,
          instrucoes: dto.instrucoes ?? null,
          lat: null,
          lng: null,
          principal,
        },
        include: { zona: true },
      });
      return this.paraResposta(criado);
    });
  }

  async listar(clienteId: string): Promise<EnderecoResponse[]> {
    const lista = await this.prisma.endereco.findMany({
      where: { clienteId },
      include: { zona: true },
      orderBy: [{ principal: 'desc' }, { criadoEm: 'asc' }],
    });
    return lista.map((e) => this.paraResposta(e));
  }

  /** SEG04: busca e confere o dono. */
  async buscarDoCliente(clienteId: string, id: string) {
    const endereco = await this.prisma.endereco.findUnique({ where: { id }, include: { zona: true } });
    if (!endereco) {
      throw new RegraNegocioException('NAO_ENCONTRADO', 'Endereço não encontrado.', HttpStatus.NOT_FOUND, 'enderecoId');
    }
    if (endereco.clienteId !== clienteId) {
      throw new RegraNegocioException('SEM_PERMISSAO', 'Você não tem permissão para esta ação.', HttpStatus.FORBIDDEN);
    }
    return endereco;
  }

  /**
   * CEP, número e complemento mudam o destino da entrega: bloqueados (409 APOS_CORTE) se o endereço
   * estiver em um ciclo ainda não entregue cujo corte já passou (RN07/RN09). O resto é livre.
   */
  async atualizar(clienteId: string, id: string, dto: AtualizarEnderecoDto): Promise<EnderecoResponse> {
    const atual = await this.buscarDoCliente(clienteId, id);
    const mudaDestino = dto.cep !== undefined || dto.numero !== undefined || dto.complemento !== undefined;
    if (mudaDestino) {
      const travado = await this.prisma.ciclo.count({
        where: { enderecoId: id, status: { in: CICLOS_PENDENTES }, dataCorte: { lt: this.clock.agora() } },
      });
      if (travado > 0) {
        throw new RegraNegocioException(
          'APOS_CORTE',
          'A próxima entrega já passou do corte e vai para este endereço. Altere depois dela ou use outro endereço.',
          HttpStatus.CONFLICT,
          'enderecoId',
        );
      }
    }
    const consulta = dto.cep !== undefined ? await this.cep.consultar(dto.cep) : null;

    return this.prisma.$transaction(async (tx) => {
      if (dto.principal === true) {
        await tx.endereco.updateMany({ where: { clienteId, principal: true }, data: { principal: false } });
      }
      const atualizado = await tx.endereco.update({
        where: { id },
        data: {
          ...(consulta && {
            cep: consulta.cep,
            logradouro: consulta.logradouro,
            bairro: consulta.bairro,
            zonaId: consulta.zona.id,
          }),
          ...(dto.numero !== undefined && { numero: dto.numero }),
          ...(dto.complemento !== undefined && { complemento: dto.complemento }),
          ...(dto.apelido !== undefined && { apelido: dto.apelido }),
          ...(dto.referencia !== undefined && { referencia: dto.referencia }),
          ...(dto.instrucoes !== undefined && { instrucoes: dto.instrucoes }),
          // Desmarcar o principal sem indicar outro não é permitido: o principal só muda marcando outro.
          ...(dto.principal === true && !atual.principal && { principal: true }),
        },
        include: { zona: true },
      });
      return this.paraResposta(atualizado);
    });
  }

  /** Não remove o principal nem endereço ligado a assinatura ou ciclo (o histórico de entregas aponta para ele). */
  async remover(clienteId: string, id: string): Promise<void> {
    const endereco = await this.buscarDoCliente(clienteId, id);
    if (endereco.principal) {
      throw new RegraNegocioException(
        'ENDERECO_PRINCIPAL',
        'Marque outro endereço como principal antes de remover este.',
        HttpStatus.UNPROCESSABLE_ENTITY,
        'enderecoId',
      );
    }
    const emUso =
      (await this.prisma.assinatura.count({ where: { enderecoId: id, status: { not: StatusAssinatura.CANCELADA } } })) +
      (await this.prisma.ciclo.count({ where: { enderecoId: id } }));
    if (emUso > 0) {
      throw new RegraNegocioException(
        'ENDERECO_EM_USO',
        'Este endereço está ligado a uma assinatura ou entrega. Troque o endereço da assinatura antes.',
        HttpStatus.CONFLICT,
        'enderecoId',
      );
    }
    await this.prisma.endereco.delete({ where: { id } });
  }

  paraResposta(e: EnderecoComZona): EnderecoResponse {
    return {
      id: e.id,
      apelido: e.apelido,
      cep: e.cep,
      logradouro: e.logradouro,
      numero: e.numero,
      complemento: e.complemento,
      bairro: e.bairro,
      cidade: 'Rio de Janeiro',
      uf: 'RJ',
      referencia: e.referencia,
      instrucoes: e.instrucoes,
      lat: e.lat === null ? null : Number(e.lat.toString()),
      lng: e.lng === null ? null : Number(e.lng.toString()),
      principal: e.principal,
      zona: {
        id: e.zona.id,
        nome: e.zona.nome,
        taxaEntrega: Number(e.zona.taxaEntrega.toString()),
        diasEntrega: e.zona.diasEntrega,
      },
    };
  }
}
