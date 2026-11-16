import { CanActivate, ExecutionContext, HttpStatus, Injectable } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { RegraNegocioException } from '../common/regra-negocio.exception';
import { Papel } from '../../prisma/generated/prisma/client';
import { CHAVE_PAPEIS, CHAVE_PUBLICO, RequisicaoAutenticada } from './decorators';
import { TokenService } from './token.service';

/** Guard global: exige `Authorization: Bearer <accessToken>` salvo em rotas `@Publico()`. */
@Injectable()
export class JwtAuthGuard implements CanActivate {
  constructor(
    private readonly reflector: Reflector,
    private readonly tokens: TokenService,
  ) {}

  async canActivate(ctx: ExecutionContext): Promise<boolean> {
    const publico = this.reflector.getAllAndOverride<boolean>(CHAVE_PUBLICO, [
      ctx.getHandler(),
      ctx.getClass(),
    ]);
    const req = ctx.switchToHttp().getRequest<RequisicaoAutenticada>();
    const [esquema, token] = (req.headers.authorization ?? '').split(' ');
    const temBearer = esquema === 'Bearer' && !!token;

    // Rota pública: sem token segue anônimo; com Bearer válido anexa o usuário (ex.: simular).
    if (publico) {
      if (temBearer) req.usuario = await this.tokens.verificarAcesso(token);
      return true;
    }

    if (!temBearer) {
      throw new RegraNegocioException(
        'NAO_AUTENTICADO',
        'Entre na sua conta para continuar.',
        HttpStatus.UNAUTHORIZED,
      );
    }
    req.usuario = await this.tokens.verificarAcesso(token);
    return true;
  }
}

/** Guard global de papéis (SEG03). Sem `@Papeis`, qualquer usuário autenticado passa. */
@Injectable()
export class PapeisGuard implements CanActivate {
  constructor(private readonly reflector: Reflector) {}

  canActivate(ctx: ExecutionContext): boolean {
    const papeis = this.reflector.getAllAndOverride<Papel[] | undefined>(CHAVE_PAPEIS, [
      ctx.getHandler(),
      ctx.getClass(),
    ]);
    if (!papeis?.length) return true;
    const usuario = ctx.switchToHttp().getRequest<RequisicaoAutenticada>().usuario;
    if (usuario && papeis.includes(usuario.papel)) return true;
    throw new RegraNegocioException(
      'SEM_PERMISSAO',
      'Você não tem permissão para esta ação.',
      HttpStatus.FORBIDDEN,
    );
  }
}
