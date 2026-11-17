import { HttpStatus, Inject, Injectable, Logger, Optional } from '@nestjs/common';
import {
  FormaPagamento,
  Prisma,
  StatusAssinatura,
  StatusCiclo,
  StatusPagamento,
} from '../../prisma/generated/prisma/client';
import { dataCorte, primeiraEntrega, somarDias } from '../ciclos/agenda';
import { ClockService } from '../common/clock.service';
import { PrismaService } from '../common/prisma.service';
import { RegraNegocioException } from '../common/regra-negocio.exception';
import { CreditosService } from '../creditos/creditos.service';
import { MaquinaEstadosService } from '../assinaturas/maquina-estados.service';
import { MENSAGENS, NotificacoesService } from '../notificacoes/notificacoes.service';
import { dec } from '../precos/preco.tipos';
import { PAGAMENTO_GATEWAY, PagamentoGateway, PixQrCode } from './pagamento.gateway';

type Db = Prisma.TransactionClient;

export interface PixDoCiclo extends PixQrCode {
  pagamentoId: string;
  asaasPaymentId: string;
  vencimento: string;
  valor: number;
}

/** Resultado da cobrança de um ciclo em qualquer forma. */
export interface CobrancaDoCiclo {
  pagamentoId: string;
  asaasPaymentId: string | null;
  forma: FormaPagamento;
  valor: number;
  vencimento: string;
  pix?: PixQrCode;
  linkBoleto?: string | null;
  /** Total zerado por créditos (RN20): ciclo pago sem cobrança no Asaas. */
  pagoComCreditos?: boolean;
}

/** CT18: depois desta quantidade de recusas no cartão, não tenta mais (pede outra forma). */
export const TENTATIVAS_CARTAO = 2;

/** Eventos do Asaas tratados aqui (os de confirmação vão para `confirmarPagamentoDoCiclo`). */
export const EVENTOS = {
  recusado: 'PAYMENT_CREDIT_CARD_CAPTURE_REFUSED',
  vencido: 'PAYMENT_OVERDUE',
  estornado: 'PAYMENT_REFUNDED',
  removido: 'PAYMENT_DELETED',
  criado: 'PAYMENT_CREATED',
} as const;

/**
 * Cobrança avulsa por ciclo (Pix, boleto ou cartão tokenizado), confirmação e eventos do Asaas.
 * Status só via `MaquinaEstadosService`. Número e CVV de cartão nunca passam por aqui (só token).
 */
@Injectable()
export class CobrancaService {
  private readonly log = new Logger(CobrancaService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly clock: ClockService,
    private readonly maquina: MaquinaEstadosService,
    @Inject(PAGAMENTO_GATEWAY) private readonly gateway: PagamentoGateway,
    @Optional() private readonly creditos?: CreditosService,
    @Optional() private readonly notificacoes?: NotificacoesService,
  ) {}

  /** Garante o cliente no Asaas (`asaasCustomerId`). */
  async garantirClienteAsaas(clienteId: string): Promise<string> {
    const cliente = await this.prisma.cliente.findUnique({ where: { id: clienteId } });
    if (!cliente) throw new RegraNegocioException('NAO_ENCONTRADO', 'Cliente não encontrado.', HttpStatus.NOT_FOUND);
    if (cliente.asaasCustomerId) return cliente.asaasCustomerId;
    const customerId = await this.gateway.criarCliente({
      id: cliente.id,
      nome: cliente.nome,
      cpfCnpj: cliente.cpfCnpj,
      email: cliente.email,
      celular: cliente.celular,
    });
    await this.prisma.cliente.update({ where: { id: cliente.id }, data: { asaasCustomerId: customerId } });
    return customerId;
  }

