import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { criarAppDeTeste } from './support/criar-app';
import { PrismaFake } from './support/prisma-fake';

async function entrar(app: INestApplication, email: string, cpfCnpj: string): Promise<string> {
  const r = await request(app.getHttpServer())
    .post('/api/v1/clientes')
    .send({
      nome: 'Cliente Teste',
      cpfCnpj,
      email,
      dataNascimento: '1990-01-01',
      senha: 'senha-forte-123',
      aceiteTermos: true,
    })
    .expect(201);
  return r.body.tokens.accessToken as string;
}

describe('Catálogo, quiz e preço (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaFake;
  let token: string;
  const http = () => request(app.getHttpServer());
  const autenticado = (t = token) => ({ Authorization: `Bearer ${t}` });

  beforeEach(async () => {
    ({ app, prisma } = await criarAppDeTeste());
    prisma.carregarCatalogo();
    token = await entrar(app, 'ana@exemplo.com', '52998224725');
  });

  afterEach(async () => {
    await app.close();
  });

  describe('GET /produtos e /kits (públicos)', () => {
    it('lista os 8 produtos ativos com números no JSON', async () => {
      const r = await http().get('/api/v1/produtos').expect(200);
      expect(r.body).toHaveLength(8);
      expect(r.body.find((p: { codigo: string }) => p.codigo === 'AMC510')).toMatchObject({
        tipo: 'COMPLEMENTO',
        volumeMl: 510,
        ue: 1.02,
        embalagemQtd: 12,
        precoBase: 2.9,
        precoPiso: 2,
        pesoKg: 0.53,
      });
    });

    it('filtra por tipo e recusa tipo inválido', async () => {
      const r = await http().get('/api/v1/produtos?tipo=PRINCIPAL').expect(200);
      expect(r.body.map((p: { codigo: string }) => p.codigo).sort()).toEqual(['FF500', 'WP500']);
      const erro = await http().get('/api/v1/produtos?tipo=CERVEJA').expect(400);
      expect(erro.body).toMatchObject({ codigo: 'DADOS_INVALIDOS', campo: 'tipo' });
    });

    it('não lista produto inativo', async () => {
      prisma.produtos.find((p) => p.codigo === 'GUA2000')!.ativo = false;
      const r = await http().get('/api/v1/produtos').expect(200);
      expect(r.body).toHaveLength(7);
    });

    it('lista os 4 kits com composição, UE e subtotal base', async () => {
      const r = await http().get('/api/v1/kits').expect(200);
      const porCodigo = Object.fromEntries(r.body.map((k: { codigo: string }) => [k.codigo, k]));
      expect(Object.keys(porCodigo).sort()).toEqual(['KIT-CASA', 'KIT-EQUILIBRIO', 'KIT-ESCRITORIO', 'KIT-TREINO']);
      expect(porCodigo['KIT-TREINO']).toMatchObject({ ue: 12, subtotalBase: 118.8, itens: [{ produto: 'WP500', quantidade: 12 }] });
      expect(porCodigo['KIT-EQUILIBRIO']).toMatchObject({ ue: 12, subtotalBase: 112.8 });
      expect(porCodigo['KIT-CASA']).toMatchObject({ ue: 26, subtotalBase: 79.2 });
      expect(porCodigo['KIT-ESCRITORIO']).toMatchObject({ ue: 31.2, subtotalBase: 162 });
    });
  });

  describe('POST/GET /recomendacoes', () => {
    const casoA = { objetivo: 'TREINO', diasSemana: '5-7', pessoas: '1', flowFiber: false, comGas: false };

    it('exige token', async () => {
      await http().post('/api/v1/recomendacoes').send(casoA).expect(401);
      await http().get('/api/v1/recomendacoes').expect(401);
    });

    it('CT03: caso A → 201 com o JSON do Anexo', async () => {
      const r = await http().post('/api/v1/recomendacoes').set(autenticado()).send(casoA).expect(201);
      expect(r.body).toMatchObject({
        kit: 'KIT-TREINO',
        multiplicador: 1,
        frequencia: 'QUINZENAL',
        itens: [{ produto: 'WP500', quantidade: 12 }],
        ue: 12,
        valorEstimado: 118.8,
        perfilEmpresa: false,
      });
      expect(r.body).not.toHaveProperty('contatoComercial');
    });

    it('CT05: caso C → perfil Empresa com contato comercial', async () => {
      const r = await http()
        .post('/api/v1/recomendacoes')
        .set(autenticado())
        .send({ ...casoA, objetivo: 'ESCRITORIO', pessoas: '11-20' })
        .expect(201);
      expect(r.body).toMatchObject({ kit: null, perfilEmpresa: true, ue: 249.6, valorEstimado: null });
      expect(r.body.contatoComercial.email).toBe('contato@cristalins.com.br');
    });

    it('respostas fora das opções → 400 DADOS_INVALIDOS', async () => {
      const r = await http()
        .post('/api/v1/recomendacoes')
        .set(autenticado())
        .send({ ...casoA, pessoas: '7' })
        .expect(400);
      expect(r.body).toMatchObject({ codigo: 'DADOS_INVALIDOS', campo: 'pessoas' });
    });

    it('lista e busca as do próprio cliente; outro cliente → 403; id inválido → 404', async () => {
      const criada = await http().post('/api/v1/recomendacoes').set(autenticado()).send(casoA).expect(201);
      const lista = await http().get('/api/v1/recomendacoes').set(autenticado()).expect(200);
      expect(lista.body).toHaveLength(1);
      await http().get(`/api/v1/recomendacoes/${criada.body.id}`).set(autenticado()).expect(200);

      const outro = await entrar(app, 'bruno@exemplo.com', '11144477735');
      const negado = await http().get(`/api/v1/recomendacoes/${criada.body.id}`).set(autenticado(outro)).expect(403);
      expect(negado.body.codigo).toBe('SEM_PERMISSAO');
      const vazia = await http().get('/api/v1/recomendacoes').set(autenticado(outro)).expect(200);
      expect(vazia.body).toEqual([]);

      const invalido = await http().get('/api/v1/recomendacoes/nao-e-uuid').set(autenticado()).expect(404);
      expect(invalido.body.codigo).toBe('NAO_ENCONTRADO');
    });
  });

  describe('POST /precos/simular', () => {
    const base = { itens: [{ produto: 'WP500', quantidade: 24 }], frequencia: 'QUINZENAL', plano: 'TRIMESTRAL' };

    it('exige token', async () => {
      await http().post('/api/v1/precos/simular').send(base).expect(401);
    });

    it('CT02: 200 com total 213,19 e detalhe no formato do Anexo', async () => {
      const r = await http()
        .post('/api/v1/precos/simular')
        .set(autenticado())
        .send({ ...base, zonaId: 'zona-Zona-Sul', dataEntrega: '2026-11-16' })
        .expect(200);
      expect(r.body).toMatchObject({ subtotal: 203.29, frete: 9.9, total: 213.19 });
      expect(r.body.detalhePreco).toEqual([
        { fator: 'VOLUME', percentual: -8 },
        { fator: 'COMPROMISSO', percentual: -7 },
        { fator: 'FRETE', valor: 9.9 },
      ]);
    });

    it('CT06: 11 UE → 422 CESTA_ABAIXO_MINIMO no formato de erro', async () => {
      const r = await http()
        .post('/api/v1/precos/simular')
        .set(autenticado())
        .send({ ...base, itens: [{ produto: 'WP500', quantidade: 11 }] })
        .expect(422);
      expect(r.body).toEqual({
        codigo: 'CESTA_ABAIXO_MINIMO',
        mensagem: 'A cesta precisa ter pelo menos 12 UE por entrega (sem contar o Guaraná).',
        campo: 'itens',
      });
    });

    it('CT07: 121 UE → 422 CESTA_ACIMA_MAXIMO', async () => {
      const r = await http()
        .post('/api/v1/precos/simular')
        .set(autenticado())
        .send({ ...base, itens: [{ produto: 'AMN5000', quantidade: 12 }, { produto: 'WP500', quantidade: 1 }] })
        .expect(422);
      expect(r.body.codigo).toBe('CESTA_ACIMA_MAXIMO');
    });

    it('CT25: 5 WP500 → 422 EMBALAGEM_INVALIDA', async () => {
      const r = await http()
        .post('/api/v1/precos/simular')
        .set(autenticado())
        .send({ ...base, itens: [{ produto: 'wp500', quantidade: 5 }, { produto: 'AMS500', quantidade: 12 }] })
        .expect(422);
      expect(r.body.codigo).toBe('EMBALAGEM_INVALIDA');
    });

    it('CT13: subtotal acima de R$ 250 → frete 0', async () => {
      const r = await http()
        .post('/api/v1/precos/simular')
        .set(autenticado())
        .send({
          ...base,
          plano: 'FLEX',
          zonaId: 'zona-Zona-Oeste',
          itens: [{ produto: 'WP500', quantidade: 24 }, { produto: 'FF500', quantidade: 6 }],
        })
        .expect(200);
      expect(r.body).toMatchObject({ subtotal: 267.72, frete: 0, total: 267.72 });
    });

    it('quantidade não inteira → 400 DADOS_INVALIDOS em itens.0.quantidade', async () => {
      const r = await http()
        .post('/api/v1/precos/simular')
        .set(autenticado())
        .send({ ...base, itens: [{ produto: 'WP500', quantidade: 2.5 }] })
        .expect(400);
      expect(r.body).toMatchObject({ codigo: 'DADOS_INVALIDOS', campo: 'itens.0.quantidade' });
    });
  });

  it('Swagger documenta as rotas da fase', async () => {
    const r = await http().get('/docs-json').expect(200);
    const paths = r.body.paths as Record<string, Record<string, unknown>>;
    expect(paths['/api/v1/produtos']).toHaveProperty('get');
    expect(paths['/api/v1/kits']).toHaveProperty('get');
    expect(paths['/api/v1/recomendacoes']).toHaveProperty('post');
    expect(paths['/api/v1/recomendacoes']).toHaveProperty('get');
    expect(paths['/api/v1/recomendacoes/{id}']).toHaveProperty('get');
    expect(paths['/api/v1/precos/simular']).toHaveProperty('post');
  });
});
