import { HttpStatus, Injectable } from '@nestjs/common';
import { PrismaService } from '../common/prisma.service';
import { RegraNegocioException } from '../common/regra-negocio.exception';
import { conferirSenha } from './senha';
import { Tokens, TokenService } from './token.service';

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly tokens: TokenService,
  ) {}

  /** RF02: e-mail e senha. Mesma resposta para e-mail inexistente e senha errada. */
  async login(email: string, senha: string): Promise<Tokens> {
    const cliente = await this.prisma.cliente.findUnique({ where: { email } });
    const senhaOk = await conferirSenha(senha, cliente?.senhaHash);
    if (!cliente || cliente.excluidoEm || !senhaOk) {
      throw new RegraNegocioException(
        'CREDENCIAIS_INVALIDAS',
        'E-mail ou senha incorretos.',
        HttpStatus.UNAUTHORIZED,
      );
    }
    return this.tokens.emitir({ id: cliente.id, papel: cliente.papel });
  }

  /** Renova os dois tokens. O papel vem do banco (mudança de papel vale na renovação). */
  async renovar(refreshToken: string): Promise<Tokens> {
    const { id } = await this.tokens.verificarRefresh(refreshToken);
    const cliente = await this.prisma.cliente.findUnique({ where: { id } });
    if (!cliente || cliente.excluidoEm) {
      throw new RegraNegocioException(
        'NAO_AUTENTICADO',
        'Sessão inválida ou expirada. Entre de novo.',
        HttpStatus.UNAUTHORIZED,
      );
    }
    return this.tokens.emitir({ id: cliente.id, papel: cliente.papel });
  }
}
