import { Module } from '@nestjs/common';
import { PrecosModule } from '../precos/precos.module';
import { RecomendacaoService } from './recomendacao.service';
import { RecomendacoesController } from './recomendacoes.controller';

@Module({
  imports: [PrecosModule],
  controllers: [RecomendacoesController],
  providers: [RecomendacaoService],
})
export class RecomendacoesModule {}
