import { Injectable } from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import {
  ClienteGateway,
  CobrancaCriada,
  CriarCobrancaPix,
  PagamentoGateway,
  PixQrCode,
} from './pagamento.gateway';

interface CobrancaMemoria extends CobrancaCriada {
  customerId: string;
  confirmado: boolean;
}

/**
 * Gateway em memória (`ASAAS_MODE=fake`): testes e plano B da apresentação, sem rede.
 * `confirmarPagamento` simula o botão "Confirmar pagamento" do sandbox.
 */
@Injectable()
export class FakeGateway implements PagamentoGateway {
  readonly clientes = new Map<string, string>(); // cpfCnpj → asaas id
  readonly cobrancas = new Map<string, CobrancaMemoria>();
  readonly confirmados = new Set<string>();

  async criarCliente(dados: ClienteGateway): Promise<string> {
    const existente = this.clientes.get(dados.cpfCnpj);
    if (existente) return existente;
    const id = `cus_fake_${randomUUID().slice(0, 8)}`;
    this.clientes.set(dados.cpfCnpj, id);
    return id;
  }

  async criarCobrancaPix(dados: CriarCobrancaPix): Promise<CobrancaCriada> {
    const id = `pay_fake_${randomUUID().slice(0, 8)}`;
    const cobranca: CobrancaMemoria = {
      id,
      status: 'PENDING',
      valor: dados.valor,
      vencimento: dados.vencimento,
      externalReference: dados.externalReference,
      customerId: dados.customerId,
      confirmado: false,
    };
    this.cobrancas.set(id, cobranca);
    return cobranca;
  }

  async obterPixQrCode(paymentId: string): Promise<PixQrCode> {
    const c = this.cobrancas.get(paymentId);
    if (!c) throw new Error(`Cobrança fake não encontrada: ${paymentId}`);
    return {
      copiaECola: `00020126FAKE-PIX-${paymentId}`,
      qrCodeBase64: Buffer.from(`qr-${paymentId}`).toString('base64'),
    };
  }

  async confirmarPagamento(paymentId: string): Promise<void> {
    const c = this.cobrancas.get(paymentId);
    if (!c) throw new Error(`Cobrança fake não encontrada: ${paymentId}`);
    c.confirmado = true;
    c.status = 'RECEIVED';
    this.confirmados.add(paymentId);
  }
}
