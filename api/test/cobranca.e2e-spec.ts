import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { gerarHashSenha } from '../src/auth/senha';
import { RespostaViaCep } from '../src/enderecos/viacep.client';
import { criarAppDeTeste, RelogioAjustavel } from './support/criar-app';
import { PrismaFake } from './support/prisma-fake';

const VIACEP: Record<string, RespostaViaCep> = {
  '22041001': { cep: '22041-001', logradouro: 'Avenida Nossa Senhora de Copacabana', bairro: 'Copacabana', localidade: 'Rio de Janeiro', uf: 'RJ' },
};
const PAN = '5555666677778884';

describe('Cartão, faturas, forma de pagamento e cupom (e2e, cr-5)', () => {
  let app: INestApplication;
  let prisma: PrismaFake;
  const http = () => request(app.getHttpServer());
  const bearer = (t: string) => ({ Authorization: `Bearer ${t}` });

  async function entrar(email: string, cpfCnpj: string): Promise<string> {
    const r = await http()
      .post('/api/v1/clientes')
      .send({ nome: 'Teste', cpfCnpj, email, dataNascimento: '1990-01-01', senha: 'senha-forte-123', aceiteTermos: true })
      .expect(201);
    return r.body.tokens.accessToken;
  }

  async function assinar(token: string): Promise<string> {
    const end = await http().post('/api/v1/enderecos').set(bearer(token)).send({ cep: '22041-001', numero: '100' }).expect(201);
    const a = await http()
      .post('/api/v1/assinaturas')
      .set(bearer(token))
      .send({ itens: [{ produto: 'WP500', quantidade: 24 }], frequencia: 'QUINZENAL', plano: 'TRIMESTRAL', enderecoId: end.body.id, janela: 'MANHA', formaPagamento: 'PIX' })
      .expect(201);
    return a.body.id;
  }

  beforeEach(async () => {
    ({ app, prisma } = await criarAppDeTeste({
      relogio: new RelogioAjustavel(),
      viaCep: { buscar: async (cep: string) => VIACEP[cep] ?? null },
    }));
    prisma.carregarCatalogo();
  });

  afterEach(async () => {
    await app.close();
  });

  it('CT18 (cadastro): POST /cartoes devolve só bandeira e final; PAN e CVV não ficam em lugar nenhum', async () => {
    const ana = await entrar('ana@exemplo.com', '52998224725');
    await http().post('/api/v1/cartoes').send({}).expect(401);
    const invalido = await http().post('/api/v1/cartoes').set(bearer(ana)).send({ numero: '123' }).expect(400);
    expect(invalido.body.codigo).toBe('DADOS_INVALIDOS');

    const semTelefone = await http()
      .post('/api/v1/cartoes')
      .set(bearer(ana))
      .send({ nomeNoCartao: 'ANA T', numero: PAN, mesValidade: '08', anoValidade: '2031', cvv: '321', cep: '22041001', numeroEndereco: '100' })
      .expect(400);
    expect(semTelefone.body.campo).toBe('telefone'); // cadastro sem celular: o Asaas exige telefone
    const r = await http()
      .post('/api/v1/cartoes')
      .set(bearer(ana))
      .send({ nomeNoCartao: 'ANA T', numero: PAN, mesValidade: '08', anoValidade: '2031', cvv: '321', cep: '22041001', numeroEndereco: '100', telefone: '(21) 98765-4321' })
      .expect(201);
    expect(r.body).toEqual({ id: expect.any(String), bandeira: 'MASTERCARD', final: '8884' });
    expect(JSON.stringify(prisma)).not.toContain(PAN);
    expect(JSON.stringify(prisma)).not.toContain('"321"');

    const lista = await http().get('/api/v1/cartoes').set(bearer(ana)).expect(200);
    expect(lista.body).toEqual([r.body]);
  });

  it('faturas, comprovante e troca de forma de pagamento; outro cliente → 403', async () => {
    const ana = await entrar('ana@exemplo.com', '52998224725');
    const bruno = await entrar('bruno@exemplo.com', '11144477735');
    const id = await assinar(ana);

    const faturas = await http().get('/api/v1/faturas').set(bearer(ana)).expect(200);
    expect(faturas.body).toEqual([expect.objectContaining({ cicloNumero: 1, forma: 'PIX', status: 'PENDENTE', temComprovante: false })]);
    expect((await http().get('/api/v1/faturas').set(bearer(bruno)).expect(200)).body).toEqual([]);

    const semComprovante = await http().get(`/api/v1/faturas/${faturas.body[0].id}/comprovante`).set(bearer(ana)).expect(422);
    expect(semComprovante.body.codigo).toBe('COMPROVANTE_INDISPONIVEL');
    await http().get(`/api/v1/faturas/${faturas.body[0].id}/comprovante`).set(bearer(bruno)).expect(403);

    expect((await http().get(`/api/v1/assinaturas/${id}/forma-pagamento`).set(bearer(ana)).expect(200)).body).toEqual({
      formaPagamento: 'PIX',
      cartao: null,
    });
    const boleto = await http().put(`/api/v1/assinaturas/${id}/forma-pagamento`).set(bearer(ana)).send({ formaPagamento: 'BOLETO' }).expect(200);
    expect(boleto.body).toEqual({ formaPagamento: 'BOLETO', cartao: null });
    await http().put(`/api/v1/assinaturas/${id}/forma-pagamento`).set(bearer(ana)).send({ formaPagamento: 'DINHEIRO' }).expect(400);
    await http().put(`/api/v1/assinaturas/${id}/forma-pagamento`).set(bearer(bruno)).send({ formaPagamento: 'PIX' }).expect(403);
  });

  it('RN14 pela API: arrependimento em até 7 dias cancela a assinatura', async () => {
    const ana = await entrar('ana@exemplo.com', '52998224725');
    const id = await assinar(ana);
    prisma.assinaturas[0].criadoEm = new Date('2026-11-14T15:00:00.000Z');
    const r = await http().post(`/api/v1/assinaturas/${id}/arrependimento`).set(bearer(ana)).expect(200);
    expect(r.body).toMatchObject({ estorno: 'INTEGRAL', valorEstornado: 0 });
    expect(prisma.assinaturas[0].status).toBe('CANCELADA');
  });

  it('RN21: POST /admin/cupons → 403 para cliente, 201 para admin e 409 se repetido', async () => {
    const ana = await entrar('ana@exemplo.com', '52998224725');
    await http().post('/api/v1/admin/cupons').set(bearer(ana)).send({ codigo: 'BEMVINDO', percentual: 10 }).expect(403);

    await prisma.inserir({
      nome: 'Admin',
      cpfCnpj: '00000000191',
      email: 'admin@cristalins.local',
      papel: 'ADMIN',
      senhaHash: await gerarHashSenha('senha-admin-123'),
    });
    const login = await http().post('/api/v1/auth/login').send({ email: 'admin@cristalins.local', senha: 'senha-admin-123' }).expect(200);
    const admin = login.body.accessToken;
    const criado = await http().post('/api/v1/admin/cupons').set(bearer(admin)).send({ codigo: 'bemvindo', percentual: 10 }).expect(201);
    expect(criado.body).toMatchObject({ codigo: 'BEMVINDO', percentual: 10, usos: 0, validade: null, usosMax: null });
    const repetido = await http().post('/api/v1/admin/cupons').set(bearer(admin)).send({ codigo: 'BEMVINDO', percentual: 5 }).expect(409);
    expect(repetido.body.codigo).toBe('CUPOM_JA_EXISTE');
    await http().post('/api/v1/admin/cupons').set(bearer(admin)).send({ codigo: 'X', percentual: 150 }).expect(400);
  });
});
