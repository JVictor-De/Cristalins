import { ApiPropertyOptional } from '@nestjs/swagger';
import { Transform } from 'class-transformer';
import { IsBoolean, IsOptional, IsString, Length, Matches } from 'class-validator';

/** Só campos que o cliente pode alterar. CPF/CNPJ, e-mail e nascimento não mudam por aqui. */
export class AtualizarClienteDto {
  @ApiPropertyOptional({ example: 'Ana Souza Lima' })
  @IsOptional()
  @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value))
  @IsString()
  @Length(2, 120, { message: 'Informe o nome completo.' })
  nome?: string;

  @ApiPropertyOptional({ example: '21987654321' })
  @IsOptional()
  @Transform(({ value }) => (typeof value === 'string' ? value.replace(/\D/g, '') : value))
  @Matches(/^\d{10,11}$/, { message: 'Informe o celular com DDD.' })
  celular?: string;

  @ApiPropertyOptional({ example: true })
  @IsOptional()
  @IsBoolean()
  marketingOk?: boolean;
}