  /** 1ª cobrança na criação da assinatura (Pix). Mantido para o fluxo da AP2. */
  async cobrarCicloPix(cicloId: string): Promise<PixDoCiclo> {
    try {
      const c = await this.cobrarCiclo(cicloId, FormaPagamento.PIX);
      return {
        copiaECola: c.pix?.copiaECola ?? '',
        qrCodeBase64: c.pix?.qrCodeBase64 ?? '',
        pagamentoId: c.pagamentoId,
        asaasPaymentId: c.asaasPaymentId ?? '',
        vencimento: c.vencimento,
        valor: c.valor,
      };
    } catch (e) {
      // FakeGateway / rede ainda podem lançar Error cru → evita "Erro inesperado" no Assinar.
      if (e instanceof RegraNegocioException) throw e;
      this.log.warn(`cobrarCicloPix(${cicloId}): ${(e as Error).message}`);
      throw new RegraNegocioException(
        'PAGAMENTO_INDISPONIVEL',
        'Não conseguimos gerar o Pix agora. Tente de novo em instantes.',
        HttpStatus.SERVICE_UNAVAILABLE,
      );
    }
  }

  /**
   * Cobra o ciclo na forma da assinatura (ou na `forma` indicada), com vencimento hoje — em D-5
   * quando chamado pelo job (RN19/RN25). Abate créditos válidos uma vez por ciclo (RN20); o
   * total nunca fica negativo e, se zerar, o ciclo é pago sem cobrança no Asaas.
   */
  async cobrarCiclo(cicloId: string, forma?: FormaPagamento): Promise<CobrancaDoCiclo> {
    const ciclo = await this.prisma.ciclo.findUnique({
      where: { id: cicloId },
      include: {
        calculoPreco: true,
        assinatura: { include: { cliente: true, cartao: true } },
        pagamentos: { orderBy: { criadoEm: 'desc' } },
      },
    });
    if (!ciclo?.calculoPreco) {
      throw new RegraNegocioException('NAO_ENCONTRADO', 'Ciclo sem cálculo de preço.', HttpStatus.NOT_FOUND);
    }
    const formaUsada = forma ?? ciclo.assinatura.formaPagamento;

    // Idempotente: já existe cobrança em aberto no Asaas para o ciclo.
    const pendente = ciclo.pagamentos.find((p) => p.status === StatusPagamento.PENDENTE && p.asaasPaymentId);
    if (pendente?.asaasPaymentId) {
      return {
        pagamentoId: pendente.id,
        asaasPaymentId: pendente.asaasPaymentId,
        forma: pendente.forma,
        valor: Number(pendente.valor.toString()),
        vencimento: pendente.vencimento.toISOString().slice(0, 10),
        ...(pendente.forma === FormaPagamento.PIX && { pix: await this.gateway.obterPixQrCode(pendente.asaasPaymentId) }),
        ...(pendente.forma === FormaPagamento.BOLETO && { linkBoleto: pendente.linkPagamento }),
      };
    }

    const valor = await this.aplicarCreditos(ciclo.id, ciclo.assinatura.clienteId);
    const vencimento = this.clock.hoje();

    if (valor === 0) {
      const pago = await this.prisma.pagamento.create({
        data: {
          cicloId: ciclo.id,
          forma: formaUsada,
          valor: '0',
          vencimento: new Date(`${vencimento}T00:00:00.000Z`),
          status: StatusPagamento.PENDENTE,
        },
      });
      await this.confirmarPagamentoDoCiclo(ciclo.id);
      return { pagamentoId: pago.id, asaasPaymentId: null, forma: formaUsada, valor: 0, vencimento, pagoComCreditos: true };
    }

    const customerId = await this.garantirClienteAsaas(ciclo.assinatura.clienteId);
    const base = { customerId, valor, vencimento, externalReference: ciclo.id, descricao: `Ciclo ${ciclo.numero} — Cristalins` };

    if (formaUsada === FormaPagamento.CARTAO) {
      const token = ciclo.assinatura.cartao?.asaasToken;
      if (!token) {
        throw new RegraNegocioException(
          'CARTAO_NAO_CADASTRADO',
          'Cadastre um cartão ou escolha outra forma de pagamento.',
          HttpStatus.UNPROCESSABLE_ENTITY,
        );
      }
      const cobranca = await this.gateway.criarCobrancaCartao({ ...base, token });
      const p = await this.registrar(ciclo.id, formaUsada, cobranca.id, valor, vencimento, cobranca.linkFatura);
      await this.avisarCobranca(ciclo, valor, vencimento);
      return { pagamentoId: p.id, asaasPaymentId: cobranca.id, forma: formaUsada, valor, vencimento };
    }
    if (formaUsada === FormaPagamento.BOLETO) {
      const cobranca = await this.gateway.criarCobrancaBoleto(base);
      const link = cobranca.linkBoleto ?? cobranca.linkFatura;
      const p = await this.registrar(ciclo.id, formaUsada, cobranca.id, valor, vencimento, link);
      await this.avisarCobranca(ciclo, valor, vencimento);
      return { pagamentoId: p.id, asaasPaymentId: cobranca.id, forma: formaUsada, valor, vencimento, linkBoleto: link };
    }
    const cobranca = await this.gateway.criarCobrancaPix(base);
    const pix = await this.gateway.obterPixQrCode(cobranca.id);
    const p = await this.registrar(ciclo.id, FormaPagamento.PIX, cobranca.id, valor, vencimento, null);
    await this.avisarCobranca(ciclo, valor, vencimento);
    return { pagamentoId: p.id, asaasPaymentId: cobranca.id, forma: FormaPagamento.PIX, valor, vencimento, pix };
  }

