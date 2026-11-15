import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  ArrayMaxSize,
  ArrayUnique,
  IsArray,
  IsBoolean,
  IsEnum,
  IsInt,
  IsNumber,
  IsOptional,
  IsString,
  Length,
  Matches,
  Max,
  Min,
} from 'class-validator';
import { DiaSemana } from '../../../prisma/generated/prisma/client';

const dinheiro = { maxDecimalPlaces: 2 };

export class AtualizarProdutoDto {
  @ApiPropertyOptional({ example: 9.9 })
  @IsOptional()
  @IsNumber(dinheiro, { message: 'Use um valor com até 2 casas.' })
  @Min(0.01)
  @Max(99999)
  precoBase?: number;

  @ApiPropertyOptional({ example: 7.5 })
  @IsOptional()
  @IsNumber(dinheiro, { message: 'Use um valor com até 2 casas.' })
  @Min(0.01)
  @Max(99999)
  precoPiso?: number;

  @ApiPropertyOptional({ example: 500, nullable: true })
  @IsOptional()
  @IsInt()
  @Min(0)
  estoque?: number;

  @ApiPropertyOptional({ example: true })
  @IsOptional()
  @IsBoolean()
  ativo?: boolean;
}

export class AtualizarFatorDto {
  @ApiProperty({
    example: 'DEMANDA_VERAO',
    description:
      'VOLUME_24_47, VOLUME_48_MAIS, COMPROMISSO_TRIMESTRAL, COMPROMISSO_EMPRESA, FIDELIDADE_POR_CICLO, FIDELIDADE_MAXIMO ou DEMANDA_*',
  })
  @IsString()
  @Matches(/^[A-Z0-9_]{3,40}$/)
  chave: string;

  @ApiProperty({ example: 0.05, description: 'Fração: 0,05 = 5%. Demanda pode ser negativa.' })
  @IsNumber({ maxDecimalPlaces: 4 })
  @Min(-1)
  @Max(1)
  valor: number;

  @ApiProperty({ example: '2027-12-01' })
  @Matches(/^\d{4}-\d{2}-\d{2}$/, { message: 'Use a data no formato AAAA-MM-DD.' })
  ativoDe: string;

  @ApiPropertyOptional({ example: '2028-03-31', nullable: true })
  @IsOptional()
  @Matches(/^\d{4}-\d{2}-\d{2}$/, { message: 'Use a data no formato AAAA-MM-DD.' })
  ativoAte?: string;
}

export class AtualizarZonaDto {
  @ApiPropertyOptional({ example: 9.9 })
  @IsOptional()
  @IsNumber(dinheiro, { message: 'Use um valor com até 2 casas.' })
  @Min(0)
  @Max(9999)
  taxaEntrega?: number;

  @ApiPropertyOptional({ enum: DiaSemana, isArray: true, example: ['SEG', 'QUA', 'SEX'] })
  @IsOptional()
  @IsArray()
  @ArrayUnique()
  @ArrayMaxSize(7)
  @IsEnum(DiaSemana, { each: true })
  diasEntrega?: DiaSemana[];

  @ApiPropertyOptional({ example: ['Copacabana', 'Ipanema'] })
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(500)
  @IsString({ each: true })
  @Length(1, 80, { each: true })
  bairros?: string[];

  @ApiPropertyOptional({ example: true })
  @IsOptional()
  @IsBoolean()
  ativa?: boolean;
}
