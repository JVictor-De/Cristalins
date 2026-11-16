import { HttpStatus, Inject, Injectable, Logger } from '@nestjs/common';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Transform } from 'class-transformer';
import { IsOptional, IsString, Length, Matches } from 'class-validator';
import { PrismaService } from '../common/prisma.service';
import { RegraNegocioException } from '../common/regra-negocio.exception';
import { CobrancaService } from './cobranca.service';
import { PAGAMENTO_GATEWAY, PagamentoGateway } from './pagamento.gateway';

const digitos = ({ value }: { value: unknown }) => (typeof value === 'string' ? value.replace(/\D/g, '') : value);

/**
 * Dados do cartão para tokenizar. Passam só em memória até o Asaas: a API **não grava** número
 * nem CVV (nem em log), só o token, a bandeira e os 4 últimos dígitos.
 */
export class CadastrarCartaoDto {
  @ApiProperty({ example: 'ANA SOUZA' })
  @IsString()
  @Length(2, 80)
  nomeNoCartao: string;

  @ApiProperty({ example: '4444444444444444', description: 'Só trafega até o Asaas; nunca é guardado' })
  @Transform(digitos)
  @Matches(/^\d{13,19}$/, { message: 'Número do cartão inválido.' })
  numero: string;

  @ApiProperty({ example: '12' })
  @Matches(/^(0[1-9]|1[0-2])$/, { message: 'Mês de validade inválido.' })
  mesValidade: string;

  @ApiProperty({ example: '2030' })
  @Matches(/^20\d{2}$/, { message: 'Ano de validade inválido.' })
  anoValidade: string;

  @ApiProperty({ example: '123', description: 'Só trafega até o Asaas; nunca é guardado' })
  @Matches(/^\d{3,4}$/, { message: 'CVV inválido.' })
  cvv: string;

  @ApiProperty({ example: '22041001', description: 'CEP do titular (exigido pelo Asaas)' })
  @Transform(digitos)
  @Matches(/^\d{8}$/, { message: 'Informe o CEP com 8 dígitos.' })
  cep: string;

  @ApiProperty({ example: '100' })
  @IsString()
  @Length(1, 20)
  numeroEndereco: string;

  @ApiPropertyOptional({ example: '21987654321', description: 'Padrão: celular do cadastro' })
  @IsOptional()
  @Transform(digitos)
  @Matches(/^\d{10,11}$/, { message: 'Informe o telefone com DDD.' })
  telefone?: string;
}

export class CartaoResponse {
  @ApiProperty() id: string;
  @ApiProperty({ example: 'VISA' }) bandeira: string;
  @ApiProperty({ example: '4444', description: '4 últimos dígitos' }) final: string;
}

@Injectable()
export class CartaoService {
  private readonly log = new Logger(CartaoService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly cobranca: CobrancaService,
    @Inject(PAGAMENTO_GATEWAY) private readonly gateway: PagamentoGateway,
  ) {}

  /** `POST /cartoes`: tokeniza no Asaas e guarda só token, bandeira e final. */
  async cadastrar(clienteId: string, dto: CadastrarCartaoDto, ipRemoto: string): Promise<CartaoResponse> {
    const cliente = await this.prisma.cliente.findUnique({ where: { id: clienteId } });
    if (!cliente) throw new RegraNegocioException('NAO_ENCONTRADO', 'Cliente não encontrado.', HttpStatus.NOT_FOUND);
    const telefone = dto.telefone ?? cliente.celular;
    if (!telefone) {
      throw new RegraNegocioException('DADOS_INVALIDOS', 'Informe o telefone com DDD.', HttpStatus.BAD_REQUEST, 'telefone');
    }
    const customerId = await this.cobranca.garantirClienteAsaas(clienteId);

    let tokenizado;
    try {
      tokenizado = await this.gateway.tokenizarCartao({
        customerId,
        nomeNoCartao: dto.nomeNoCartao,
        numero: dto.numero,
        mesValidade: dto.mesValidade,
        anoValidade: dto.anoValidade,
        cvv: dto.cvv,
        titular: {
          nome: cliente.nome,
          email: cliente.email,
          cpfCnpj: cliente.cpfCnpj,
          cep: dto.cep,
          numeroEndereco: dto.numeroEndereco,
          telefone,
        },
        ipRemoto,
      });
    } catch {
      // Sem detalhes do erro no log: a resposta do Asaas poderia ecoar dados do cartão.
      this.log.warn(`Tokenização recusada para o cliente ${clienteId}`);
      throw new RegraNegocioException(
        'CARTAO_RECUSADO',
        'Não conseguimos validar este cartão. Confira os dados ou use outro.',
        HttpStatus.UNPROCESSABLE_ENTITY,
      );
    }

    const cartao = await this.prisma.cartao.create({
      data: { clienteId, asaasToken: tokenizado.token, bandeira: tokenizado.bandeira, final: tokenizado.final },
    });
    return { id: cartao.id, bandeira: cartao.bandeira, final: cartao.final };
  }

  async listar(clienteId: string): Promise<CartaoResponse[]> {
    const lista = await this.prisma.cartao.findMany({ where: { clienteId }, orderBy: { criadoEm: 'desc' } });
    return lista.map((c) => ({ id: c.id, bandeira: c.bandeira, final: c.final }));
  }
}
