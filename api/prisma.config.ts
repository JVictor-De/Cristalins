import path from 'node:path';
import { config as carregarEnv } from 'dotenv';
import { defineConfig } from 'prisma/config';

// .env fica na raiz do monorepo (usado também pelo docker-compose); api/.env, se existir, tem prioridade.
carregarEnv({ path: path.resolve(__dirname, '.env'), quiet: true });
carregarEnv({ path: path.resolve(__dirname, '..', '.env'), quiet: true });

export default defineConfig({
  schema: 'prisma/schema.prisma',
  migrations: {
    path: 'prisma/migrations',
    seed: 'tsx prisma/seed.ts',
  },
  datasource: {
    // Vazio permite `prisma validate` / `generate` sem banco; migrate e seed exigem DATABASE_URL.
    url: process.env.DATABASE_URL ?? '',
  },
});
