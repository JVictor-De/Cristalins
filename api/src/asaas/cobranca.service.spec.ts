import { UnauthorizedException } from '@nestjs/common';
import { ClockService } from '../common/clock.service';
import { PrismaService } from '../common/prisma.service';
import { PrismaFake } from '../../test/support/prisma-fake';
import { AssinaturasService } from '../assinaturas/assinaturas.service';
import { MaquinaEstadosService } from '../assinaturas/maquina-estados.service';
import { PrecoService } from '../precos/preco.service';
import { JobsService } from '../jobs/jobs.service';
import { WebhooksService } from '../webhooks/webhooks.service';
import { CobrancaService } from './cobranca.service';
import { FakeGateway } from './fake.gateway';

/** Evita importar criar-app (puxa AppModule + ESM do schedule). */
class RelogioAjustavel extends ClockService {
  constructor(public instante: Date = new Date('2026-11-14T15:00:00.000Z')) {
    super();
  }
  override agora(): Date {
    return new Date(this.instante);
  }
}

const ANA = 'cliente-ana';
const END_ANA = 'end-ana';

describe('cr-3-gateway — Pix, webhook e jobs (FakeGateway)', () => {
  let prisma: PrismaFake;
  let relogio: RelogioAjustavel;
  let maquina: MaquinaEstadosService;
  let gateway: FakeGateway;
  let cobranca: CobrancaService;
  let assinaturas: AssinaturasService;
  let webhooks: WebhooksService;
  let jobs: JobsService;

  beforeEach(() => {
    process.env.ASAAS_MODE = 'fake';
    process.env.ASAAS_WEBHOOK_TOKEN = 'token-teste-webhook';
    prisma = new PrismaFake().carregarCatalogo();
    const zonaSul = prisma.zonas.find((z) => z.nome === 'Zona Sul')!.id;
    prisma.clientes.push({
      id: ANA,
      nome: 'Ana Teste',
      cpfCnpj: '52998224725',
      email: 'ana.teste@cristalins.local',
      celular: '21999999999',
      senhaHash: 'x',
      papel: 'CLIENTE',
      asaasCustomerId: null,
    });
    prisma.enderecos.push({
      id: END_ANA,
      clienteId: ANA,
      zonaId: zonaSul,
      cep: '22041001',
      bairro: 'Copacabana',
      logradouro: 'Rua Teste',
      numero: '100',
      principal: true,
    });
    relogio = new RelogioAjustavel();
    maquina = new MaquinaEstadosService();
    gateway = new FakeGateway();
    const preco = new PrecoService(prisma as unknown as PrismaService, relogio);
    cobranca = new CobrancaService(prisma as unknown as PrismaService, relogio, maquina, gateway);
    assinaturas = new AssinaturasService(
      prisma as unknown as PrismaService,
      preco,
      maquina,
      relogio,
      cobranca,
    );
    webhooks = new WebhooksService(prisma as unknown as PrismaService, cobranca);
    jobs = new JobsService(
      prisma as unknown as PrismaService,
      relogio,
      assinaturas,
      maquina,
      cobranca,
      webhooks,
    );
  });

  it('cria assinatura PIX com copia-e-cola e QR (FakeGateway, sem rede)', async () => {
    const r = await assinaturas.criar(ANA, {
      itens: [{ produto: 'WP500', quantidade: 24 }],
      frequencia: 'QUINZENAL',
      plano: 'TRIMESTRAL',
      enderecoId: END_ANA,
      janela: 'MANHA',
      formaPagamento: 'PIX',
    } as never);
    expect(r.ciclo.valor).toBe(203.29);
    expect(r.ciclo.pix?.copiaECola).toMatch(/^00020126FAKE-PIX-/);
    expect(r.ciclo.pix?.qrCodeBase64).toBeTruthy();
    expect(prisma.pagamentos).toHaveLength(1);
    expect(prisma.pagamentos[0].status).toBe('PENDENTE');
  });

  it('CT15: token errado → 401 e nada gravado', async () => {
    expect(() => webhooks.validarToken('errado')).toThrow(UnauthorizedException);
    expect(() => webhooks.validarToken(undefined)).toThrow(UnauthorizedException);
    expect(prisma.eventosWebhook).toHaveLength(0);
  });

  it('CT14: webhook duplicado processado uma vez', async () => {
    const criada = await assinaturas.criar(ANA, {
      itens: [{ produto: 'WP500', quantidade: 24 }],
      frequencia: 'QUINZENAL',
      plano: 'TRIMESTRAL',
      enderecoId: END_ANA,
      janela: 'MANHA',
      formaPagamento: 'PIX',
    } as never);
    const payId = prisma.pagamentos[0].asaasPaymentId as string;
    const body = {
      id: 'evt_dup_1',
      event: 'PAYMENT_RECEIVED',
      payment: { id: payId, externalReference: criada.ciclo.id },
    };
    webhooks.validarToken('token-teste-webhook');
    const a = await webhooks.receber(body.id, body.event, body);
    const b = await webhooks.receber(body.id, body.event, body);
    expect(a.gravado).toBe(true);
    expect(b.gravado).toBe(false);
    expect(prisma.eventosWebhook).toHaveLength(1);

    await webhooks.processarPendentes();
    await webhooks.processarPendentes(); // segunda passagem: já processadoEm
    const ass = prisma.assinaturas.find((x) => x.id === criada.id)!;
    const ciclo = prisma.ciclos.find((c) => c.id === criada.ciclo.id)!;
    expect(ass.status).toBe('ATIVA');
    expect(ciclo.status).toBe('PAGO');
    expect(prisma.pagamentos[0].status).toBe('PAGO');
  });

  it('CT22: ciclo COBRADO sem pagamento após o corte → CANCELADO', async () => {
    const criada = await assinaturas.criar(ANA, {
      itens: [{ produto: 'WP500', quantidade: 24 }],
      frequencia: 'QUINZENAL',
      plano: 'FLEX',
      enderecoId: END_ANA,
      janela: 'MANHA',
      formaPagamento: 'PIX',
    } as never);
    const ciclo = prisma.ciclos.find((c) => c.id === criada.ciclo.id)!;
    await maquina.ciclo(prisma as never, ciclo as never, 'COBRADO');
    // Avança o relógio para depois do dataCorte (corte = entrega−2 23:59 SP)
    relogio.instante = new Date(ciclo.dataCorte.getTime() + 1000);
    const n = await jobs.cancelarCobradoAposCorte();
    expect(n).toBe(1);
    expect(prisma.ciclos.find((c) => c.id === ciclo.id)!.status).toBe('CANCELADO');
  });
});
