import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Frequencia } from '../../../prisma/generated/prisma/client';

export class ItemRecomendado {
  @ApiProperty({ example: 'WP500' })
  produto: string;

  @ApiProperty({ example: 12 })
  quantidade: number;
}

export class ContatoComercial {
  @ApiProperty({ example: 'contato@cristalins.com.br' })
  email: string;

  @ApiProperty({ example: '(14) 3523-1001' })
  telefone: string;
}

/** Resposta do quiz (exemplo do Anexo: caso A). Dinheiro em número com 2 casas. */
export class RecomendacaoResponse {
  @ApiProperty({ example: '0b6e3c1a-2f0d-4d1e-9a51-7c1c7c3f2a10' })
  id: string;

  @ApiProperty({ example: 'KIT-TREINO', nullable: true, type: String, description: 'Nulo no perfil Empresa' })
  kit: string | null;

  @ApiProperty({ example: 1 })
  multiplicador: number;

  @ApiProperty({ enum: Frequencia, example: Frequencia.QUINZENAL })
  frequencia: Frequencia;

  @ApiProperty({ type: [ItemRecomendado], example: [{ produto: 'WP500', quantidade: 12 }] })
  itens: ItemRecomendado[];

  @ApiProperty({ example: 12, description: 'UE da cesta (RN01)' })
  ue: number;

  @ApiProperty({
    example: 118.8,
    nullable: true,
    type: Number,
    description: 'Plano Flex, sem fidelidade e sem frete; nulo no perfil Empresa',
  })
  valorEstimado: number | null;

  @ApiProperty({ example: false })
  perfilEmpresa: boolean;

  @ApiPropertyOptional({ type: ContatoComercial, description: 'Só no perfil Empresa' })
  contatoComercial?: ContatoComercial;

  @ApiProperty({ example: '2026-11-14T15:00:00.000Z' })
  criadoEm: string;
}
