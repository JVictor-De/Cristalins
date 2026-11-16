import { Module } from '@nestjs/common';
import { CreditosModule } from '../creditos/creditos.module';
import { ARMAZENAMENTO_FOTOS, criarArmazenamentoFotos } from './armazenamento-fotos';
import { OcorrenciasController } from './ocorrencias.controller';
import { OcorrenciasService } from './ocorrencias.service';

/** RN15/RF49: avaria ou falta com foto (MinIO via `S3_*`), crédito ou reposição. */
@Module({
  imports: [CreditosModule],
  controllers: [OcorrenciasController],
  providers: [OcorrenciasService, { provide: ARMAZENAMENTO_FOTOS, useFactory: criarArmazenamentoFotos }],
  exports: [OcorrenciasService],
})
export class OcorrenciasModule {}
