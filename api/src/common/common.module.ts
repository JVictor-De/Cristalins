import { Global, Module } from '@nestjs/common';
import { ClockService } from './clock.service';
import { PrismaService } from './prisma.service';

@Global()
@Module({
  providers: [ClockService, PrismaService],
  exports: [ClockService, PrismaService],
})
export class CommonModule {}
