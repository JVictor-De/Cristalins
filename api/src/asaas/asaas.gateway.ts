import { HttpStatus, Injectable, Logger } from '@nestjs/common';
import { RegraNegocioException } from '../common/regra-negocio.exception';
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

const USER_AGENT = 'CristalinsAssinatura/0.1.0';

/**
 * HTTP real do Asaas (`ASAAS_MODE=sandbox|producao`).
 * Lê só nomes de env em runtime — nunca hardcode de chave.
 * Falhas viram `PAGAMENTO_INDISPONIVEL` (não `ERRO_INTERNO` / "Erro inesperado").
 */
@Injectable()
export class AsaasGateway implements PagamentoGateway {
  private readonly log = new Logger(AsaasGateway.name);

  private baseUrl(): string {
    const url = process.env.ASAAS_API_URL?.replace(/\/$/, '');
    if (!url) this.falha('ASAAS_API_URL não configurada');
    return url;
  }

  private chave(): string {
    const key = process.env.ASAAS_API_KEY;
    if (!key) this.falha('ASAAS_API_KEY não configurada');
    return key;
  }

  /** Nunca lançar `Error` cru: o filtro vira "Erro inesperado" sem código útil no app. */
  private falha(detalhe: string): never {
    this.log.warn(detalhe);
    throw new RegraNegocioException(
      'PAGAMENTO_INDISPONIVEL',
      'Não conseguimos falar com o pagamento agora. Tente de novo em instantes.',
      HttpStatus.SERVICE_UNAVAILABLE,
    );
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
      this.falha(`Asaas ${method} ${path} → ${res.status}: ${texto.slice(0, 200)}`);
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

  async criarCobrancaBoleto(dados: CriarCobrancaPix): Promise<CobrancaDetalhe> {
    const r = await this.request<PagamentoAsaas>('POST', '/payments', {
      customer: dados.customerId,
      billingType: 'BOLETO',
      value: dados.valor,
      dueDate: dados.vencimento,
      externalReference: dados.externalReference,
      description: dados.descricao ?? 'Ciclo Cristalins',
    });
    return detalhe(r);
  }

  /**
   * `POST /v3/creditCard/tokenize`. O corpo leva número e CVV só nesta chamada; nada disso é
   * guardado nem registrado em log (o log de erro abaixo só mostra o status HTTP).
   */
  async tokenizarCartao(d: CartaoParaTokenizar): Promise<CartaoTokenizado> {
    const r = await this.request<{ creditCardToken: string; creditCardBrand: string; creditCardNumber: string }>(
      'POST',
      '/creditCard/tokenize',
      {
        customer: d.customerId,
        creditCard: {
          holderName: d.nomeNoCartao,
          number: d.numero,
          expiryMonth: d.mesValidade,
          expiryYear: d.anoValidade,
          ccv: d.cvv,
        },
        creditCardHolderInfo: {
          name: d.titular.nome,
          email: d.titular.email,
          cpfCnpj: d.titular.cpfCnpj,
          postalCode: d.titular.cep,
          addressNumber: d.titular.numeroEndereco,
          phone: d.titular.telefone,
        },
        remoteIp: d.ipRemoto,
      },
    );
    return { token: r.creditCardToken, bandeira: r.creditCardBrand, final: r.creditCardNumber.slice(-4) };
  }

  async criarCobrancaCartao(dados: CriarCobrancaCartao): Promise<CobrancaDetalhe> {
    const r = await this.request<PagamentoAsaas>('POST', '/payments', {
      customer: dados.customerId,
      billingType: 'CREDIT_CARD',
      value: dados.valor,
      dueDate: dados.vencimento,
      externalReference: dados.externalReference,
      description: dados.descricao ?? 'Ciclo Cristalins',
      creditCardToken: dados.token,
      ...(dados.ipRemoto && { remoteIp: dados.ipRemoto }),
    });
    return detalhe(r);
  }

  async obterCobranca(paymentId: string): Promise<CobrancaDetalhe> {
    return detalhe(await this.request<PagamentoAsaas>('GET', `/payments/${paymentId}`));
  }

  async estornar(paymentId: string): Promise<void> {
    await this.request('POST', `/payments/${paymentId}/refund`, {});
  }

  async cancelarCobranca(paymentId: string): Promise<void> {
    await this.request('DELETE', `/payments/${paymentId}`);
  }

  async listarCobrancas(desde: string): Promise<CobrancaDetalhe[]> {
    const todas: CobrancaDetalhe[] = [];
    for (let offset = 0; ; offset += 100) {
      const r = await this.request<{ data: PagamentoAsaas[]; hasMore: boolean }>(
        'GET',
        `/payments?dateCreated%5Bge%5D=${desde}&limit=100&offset=${offset}`,
      );
      todas.push(...r.data.map(detalhe));
      if (!r.hasMore) return todas;
    }
  }
}

/** Campos do objeto `payment` do Asaas que a API usa. */
interface PagamentoAsaas {
  id: string;
  status: string;
  value: number;
  dueDate: string;
  externalReference?: string | null;
  invoiceUrl?: string | null;
  bankSlipUrl?: string | null;
  transactionReceiptUrl?: string | null;
}

function detalhe(p: PagamentoAsaas): CobrancaDetalhe {
  return {
    id: p.id,
    status: p.status,
    valor: p.value,
    vencimento: p.dueDate,
    externalReference: p.externalReference ?? null,
    linkFatura: p.invoiceUrl ?? null,
    linkBoleto: p.bankSlipUrl ?? null,
    comprovante: p.transactionReceiptUrl ?? null,
  };
}
