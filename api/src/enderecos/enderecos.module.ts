import { Module } from '@nestjs/common';
import { CepService } from './cep.service';
import { EnderecosController } from './enderecos.controller';
import { EnderecosService } from './enderecos.service';
import { ViaCepClient } from './viacep.client';

@Module({
  controllers: [EnderecosController],
  providers: [ViaCepClient, CepService, EnderecosService],
  exports: [CepService, EnderecosService],
})
export class EnderecosModule {}
