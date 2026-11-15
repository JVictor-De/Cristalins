import { Module, forwardRef } from '@nestjs/common';
import { ScheduleModule } from '@nestjs/schedule';
import { AssinaturasModule } from '../assinaturas/assinaturas.module';
import { AsaasModule } from '../asaas/asaas.module';
import { WebhooksModule } from '../webhooks/webhooks.module';
import { JobsScheduler } from './jobs.scheduler';
import { JobsService } from './jobs.service';

@Module({
  imports: [
    ScheduleModule.forRoot(),
    forwardRef(() => AssinaturasModule),
    AsaasModule,
    WebhooksModule,
  ],
  providers: [JobsService, JobsScheduler],
  exports: [JobsService],
})
export class JobsModule {}