  /**
   * RF51: aviso da cobrança. RF22: se o total do ciclo (antes dos créditos) subiu em relação ao
   * ciclo anterior, avisa que dá para pular ou alterar até o corte. Falha de envio não quebra a cobrança.
   */
  private async avisarCobranca(
    ciclo: { id: string; assinaturaId: string; numero: number; dataEntrega: Date; dataCorte: Date; assinatura: { clienteId: string } },
    valor: number,
    vencimento: string,
  ): Promise<void> {
    if (!this.notificacoes) return;
    try {
      const entrega = ciclo.dataEntrega.toISOString().slice(0, 10);
      const dados = { cicloId: ciclo.id };
      await this.notificacoes.notificar(ciclo.assinatura.clienteId, 'COBRANCA', MENSAGENS.cobranca(entrega, valor, vencimento), dados);
      if (ciclo.numero <= 1) return;
      const [atual, anterior] = await Promise.all([
        this.prisma.calculoPreco.findUnique({ where: { cicloId: ciclo.id } }),
        this.prisma.calculoPreco.findFirst({ where: { ciclo: { assinaturaId: ciclo.assinaturaId, numero: ciclo.numero - 1 } } }),
      ]);
      if (!atual || !anterior) return;
      const bruto = (c: { valorFinal: unknown; creditos: unknown }) => dec(c.valorFinal as string).plus(dec(c.creditos as string));
      if (bruto(atual).gt(bruto(anterior))) {
        const corte = new Date(ciclo.dataCorte.getTime() - 3 * 60 * 60 * 1000).toISOString().slice(0, 10); // dia civil em São Paulo
        await this.notificacoes.notificar(
          ciclo.assinatura.clienteId,
          'AUMENTO_PRECO',
          MENSAGENS.aumento(entrega, Number(bruto(atual).toFixed(2)), Number(bruto(anterior).toFixed(2)), corte),
          dados,
        );
      }
    } catch (e) {
      // Falha de aviso não pode derrubar a cobrança (vira "Erro inesperado" no Assinar).
      this.log.warn(`Aviso de cobrança falhou: ${(e as Error).message}`);
    }
  }

