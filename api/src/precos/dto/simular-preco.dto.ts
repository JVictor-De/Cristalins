import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Transform, Type } from 'class-transformer';
import {
  ArrayMaxSize,
  ArrayMinSize,
  IsArray,
  IsEnum,
  IsInt,
  IsOptional,
  IsString,
  Length,
  Matches,
  Max,
  Min,
  ValidateNested,
} from 'class-validator';
import { Frequencia, Plano } from '../../../prisma/generated/prisma/client';

export class ItemSimulacaoDto {
  @ApiProperty({ example: 'WP500', description: 'Código do produto' })
  @Transform(({ value }) => (typeof value === 'string' ? value.trim().toUpperCase() : value))
  @IsString()
  @Length(1, 20)
  produto: string;

  @ApiProperty({ example: 24, minimum: 1 })
  @IsInt({ message: 'A quantidade precisa ser um número inteiro.' })
  @Min(1, { message: 'A quantidade precisa ser maior que zero.' })
  @Max(10000)
  quantidade: number;
}

export class SimularPrecoDto {
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

  @ApiProperty({ enum: Plano, example: Plano.TRIMESTRAL })
  @IsEnum(Plano)
  plano: Plano;

  @ApiPropertyOptional({ description: 'Zona para o frete (sem zona e sem endereço, frete 0)' })
  @IsOptional()
  @IsString()
  zonaId?: string;

  @ApiPropertyOptional({ description: 'Endereço do próprio cliente; a zona dele define o frete' })
  @IsOptional()
  @IsString()
  enderecoId?: string;

  @ApiPropertyOptional({ example: 'BEMVINDO10' })
  @IsOptional()
  @Transform(({ value }) => (typeof value === 'string' ? value.trim().toUpperCase() : value))
  @IsString()
  @Length(1, 40)
  cupom?: string;

  @ApiPropertyOptional({ example: '2026-11-16', description: 'AAAA-MM-DD; define a demanda. Padrão: hoje (São Paulo)' })
  @IsOptional()
  @Matches(/^\d{4}-\d{2}-\d{2}$/, { message: 'Use a data no formato AAAA-MM-DD.' })
  dataEntrega?: string;

  @ApiPropertyOptional({ description: 'Ciclo anterior da assinatura: trava de ±10% e fidelidade' })
  @IsOptional()
  @IsString()
  cicloAnteriorId?: string;
}
