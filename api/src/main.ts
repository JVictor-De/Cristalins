import path from 'node:path';
import { config as carregarEnv } from 'dotenv';

// Antes de qualquer Date: respeita TZ do ambiente e usa o fuso de negócio como padrão.
process.env.TZ = process.env.TZ || 'America/Sao_Paulo';
// Em dev, lê api/.env ou o .env da raiz; no Docker as variáveis já vêm do compose.
carregarEnv({ path: path.resolve(process.cwd(), '.env'), quiet: true });
carregarEnv({ path: path.resolve(process.cwd(), '..', '.env'), quiet: true });

import { Logger } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { configurarApp, PREFIXO_API } from './configurar-app';

async function bootstrap(): Promise<void> {
  const app = await NestFactory.create(AppModule);
  app.enableShutdownHooks();
  const origens = process.env.CORS_ORIGINS?.split(',').map((o) => o.trim()).filter(Boolean);
  if (origens?.length) app.enableCors({ origin: origens });
  configurarApp(app);

  const porta = Number(process.env.PORT ?? 3000);
  await app.listen(porta);
  Logger.log(`API em http://localhost:${porta}/${PREFIXO_API} · Swagger em /docs`, 'Bootstrap');
}

void bootstrap();
