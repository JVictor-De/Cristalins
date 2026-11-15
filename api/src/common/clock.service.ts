import { Injectable } from '@nestjs/common';

export const FUSO_NEGOCIO = 'America/Sao_Paulo';

/**
 * Fonte única de "agora" para as regras. Testes substituem o provider para fixar a data.
 * Datas de regra (entrega, corte, cobrança) são sempre interpretadas em America/Sao_Paulo.
 */
@Injectable()
export class ClockService {
  agora(): Date {
    return new Date();
  }

  /** Data de hoje em America/Sao_Paulo no formato AAAA-MM-DD. */
  hoje(): string {
    return this.dataNoFuso(this.agora());
  }

  /** Data (AAAA-MM-DD) de um instante no fuso de negócio. */
  dataNoFuso(instante: Date): string {
    // en-CA formata como AAAA-MM-DD.
    return new Intl.DateTimeFormat('en-CA', {
      timeZone: FUSO_NEGOCIO,
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
    }).format(instante);
  }
}
