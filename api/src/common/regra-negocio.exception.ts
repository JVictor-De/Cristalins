import { HttpException, HttpStatus } from '@nestjs/common';

export interface CorpoErro {
  codigo: string;
  mensagem: string;
  campo?: string;
}

/**
 * Erro de regra de negócio no formato do contrato: { codigo, mensagem, campo? }.
 * Padrão 422; use outro status quando o Anexo pedir (ex.: 409 APOS_CORTE, 403 SEM_PERMISSAO).
 */
export class RegraNegocioException extends HttpException {
  constructor(
    readonly codigo: string,
    readonly mensagem: string,
    status: HttpStatus = HttpStatus.UNPROCESSABLE_ENTITY,
    readonly campo?: string,
  ) {
    const corpo: CorpoErro = { codigo, mensagem };
    if (campo) corpo.campo = campo;
    super(corpo, status);
  }
}