  /** CT18: nova tentativa agendada no cartão → cobra com o token salvo. */
  async cobrarTentativaCartao(pagamentoId: string): Promise<boolean> {
    const p = await this.prisma.pagamento.findUnique({
      where: { id: pagamentoId },
      include: { ciclo: { include: { assinatura: { include: { cartao: true } } } } },
    });
    if (!p || p.asaasPaymentId || p.status !== StatusPagamento.PENDENTE) return false;
    const token = p.ciclo.assinatura.cartao?.asaasToken;
    if (!token) return false;
    const customerId = await this.garantirClienteAsaas(p.ciclo.assinatura.clienteId);
    const cobranca = await this.gateway.criarCobrancaCartao({
      customerId,
      valor: Number(p.valor.toString()),
      vencimento: this.clock.hoje(),
      externalReference: p.cicloId,
      descricao: `Ciclo ${p.ciclo.numero} — Cristalins (nova tentativa)`,
      token,
    });
    await this.prisma.pagamento.update({
      where: { id: p.id },
      data: { asaasPaymentId: cobranca.id, linkPagamento: cobranca.linkFatura },
    });
    return true;
  }

  private registrar(cicloId: string, forma: FormaPagamento, asaasPaymentId: string, valor: number, vencimento: string, link: string | null) {
    return this.prisma.pagamento.create({
      data: {
        cicloId,
        asaasPaymentId,
        forma,
        valor: String(valor),
        vencimento: new Date(`${vencimento}T00:00:00.000Z`),
        linkPagamento: link,
        status: StatusPagamento.PENDENTE,
      },
    });
  }

  /**
   * RN20: abate créditos válidos do total do ciclo, uma vez (se o cálculo já tem créditos, não
   * abate de novo). Depois do preço com piso: o crédito reduz o total, não o unitário.
   */
  private async aplicarCreditos(cicloId: string, clienteId: string): Promise<number> {
    const calc = await this.prisma.calculoPreco.findUnique({ where: { cicloId } });
    const total = dec(calc!.valorFinal);
    if (!this.creditos || dec(calc!.creditos).gt(0) || total.lte(0)) return Number(total.toFixed(2));
    return this.prisma.$transaction(async (tx) => {
      const usado = await this.creditos!.consumir(tx, clienteId, total);
      if (usado.lte(0)) return Number(total.toFixed(2));
      const novo = total.minus(usado).toDecimalPlaces(2);
      await tx.calculoPreco.update({
        where: { cicloId },
        data: { creditos: usado.toFixed(2), valorFinal: novo.toFixed(2) },
      });
      return Number(novo.toFixed(2));
    });
  }

