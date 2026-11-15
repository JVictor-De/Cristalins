import { ApiProperty } from '@nestjs/swagger';

export class TokensResponse {
  @ApiProperty({ description: 'JWT de acesso (15 min). Envie em Authorization: Bearer' })
  accessToken: string;

  @ApiProperty({ description: 'JWT de renovação (30 dias). Use em POST /auth/refresh' })
  refreshToken: string;

  @ApiProperty({ example: 900, description: 'Validade do accessToken em segundos' })
  expiresIn: number;
}
