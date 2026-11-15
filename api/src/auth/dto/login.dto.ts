import { ApiProperty } from '@nestjs/swagger';
import { Transform } from 'class-transformer';
import { IsEmail, IsString, Length } from 'class-validator';

export class LoginDto {
  @ApiProperty({ example: 'ana.teste@cristalins.local' })
  @Transform(({ value }) => (typeof value === 'string' ? value.trim().toLowerCase() : value))
  @IsEmail({}, { message: 'Informe um e-mail válido.' })
  email: string;

  @ApiProperty({ example: 'cristalins-dev-123' })
  @IsString()
  @Length(1, 72, { message: 'Informe a senha.' })
  senha: string;
}

export class RefreshDto {
  @ApiProperty({ description: 'refreshToken recebido no login ou no cadastro' })
  @IsString()
  @Length(1, 4096, { message: 'Informe o refreshToken.' })
  refreshToken: string;
}
