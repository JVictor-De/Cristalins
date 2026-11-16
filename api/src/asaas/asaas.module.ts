import { Module, forwardRef } from '@nestjs/common';
import { AssinaturasModule } from '../assinaturas/assinaturas.module';
import { CreditosModule } from '../creditos/creditos.module';
import { NotificacoesModule } from '../notificacoes/notificacoes.module';
import { AsaasGateway } from './asaas.gateway';
import { CartaoService } from './cartao.service';
import { CobrancaService } from './cobranca.service';
import { ConciliacaoService } from './conciliacao.service';
import { FakeGateway } from './fake.gateway';
import { FaturasService } from './faturas.service';
import { PAGAMENTO_GATEWAY, PagamentoGateway } from './pagamento.gateway';
import { PagamentosController } from './pagamentos.controller';
import { ReguaService } from './regua.service';

function criarGateway(): PagamentoGateway {
  const modo = (process.env.ASAAS_MODE ?? 'fake').toLowerCase();
  if (modo === 'sandbox' || modo === 'producao') return new AsaasGateway();
  return new FakeGateway();
}

@Module({
  imports: [forwardRef(() => AssinaturasModule), CreditosModule, NotificacoesModule],
  controllers: [PagamentosController],
  providers: [
    { provide: PAGAMENTO_GATEWAY, useFactory: criarGateway },
    CobrancaService,
    CartaoService,
    FaturasService,
    ReguaService,
    ConciliacaoService,
    FakeGateway,
  ],
  exports: [CobrancaService, ReguaService, ConciliacaoService, PAGAMENTO_GATEWAY, FakeGateway],
})
export class AsaasModule {}
