/** Porta de pagamento (CONTEXTO). Escolhida por `ASAAS_MODE=sandbox|producao|fake`. */

export const PAGAMENTO_GATEWAY = Symbol('PAGAMENTO_GATEWAY');

export interface ClienteGateway {
  id: string;
  nome: string;
  cpfCnpj: string;
  email: string;
  celular?: string | null;
}

export interface CriarCobrancaPix {
  customerId: string;
  valor: number;
  vencimento: string; // AAAA-MM-DD
  externalReference: string; // id do ciclo
  descricao?: string;
}

export interface CobrancaCriada {
  id: string;
  status: string;
  valor: number;
  vencimento: string;
  externalReference: string;
}

export interface PixQrCode {
  copiaECola: string;
  qrCodeBase64: string;
}

export interface PagamentoGateway {
  criarCliente(dados: ClienteGateway): Promise<string>;
  criarCobrancaPix(dados: CriarCobrancaPix): Promise<CobrancaCriada>;
  obterPixQrCode(paymentId: string): Promise<PixQrCode>;
  /** Fake / plano B: confirma pagamento sob comando (não existe no Asaas real). */
  confirmarPagamento?(paymentId: string): Promise<void>;
}
