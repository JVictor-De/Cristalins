import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { gerarHashSenha } from '../src/auth/senha';
import { AppDeTeste, criarAppDeTeste } from './support/criar-app';
import { PrismaFake } from './support/prisma-fake';

const CPF_VALIDO = '529.982.247-25';
const OUTRO_CPF_VALIDO = '11144477735';

function novoCliente(extra: Record<string, unknown> = {}) {
  return {
    nome: 'Ana Souza',
    cpfCnpj: CPF_VALIDO,
    email: 'ana@exemplo.com',
    celular: '(21) 98765-4321',
    dataNascimento: '1995-05-10',
    senha: 'senha-forte-123',
    aceiteTermos: true,
    ...extra,
  };
}

describe('Clientes e auth (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaFake;
  let http: () => ReturnType<typeof request>;

  beforeEach(async () => {
    ({ app, prisma } = (await criarAppDeTeste()) as AppDeTeste);
    http = () => request(app.getHttpServer());
  });

  afterEach(async () => {
    await app.close();
  });

  describe('POST /clientes', () => {
    it('cria a conta, devolve tokens e nunca expõe o hash da senha', async () => {
      const r = await http().post('/api/v1/clientes').send(novoCliente()).expect(201);

      expect(r.body.cliente).toMatchObject({
        nome: 'Ana Souza',
        cpfCnpj: '52998224725',
        email: 'ana@exemplo.com',
        celular: '21987654321',
        dataNascimento: '1995-05-10',
        papel: 'CLIENTE',
        marketingOk: false,
        aceiteTermosEm: '2026-11-14T15:00:00.000Z', // ClockService fixo
      });
      expect(r.body.cliente).not.toHaveProperty('senhaHash');
      expect(r.body.tokens).toMatchObject({ expiresIn: 900 });
      expect(typeof r.body.tokens.accessToken).toBe('string');

      const gravado = await prisma.cliente.findUnique({ where: { email: 'ana@exemplo.com' } });
      expect(gravado?.senhaHash).toMatch(/^\$2[aby]\$10\$/); // SEG02 bcrypt
    });

    it('CT24: menor de 18 anos → 422 MENOR_DE_IDADE', async () => {
      // Faz 18 anos amanhã (15/11/2026) no relógio fixo de 14/11/2026.
      const r = await http()
        .post('/api/v1/clientes')
        .send(novoCliente({ dataNascimento: '2008-11-15' }))
        .expect(422);
      expect(r.body).toEqual({
        codigo: 'MENOR_DE_IDADE',
        mensagem: 'A assinatura é só para maiores de 18 anos.',
        campo: 'dataNascimento',
      });
    });

    it('aceita quem faz 18 anos hoje', async () => {
      await http()
        .post('/api/v1/clientes')
        .send(novoCliente({ dataNascimento: '2008-11-14' }))
        .expect(201);
    });

    it('CPF com dígito verificador errado → 422 CPF_INVALIDO', async () => {
      const r = await http()
        .post('/api/v1/clientes')
        .send(novoCliente({ cpfCnpj: '529.982.247-26' }))
        .expect(422);
      expect(r.body).toMatchObject({ codigo: 'CPF_INVALIDO', campo: 'cpfCnpj' });
    });

    it('aceita CNPJ válido (RF01/RF03)', async () => {
      await http()
        .post('/api/v1/clientes')
        .send(novoCliente({ cpfCnpj: '11.222.333/0001-81' }))
        .expect(201);
    });

    it('um CPF por conta → 409 CPF_JA_CADASTRADO', async () => {
      await http().post('/api/v1/clientes').send(novoCliente()).expect(201);
      const r = await http()
        .post('/api/v1/clientes')
        .send(novoCliente({ email: 'outra@exemplo.com' }))
        .expect(409);
      expect(r.body).toMatchObject({ codigo: 'CPF_JA_CADASTRADO', campo: 'cpfCnpj' });
    });

    it('e-mail repetido → 409 EMAIL_JA_CADASTRADO', async () => {
      await http().post('/api/v1/clientes').send(novoCliente()).expect(201);
      const r = await http()
        .post('/api/v1/clientes')
        .send(novoCliente({ cpfCnpj: OUTRO_CPF_VALIDO, email: 'ANA@exemplo.com ' }))
        .expect(409);
      expect(r.body.codigo).toBe('EMAIL_JA_CADASTRADO');
    });

    it('sem aceite dos termos → 400 DADOS_INVALIDOS em aceiteTermos', async () => {
      const r = await http()
        .post('/api/v1/clientes')
        .send(novoCliente({ aceiteTermos: false }))
        .expect(400);
      expect(r.body).toMatchObject({ codigo: 'DADOS_INVALIDOS', campo: 'aceiteTermos' });
    });

    it('SEG05: campo desconhecido (ex.: papel) é recusado', async () => {
      const r = await http()
        .post('/api/v1/clientes')
        .send(novoCliente({ papel: 'ADMIN' }))
        .expect(400);
      expect(r.body.codigo).toBe('DADOS_INVALIDOS');
    });
  });

  describe('login, refresh e /clientes/me', () => {
    async function cadastrarELogar(email = 'ana@exemplo.com', cpfCnpj = CPF_VALIDO) {
      await http().post('/api/v1/clientes').send(novoCliente({ email, cpfCnpj })).expect(201);
      const r = await http()
        .post('/api/v1/auth/login')
        .send({ email, senha: 'senha-forte-123' })
        .expect(200);
      return r.body as { accessToken: string; refreshToken: string; expiresIn: number };
    }

    it('login devolve tokens; senha errada → 401 CREDENCIAIS_INVALIDAS', async () => {
      const tokens = await cadastrarELogar();
      expect(tokens.expiresIn).toBe(900);

      const r = await http()
        .post('/api/v1/auth/login')
        .send({ email: 'ana@exemplo.com', senha: 'errada-123' })
        .expect(401);
      expect(r.body.codigo).toBe('CREDENCIAIS_INVALIDAS');

      const inexistente = await http()
        .post('/api/v1/auth/login')
        .send({ email: 'ninguem@exemplo.com', senha: 'errada-123' })
        .expect(401);
      expect(inexistente.body.codigo).toBe('CREDENCIAIS_INVALIDAS');
    });

    it('GET /clientes/me exige token e devolve o próprio cadastro', async () => {
      const { accessToken } = await cadastrarELogar();

      const semToken = await http().get('/api/v1/clientes/me').expect(401);
      expect(semToken.body.codigo).toBe('NAO_AUTENTICADO');

      const r = await http()
        .get('/api/v1/clientes/me')
        .set('Authorization', `Bearer ${accessToken}`)
        .expect(200);
      expect(r.body).toMatchObject({ email: 'ana@exemplo.com', papel: 'CLIENTE' });
      expect(r.body).not.toHaveProperty('senhaHash');
    });

    it('SEG04: cada token só enxerga o próprio cadastro', async () => {
      const ana = await cadastrarELogar('ana@exemplo.com', CPF_VALIDO);
      const bruno = await cadastrarELogar('bruno@exemplo.com', OUTRO_CPF_VALIDO);

      const rAna = await http()
        .get('/api/v1/clientes/me')
        .set('Authorization', `Bearer ${ana.accessToken}`)
        .expect(200);
      const rBruno = await http()
        .get('/api/v1/clientes/me')
        .set('Authorization', `Bearer ${bruno.accessToken}`)
        .expect(200);
      expect(rAna.body.email).toBe('ana@exemplo.com');
      expect(rBruno.body.email).toBe('bruno@exemplo.com');
    });

    it('PUT /clientes/me altera nome, celular e marketing; CPF não muda', async () => {
      const { accessToken } = await cadastrarELogar();

      const r = await http()
        .put('/api/v1/clientes/me')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({ nome: 'Ana Souza Lima', marketingOk: true, celular: '21 91234-5678' })
        .expect(200);
      expect(r.body).toMatchObject({ nome: 'Ana Souza Lima', marketingOk: true, celular: '21912345678' });

      const cpf = await http()
        .put('/api/v1/clientes/me')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({ cpfCnpj: OUTRO_CPF_VALIDO })
        .expect(400);
      expect(cpf.body.codigo).toBe('DADOS_INVALIDOS');
    });

    it('refresh renova os tokens; access token não serve como refresh e vice-versa', async () => {
      const { accessToken, refreshToken } = await cadastrarELogar();

      const r = await http().post('/api/v1/auth/refresh').send({ refreshToken }).expect(200);
      expect(typeof r.body.accessToken).toBe('string');
      await http()
        .get('/api/v1/clientes/me')
        .set('Authorization', `Bearer ${r.body.accessToken}`)
        .expect(200);

      const trocado = await http()
        .post('/api/v1/auth/refresh')
        .send({ refreshToken: accessToken })
        .expect(401);
      expect(trocado.body.codigo).toBe('NAO_AUTENTICADO');

      await http()
        .get('/api/v1/clientes/me')
        .set('Authorization', `Bearer ${refreshToken}`)
        .expect(401);
    });
  });

  describe('SEG03: rotas /admin', () => {
    it('cliente → 403 SEM_PERMISSAO; admin → 200', async () => {
      await prisma.inserir({
        nome: 'Admin',
        cpfCnpj: '00000000191',
        email: 'admin@cristalins.local',
        papel: 'ADMIN',
        senhaHash: await gerarHashSenha('senha-admin-123'),
      });
      await http().post('/api/v1/clientes').send(novoCliente()).expect(201);

      const cliente = await http()
        .post('/api/v1/auth/login')
        .send({ email: 'ana@exemplo.com', senha: 'senha-forte-123' })
        .expect(200);
      const admin = await http()
        .post('/api/v1/auth/login')
        .send({ email: 'admin@cristalins.local', senha: 'senha-admin-123' })
        .expect(200);

      const negado = await http()
        .get('/api/v1/admin/teste-papel')
        .set('Authorization', `Bearer ${cliente.body.accessToken}`)
        .expect(403);
      expect(negado.body).toEqual({
        codigo: 'SEM_PERMISSAO',
        mensagem: 'Você não tem permissão para esta ação.',
      });

      await http()
        .get('/api/v1/admin/teste-papel')
        .set('Authorization', `Bearer ${admin.body.accessToken}`)
        .expect(200, { ok: true });

      await http().get('/api/v1/admin/teste-papel').expect(401);
    });
  });

  describe('CT19 / SEG06: limite de login', () => {
    it('a 6ª tentativa em 1 minuto → 429 MUITAS_TENTATIVAS', async () => {
      await http().post('/api/v1/clientes').send(novoCliente()).expect(201);
      const errada = { email: 'ana@exemplo.com', senha: 'senha-errada' };

      for (let i = 1; i <= 5; i++) {
        await http().post('/api/v1/auth/login').send(errada).expect(401);
      }
      const r = await http().post('/api/v1/auth/login').send(errada).expect(429);
      expect(r.body).toEqual({
        codigo: 'MUITAS_TENTATIVAS',
        mensagem: 'Muitas tentativas de login. Aguarde um minuto e tente de novo.',
      });

      // Bloqueia até a senha certa enquanto durar a janela.
      await http()
        .post('/api/v1/auth/login')
        .send({ email: 'ana@exemplo.com', senha: 'senha-forte-123' })
        .expect(429);
    });

    it('o limite vale só para o login (cadastro e refresh não contam)', async () => {
      for (let i = 0; i < 6; i++) {
        await http()
          .post('/api/v1/clientes')
          .send(novoCliente({ dataNascimento: '2010-01-01' }))
          .expect(422);
      }
      await http().post('/api/v1/auth/login').send({ email: 'x@exemplo.com', senha: 'y' }).expect(401);
    });
  });

  describe('Swagger', () => {
    it('documenta login, refresh, POST /clientes e GET/PUT /clientes/me', async () => {
      const r = await http().get('/docs-json').expect(200);
      const paths = r.body.paths as Record<string, Record<string, unknown>>;
      expect(paths['/api/v1/auth/login']).toHaveProperty('post');
      expect(paths['/api/v1/auth/refresh']).toHaveProperty('post');
      expect(paths['/api/v1/clientes']).toHaveProperty('post');
      expect(paths['/api/v1/clientes/me']).toHaveProperty('get');
      expect(paths['/api/v1/clientes/me']).toHaveProperty('put');
      expect(paths['/api/v1/clientes/me']).not.toHaveProperty('delete');
      expect(paths['/api/v1/clientes/me'].get).toHaveProperty('security', [{ bearer: [] }]);
    });
  });
});
