import { Controller, Get } from '@nestjs/common';
import { ApiOkResponse, ApiServiceUnavailableResponse, ApiTags } from '@nestjs/swagger';
import { Publico } from '../auth/decorators';
import { HealthService, StatusSaude } from './health.service';

@ApiTags('health')
@Publico()
@Controller('health')
export class HealthController {
  constructor(private readonly health: HealthService) {}

  @Get()
  @ApiOkResponse({
    description: 'API e banco respondendo',
    schema: { example: { status: 'ok', banco: 'ok', horario: '2026-11-14T23:00:00.000Z' } },
  })
  @ApiServiceUnavailableResponse({
    description: 'Banco indisponível',
    schema: { example: { codigo: 'SERVICO_INDISPONIVEL', mensagem: 'Banco de dados indisponível.' } },
  })
  verificar(): Promise<StatusSaude> {
    return this.health.verificar();
  }
}
