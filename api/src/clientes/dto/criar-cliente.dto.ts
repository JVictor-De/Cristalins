import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Transform } from 'class-transformer';
import {
  Equals,
  IsBoolean,
  IsEmail,
  IsOptional,
  IsString,
  Length,
  Matches,
  MaxLength,
} from 'class-validator';

const aparar = ({ value }: { value: unknown }) => (typeof value === 'string' ? value.trim() : value);
const digitos = ({ value }: { value: unknown }) =>
  typeof value === 'string' ? value.replace(/\D/g, '') : value;

export class CriarClienteDto {
  @ApiProperty({ example: 'Ana Souza' })
  @Transform(aparar)
  @IsString()
  @Length(2, 120, { message: 'Informe o nome completo.' })
  nome: string;

  @ApiProperty({ example: '529.982.247-25', description: 'CPF (11 dígitos) ou CNPJ (14 dígitos); pontuação é ignorada' })
  @Transform(digitos)
  @IsString()
  @Matches(/^(\d{11}|\d{14})$/, { message: 'Informe um CPF ou CNPJ com todos os dígitos.' })
  cpfCnpj: string;

  @ApiProperty({ example: 'ana@exemplo.com' })
  @Transform(({ value }) => (typeof value === 'string' ? value.trim().toLowerCase() : value))
  @IsEmail({}, { message: 'Informe um e-mail válido.' })
  @MaxLength(254)
  email: string;

  @ApiPropertyOptional({ example: '21987654321', description: 'DDD + número' })
  @IsOptional()
  @Transform(digitos)
  @Matches(/^\d{10,11}$/, { message: 'Informe o celular com DDD.' })
  celular?: string;

  @ApiProperty({ example: '1995-05-10', description: 'AAAA-MM-DD; exige 18 anos ou mais' })
  @Matches(/^\d{4}-\d{2}-\d{2}$/, { message: 'Informe a data de nascimento no formato AAAA-MM-DD.' })
  dataNascimento: string;

  @ApiProperty({ example: 'senha-forte-123', minLength: 8, maxLength: 72 })
  @IsString()
  @Length(8, 72, { message: 'A senha precisa ter de 8 a 72 caracteres.' })
  senha: string;

  @ApiProperty({ example: true, description: 'Aceite dos termos de uso e da política de privacidade (RF04)' })
  @Equals(true, { message: 'É preciso aceitar os termos de uso e a política de privacidade.' })
  aceiteTermos: boolean;

  @ApiPropertyOptional({ example: false })
  @IsOptional()
  @IsBoolean()
  marketingOk?: boolean;
}
