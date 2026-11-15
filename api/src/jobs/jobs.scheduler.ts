import { Injectable } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { FUSO_NEGOCIO } from '../common/clock.service';
import { JobsService } from './jobs.service';

/** Cron wrappers (America/Sao_Paulo). Isolado para o Jest não carregar ESM do schedule nos unit tests. */
@Injectable()
export class JobsScheduler {
  constructor(private readonly jobs: JobsService) {}

  @Cron('0 6 * * *', { timeZone: FUSO_NEGOCIO, name: 'gerar-cobrancas' })
  async asSeis(): Promise<void> {
    await this.jobs.gerarCobrancas();
  }

  @Cron('5 0 * * *', { timeZone: FUSO_NEGOCIO, name: 'corte-e-regua' })
  async aMeiaNoiteCinco(): Promise<void> {
    await this.jobs.corteERegua();
  }

  @Cron(CronExpression.EVERY_MINUTE, { timeZone: FUSO_NEGOCIO, name: 'fila-webhook' })
  async aCadaMinuto(): Promise<void> {
    await this.jobs.processarFilaWebhook();
  }
}
