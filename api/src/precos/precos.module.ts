import { Module } from '@nestjs/common';
import { PrecoService } from './preco.service';
import { PrecosController } from './precos.controller';

@Module({
  controllers: [PrecosController],
  providers: [PrecoService],
  exports: [PrecoService],
})
export class PrecosModule {}
