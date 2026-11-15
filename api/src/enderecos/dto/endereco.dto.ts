import { ApiProperty, ApiPropertyOptional, PartialType } from '@nestjs/swagger';
import { Transform } from 'class-transformer';
import { IsBoolean, IsOptional, IsString, Length, Matches, MaxLength } from 'class-validator';

const aparar = ({ value }: { value: unknown }) => (typeof value === 'string' ? value.trim() : value);

/** Logradouro, bairro e zona vêm do ViaCEP + seed; `lat`/`lng` ficam nulos até `cr-6-operacao`. */
export class CriarEnderecoDto {
  @ApiProperty({ example: '22041-001' })
  @Matches(/^\d{5}-?\d{3}$/, { message: 'Informe o CEP com 8 dígitos.' })
  cep: string;

  @ApiProperty({ example: '100' })
  @Transform(aparar)
  @IsString()
  @Length(1, 20, { message: 'Informe o número.' })
  numero: string;

  @ApiPropertyOptional({ example: 'Apto 301' })
  @IsOptional()
  @Transform(aparar)
  @IsString()
  @MaxLength(80)
  complemento?: string;

  @ApiPropertyOptional({ example: 'Casa', description: 'Casa, Trabalho, Academia…' })
  @IsOptional()
  @Transform(aparar)
  @IsString()
  @MaxLength(40)
  apelido?: string;

  @ApiPropertyOptional({ example: 'Em frente à padaria' })
  @IsOptional()
  @Transform(aparar)
  @IsString()
  @MaxLength(200)
  referencia?: string;

  @ApiPropertyOptional({ example: 'Portaria 24h' })
  @IsOptional()
  @Transform(aparar)
  @IsString()
  @MaxLength(300)
  instrucoes?: string;

  @ApiPropertyOptional({ example: true, description: 'O primeiro endereço é sempre principal' })
  @IsOptional()
  @IsBoolean()
  principal?: boolean;
}

export class AtualizarEnderecoDto extends PartialType(CriarEnderecoDto) {}