  /**
   * Confirma pagamento do ciclo: AGENDADO→COBRADO→PAGO (ou COBRADO→PAGO); assinatura
   * AGUARDANDO→ATIVA (recalcula a 1ª entrega — RN08) ou SUSPENSA→ATIVA (régua). Na 1ª
   * cobrança paga do cliente, credita a indicação de quem o indicou (RN22).
   */
  async confirmarPagamentoDoCiclo(cicloId: string, asaasPaymentId?: string): Promise<void> {
    const confirmado = await this.prisma.$transaction(async (tx) => {
      const ciclo = await tx.ciclo.findUnique({
        where: { id: cicloId },
        include: {
          assinatura: { include: { endereco: { include: { zona: true } } } },
          pagamentos: true,
        },
      });
      if (!ciclo) return null;

      if (ciclo.status === StatusCiclo.PAGO || ciclo.status === StatusCiclo.CANCELADO || ciclo.status === StatusCiclo.PULADO) {
        return null; // idempotente
      }

      if (ciclo.status === StatusCiclo.AGENDADO) {
        await this.maquina.ciclo(tx, ciclo, StatusCiclo.COBRADO);
      }
      if (ciclo.status === StatusCiclo.COBRADO) {
        await this.maquina.ciclo(tx, ciclo, StatusCiclo.PAGO);
      }

      const abertos = [StatusPagamento.PENDENTE, StatusPagamento.VENCIDO] as StatusPagamento[];
      const pagamento =
        ciclo.pagamentos.find((p) => asaasPaymentId && p.asaasPaymentId === asaasPaymentId) ??
        ciclo.pagamentos.find((p) => abertos.includes(p.status)) ??
        ciclo.pagamentos[0];
      if (pagamento && pagamento.status !== StatusPagamento.PAGO) {
        await tx.pagamento.update({
          where: { id: pagamento.id },
          data: { status: StatusPagamento.PAGO, pagoEm: this.clock.agora() },
        });
      }

      const assinatura = ciclo.assinatura;
      if (assinatura.status === StatusAssinatura.SUSPENSA) {
        await this.maquina.assinatura(tx, assinatura, StatusAssinatura.ATIVA);
      }
      if (assinatura.status === StatusAssinatura.AGUARDANDO_PAGAMENTO) {
        await this.maquina.assinatura(tx, assinatura, StatusAssinatura.ATIVA);
        // RN08: recalcula a 1ª entrega a partir da confirmação
        if (ciclo.numero === 1) {
          const nova = primeiraEntrega(this.clock.hoje(), assinatura.endereco.zona.diasEntrega);
          await tx.ciclo.update({
            where: { id: ciclo.id },
            data: { dataEntrega: new Date(`${nova}T00:00:00.000Z`), dataCorte: dataCorte(nova) },
          });
          await tx.assinatura.update({
            where: { id: assinatura.id },
            data: { inicio: new Date(`${nova}T00:00:00.000Z`) },
          });
        }
      }

      if (this.creditos && ciclo.numero === 1) {
        const concedido = await this.creditos.concederIndicacao(tx, assinatura.clienteId);
        if (concedido) this.log.log(`RN22: crédito de indicação pelo cliente ${assinatura.clienteId}`);
      }
      const entrega = await tx.ciclo.findUnique({ where: { id: ciclo.id } });
      return { clienteId: assinatura.clienteId, entrega: entrega!.dataEntrega.toISOString().slice(0, 10) };
    });
    // RF51: aviso do pagamento, fora da transação.
    if (confirmado && this.notificacoes) {
      await this.notificacoes.notificar(confirmado.clienteId, 'PAGAMENTO', MENSAGENS.pagamento(confirmado.entrega), { cicloId });
    }
  }

  /**
   * Eventos do Asaas além da confirmação (tabela do Anexo):
   * - CAPTURE_REFUSED (CT18): cobrança cancelada; nova tentativa no dia seguinte (até 2 recusas) e aviso;
   * - OVERDUE: VENCIDO (a régua segue em `ReguaService`);
   * - REFUNDED: ESTORNADO e a entrega pendente não acontece;
   * - DELETED: CANCELADO.
   */
  async processarEvento(tipo: string, asaasPaymentId?: string): Promise<void> {
    if (!asaasPaymentId) return;
    const pagamento = await this.prisma.pagamento.findFirst({
      where: { asaasPaymentId },
      include: { ciclo: { include: { assinatura: true, pagamentos: true } } },
    });
    if (!pagamento) {
      this.log.warn(`Evento ${tipo}: pagamento local não encontrado (${asaasPaymentId})`);
      return;
    }

    switch (tipo) {
      case EVENTOS.recusado: {
        if (pagamento.status !== StatusPagamento.PENDENTE) return; // idempotente
        await this.prisma.pagamento.update({ where: { id: pagamento.id }, data: { status: StatusPagamento.CANCELADO } });
        const recusas = pagamento.ciclo.pagamentos.filter(
          (p) => p.forma === FormaPagamento.CARTAO && (p.status === StatusPagamento.CANCELADO || p.id === pagamento.id),
        ).length;
        if (recusas < TENTATIVAS_CARTAO) {
          const amanha = somarDias(this.clock.hoje(), 1);
          await this.prisma.pagamento.create({
            data: {
              cicloId: pagamento.cicloId,
              forma: FormaPagamento.CARTAO,
              valor: pagamento.valor.toString(),
              vencimento: new Date(`${amanha}T00:00:00.000Z`),
              status: StatusPagamento.PENDENTE,
            },
          });
          this.avisar(pagamento.ciclo.assinatura.clienteId, `Cartão recusado. Nova tentativa em ${amanha}.`);
        } else {
          this.avisar(pagamento.ciclo.assinatura.clienteId, 'Cartão recusado de novo. Escolha outra forma de pagamento.');
        }
        return;
      }
      case EVENTOS.vencido:
        if (pagamento.status === StatusPagamento.PENDENTE) {
          await this.prisma.pagamento.update({ where: { id: pagamento.id }, data: { status: StatusPagamento.VENCIDO } });
        }
        return;
      case EVENTOS.estornado:
        await this.registrarEstorno(pagamento.id, pagamento.cicloId);
        return;
      case EVENTOS.removido:
        if (pagamento.status === StatusPagamento.PENDENTE || pagamento.status === StatusPagamento.VENCIDO) {
          await this.prisma.pagamento.update({ where: { id: pagamento.id }, data: { status: StatusPagamento.CANCELADO } });
        }
        return;
      default:
        this.log.debug(`Evento ${tipo} registrado sem ação`);
    }
  }

