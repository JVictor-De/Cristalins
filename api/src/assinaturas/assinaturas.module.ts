import { Module, forwardRef } from '@nestjs/common';
import { AsaasModule } from '../asaas/asaas.module';
import { PrecosModule } from '../precos/precos.module';
import { AssinaturasController } from './assinaturas.controller';
import { AssinaturasService } from './assinaturas.service';
import { MaquinaEstadosService } from './maquina-estados.service';

/**
 * Assinaturas, ciclos e a máquina de estados. Preço só pelo `PrecoService` (sem regra duplicada).
 * Cobrança Pix via `AsaasModule` (`cr-3-gateway`).
 */
@Module({
  imports: [PrecosModule, forwardRef(() => AsaasModule)],
  controllers: [AssinaturasController],
  providers: [AssinaturasService, MaquinaEstadosService],
  exports: [AssinaturasService, MaquinaEstadosService],
})
export class AssinaturasModule {}
