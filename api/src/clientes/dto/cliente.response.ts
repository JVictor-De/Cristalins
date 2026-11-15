import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Papel } from '../../../prisma/generated/prisma/client';
import { TokensResponse } from '../../auth/dto/tokens.response';

/** Perfil do cliente, sem `senhaHash` nem dados internos (Asaas, push). */
export class ClienteResponse {
  @ApiProperty({ example: '6f1c2c8e-5b1a-4c55-9a43-0f7d8f2a1b11' })
  id: string;

  @ApiProperty({ example: 'Ana Souza' })
  nome: string;

  @ApiProperty({ example: '52998224725' })
  cpfCnpj: string;

  @ApiProperty({ example: 'ana@exemplo.com' })
  email: string;

  @ApiPropertyOptional({ example: '21987654321', nullable: true, type: String })
  celular: string | null;

  @ApiPropertyOptional({ example: '1995-05-10', nullable: true, type: String })
  dataNascimento: string | null;

  @ApiProperty({ enum: Papel, example: Papel.CLIENTE })
  papel: Papel;

  @ApiProperty({ example: false })
  marketingOk: boolean;

  @ApiPropertyOptional({ example: '2026-11-14T23:30:00.000Z', nullable: true, type: String })
  aceiteTermosEm: string | null;

  @ApiProperty({ example: '2026-11-14T23:30:00.000Z' })
  criadoEm: string;
}

export class CadastroResponse {
  @ApiProperty({ type: ClienteResponse })
  cliente: ClienteResponse;

  @ApiProperty({ type: TokensResponse })
  tokens: TokensResponse;
}
