import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Transform, Type } from 'class-transformer';
import {
  ArrayMaxSize,
  ArrayMinSize,
  IsArray,
  IsEnum,
  IsIn,
  IsOptional,
  IsString,
  Length,
  ValidateNested,
} from 'class-validator';
import { FormaPagamento, Frequencia, Janela, Plano } from '../../../prisma/generated/prisma/client';
import { ItemSimulacaoDto } from '../../precos/dto/simular-preco.dto';

/** RF13: Flex ou Trimestral no app; Empresa só pelo comercial. */
export const PLANOS_DO_APP = [Plano.FLEX, Plano.TRIMESTRAL] as const;
/** AP2: só Pix (cartão e boleto em `cr-5-cobranca`). */
export const FORMAS_DA_AP2 = [FormaPagamento.PIX] as const;

const maiusculas = ({ value }: { value: unknown }) => (typeof value === 'string' ? value.trim().toUpperCase() : value);

export class CriarAssinaturaDto {
  @ApiPropertyOptional({ description: 'Recomendação do quiz que originou a cesta (do próprio cliente)' })
  @IsOptional()
  @IsString()
  recomendacaoId?: string;

  @ApiProperty({ type: [ItemSimulacaoDto], example: [{ produto: 'WP500', quantidade: 24 }] })
  @IsArray()
  @ArrayMinSize(1, { message: 'Adicione ao menos um item à cesta.' })
  @ArrayMaxSize(50)
  @ValidateNested({ each: true })
  @Type(() => ItemSimulacaoDto)
  itens: ItemSimulacaoDto[];

  @ApiProperty({ enum: Frequencia, example: Frequencia.QUINZENAL })
  @IsEnum(Frequencia)
  frequencia: Frequencia;

  @ApiProperty({ enum: PLANOS_DO_APP, example: Plano.TRIMESTRAL })
  @IsIn(PLANOS_DO_APP, { message: 'No app, escolha o plano Flex ou Trimestral. O plano Empresa é pelo comercial.' })
  plano: Plano;

  @ApiProperty({ description: 'Endereço do próprio cliente' })
  @IsString()
  enderecoId: string;

  @ApiProperty({ enum: Janela, example: Janela.MANHA, description: 'Manhã 8h–12h ou tarde 13h–18h' })
  @IsEnum(Janela)
  janela: Janela;

  @ApiProperty({ enum: FORMAS_DA_AP2, example: FormaPagamento.PIX })
  @IsIn(FORMAS_DA_AP2, { message: 'Por enquanto o pagamento é só por Pix.' })
  formaPagamento: FormaPagamento;

  @ApiPropertyOptional({ example: 'BEMVINDO10' })
  @IsOptional()
  @Transform(maiusculas)
  @IsString()
  @Length(1, 40)
  cupom?: string;
}

/** PUT /assinaturas/{id}: alterações respeitam o corte D-2 (RN09). */
export class AlterarAssinaturaDto {
  @ApiPropertyOptional({ type: [ItemSimulacaoDto] })
  @IsOptional()
  @IsArray()
  @ArrayMinSize(1)
  @ArrayMaxSize(50)
  @ValidateNested({ each: true })
  @Type(() => ItemSimulacaoDto)
  itens?: ItemSimulacaoDto[];

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  enderecoId?: string;

  @ApiPropertyOptional({ enum: Frequencia })
  @IsOptional()
  @IsEnum(Frequencia)
  frequencia?: Frequencia;

  @ApiPropertyOptional({ enum: PLANOS_DO_APP })
  @IsOptional()
  @IsIn(PLANOS_DO_APP, { message: 'No app, escolha o plano Flex ou Trimestral.' })
  plano?: Plano;

  @ApiPropertyOptional({ enum: Janela })
  @IsOptional()
  @IsEnum(Janela)
  janela?: Janela;

  @ApiPropertyOptional({ enum: FORMAS_DA_AP2 })
  @IsOptional()
  @IsIn(FORMAS_DA_AP2, { message: 'Por enquanto o pagamento é só por Pix.' })
  formaPagamento?: FormaPagamento;

  @ApiPropertyOptional({ example: 'BEMVINDO10', description: 'Um cupom por assinatura (RN21)' })
  @IsOptional()
  @Transform(maiusculas)
  @IsString()
  @Length(1, 40)
  cupom?: string;
}

export class PausarAssinaturaDto {
  @ApiProperty({ enum: [1, 2], example: 1, description: 'Ciclos a pausar (RN11)' })
  @IsIn([1, 2], { message: 'Pause 1 ou 2 entregas.' })
  ciclos: 1 | 2;
}
