import { ClockService } from '../common/clock.service';
import { PrismaService } from '../common/prisma.service';
import { RegraNegocioException } from '../common/regra-negocio.exception';
import { PrismaFake } from '../../test/support/prisma-fake';
import { AssinaturasService } from '../assinaturas/assinaturas.service';
import { MaquinaEstadosService } from '../assinaturas/maquina-estados.service';
import { CreditosService } from '../creditos/creditos.service';
import { CuponsService } from '../cupons/cupons.service';
import { JobsService } from '../jobs/jobs.service';
import { PrecoService } from '../precos/preco.service';
import { WebhooksService } from '../webhooks/webhooks.service';
import { CartaoService } from './cartao.service';
import { CobrancaService, EVENTOS } from './cobranca.service';
import { ConciliacaoService } from './conciliacao.service';
import { FakeGateway } from './fake.gateway';
import { FaturasService } from './faturas.service';
import { ReguaService } from './regua.service';

/** Evita importar criar-app (puxa AppModule + ESM do schedule). */
class RelogioAjustavel extends ClockService {
  constructor(public instante: Date = new Date('2026-11-14T15:00:00.000Z')) {
    super();
  }
  override agora(): Date {
    return new Date(this.instante);
  }
  irPara(data: string, hora = '12:00'): void {
    this.instante = new Date(`${data}T${hora}:00.000-03:00`);
  }
}

const ANA = 'cliente-ana';
const BRUNO = 'cliente-bruno';
const END_ANA = 'end-ana';
const PAN = '4444444444444444';
const CVV = '987';

async function codigo(p: Promise<unknown>): Promise<string> {
  try {
    await p;
  } catch (e) {
    if (e instanceof RegraNegocioException) return e.codigo;
    throw e;
  }
  throw new Error('esperava erro');
}

