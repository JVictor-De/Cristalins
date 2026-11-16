import { HttpStatus, Injectable } from '@nestjs/common';
import { ApiProperty } from '@nestjs/swagger';
import { Transform } from 'class-transformer';
import { IsEmail, IsString, Length, Matches } from 'class-validator';
import { createHmac, timingSafeEqual } from 'node:crypto';
import { gerarHashSenha } from '../auth/senha';
import { ClockService } from '../common/clock.service';
import { PrismaService } from '../common/prisma.service';
import { RegraNegocioException } from '../common/regra-negocio.exception';
import { NotificacoesService } from './notificacoes.service';

/** Janela do código: vale na janela em que foi pedido e na seguinte (15–30 min). */
export const JANELA_CODIGO_MS = 15 * 60 * 1000;
/** Erros de código por e-mail antes de bloquear (até a janela passar). */
export const TENTATIVAS_CODIGO = 5;

const minusculo = ({ value }: { value: unknown }) => (typeof value === 'string' ? value.trim().toLowerCase() : value);

export class EsqueciSenhaDto {
  @ApiProperty({ example: 'ana@exemplo.com' })
  @Transform(minusculo)
  @IsEmail({}, { message: 'Informe um e-mail válido.' })
  email: string;
}

export class RedefinirSenhaDto {
  @ApiProperty({ example: 'ana@exemplo.com' })
  @Transform(minusculo)
  @IsEmail({}, { message: 'Informe um e-mail válido.' })
  email: string;

  @ApiProperty({ example: '123456', description: 'Código de 6 dígitos enviado por e-mail' })
  @Matches(/^\d{6}$/, { message: 'O código tem 6 dígitos.' })
  codigo: string;

  @ApiProperty({ example: 'nova-senha-forte', minLength: 8, maxLength: 72 })
  @IsString()
  @Length(8, 72, { message: 'A senha precisa ter de 8 a 72 caracteres.' })
  novaSenha: string;
}

export class MensagemResponse {
  @ApiProperty() mensagem: string;
}

/**
 * RF52 sem tabela nova: o código é um HMAC (segredo do JWT) do id do cliente, do hash atual da
 * senha e da janela de tempo. Vence sozinho, e vale uma vez só, porque o hash muda ao redefinir.
 */
@Injectable()
export class RecuperacaoSenhaService {
  private readonly falhas = new Map<string, { quantidade: number; desde: number }>();

  constructor(
    private readonly prisma: PrismaService,
    private readonly clock: ClockService,
    private readonly notificacoes: NotificacoesService,
  ) {}

  private segredo(): string {
    const s = process.env.JWT_SECRET;
    if (!s) throw new Error('JWT_SECRET não definida (veja .env.example).');
    return s;
  }

  codigoPara(cliente: { id: string; senhaHash: string }, instante: number): string {
    const janela = Math.floor(instante / JANELA_CODIGO_MS);
    const h = createHmac('sha256', this.segredo()).update(`${cliente.id}:${cliente.senhaHash}:${janela}`).digest();
    return String(h.readUInt32BE(0) % 1_000_000).padStart(6, '0');
  }

  /** Sempre a mesma resposta: não revela se o e-mail tem cadastro. */
  async esqueci(email: string): Promise<MensagemResponse> {
    const cliente = await this.prisma.cliente.findUnique({ where: { email } });
    if (cliente && !cliente.excluidoEm) {
      const codigo = this.codigoPara(cliente, this.clock.agora().getTime());
      await this.notificacoes.enviarEmail(
        cliente.email,
        'Código para criar uma nova senha',
        `Seu código para criar uma nova senha no app Cristalins é ${codigo}. ` +
          'Ele vale por até 30 minutos. Se você não pediu, ignore este e-mail: sua senha continua a mesma.',
        'SENHA',
      );
    }
    return { mensagem: 'Se o e-mail tiver cadastro, enviamos um código para criar uma nova senha.' };
  }

  async redefinir(dto: RedefinirSenhaDto): Promise<MensagemResponse> {
    const agora = this.clock.agora().getTime();
    const f = this.falhas.get(dto.email);
    if (f && agora - f.desde < 2 * JANELA_CODIGO_MS && f.quantidade >= TENTATIVAS_CODIGO) {
      throw new RegraNegocioException(
        'MUITAS_TENTATIVAS',
        'Muitas tentativas com código errado. Peça um novo código daqui a 30 minutos.',
        HttpStatus.TOO_MANY_REQUESTS,
      );
    }
    const cliente = await this.prisma.cliente.findUnique({ where: { email: dto.email } });
    const valido =
      !!cliente &&
      !cliente.excluidoEm &&
      [agora, agora - JANELA_CODIGO_MS].some((t) => iguais(this.codigoPara(cliente, t), dto.codigo));
    if (!valido) {
      const atual = f && agora - f.desde < 2 * JANELA_CODIGO_MS ? f : { quantidade: 0, desde: agora };
      this.falhas.set(dto.email, { quantidade: atual.quantidade + 1, desde: atual.desde });
      throw new RegraNegocioException('CODIGO_INVALIDO', 'Código inválido ou vencido. Peça um novo.', HttpStatus.BAD_REQUEST, 'codigo');
    }
    await this.prisma.cliente.update({ where: { id: cliente.id }, data: { senhaHash: await gerarHashSenha(dto.novaSenha) } });
    this.falhas.delete(dto.email);
    return { mensagem: 'Senha alterada. Entre com a nova senha.' };
  }
}

function iguais(a: string, b: string): boolean {
  const x = Buffer.from(a);
  const y = Buffer.from(b);
  return x.length === y.length && timingSafeEqual(x, y);
}
