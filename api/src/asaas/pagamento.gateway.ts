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

/** Dados do cartão: só em memória, a caminho do Asaas. Nunca persistir nem registrar em log. */
export interface CartaoParaTokenizar {
  customerId: string;
  nomeNoCartao: string;
  numero: string;
  mesValidade: string; // MM
  anoValidade: string; // AAAA
  cvv: string;
  titular: { nome: string; email: string; cpfCnpj: string; cep: string; numeroEndereco: string; telefone: string };
  ipRemoto: string;
}

export interface CartaoTokenizado {
  token: string;
  bandeira: string;
  final: string; // 4 últimos dígitos
}

export interface CriarCobrancaCartao extends CriarCobrancaPix {
  token: string;
  ipRemoto?: string;
}

/** Cobrança no Asaas com os links que o app mostra. */
export interface CobrancaDetalhe {
  id: string;
  status: string;
  valor: number;
  vencimento: string;
  externalReference: string | null;
  linkFatura: string | null; // invoiceUrl
  linkBoleto: string | null; // bankSlipUrl
  comprovante: string | null; // transactionReceiptUrl (pagas)
}

export interface PagamentoGateway {
  criarCliente(dados: ClienteGateway): Promise<string>;
  criarCobrancaPix(dados: CriarCobrancaPix): Promise<CobrancaCriada>;
  obterPixQrCode(paymentId: string): Promise<PixQrCode>;
  /** Boleto (RN25: vence em D-5). Devolve o link do boleto em `linkBoleto`. */
  criarCobrancaBoleto(dados: CriarCobrancaPix): Promise<CobrancaDetalhe>;
  /** `POST /v3/creditCard/tokenize`. */
  tokenizarCartao(dados: CartaoParaTokenizar): Promise<CartaoTokenizado>;
  /** Cobrança no cartão com o token salvo (`billingType: CREDIT_CARD`). */
  criarCobrancaCartao(dados: CriarCobrancaCartao): Promise<CobrancaDetalhe>;
  obterCobranca(paymentId: string): Promise<CobrancaDetalhe>;
  /** RN14: estorno integral. */
  estornar(paymentId: string): Promise<void>;
  /** Régua +30: cobrança encerrada. */
  cancelarCobranca(paymentId: string): Promise<void>;
  /** Conciliação: cobranças criadas a partir de `desde` (AAAA-MM-DD). */
  listarCobrancas(desde: string): Promise<CobrancaDetalhe[]>;
  /** Fake / plano B: confirma pagamento sob comando (não existe no Asaas real). */
  confirmarPagamento?(paymentId: string): Promise<void>;
}
