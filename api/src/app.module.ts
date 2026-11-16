import { Module } from '@nestjs/common';
import { AdminModule } from './admin/admin.module';
import { AsaasModule } from './asaas/asaas.module';
import { AssinaturasModule } from './assinaturas/assinaturas.module';
import { AuthModule } from './auth/auth.module';
import { CiclosModule } from './ciclos/ciclos.module';
import { ClientesModule } from './clientes/clientes.module';
import { CommonModule } from './common/common.module';
import { CuponsModule } from './cupons/cupons.module';
import { EnderecosModule } from './enderecos/enderecos.module';
import { HealthModule } from './health/health.module';
import { JobsModule } from './jobs/jobs.module';
import { KitsModule } from './kits/kits.module';
import { ListaEsperaModule } from './lista-espera/lista-espera.module';
import { NotificacoesModule } from './notificacoes/notificacoes.module';
import { OcorrenciasModule } from './ocorrencias/ocorrencias.module';
import { PrecosModule } from './precos/precos.module';
import { ProdutosModule } from './produtos/produtos.module';
import { RecomendacoesModule } from './recomendacoes/recomendacoes.module';
import { WebhooksModule } from './webhooks/webhooks.module';

@Module({
  imports: [
    CommonModule,
    HealthModule,
    AuthModule,
    ClientesModule,
    ProdutosModule,
    KitsModule,
    RecomendacoesModule,
    EnderecosModule,
    PrecosModule,
    AssinaturasModule,
    CiclosModule,
    OcorrenciasModule,
    NotificacoesModule,
    AsaasModule,
    WebhooksModule,
    JobsModule,
    AdminModule,
    CuponsModule,
    ListaEsperaModule,
  ],
})
export class AppModule {}
