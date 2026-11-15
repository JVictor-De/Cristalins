import { Controller, Get, INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { AppModule } from '../../src/app.module';
import { Papeis } from '../../src/auth/decorators';
import { ClockService } from '../../src/common/clock.service';
import { PrismaService } from '../../src/common/prisma.service';
import { configurarApp } from '../../src/configurar-app';
import { ViaCepClient } from '../../src/enderecos/viacep.client';
import { PrismaFake } from './prisma-fake';

/** 14/11/2026 12:00 em São Paulo. */
export const AGORA_FIXA = new Date('2026-11-14T15:00:00.000Z');

/** Relógio fixo: as regras de data (18 anos, aceite) ficam determinísticas. */
export class ClockFixo extends ClockService {
  constructor(private readonly instante: Date = AGORA_FIXA) {
    super();
  }

  override agora(): Date {
    return new Date(this.instante);
  }
}

/** Relógio que o teste avança (ex.: passar do corte D-2). */
export class RelogioAjustavel extends ClockService {
  constructor(public instante: Date = AGORA_FIXA) {
    super();
  }

  override agora(): Date {
    return new Date(this.instante);
  }

  /** Vai para AAAA-MM-DD às HH:mm de São Paulo. */
  irPara(data: string, hora = '12:00'): void {
    this.instante = new Date(`${data}T${hora}:00.000-03:00`);
  }
}

/** Rota /admin só de teste: prova o SEG03 sem antecipar endpoints de outras fases. */
@Controller('admin/teste-papel')
export class RotaAdminDeTeste {
  @Get()
  @Papeis('ADMIN')
  ok() {
    return { ok: true };
  }
}

export interface AppDeTeste {
  app: INestApplication;
  prisma: PrismaFake;
}

export interface OpcoesAppDeTeste {
  /** Relógio injetado (padrão: ClockFixo em 14/11/2026 12:00 SP). */
  relogio?: ClockService;
  /** Substitui o ViaCEP real (rede) por um fake. */
  viaCep?: Pick<ViaCepClient, 'buscar'>;
}

export async function criarAppDeTeste(opcoes: OpcoesAppDeTeste = {}): Promise<AppDeTeste> {
  const prisma = new PrismaFake();
  const modulo = await Test.createTestingModule({
    imports: [AppModule],
    controllers: [RotaAdminDeTeste],
  })
    .overrideProvider(PrismaService)
    .useValue(prisma)
    .overrideProvider(ClockService)
    .useValue(opcoes.relogio ?? new ClockFixo())
    .overrideProvider(ViaCepClient)
    .useValue(opcoes.viaCep ?? { buscar: async () => { throw new Error('ViaCEP não configurado no teste'); } })
    .compile();
  const app = modulo.createNestApplication();
  configurarApp(app);
  await app.init();
  return { app, prisma };
}
