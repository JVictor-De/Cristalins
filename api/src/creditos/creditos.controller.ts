import { Controller, Get } from '@nestjs/common';
import { ApiBearerAuth, ApiOkResponse, ApiTags } from '@nestjs/swagger';
import { UsuarioAtual } from '../auth/decorators';
import type { UsuarioToken } from '../auth/token.service';
import { CreditoResponse, CreditosService } from './creditos.service';

@ApiTags('creditos')
@ApiBearerAuth()
@Controller('creditos')
export class CreditosController {
  constructor(private readonly creditos: CreditosService) {}

  @Get()
  @ApiOkResponse({ type: [CreditoResponse], description: 'Créditos válidos (RN20: 90 dias), abatidos na próxima cobrança' })
  listar(@UsuarioAtual() u: UsuarioToken): Promise<CreditoResponse[]> {
    return this.creditos.listar(u.id);
  }
}