  /**
   * Pagamento ESTORNADO. Ciclo ainda não pago: COBRADO→CANCELADO. Ciclo já PAGO: o diagrama não
   * tem PAGO→CANCELADO; o ciclo fica marcado `estornado` no CalculoPreco para não ser separado.
   */
  async registrarEstorno(pagamentoId: string, cicloId: string): Promise<void> {
    await this.prisma.$transaction(async (tx) => {
      await tx.pagamento.update({ where: { id: pagamentoId }, data: { status: StatusPagamento.ESTORNADO } });
      const ciclo = await tx.ciclo.findUnique({ where: { id: cicloId }, include: { calculoPreco: true } });
      if (!ciclo) return;
      if (ciclo.status === StatusCiclo.COBRADO) await this.maquina.ciclo(tx, ciclo, StatusCiclo.CANCELADO);
      await this.marcar(tx, cicloId, { estornado: true });
    });
  }

  private async marcar(tx: Db, cicloId: string, extra: Record<string, unknown>): Promise<void> {
    const calc = await tx.calculoPreco.findUnique({ where: { cicloId } });
    if (!calc) return;
    const fatores = { ...((calc.fatores as object | null) ?? {}), ...extra } as Prisma.InputJsonValue;
    await tx.calculoPreco.update({ where: { cicloId }, data: { fatores } });
  }

  /** Aviso ao cliente. Push e e-mail chegam em `cr-6-operacao`; até lá, log e status na fatura. */
  private avisar(clienteId: string, mensagem: string): void {
    this.log.log(`AVISO cliente=${clienteId}: ${mensagem}`);
  }

  /** Fake: confirma cobrança e aplica o mesmo efeito do webhook. */
  async confirmarFake(asaasPaymentId: string): Promise<void> {
    if (!this.gateway.confirmarPagamento) {
      throw new RegraNegocioException(
        'GATEWAY_INDISPONIVEL',
        'Confirmação manual só existe com ASAAS_MODE=fake.',
        HttpStatus.BAD_GATEWAY,
      );
    }
    await this.gateway.confirmarPagamento(asaasPaymentId);
    const pagamento = await this.prisma.pagamento.findFirst({ where: { asaasPaymentId } });
    if (!pagamento) {
      this.log.warn(`Pagamento local não encontrado para ${asaasPaymentId}`);
      return;
    }
    await this.confirmarPagamentoDoCiclo(pagamento.cicloId, asaasPaymentId);
  }
}
