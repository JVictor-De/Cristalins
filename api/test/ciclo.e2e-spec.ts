import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { gerarHashSenha } from '../src/auth/senha';
import { RespostaViaCep } from '../src/enderecos/viacep.client';
import { criarAppDeTeste, RelogioAjustavel } from './support/criar-app';
import { PrismaFake } from './support/prisma-fake';

const VIACEP: Record<string, RespostaViaCep> = {
  '22041001': { cep: '22041-001', logradouro: 'Avenida Nossa Senhora de Copacabana', bairro: 'Copacabana', localidade: 'Rio de Janeiro', uf: 'RJ' },
  '20550013': { cep: '20550-013', logradouro: 'Rua Sem Cobertura', bairro: 'Morro do Teste', localidade: 'Rio de Janeiro', uf: 'RJ' },
};

describe('Endereço, assinatura e ciclos (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaFake;
  let relogio: RelogioAjustavel;
  const http = () => request(app.getHttpServer());

  async function entrar(email: string, cpfCnpj: string): Promise<string> {
    const r = await http()
      .post('/api/v1/clientes')
      .send({ nome: 'Teste', cpfCnpj, email, dataNascimento: '1990-01-01', senha: 'senha-forte-123', aceiteTermos: true })
      .expect(201);
    return r.body.tokens.accessToken;
  }
  const bearer = (t: string) => ({ Authorization: `Bearer ${t}` });

  async function enderecoEm(token: string, cep = '22041-001'): Promise<string> {
    const r = await http().post('/api/v1/enderecos').set(bearer(token)).send({ cep, numero: '100', apelido: 'Casa' }).expect(201);
    return r.body.id;
  }

  beforeEach(async () => {
    relogio = new RelogioAjustavel();
    ({ app, prisma } = await criarAppDeTeste({
      relogio,
      viaCep: { buscar: async (cep: string) => VIACEP[cep] ?? null },
    }));
    prisma.carregarCatalogo();
  });

  afterEach(async () => {
    await app.close();
  });

  describe('CEP e lista de espera (públicos)', () => {
    it('CT08: GET /cep/01310-100 → 422 CEP_FORA_AREA', async () => {
      const r = await http().get('/api/v1/cep/01310-100').expect(422);
      expect(r.body).toEqual({
        codigo: 'CEP_FORA_AREA',
        mensagem: 'Por enquanto entregamos só no município do Rio de Janeiro.',
        campo: 'cep',
      });
    });

    it('CT23: bairro do Rio sem zona → 422 BAIRRO_NAO_ATENDIDO e POST /lista-espera grava', async () => {
      const r = await http().get('/api/v1/cep/20550013').expect(422);
      expect(r.body).toMatchObject({ codigo: 'BAIRRO_NAO_ATENDIDO', campo: 'bairro' });
      const espera = await http()
        .post('/api/v1/lista-espera')
        .send({ email: 'Ana@Exemplo.com', cep: '20550-013', bairro: 'Morro do Teste' })
        .expect(201);
      expect(espera.body).toMatchObject({ email: 'ana@exemplo.com', cep: '20550013', bairro: 'Morro do Teste' });
      expect(prisma.filaEspera).toHaveLength(1);
    });

    it('CEP atendido devolve zona, taxa e dias', async () => {
      const r = await http().get('/api/v1/cep/22041-001').expect(200);
      expect(r.body.zona).toMatchObject({ nome: 'Zona Sul', taxaEntrega: 9.9, diasEntrega: ['SEG', 'QUA', 'SEX'] });
    });
  });

  describe('endereços', () => {
    it('exige token e cria/lista só os do cliente', async () => {
      await http().post('/api/v1/enderecos').send({ cep: '22041-001', numero: '1' }).expect(401);
      const ana = await entrar('ana@exemplo.com', '52998224725');
      const bruno = await entrar('bruno@exemplo.com', '11144477735');
      const id = await enderecoEm(ana);
      await enderecoEm(bruno);
      const lista = await http().get('/api/v1/enderecos').set(bearer(ana)).expect(200);
      expect(lista.body).toHaveLength(1);
      expect(lista.body[0]).toMatchObject({ id, bairro: 'Copacabana', principal: true, lat: null, lng: null });
      await http().delete(`/api/v1/enderecos/${id}`).set(bearer(bruno)).expect(403);
      const principal = await http().delete(`/api/v1/enderecos/${id}`).set(bearer(ana)).expect(422);
      expect(principal.body.codigo).toBe('ENDERECO_PRINCIPAL');
    });
  });

  describe('assinaturas', () => {
    const corpo = (enderecoId: string) => ({
      itens: [{ produto: 'WP500', quantidade: 24 }],
      frequencia: 'QUINZENAL',
      plano: 'TRIMESTRAL',
      enderecoId,
      janela: 'MANHA',
      formaPagamento: 'PIX',
    });

    it('CT02: POST /assinaturas → 201 AGUARDANDO_PAGAMENTO com ciclo de 213,19 e Pix (cr-3)', async () => {
      const ana = await entrar('ana@exemplo.com', '52998224725');
      const r = await http().post('/api/v1/assinaturas').set(bearer(ana)).send(corpo(await enderecoEm(ana))).expect(201);
      expect(r.body).toMatchObject({
        status: 'AGUARDANDO_PAGAMENTO',
        proximaEntrega: '2026-11-16',
        ciclo: { numero: 1, valor: 213.19, vencimento: '2026-11-14' },
        detalhePreco: [
          { fator: 'VOLUME', percentual: -8 },
          { fator: 'COMPROMISSO', percentual: -7 },
          { fator: 'FRETE', valor: 9.9 },
        ],
      });
      expect(r.body.ciclo.pix).toEqual({ copiaECola: expect.any(String), qrCodeBase64: expect.any(String) });
      const ciclos = await http().get(`/api/v1/assinaturas/${r.body.id}/ciclos`).set(bearer(ana)).expect(200);
      expect(ciclos.body).toHaveLength(1);
    });

    it('plano Empresa e forma de pagamento diferente de Pix são recusados no app', async () => {
      const ana = await entrar('ana@exemplo.com', '52998224725');
      const end = await enderecoEm(ana);
      const empresa = await http().post('/api/v1/assinaturas').set(bearer(ana)).send({ ...corpo(end), plano: 'EMPRESA' }).expect(400);
      expect(empresa.body).toMatchObject({ codigo: 'DADOS_INVALIDOS', campo: 'plano' });
      const cartao = await http().post('/api/v1/assinaturas').set(bearer(ana)).send({ ...corpo(end), formaPagamento: 'CARTAO' }).expect(400);
      expect(cartao.body.campo).toBe('formaPagamento');
    });

    it('CT16: cliente A consulta a assinatura do cliente B → 403 SEM_PERMISSAO', async () => {
      const ana = await entrar('ana@exemplo.com', '52998224725');
      const bruno = await entrar('bruno@exemplo.com', '11144477735');
      const b = await http().post('/api/v1/assinaturas').set(bearer(bruno)).send(corpo(await enderecoEm(bruno))).expect(201);
      const r = await http().get(`/api/v1/assinaturas/${b.body.id}`).set(bearer(ana)).expect(403);
      expect(r.body).toEqual({ codigo: 'SEM_PERMISSAO', mensagem: 'Você não tem permissão para esta ação.' });
      await http().get(`/api/v1/assinaturas/${b.body.id}/ciclos`).set(bearer(ana)).expect(403);
      await http().delete(`/api/v1/assinaturas/${b.body.id}`).set(bearer(ana)).expect(403);
      const lista = await http().get('/api/v1/assinaturas').set(bearer(ana)).expect(200);
      expect(lista.body).toEqual([]);
    });

    it('pausar exige assinatura ativa (409 TRANSICAO_INVALIDA) e valida 1 ou 2 ciclos', async () => {
      const ana = await entrar('ana@exemplo.com', '52998224725');
      const a = await http().post('/api/v1/assinaturas').set(bearer(ana)).send(corpo(await enderecoEm(ana))).expect(201);
      await http().post(`/api/v1/assinaturas/${a.body.id}/pausar`).set(bearer(ana)).send({ ciclos: 3 }).expect(400);
      const r = await http().post(`/api/v1/assinaturas/${a.body.id}/pausar`).set(bearer(ana)).send({ ciclos: 1 }).expect(409);
      expect(r.body.codigo).toBe('TRANSICAO_INVALIDA');
    });

    it('CT09 e CT10 pela API: depois do corte, pular → 409 APOS_CORTE e alterar vale para a seguinte', async () => {
      const ana = await entrar('ana@exemplo.com', '52998224725');
      const a = await http().post('/api/v1/assinaturas').set(bearer(ana)).send(corpo(await enderecoEm(ana))).expect(201);
      // Ativa como o webhook da cr-3 fará (pagamento confirmado do 1º ciclo).
      const ciclo1 = prisma.ciclos[0];
      ciclo1.status = 'PAGO';
      prisma.pagamentos[0].status = 'PAGO'; // a cr-3 cria o Pix do 1º ciclo na assinatura
      prisma.assinaturas[0].status = 'ATIVA';

      relogio.irPara('2026-11-15', '10:00'); // ciclo 1 (16/11): corte 14/11 23:59 já passou; próxima em aberto é ela
      const pular = await http().post(`/api/v1/assinaturas/${a.body.id}/pular-entrega`).set(bearer(ana)).expect(409);
      expect(pular.body).toMatchObject({ codigo: 'APOS_CORTE' });

      const alterar = await http()
        .put(`/api/v1/assinaturas/${a.body.id}`)
        .set(bearer(ana))
        .send({ itens: [{ produto: 'WP500', quantidade: 12 }] })
        .expect(200);
      // O 1º ciclo já está pago; a alteração vai para o ciclo 2 (30/11), que ainda está antes do corte.
      expect(alterar.body.aplicadaAPartirDe).toEqual({ numero: 2, dataEntrega: '2026-11-30' });
      const ciclos = await http().get(`/api/v1/assinaturas/${a.body.id}/ciclos`).set(bearer(ana)).expect(200);
      expect(ciclos.body[0].itens).toEqual([{ produto: 'WP500', quantidade: 24, precoUnitario: 8.47 }]);
    });

    it('DELETE cancela (Flex sem multa) e o segundo DELETE → 409', async () => {
      const ana = await entrar('ana@exemplo.com', '52998224725');
      const a = await http()
        .post('/api/v1/assinaturas')
        .set(bearer(ana))
        .send({ ...corpo(await enderecoEm(ana)), plano: 'FLEX' })
        .expect(201);
      const r = await http().delete(`/api/v1/assinaturas/${a.body.id}`).set(bearer(ana)).expect(200);
      expect(r.body).toMatchObject({ status: 'CANCELADA', diferencaCompromisso: 0 });
      await http().delete(`/api/v1/assinaturas/${a.body.id}`).set(bearer(ana)).expect(409);
    });
  });

  describe('admin', () => {
    async function admin(): Promise<string> {
      await prisma.inserir({
        nome: 'Admin',
        cpfCnpj: '00000000191',
        email: 'admin@cristalins.local',
        papel: 'ADMIN',
        senhaHash: await gerarHashSenha('senha-admin-123'),
      });
      const r = await http().post('/api/v1/auth/login').send({ email: 'admin@cristalins.local', senha: 'senha-admin-123' }).expect(200);
      return r.body.accessToken;
    }

    it('cliente → 403; admin altera produto, fator e zona', async () => {
      const cliente = await entrar('ana@exemplo.com', '52998224725');
      await http().put('/api/v1/admin/produtos/prod-WP500').set(bearer(cliente)).send({ precoBase: 10.5 }).expect(403);

      const token = await admin();
      const p = await http().put('/api/v1/admin/produtos/prod-WP500').set(bearer(token)).send({ precoBase: 10.5, estoque: 200 }).expect(200);
      expect(p.body).toMatchObject({ codigo: 'WP500', precoBase: 10.5, precoPiso: 7.5, estoque: 200 });
      const piso = await http().put('/api/v1/admin/produtos/prod-WP500').set(bearer(token)).send({ precoPiso: 11 }).expect(400);
      expect(piso.body.campo).toBe('precoPiso');

      const f = await http()
        .put('/api/v1/admin/fatores-preco')
        .set(bearer(token))
        .send({ chave: 'DEMANDA_VERAO', valor: 0.05, ativoDe: '2027-12-01', ativoAte: '2028-03-31' })
        .expect(200);
      expect(f.body).toMatchObject({ chave: 'DEMANDA_VERAO', valor: 0.05, ativoDe: '2027-12-01', ativoAte: '2028-03-31' });
      expect(prisma.fatores.filter((x) => x.chave === 'DEMANDA_VERAO')).toHaveLength(2);
      await http().put('/api/v1/admin/fatores-preco').set(bearer(token)).send({ chave: 'INVENTADO', valor: 0.1, ativoDe: '2027-01-01' }).expect(400);

      const z = await http().put('/api/v1/admin/zonas/zona-Zona-Oeste').set(bearer(token)).send({ taxaEntrega: 17.9, diasEntrega: ['QUA', 'SAB'] }).expect(200);
      expect(z.body).toMatchObject({ nome: 'Zona Oeste', taxaEntrega: 17.9, diasEntrega: ['QUA', 'SAB'] });
    });
  });

  it('Swagger documenta as rotas da fase', async () => {
    const r = await http().get('/docs-json').expect(200);
    const paths = Object.keys(r.body.paths);
    for (const p of [
      '/api/v1/cep/{cep}',
      '/api/v1/lista-espera',
      '/api/v1/enderecos',
      '/api/v1/enderecos/{id}',
      '/api/v1/assinaturas',
      '/api/v1/assinaturas/{id}',
      '/api/v1/assinaturas/{id}/pausar',
      '/api/v1/assinaturas/{id}/retomar',
      '/api/v1/assinaturas/{id}/pular-entrega',
      '/api/v1/assinaturas/{id}/ciclos',
      '/api/v1/admin/produtos/{id}',
      '/api/v1/admin/fatores-preco',
      '/api/v1/admin/zonas/{id}',
    ]) {
      expect(paths).toContain(p);
    }
    expect(r.body.paths['/api/v1/webhooks/asaas']).toBeUndefined();
  });
});
