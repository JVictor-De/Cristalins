import { Injectable } from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import {
  CartaoParaTokenizar,
  CartaoTokenizado,
  ClienteGateway,
  CobrancaCriada,
  CobrancaDetalhe,
  CriarCobrancaCartao,
  CriarCobrancaPix,
  PagamentoGateway,
  PixQrCode,
} from './pagamento.gateway';

interface CobrancaMemoria extends CobrancaCriada {
  customerId: string;
  confirmado: boolean;
  tipo: 'PIX' | 'BOLETO' | 'CREDIT_CARD';
  token?: string;
  criadaEm: string;
}

/**
 * Gateway em memória (`ASAAS_MODE=fake`): testes e plano B da apresentação, sem rede.
 * `confirmarPagamento` simula o botão "Confirmar pagamento" do sandbox.
 * Cartão: guarda só token, bandeira e final (o número e o CVV não ficam em lugar nenhum).
 */
@Injectable()
export class FakeGateway implements PagamentoGateway {
  readonly clientes = new Map<string, string>(); // cpfCnpj → asaas id
  readonly cobrancas = new Map<string, CobrancaMemoria>();
  readonly confirmados = new Set<string>();
  readonly estornados = new Set<string>();
  readonly cancelados = new Set<string>();
  readonly tokens = new Map<string, CartaoTokenizado>();

  async criarCliente(dados: ClienteGateway): Promise<string> {
    const existente = this.clientes.get(dados.cpfCnpj);
    if (existente) return existente;
    const id = `cus_fake_${randomUUID().slice(0, 8)}`;
    this.clientes.set(dados.cpfCnpj, id);
    return id;
  }

  private registrar(dados: CriarCobrancaPix, tipo: CobrancaMemoria['tipo'], token?: string): CobrancaMemoria {
    const id = `pay_fake_${randomUUID().slice(0, 8)}`;
    const cobranca: CobrancaMemoria = {
      id,
      status: 'PENDING',
      valor: dados.valor,
      vencimento: dados.vencimento,
      externalReference: dados.externalReference,
      customerId: dados.customerId,
      confirmado: false,
      tipo,
      token,
      criadaEm: new Date().toISOString().slice(0, 10),
    };
    this.cobrancas.set(id, cobranca);
    return cobranca;
  }

  private detalhe(c: CobrancaMemoria): CobrancaDetalhe {
    return {
      id: c.id,
      status: c.status,
      valor: c.valor,
      vencimento: c.vencimento,
      externalReference: c.externalReference,
      linkFatura: `https://fake.asaas.local/i/${c.id}`,
      linkBoleto: c.tipo === 'BOLETO' ? `https://fake.asaas.local/b/${c.id}` : null,
      comprovante: c.confirmado ? `https://fake.asaas.local/comprovantes/${c.id}` : null,
    };
  }

  private buscar(paymentId: string): CobrancaMemoria {
    const c = this.cobrancas.get(paymentId);
    if (!c) throw new Error(`Cobrança fake não encontrada: ${paymentId}`);
    return c;
  }

  async criarCobrancaPix(dados: CriarCobrancaPix): Promise<CobrancaCriada> {
    return this.registrar(dados, 'PIX');
  }

  async obterPixQrCode(paymentId: string): Promise<PixQrCode> {
    this.buscar(paymentId);
    return {
      copiaECola: `00020126FAKE-PIX-${paymentId}`,
      qrCodeBase64: Buffer.from(`qr-${paymentId}`).toString('base64'),
    };
  }

  async criarCobrancaBoleto(dados: CriarCobrancaPix): Promise<CobrancaDetalhe> {
    return this.detalhe(this.registrar(dados, 'BOLETO'));
  }

  async tokenizarCartao(dados: CartaoParaTokenizar): Promise<CartaoTokenizado> {
    const digitos = dados.numero.replace(/\D/g, '');
    const bandeira = digitos.startsWith('4') ? 'VISA' : digitos.startsWith('5') ? 'MASTERCARD' : 'OUTRA';
    const cartao = { token: `tok_fake_${randomUUID().slice(0, 8)}`, bandeira, final: digitos.slice(-4) };
    this.tokens.set(cartao.token, cartao);
    return cartao;
  }

  async criarCobrancaCartao(dados: CriarCobrancaCartao): Promise<CobrancaDetalhe> {
    if (!this.tokens.has(dados.token)) throw new Error('Token de cartão desconhecido no fake');
    return this.detalhe(this.registrar(dados, 'CREDIT_CARD', dados.token));
  }

  async obterCobranca(paymentId: string): Promise<CobrancaDetalhe> {
    return this.detalhe(this.buscar(paymentId));
  }

  async estornar(paymentId: string): Promise<void> {
    this.buscar(paymentId).status = 'REFUNDED';
    this.estornados.add(paymentId);
  }

  async cancelarCobranca(paymentId: string): Promise<void> {
    this.buscar(paymentId).status = 'DELETED';
    this.cancelados.add(paymentId);
  }

  async listarCobrancas(desde: string): Promise<CobrancaDetalhe[]> {
    return [...this.cobrancas.values()].filter((c) => c.criadaEm >= desde).map((c) => this.detalhe(c));
  }

  async confirmarPagamento(paymentId: string): Promise<void> {
    const c = this.buscar(paymentId);
    c.confirmado = true;
    c.status = 'RECEIVED';
    this.confirmados.add(paymentId);
  }
}
