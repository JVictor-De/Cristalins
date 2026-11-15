import { ServiceUnavailableException } from '@nestjs/common';
import { ClockService } from '../common/clock.service';
import { PrismaService } from '../common/prisma.service';
import { HealthService } from './health.service';

describe('HealthService', () => {
  const clock = { agora: () => new Date('2026-11-14T23:00:00.000Z') } as ClockService;

  it('responde ok quando o banco responde', async () => {
    const prisma = { $queryRaw: jest.fn().mockResolvedValue([{ '?column?': 1 }]) };
    const service = new HealthService(prisma as unknown as PrismaService, clock);

    await expect(service.verificar()).resolves.toEqual({
      status: 'ok',
      banco: 'ok',
      horario: '2026-11-14T23:00:00.000Z',
    });
  });

  it('lança 503 quando o banco não responde', async () => {
    const prisma = { $queryRaw: jest.fn().mockRejectedValue(new Error('ECONNREFUSED')) };
    const service = new HealthService(prisma as unknown as PrismaService, clock);

    await expect(service.verificar()).rejects.toBeInstanceOf(ServiceUnavailableException);
  });
});
