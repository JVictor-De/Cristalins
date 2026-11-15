import { Module } from '@nestjs/common';
import { PrecosModule } from '../precos/precos.module';
import { AssinaturasController } from './assinaturas.controller';
import { AssinaturasService } from './assinaturas.service';
import { MaquinaEstadosService } from './maquina-estados.service';

/**
 * Assinaturas, ciclos e a máquina de estados. Preço só pelo `PrecoService` (sem regra duplicada).
 * `cr-3-gateway` importa este módulo para usar `MaquinaEstadosService`, `congelarCiclo` e `proximoCicloAberto`.
 */
@Module({
  imports: [PrecosModule],
  controllers: [AssinaturasController],
  providers: [AssinaturasService, MaquinaEstadosService],
  exports: [AssinaturasService, MaquinaEstadosService],
})
export class AssinaturasModule {}
