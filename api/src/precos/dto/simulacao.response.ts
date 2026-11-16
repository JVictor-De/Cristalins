import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Frequencia, Plano } from '../../../prisma/generated/prisma/client';

export class ItemSimulado {
  @ApiProperty({ example: 'WP500' })
  produto: string;

  @ApiProperty({ example: 24 })
  quantidade: number;

  @ApiProperty({ example: 9.9 })
  precoBase: number;

  @ApiProperty({
    example: 8.47,
    description: 'Unitário exibido com 2 casas. O total usa o valor sem arredondar, então Σ unitário × qtd pode diferir em centavos',
  })
  precoUnitario: number;

  @ApiProperty({
    enum: ['PISO', 'TRAVA_MAXIMA', 'TRAVA_MINIMA', 'ADDON'],
    nullable: true,
    example: null,
    description: 'Regra que definiu o unitário, se houver',
  })
  regra: string | null;
}

export class FatoresSimulados {
  @ApiProperty({ example: 8, description: 'Percentual de desconto de volume' })
  volume: number;
  @ApiProperty({ example: 7 })
  compromisso: number;
  @ApiProperty({ example: 0 })
  fidelidade: number;
  @ApiProperty({ example: 0, description: 'Ajuste de demanda (positivo = acréscimo)' })
  demanda: number;
  @ApiProperty({ example: 0 })
  cupom: number;
}

export class LinhaDetalhePreco {
  @ApiProperty({ enum: ['VOLUME', 'COMPROMISSO', 'FIDELIDADE', 'DEMANDA', 'CUPOM', 'FRETE'], example: 'VOLUME' })
  fator: string;
  @ApiPropertyOptional({ example: -8, description: 'Percentual (descontos negativos)' })
  percentual?: number;
  @ApiPropertyOptional({ example: 9.9, description: 'Valor em reais (frete)' })
  valor?: number;
}

export class ZonaSimulada {
  @ApiProperty()
  id: string;
  @ApiProperty({ example: 'Zona Sul' })
  nome: string;
}

/** Exemplo: CT02 (24 WP500, Trimestral, 1º ciclo, novembro, Zona Sul). */
export class SimulacaoResponse {
  @ApiProperty({ example: '2026-11-16' })
  dataEntrega: string;
  @ApiProperty({ enum: Plano, example: Plano.TRIMESTRAL })
  plano: Plano;
  @ApiProperty({ enum: Frequencia, example: Frequencia.QUINZENAL })
  frequencia: Frequencia;
  @ApiProperty({ type: [ItemSimulado] })
  itens: ItemSimulado[];
  @ApiProperty({ example: 24, description: 'UE da cesta sem add-ons' })
  ue: number;
  @ApiProperty({ example: 12.72 })
  pesoKg: number;
  @ApiProperty({ example: 203.29 })
  subtotal: number;
  @ApiProperty({ example: 9.9 })
  frete: number;
  @ApiProperty({ example: 0 })
  creditos: number;
  @ApiProperty({ example: 213.19, description: 'Arredondado a 2 casas, meio para cima, só no final' })
  total: number;
  @ApiProperty({ type: FatoresSimulados })
  fatores: FatoresSimulados;
  @ApiProperty({
    type: [LinhaDetalhePreco],
    example: [
      { fator: 'VOLUME', percentual: -8 },
      { fator: 'COMPROMISSO', percentual: -7 },
      { fator: 'FRETE', valor: 9.9 },
    ],
  })
  detalhePreco: LinhaDetalhePreco[];
  @ApiProperty({ type: ZonaSimulada, nullable: true })
  zona: ZonaSimulada | null;

  @ApiProperty({ example: 12, description: 'UE mínima da cesta (48 no plano Empresa)' })
  ueMinima: number;

  @ApiProperty({ example: 120, description: 'UE máxima por entrega (exceto Empresa com atendimento comercial)' })
  ueMaxima: number;

  @ApiProperty({ example: 0, description: 'UE que faltam para atingir o mínimo (0 se a cesta já passa)' })
  faltaUeParaMinimo: number;

  @ApiProperty({ example: 250, description: 'Subtotal acima do qual o frete é grátis (RN18)' })
  freteGratisAcima: number;

  @ApiProperty({ example: 46.71, description: 'Quanto falta no subtotal para frete grátis (0 se já passou)' })
  faltaParaFreteGratis: number;

  @ApiProperty({
    example: 15.3,
    description: 'Economia em R$ do plano escolhido versus Flex (mesma cesta/fatores). 0 se o plano for Flex',
  })
  economiaPlano: number;
}
