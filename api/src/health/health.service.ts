import { Injectable, ServiceUnavailableException } from '@nestjs/common';
import { ClockService } from '../common/clock.service';
import { PrismaService } from '../common/prisma.service';

export interface StatusSaude {
  status: 'ok';
  banco: 'ok';
  horario: string;
}

@Injectable()
export class HealthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly clock: ClockService,
  ) {}

  async verificar(): Promise<StatusSaude> {
    try {
      await this.prisma.$queryRaw`SELECT 1`;
    } catch {
      throw new ServiceUnavailableException('Banco de dados indisponível.');
    }
    return { status: 'ok', banco: 'ok', horario: this.clock.agora().toISOString() };
  }
}
