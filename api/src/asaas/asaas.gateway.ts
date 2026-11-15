import { Injectable, Logger } from '@nestjs/common';
import {
  ClienteGateway,
  CobrancaCriada,
  CriarCobrancaPix,
  PagamentoGateway,
  PixQrCode,
} from './pagamento.gateway';

const USER_AGENT = 'CristalinsAssinatura/0.1.0';

/**
 * HTTP real do Asaas (`ASAAS_MODE=sandbox|producao`).
 * Lê só nomes de env em runtime — nunca hardcode de chave.
 */
@Injectable()
export class AsaasGateway implements PagamentoGateway {
  private readonly log = new Logger(AsaasGateway.name);

  private baseUrl(): string {
    const url = process.env.ASAAS_API_URL?.replace(/\/$/, '');
    if (!url) throw new Error('ASAAS_API_URL não configurada');
    return url;
  }

  private chave(): string {
    const key = process.env.ASAAS_API_KEY;
    if (!key) throw new Error('ASAAS_API_KEY não configurada');
    return key;
  }

  private async request<T>(method: string, path: string, body?: unknown): Promise<T> {
    const res = await fetch(`${this.baseUrl()}${path}`, {
      method,
      headers: {
        'Content-Type': 'application/json',
        access_token: this.chave(),
        'User-Agent': USER_AGENT,
      },
      body: body === undefined ? undefined : JSON.stringify(body),
    });
    const texto = await res.text();
    let json: unknown = null;
    try {
      json = texto ? JSON.parse(texto) : null;
    } catch {
      json = { raw: texto };
    }
    if (!res.ok) {
      this.log.warn(`Asaas ${method} ${path} → ${res.status}`);
      throw new Error(`Asaas ${res.status}: ${texto.slice(0, 200)}`);
    }
    return json as T;
  }

  async criarCliente(dados: ClienteGateway): Promise<string> {
    const r = await this.request<{ id: string }>('POST', '/customers', {
      name: dados.nome,
      cpfCnpj: dados.cpfCnpj,
      email: dados.email,
      mobilePhone: dados.celular ?? undefined,
    });
    return r.id;
  }

  async criarCobrancaPix(dados: CriarCobrancaPix): Promise<CobrancaCriada> {
    const r = await this.request<{
      id: string;
      status: string;
      value: number;
      dueDate: string;
      externalReference: string;
    }>('POST', '/payments', {
      customer: dados.customerId,
      billingType: 'PIX',
      value: dados.valor,
      dueDate: dados.vencimento,
      externalReference: dados.externalReference,
      description: dados.descricao ?? 'Ciclo Cristalins',
    });
    return {
      id: r.id,
      status: r.status,
      valor: r.value,
      vencimento: r.dueDate,
      externalReference: r.externalReference,
    };
  }

  async obterPixQrCode(paymentId: string): Promise<PixQrCode> {
    const r = await this.request<{ encodedImage: string; payload: string }>(
      'GET',
      `/payments/${paymentId}/pixQrCode`,
    );
    return { copiaECola: r.payload, qrCodeBase64: r.encodedImage };
  }
}
