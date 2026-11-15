import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  FormaPagamento,
  Frequencia,
  Janela,
  Plano,
  StatusAssinatura,
  StatusCiclo,
} from '../../../prisma/generated/prisma/client';
import { LinhaDetalhePreco } from '../../precos/dto/simulacao.response';

export class ItemAssinaturaResponse {
  @ApiProperty({ example: 'WP500' }) produto: string;
  @ApiProperty({ example: 24 }) quantidade: number;
}

export class ItemCicloResponse extends ItemAssinaturaResponse {
  @ApiProperty({ example: 8.47 }) precoUnitario: number;
}

export class EnderecoResumo {
  @ApiProperty() id: string;
  @ApiPropertyOptional({ nullable: true, type: String, example: 'Casa' }) apelido: string | null;
  @ApiProperty({ example: 'Copacabana' }) bairro: string;
  @ApiProperty({ example: 'Zona Sul' }) zona: string;
}

export class CicloResponse {
  @ApiProperty() id: string;
  @ApiProperty({ example: 1 }) numero: number;
  @ApiProperty({ example: '2026-11-16' }) dataEntrega: string;
  @ApiProperty({ example: '2026-11-15T02:59:59.999Z', description: 'Corte: 23h59 de D-2 em São Paulo' }) dataCorte: string;
  @ApiProperty({ enum: StatusCiclo }) status: StatusCiclo;
  @ApiProperty({ enum: Janela }) janela: Janela;
  @ApiProperty() enderecoId: string;
  @ApiProperty({ nullable: true, type: Number, example: 213.19, description: 'Nulo até a cesta ser travada (D-5)' }) valor: number | null;
  @ApiProperty({ type: [ItemCicloResponse] }) itens: ItemCicloResponse[];
  @ApiPropertyOptional({ enum: ['PULO', 'PAUSA', 'CANCELAMENTO'], description: 'Por que o ciclo não será entregue' })
  motivoPulo?: string;
  @ApiPropertyOptional({ nullable: true, example: { status: 'PENDENTE', valor: 213.19, vencimento: '2026-11-14' } })
  pagamento: { status: string; valor: number; vencimento: string } | null;
}

export class AssinaturaResponse {
  @ApiProperty() id: string;
  @ApiProperty({ enum: StatusAssinatura, example: StatusAssinatura.AGUARDANDO_PAGAMENTO }) status: StatusAssinatura;
  @ApiProperty({ enum: Plano }) plano: Plano;
  @ApiProperty({ enum: Frequencia }) frequencia: Frequencia;
  @ApiProperty({ enum: Janela }) janela: Janela;
  @ApiProperty({ enum: FormaPagamento }) formaPagamento: FormaPagamento;
  @ApiPropertyOptional({ nullable: true, type: String, example: 'BEMVINDO10' }) cupom: string | null;
  @ApiProperty({ type: EnderecoResumo }) endereco: EnderecoResumo;
  @ApiProperty({ type: [ItemAssinaturaResponse] }) itens: ItemAssinaturaResponse[];
  @ApiProperty({ nullable: true, type: String, example: '2026-11-16', description: 'Próxima entrega em aberto' })
  proximaEntrega: string | null;
  @ApiProperty({ nullable: true, type: String, example: '2026-11-16' }) inicio: string | null;
  @ApiProperty({ nullable: true, type: String, example: '2027-02-16', description: 'Trimestral: +3 meses; Empresa: +6' })
  fimCompromisso: string | null;
}

export class PixResponse {
  @ApiProperty({ example: '00020126...' }) copiaECola: string;
  @ApiProperty({ example: 'iVBOR...' }) qrCodeBase64: string;
}

export class CicloCriado {
  @ApiProperty() id: string;
  @ApiProperty({ example: 1 }) numero: number;
  @ApiProperty({ example: 213.19 }) valor: number;
  @ApiProperty({ example: '2026-11-14', description: 'Cobrança do 1º ciclo: hoje' }) vencimento: string;
  @ApiProperty({ example: '2026-11-16', description: 'Estimativa; recalculada na confirmação do pagamento (RN08)' }) dataEntrega: string;
  @ApiProperty({ example: '2026-11-15T02:59:59.999Z' }) dataCorte: string;
  @ApiPropertyOptional({ type: PixResponse, description: 'Presente quando formaPagamento=PIX (cr-3-gateway)' })
  pix?: PixResponse;
}

/** Exemplo do Anexo (CT02), com `ciclo.pix` quando PIX. */
export class AssinaturaCriadaResponse extends AssinaturaResponse {
  @ApiProperty({ type: CicloCriado }) ciclo: CicloCriado;
  @ApiProperty({
    type: [LinhaDetalhePreco],
    example: [
      { fator: 'VOLUME', percentual: -8 },
      { fator: 'COMPROMISSO', percentual: -7 },
      { fator: 'FRETE', valor: 9.9 },
    ],
  })
  detalhePreco: LinhaDetalhePreco[];
}

export class AplicacaoResponse {
  @ApiProperty({ example: 2 }) numero: number;
  @ApiProperty({ example: '2026-11-30' }) dataEntrega: string;
}

export class AssinaturaAlteradaResponse extends AssinaturaResponse {
  @ApiProperty({ type: AplicacaoResponse, description: 'Antes do corte: próxima entrega; depois: a seguinte (RN09)' })
  aplicadaAPartirDe: AplicacaoResponse;
}

export class EntregaPuladaResponse extends AssinaturaResponse {
  @ApiProperty({ type: CicloResponse }) pulada: CicloResponse;
}

export class AssinaturaCanceladaResponse extends AssinaturaResponse {
  @ApiProperty({ example: 30.6, description: 'RN13: diferença do desconto de compromisso sobre os ciclos pagos (cobrada em cr-5)' })
  diferencaCompromisso: number;
  @ApiProperty({ example: 2 }) ciclosPagos: number;
}
