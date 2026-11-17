import {
  ArgumentsHost,
  Catch,
  ExceptionFilter,
  HttpException,
  HttpStatus,
  Logger,
} from '@nestjs/common';
import type { Response } from 'express';
import { mascararPii } from './mascarar';
import { CorpoErro, RegraNegocioException } from './regra-negocio.exception';

// Código padrão quando a exceção não é uma RegraNegocioException.
const CODIGO_POR_STATUS: Record<number, string> = {
  [HttpStatus.BAD_REQUEST]: 'REQUISICAO_INVALIDA',
  [HttpStatus.UNAUTHORIZED]: 'NAO_AUTENTICADO',
  [HttpStatus.FORBIDDEN]: 'SEM_PERMISSAO',
  [HttpStatus.NOT_FOUND]: 'NAO_ENCONTRADO',
  [HttpStatus.CONFLICT]: 'CONFLITO',
  [HttpStatus.UNPROCESSABLE_ENTITY]: 'REGRA_VIOLADA',
  [HttpStatus.TOO_MANY_REQUESTS]: 'MUITAS_TENTATIVAS',
  [HttpStatus.SERVICE_UNAVAILABLE]: 'SERVICO_INDISPONIVEL',
};

/** Filtro global: toda resposta de erro sai como { codigo, mensagem, campo? }. */
@Catch()
export class FiltroExcecao implements ExceptionFilter {
  private readonly logger = new Logger(FiltroExcecao.name);

  catch(excecao: unknown, host: ArgumentsHost): void {
    const resposta = host.switchToHttp().getResponse<Response>();
    const { status, corpo } = this.converter(excecao);
    resposta.status(status).json(corpo);
  }

  private converter(excecao: unknown): { status: number; corpo: CorpoErro } {
    if (excecao instanceof RegraNegocioException) {
      return { status: excecao.getStatus(), corpo: excecao.getResponse() as CorpoErro };
    }
    if (excecao instanceof HttpException) {
      const status = excecao.getStatus();
      const r = excecao.getResponse();
      const mensagemOriginal =
        typeof r === 'string' ? r : (r as { message?: string | string[] }).message;
      const mensagem = Array.isArray(mensagemOriginal)
        ? mensagemOriginal.join('; ')
        : (mensagemOriginal ?? excecao.message);
      return { status, corpo: { codigo: CODIGO_POR_STATUS[status] ?? 'ERRO', mensagem } };
    }
    const bruto = excecao instanceof Error ? (excecao.stack ?? excecao.message) : String(excecao);
    this.logger.error(mascararPii(bruto));
    const mensagemErro = excecao instanceof Error ? excecao.message : String(excecao);
    const corpo: CorpoErro = {
      codigo: 'ERRO_INTERNO',
      mensagem: 'Erro inesperado. Tente de novo.',
    };
    // HML/sandbox/fake: o app mostra `detalhe` no snackbar (Coolify HML costuma ter NODE_ENV=production).
    const modo = (process.env.ASAAS_MODE ?? '').toLowerCase();
    const diagnostico =
      process.env.NODE_ENV !== 'production' || modo === 'sandbox' || modo === 'fake';
    if (diagnostico) {
      corpo.detalhe = mascararPii(mensagemErro).slice(0, 300);
    }
    return { status: HttpStatus.INTERNAL_SERVER_ERROR, corpo };
  }
}