describe('cr-5-cobranca — cartão, boleto, créditos, régua, arrependimento e conciliação', () => {
  let prisma: PrismaFake;
  let relogio: RelogioAjustavel;
  let maquina: MaquinaEstadosService;
  let gateway: FakeGateway;
  let creditos: CreditosService;
  let cobranca: CobrancaService;
  let assinaturas: AssinaturasService;
  let webhooks: WebhooksService;
  let jobs: JobsService;
  let cartoes: CartaoService;
  let faturas: FaturasService;
  let regua: ReguaService;
  let conciliacao: ConciliacaoService;

  beforeEach(() => {
    process.env.ASAAS_MODE = 'fake';
    process.env.ASAAS_WEBHOOK_TOKEN = 'token-teste-webhook';
    prisma = new PrismaFake().carregarCatalogo();
    const zonaSul = prisma.zonas.find((z) => z.nome === 'Zona Sul')!.id;
    for (const [id, cpf, email] of [
      [ANA, '52998224725', 'ana@cristalins.local'],
      [BRUNO, '11144477735', 'bruno@cristalins.local'],
    ]) {
      prisma.clientes.push({ id, nome: 'Teste', cpfCnpj: cpf, email, celular: '21999999999', senhaHash: 'x', papel: 'CLIENTE', asaasCustomerId: null, indicadoPorId: null });
    }
    prisma.enderecos.push({ id: END_ANA, clienteId: ANA, zonaId: zonaSul, cep: '22041001', bairro: 'Copacabana', logradouro: 'Rua', numero: '1', principal: true });
    relogio = new RelogioAjustavel();
    maquina = new MaquinaEstadosService();
    gateway = new FakeGateway();
    const db = prisma as unknown as PrismaService;
    creditos = new CreditosService(db, relogio);
    cobranca = new CobrancaService(db, relogio, maquina, gateway, creditos);
    assinaturas = new AssinaturasService(db, new PrecoService(db, relogio), maquina, relogio, cobranca);
    webhooks = new WebhooksService(db, cobranca);
    regua = new ReguaService(db, relogio, maquina, cobranca, gateway);
    conciliacao = new ConciliacaoService(db, relogio, gateway);
    jobs = new JobsService(db, relogio, assinaturas, maquina, cobranca, webhooks, regua, conciliacao);
    cartoes = new CartaoService(db, cobranca, gateway);
    faturas = new FaturasService(db, relogio, cobranca, gateway, assinaturas);
  });

  const dto = (plano: 'FLEX' | 'TRIMESTRAL' = 'FLEX') => ({
    itens: [{ produto: 'WP500', quantidade: 12 }],
    frequencia: 'QUINZENAL' as const,
    plano,
    enderecoId: END_ANA,
    janela: 'MANHA' as const,
    formaPagamento: 'PIX' as const,
  });

  /** Assinatura ativa (1º ciclo pago) e o ciclo 2 travado e COBRADO, pronto para cobrar em D-5. */
  async function assinaturaAtivaComCiclo2() {
    const a = await assinaturas.criar(ANA, dto());
    await cobranca.confirmarFake(prisma.pagamentos[0].asaasPaymentId!);
    relogio.irPara('2026-11-20');
    const c2 = await assinaturas.proximoCicloAberto(a.id);
    await assinaturas.congelarCiclo(c2.id);
    const ciclo = prisma.ciclos.find((c) => c.id === c2.id)!;
    await maquina.ciclo(prisma as never, ciclo as never, 'COBRADO');
    return { assinaturaId: a.id, cicloId: c2.id };
  }

  async function evento(id: string, tipo: string, paymentId: string) {
    await webhooks.receber(id, tipo, { event: tipo, payment: { id: paymentId } });
    await webhooks.processarPendentes();
  }

  const pagamentosDo = (cicloId: string) => prisma.pagamentos.filter((p) => p.cicloId === cicloId);

  describe('cartão tokenizado (sem PAN nem CVV guardados)', () => {
    it('tokeniza e guarda só token, bandeira e 4 últimos dígitos', async () => {
      const r = await cartoes.cadastrar(ANA, {
        nomeNoCartao: 'ANA TESTE',
        numero: PAN,
        mesValidade: '12',
        anoValidade: '2030',
        cvv: CVV,
        cep: '22041001',
        numeroEndereco: '1',
      }, '10.0.0.1');
      expect(r).toEqual({ id: expect.any(String), bandeira: 'VISA', final: '4444' });
      expect(Object.keys(prisma.cartoes[0]).sort()).toEqual(['asaasToken', 'bandeira', 'clienteId', 'criadoEm', 'final', 'id']);
      // Nada do número completo nem do CVV em nenhuma tabela
      const tudo = JSON.stringify(prisma);
      expect(tudo).not.toContain(PAN);
      expect(tudo).not.toContain(`"${CVV}"`);
    });

    it('CT18: cartão recusado → nova tentativa no dia seguinte; na 2ª recusa, pede outra forma', async () => {
      const { assinaturaId, cicloId } = await assinaturaAtivaComCiclo2();
      const cartao = await cartoes.cadastrar(ANA, {
        nomeNoCartao: 'ANA', numero: PAN, mesValidade: '12', anoValidade: '2030', cvv: CVV, cep: '22041001', numeroEndereco: '1',
      }, '10.0.0.1');
      await faturas.trocarForma(ANA, assinaturaId, { formaPagamento: 'CARTAO', cartaoId: cartao.id });

      // D-5: cobrança no cartão com o token
      const c = await cobranca.cobrarCiclo(cicloId);
      expect(c.forma).toBe('CARTAO');
      expect(gateway.cobrancas.get(c.asaasPaymentId!)!.token).toBe(prisma.cartoes[0].asaasToken);

      // 1ª recusa
      await evento('evt-1', EVENTOS.recusado, c.asaasPaymentId!);
      let pags = pagamentosDo(cicloId);
      expect(pags.map((p) => [p.forma, p.status, p.asaasPaymentId === null])).toEqual([
        ['CARTAO', 'CANCELADO', false],
        ['CARTAO', 'PENDENTE', true],
      ]);
      expect(pags[1].vencimento.toISOString().slice(0, 10)).toBe('2026-11-21'); // dia seguinte

      // No dia seguinte o job tenta de novo com o token
      relogio.irPara('2026-11-21', '00:05');
      const r = await regua.executar();
      expect(r.tentativasCartao).toBe(1);
      const nova = pagamentosDo(cicloId)[1];
      expect(nova.asaasPaymentId).toMatch(/^pay_fake_/);

      // 2ª recusa: não agenda outra tentativa
      await evento('evt-2', EVENTOS.recusado, nova.asaasPaymentId);
      pags = pagamentosDo(cicloId);
      expect(pags.map((p) => p.status)).toEqual(['CANCELADO', 'CANCELADO']);

      // Idempotente: o mesmo evento de novo não muda nada (CT14)
      await evento('evt-2', EVENTOS.recusado, nova.asaasPaymentId);
      expect(pagamentosDo(cicloId)).toHaveLength(2);

      // O app vê a recusa nas faturas
      const lista = await faturas.listar(ANA);
      expect(lista.filter((f) => f.observacao === 'Cartão recusado.')).toHaveLength(2);
    });

    it('cartão sem cadastro: troca para CARTAO exige cartão do próprio cliente', async () => {
      const a = await assinaturas.criar(ANA, dto());
      expect(await codigo(faturas.trocarForma(ANA, a.id, { formaPagamento: 'CARTAO' }))).toBe('DADOS_INVALIDOS');
      prisma.cartoes.push({ id: 'cartao-bruno', clienteId: BRUNO, asaasToken: 'tok', bandeira: 'VISA', final: '1111' });
      expect(await codigo(faturas.trocarForma(ANA, a.id, { formaPagamento: 'CARTAO', cartaoId: 'cartao-bruno' }))).toBe('SEM_PERMISSAO');
    });
  });

  describe('boleto e eventos', () => {
    it('boleto vence no dia da geração (D-5, RN25) e o link vai para a fatura', async () => {
      const { assinaturaId, cicloId } = await assinaturaAtivaComCiclo2();
      await faturas.trocarForma(ANA, assinaturaId, { formaPagamento: 'BOLETO' });
      const c = await cobranca.cobrarCiclo(cicloId);
      expect(c).toMatchObject({ forma: 'BOLETO', vencimento: '2026-11-20' });
      expect(c.linkBoleto).toMatch(/fake\.asaas\.local\/b\//);
      const fatura = (await faturas.listar(ANA)).find((f) => f.cicloNumero === 2)!;
      expect(fatura).toMatchObject({ forma: 'BOLETO', status: 'PENDENTE', link: c.linkBoleto });
    });

    it('PAYMENT_OVERDUE → VENCIDO; pagar depois confirma o ciclo', async () => {
      const { cicloId } = await assinaturaAtivaComCiclo2();
      const c = await cobranca.cobrarCiclo(cicloId);
      await evento('evt-ov', EVENTOS.vencido, c.asaasPaymentId!);
      expect(pagamentosDo(cicloId)[0].status).toBe('VENCIDO');
      await evento('evt-ok', 'PAYMENT_RECEIVED', c.asaasPaymentId!);
      expect(pagamentosDo(cicloId)[0].status).toBe('PAGO');
      expect(prisma.ciclos.find((x) => x.id === cicloId)!.status).toBe('PAGO');
    });

    it('comprovante só de fatura paga e do próprio cliente', async () => {
      await assinaturas.criar(ANA, dto());
      const pag = prisma.pagamentos[0];
      expect(await codigo(faturas.comprovante(ANA, pag.id))).toBe('COMPROVANTE_INDISPONIVEL');
      await cobranca.confirmarFake(pag.asaasPaymentId!);
      await expect(faturas.comprovante(ANA, pag.id)).resolves.toEqual({ url: expect.stringContaining('/comprovantes/') });
      expect(await codigo(faturas.comprovante(BRUNO, pag.id))).toBe('SEM_PERMISSAO');
    });
  });

  describe('créditos (RN20) e indicação (RN22)', () => {
    it('crédito abate o total na geração da cobrança, uma vez, e o saldo vira novo crédito', async () => {
      const { cicloId } = await assinaturaAtivaComCiclo2();
      const total = Number(prisma.calculos.find((x) => x.cicloId === cicloId)!.valorFinal.toString());
      await creditos.conceder(prisma as never, ANA, '20.00', 'TESTE');
      const c = await cobranca.cobrarCiclo(cicloId);
      expect(c.valor).toBeCloseTo(total - 20, 2);
      const calc = prisma.calculos.find((x) => x.cicloId === cicloId)!;
      expect(calc.creditos.toString()).toBe('20');
      expect(prisma.creditos.every((x) => x.usadoEm)).toBe(true);
    });

    it('crédito maior que o total: ciclo pago sem cobrança no Asaas; o resto continua valendo', async () => {
      const { cicloId } = await assinaturaAtivaComCiclo2();
      await creditos.conceder(prisma as never, ANA, '500.00', 'TESTE');
      const antes = gateway.cobrancas.size;
      const c = await cobranca.cobrarCiclo(cicloId);
      expect(c).toMatchObject({ valor: 0, pagoComCreditos: true, asaasPaymentId: null });
      expect(gateway.cobrancas.size).toBe(antes);
      expect(prisma.ciclos.find((x) => x.id === cicloId)!.status).toBe('PAGO');
      const saldo = await creditos.listar(ANA);
      expect(saldo).toHaveLength(1);
      expect(saldo[0].motivo).toBe('TESTE:SALDO');
      expect(saldo[0].valor).toBeGreaterThan(0);
      expect((await faturas.listar(ANA)).find((f) => f.cicloNumero === 2)!.observacao).toBe('Pago com créditos.');
    });

    it('crédito vencido (mais de 90 dias) não abate', async () => {
      const { cicloId } = await assinaturaAtivaComCiclo2();
      prisma.creditos.push({ id: 'velho', clienteId: ANA, valor: '50', motivo: 'X', expiraEm: new Date('2026-11-01T00:00:00Z'), usadoEm: null });
      await cobranca.cobrarCiclo(cicloId);
      expect(prisma.calculos.find((x) => x.cicloId === cicloId)!.creditos.toString()).toBe('0');
    });

    it('RN22: R$ 15 para quem indicou, uma vez, quando o 1º ciclo do indicado é pago', async () => {
      prisma.clientes.find((c) => c.id === ANA)!.indicadoPorId = BRUNO;
      await assinaturas.criar(ANA, dto());
      await cobranca.confirmarFake(prisma.pagamentos[0].asaasPaymentId!);
      const doBruno = await creditos.listar(BRUNO);
      expect(doBruno).toEqual([expect.objectContaining({ valor: 15, motivo: `INDICACAO:${ANA}` })]);
      // Validade de 90 dias
      expect(doBruno[0].expiraEm).toBe('2027-02-12T15:00:00.000Z');
      // Confirmar de novo não credita outra vez
      await cobranca.confirmarPagamentoDoCiclo(prisma.ciclos[0].id);
      expect(await creditos.listar(BRUNO)).toHaveLength(1);
    });
  });

  describe('régua completa', () => {
    it('vencimento +7 → SUSPENSA; pagar reativa; +30 → CANCELADA e cobrança encerrada', async () => {
      const { assinaturaId, cicloId } = await assinaturaAtivaComCiclo2();
      const c = await cobranca.cobrarCiclo(cicloId); // vence 20/11
      const assinatura = () => prisma.assinaturas.find((a) => a.id === assinaturaId)!;

      relogio.irPara('2026-11-26');
      await regua.executar();
      expect(assinatura().status).toBe('ATIVA'); // +6

      relogio.irPara('2026-11-27');
      expect((await regua.executar()).suspensas).toBe(1); // +7
      expect(assinatura().status).toBe('SUSPENSA');

      // Pagou: volta a ATIVA
      await evento('evt-pg', 'PAYMENT_CONFIRMED', c.asaasPaymentId!);
      expect(assinatura().status).toBe('ATIVA');
    });

    it('+30 sem pagar → assinatura CANCELADA e cobrança encerrada no Asaas', async () => {
      const { assinaturaId, cicloId } = await assinaturaAtivaComCiclo2();
      const c = await cobranca.cobrarCiclo(cicloId);
      relogio.irPara('2026-11-27');
      await regua.executar();
      relogio.irPara('2026-12-20');
      expect((await regua.executar()).canceladas).toBe(1);
      expect(prisma.assinaturas.find((a) => a.id === assinaturaId)!.status).toBe('CANCELADA');
      expect(pagamentosDo(cicloId)[0].status).toBe('CANCELADO');
      expect(gateway.cancelados.has(c.asaasPaymentId!)).toBe(true);
    });

    it('o job das 00:05 roda a régua e a conciliação', async () => {
      const espiaRegua = jest.spyOn(regua, 'executar');
      const espiaConc = jest.spyOn(conciliacao, 'executar');
      await jobs.corteERegua();
      expect(espiaRegua).toHaveBeenCalled();
      expect(espiaConc).toHaveBeenCalled();
    });
  });

  describe('arrependimento (RN14)', () => {
    it('até 7 dias e sem entrega: estorno integral e assinatura cancelada', async () => {
      const a = await assinaturas.criar(ANA, dto('TRIMESTRAL'));
      prisma.assinaturas[0].criadoEm = relogio.agora();
      const pag = prisma.pagamentos[0];
      await cobranca.confirmarFake(pag.asaasPaymentId!);
      relogio.irPara('2026-11-18');
      const r = await faturas.arrepender(ANA, a.id);
      expect(r).toMatchObject({ estorno: 'INTEGRAL', valorEstornado: Number(pag.valor.toString()) });
      expect(gateway.estornados.has(pag.asaasPaymentId!)).toBe(true);
      expect(pag.status).toBe('ESTORNADO');
      expect(prisma.assinaturas[0].status).toBe('CANCELADA');
      // O ciclo pago fica marcado para não ser separado (diagrama sem PAGO → CANCELADO)
      expect(prisma.calculos.find((x) => x.cicloId === pag.cicloId)!.fatores).toMatchObject({ estornado: true });
    });

    it('com entrega feita: cancela e registra o pedido; estorno depois da devolução', async () => {
      const a = await assinaturas.criar(ANA, dto());
      prisma.assinaturas[0].criadoEm = relogio.agora();
      await cobranca.confirmarFake(prisma.pagamentos[0].asaasPaymentId!);
      prisma.ciclos[0].status = 'ENTREGUE';
      const r = await faturas.arrepender(ANA, a.id);
      expect(r.estorno).toBe('APOS_DEVOLUCAO');
      expect(gateway.estornados.size).toBe(0);
      expect(prisma.eventosWebhook.find((e) => e.tipo === 'ARREPENDIMENTO_AGUARDANDO_DEVOLUCAO')).toBeDefined();
    });

    it('depois de 7 dias → PRAZO_ARREPENDIMENTO_ENCERRADO; de outro cliente → SEM_PERMISSAO', async () => {
      const a = await assinaturas.criar(ANA, dto());
      prisma.assinaturas[0].criadoEm = relogio.agora(); // o fake grava a hora real
      expect(await codigo(faturas.arrepender(BRUNO, a.id))).toBe('SEM_PERMISSAO');
      relogio.irPara('2026-11-22');
      expect(await codigo(faturas.arrepender(ANA, a.id))).toBe('PRAZO_ARREPENDIMENTO_ENCERRADO');
    });
  });

  describe('conciliação diária', () => {
    it('registra cobrança no Asaas sem ciclo, ciclo cobrado sem cobrança e status divergente', async () => {
      const { cicloId } = await assinaturaAtivaComCiclo2(); // ciclo 2 COBRADO, ainda sem cobrança
      await gateway.criarCobrancaPix({ customerId: 'cus', valor: 10, vencimento: '2026-11-20', externalReference: 'ciclo-inexistente' });
      const pag1 = prisma.pagamentos[0];
      pag1.status = 'PENDENTE'; // local diverge do Asaas (pago lá)
      const r = await conciliacao.executar();
      expect(r.map((d) => d.tipo).sort()).toEqual(['CICLO_SEM_COBRANCA', 'COBRANCA_SEM_CICLO', 'STATUS_DIVERGENTE']);
      expect(r.find((d) => d.tipo === 'CICLO_SEM_COBRANCA')!.referencia).toBe(cicloId);
      // Registro idempotente no dia e fora da fila de webhooks
      await conciliacao.executar();
      const registros = prisma.eventosWebhook.filter((e) => e.tipo.startsWith('CONCILIACAO_'));
      expect(registros).toHaveLength(3);
      expect(registros.every((e) => e.processadoEm)).toBe(true);
    });
  });

  describe('cupom (RN21)', () => {
    it('admin cria cupom; código repetido → CUPOM_JA_EXISTE', async () => {
      const cupons = new CuponsService(prisma as unknown as PrismaService);
      await expect(cupons.criar({ codigo: 'VERAO10', percentual: 10, validade: '2027-03-31', usosMax: 50 })).resolves.toMatchObject({
        codigo: 'VERAO10',
        percentual: 10,
        validade: '2027-03-31',
        usos: 0,
      });
      expect(await codigo(cupons.criar({ codigo: 'VERAO10', percentual: 5 }))).toBe('CUPOM_JA_EXISTE');
    });
  });
});
