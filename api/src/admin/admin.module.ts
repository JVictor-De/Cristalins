import { Module } from '@nestjs/common';
import { MaquinaEstadosService } from '../assinaturas/maquina-estados.service';
import { CreditosModule } from '../creditos/creditos.module';
import { JobsModule } from '../jobs/jobs.module';
import { NotificacoesModule } from '../notificacoes/notificacoes.module';
import { AdminController } from './admin.controller';
import { AdminService } from './admin.service';
import { EstoqueService } from './estoque.service';
import { OperacaoService } from './operacao.service';

@Module({
  imports: [JobsModule, CreditosModule, NotificacoesModule],
  controllers: [AdminController],
  providers: [AdminService, EstoqueService, OperacaoService, MaquinaEstadosService],
})
export class AdminModule {}
