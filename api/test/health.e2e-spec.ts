import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { PrismaService } from '../src/common/prisma.service';
import { configurarApp, TAGS_SWAGGER } from '../src/configurar-app';

describe('Health e Swagger (e2e)', () => {
  let app: INestApplication;
  const prisma = { $queryRaw: jest.fn(), $disconnect: jest.fn() };

  beforeAll(async () => {
    const modulo = await Test.createTestingModule({ imports: [AppModule] })
      .overrideProvider(PrismaService)
      .useValue(prisma)
      .compile();
    app = modulo.createNestApplication();
    configurarApp(app);
    await app.init();
  });

  afterAll(async () => {
    await app.close();
  });

  it('GET /api/v1/health → 200 ok com banco respondendo', async () => {
    prisma.$queryRaw.mockResolvedValueOnce([{ '?column?': 1 }]);
    const r = await request(app.getHttpServer()).get('/api/v1/health').expect(200);
    expect(r.body).toMatchObject({ status: 'ok', banco: 'ok' });
  });

  it('GET /api/v1/health → 503 no formato { codigo, mensagem } sem banco', async () => {
    prisma.$queryRaw.mockRejectedValueOnce(new Error('ECONNREFUSED'));
    const r = await request(app.getHttpServer()).get('/api/v1/health').expect(503);
    expect(r.body).toEqual({
      codigo: 'SERVICO_INDISPONIVEL',
      mensagem: 'Banco de dados indisponível.',
    });
  });

  it('rota inexistente → 404 no formato de erro', async () => {
    const r = await request(app.getHttpServer()).get('/api/v1/nao-existe').expect(404);
    expect(r.body.codigo).toBe('NAO_ENCONTRADO');
  });

  it('GET /docs-json tem uma tag por módulo e esquema Bearer', async () => {
    const r = await request(app.getHttpServer()).get('/docs-json').expect(200);
    const tags = (r.body.tags as { name: string }[]).map((t) => t.name);
    expect(tags).toEqual(TAGS_SWAGGER.map(([nome]) => nome));
    expect(r.body.components.securitySchemes.bearer).toMatchObject({ type: 'http', scheme: 'bearer' });
    expect(r.body.paths).toHaveProperty('/api/v1/health');
  });

  it('GET /docs abre a interface do Swagger', async () => {
    const r = await request(app.getHttpServer()).get('/docs').expect(200);
    expect(r.text).toContain('swagger');
  });
});
