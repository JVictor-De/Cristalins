import { Module } from '@nestjs/common';
import { CreditosController } from './creditos.controller';
import { CreditosService } from './creditos.service';

/** Créditos (RN20) e indicação (RN22). Importado pelo `AsaasModule`, que abate na cobrança. */
@Module({
  controllers: [CreditosController],
  providers: [CreditosService],
  exports: [CreditosService],
})
export class CreditosModule {}
