import { HttpStatus, Injectable } from '@nestjs/common';
import { gerarHashSenha } from '../auth/senha';
import { ClockService } from '../common/clock.service';
import { dataIsoParaDate, dataIsoValida, dateParaDataIso, idadeEm } from '../common/datas';
import { cpfOuCnpjValido } from '../common/documento';
import { PrismaService } from '../common/prisma.service';
import { RegraNegocioException } from '../common/regra-negocio.exception';
import { Cliente } from '../../prisma/generated/prisma/client';
import { AtualizarClienteDto } from './dto/atualizar-cliente.dto';
import { ClienteResponse } from './dto/cliente.response';
import { CriarClienteDto } from './dto/criar-cliente.dto';

export const IDADE_MINIMA = 18;
const IDADE_MAXIMA_PLAUSIVEL = 130;

@Injectable()
export class ClientesService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly clock: ClockService,
  ) {}

  async criar(dto: CriarClienteDto): Promise<Cliente> {
    if (!cpfOuCnpjValido(dto.cpfCnpj)) {
      throw new RegraNegocioException(
        'CPF_INVALIDO',
        'CPF ou CNPJ inválido. Confira os números.',
        HttpStatus.UNPROCESSABLE_ENTITY,
        'cpfCnpj',
      );
    }
    this.validarNascimento(dto.dataNascimento);
    await this.garantirUnico(dto.cpfCnpj, dto.email);

    try {
      return await this.prisma.cliente.create({
        data: {
          nome: dto.nome,
          cpfCnpj: dto.cpfCnpj,
          email: dto.email,
          celular: dto.celular ?? null,
          dataNascimento: dataIsoParaDate(dto.dataNascimento),
          senhaHash: await gerarHashSenha(dto.senha),
          aceiteTermosEm: this.clock.agora(),
          marketingOk: dto.marketingOk ?? false,
        },
      });
    } catch (erro) {
      // Corrida entre a checagem e o insert: refaz a checagem para devolver o código certo.
      if ((erro as { code?: string }).code === 'P2002') await this.garantirUnico(dto.cpfCnpj, dto.email);
      throw erro;
    }
  }

  async buscarAtivo(id: string): Promise<Cliente> {
    const cliente = await this.prisma.cliente.findUnique({ where: { id } });
    if (!cliente || cliente.excluidoEm) {
      throw new RegraNegocioException(
        'NAO_AUTENTICADO',
        'Conta não encontrada. Entre de novo.',
        HttpStatus.UNAUTHORIZED,
      );
    }
    return cliente;
  }

  /** SEG04: o id vem sempre do JWT, nunca do corpo ou da rota. */
  async atualizar(id: string, dto: AtualizarClienteDto): Promise<Cliente> {
    await this.buscarAtivo(id);
    return this.prisma.cliente.update({
      where: { id },
      data: {
        ...(dto.nome !== undefined && { nome: dto.nome }),
        ...(dto.celular !== undefined && { celular: dto.celular }),
        ...(dto.marketingOk !== undefined && { marketingOk: dto.marketingOk }),
      },
    });
  }

  paraResposta(c: Cliente): ClienteResponse {
    return {
      id: c.id,
      nome: c.nome,
      cpfCnpj: c.cpfCnpj,
      email: c.email,
      celular: c.celular,
      dataNascimento: c.dataNascimento ? dateParaDataIso(c.dataNascimento) : null,
      papel: c.papel,
      marketingOk: c.marketingOk,
      aceiteTermosEm: c.aceiteTermosEm?.toISOString() ?? null,
      criadoEm: c.criadoEm.toISOString(),
    };
  }

  private validarNascimento(dataNascimento: string): void {
    const idade = dataIsoValida(dataNascimento) ? idadeEm(dataNascimento, this.clock.hoje()) : NaN;
    if (Number.isNaN(idade) || idade < 0 || idade > IDADE_MAXIMA_PLAUSIVEL) {
      throw new RegraNegocioException(
        'DADOS_INVALIDOS',
        'Data de nascimento inválida.',
        HttpStatus.BAD_REQUEST,
        'dataNascimento',
      );
    }
    if (idade < IDADE_MINIMA) {
      throw new RegraNegocioException(
        'MENOR_DE_IDADE',
        'A assinatura é só para maiores de 18 anos.',
        HttpStatus.UNPROCESSABLE_ENTITY,
        'dataNascimento',
      );
    }
  }

  private async garantirUnico(cpfCnpj: string, email: string): Promise<void> {
    if (await this.prisma.cliente.findUnique({ where: { cpfCnpj } })) {
      throw new RegraNegocioException(
        'CPF_JA_CADASTRADO',
        'Já existe uma conta com este CPF ou CNPJ.',
        HttpStatus.CONFLICT,
        'cpfCnpj',
      );
    }
    if (await this.prisma.cliente.findUnique({ where: { email } })) {
      throw new RegraNegocioException(
        'EMAIL_JA_CADASTRADO',
        'Já existe uma conta com este e-mail.',
        HttpStatus.CONFLICT,
        'email',
      );
    }
  }
}
