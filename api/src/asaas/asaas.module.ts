import { Module, forwardRef } from '@nestjs/common';
import { AssinaturasModule } from '../assinaturas/assinaturas.module';
import { AsaasGateway } from './asaas.gateway';
import { CobrancaService } from './cobranca.service';
import { FakeGateway } from './fake.gateway';
import { PAGAMENTO_GATEWAY, PagamentoGateway } from './pagamento.gateway';

function criarGateway(): PagamentoGateway {
  const modo = (process.env.ASAAS_MODE ?? 'fake').toLowerCase();
  if (modo === 'sandbox' || modo === 'producao') return new AsaasGateway();
  return new FakeGateway();
}

@Module({
  imports: [forwardRef(() => AssinaturasModule)],
  providers: [
    { provide: PAGAMENTO_GATEWAY, useFactory: criarGateway },
    CobrancaService,
    FakeGateway,
  ],
  exports: [CobrancaService, PAGAMENTO_GATEWAY, FakeGateway],
})
export class AsaasModule {}
