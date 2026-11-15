import { HttpStatus, Injectable } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { RegraNegocioException } from '../common/regra-negocio.exception';
import { Papel } from '../../prisma/generated/prisma/client';

/** SEG01: acesso 15 min, renovação 30 dias. */
export const EXPIRA_ACESSO_SEGUNDOS = 15 * 60;
export const EXPIRA_REFRESH_SEGUNDOS = 30 * 24 * 60 * 60;

type TipoToken = 'acesso' | 'refresh';

export interface UsuarioToken {
  id: string;
  papel: Papel;
}

interface PayloadToken {
  sub: string;
  papel: Papel;
  tipo: TipoToken;
}

export interface Tokens {
  accessToken: string;
  refreshToken: string;
  expiresIn: number;
}

function segredo(nome: 'JWT_SECRET' | 'JWT_REFRESH_SECRET'): string {
  const valor = process.env[nome];
  if (!valor) throw new Error(`${nome} não definida (veja .env.example).`);
  return valor;
}

/** Emite e valida JWT. Segredos só do ambiente (SEG08); acesso e refresh usam segredos diferentes. */
@Injectable()
export class TokenService {
  private readonly segredoAcesso = segredo('JWT_SECRET');
  private readonly segredoRefresh = segredo('JWT_REFRESH_SECRET');

  constructor(private readonly jwt: JwtService) {}

  async emitir(usuario: UsuarioToken): Promise<Tokens> {
    const base = { sub: usuario.id, papel: usuario.papel };
    const [accessToken, refreshToken] = await Promise.all([
      this.jwt.signAsync({ ...base, tipo: 'acesso' } satisfies PayloadToken, {
        secret: this.segredoAcesso,
        expiresIn: EXPIRA_ACESSO_SEGUNDOS,
      }),
      this.jwt.signAsync({ ...base, tipo: 'refresh' } satisfies PayloadToken, {
        secret: this.segredoRefresh,
        expiresIn: EXPIRA_REFRESH_SEGUNDOS,
      }),
    ]);
    return { accessToken, refreshToken, expiresIn: EXPIRA_ACESSO_SEGUNDOS };
  }

  verificarAcesso(token: string): Promise<UsuarioToken> {
    return this.verificar(token, 'acesso');
  }

  verificarRefresh(token: string): Promise<UsuarioToken> {
    return this.verificar(token, 'refresh');
  }

  private async verificar(token: string, tipo: TipoToken): Promise<UsuarioToken> {
    try {
      const payload = await this.jwt.verifyAsync<PayloadToken>(token, {
        secret: tipo === 'acesso' ? this.segredoAcesso : this.segredoRefresh,
      });
      if (payload.tipo !== tipo || !payload.sub) throw new Error('tipo de token incorreto');
      return { id: payload.sub, papel: payload.papel };
    } catch {
      throw new RegraNegocioException(
        'NAO_AUTENTICADO',
        'Sessão inválida ou expirada. Entre de novo.',
        HttpStatus.UNAUTHORIZED,
      );
    }
  }
}
