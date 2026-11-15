import { Module } from '@nestjs/common';
import { ListaEsperaController } from './lista-espera.controller';
import { ListaEsperaService } from './lista-espera.service';

@Module({
  controllers: [ListaEsperaController],
  providers: [ListaEsperaService],
})
export class ListaEsperaModule {}
