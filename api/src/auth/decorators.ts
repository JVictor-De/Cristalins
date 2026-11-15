import { createParamDecorator, ExecutionContext, SetMetadata } from '@nestjs/common';
import type { Request } from 'express';
import { Papel } from '../../prisma/generated/prisma/client';
import type { UsuarioToken } from './token.service';

export const CHAVE_PUBLICO = 'rotaPublica';
export const CHAVE_PAPEIS = 'papeisPermitidos';

/** Rota sem JWT (o guard global exige token em todas as outras). */
export const Publico = () => SetMetadata(CHAVE_PUBLICO, true);

/** SEG03: restringe a rota aos papéis informados (ex.: `@Papeis(Papel.ADMIN)` nas rotas /admin). */
export const Papeis = (...papeis: Papel[]) => SetMetadata(CHAVE_PAPEIS, papeis);

export type RequisicaoAutenticada = Request & { usuario?: UsuarioToken };

/** Usuário do JWT de acesso (id e papel). */
export const UsuarioAtual = createParamDecorator((_dados: unknown, ctx: ExecutionContext) => {
  return ctx.switchToHttp().getRequest<RequisicaoAutenticada>().usuario;
});
