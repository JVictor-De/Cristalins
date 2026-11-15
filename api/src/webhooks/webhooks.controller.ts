import { Body, Controller, Headers, HttpCode, Post } from '@nestjs/common';
import { ApiExcludeEndpoint } from '@nestjs/swagger';
import { Publico } from '../auth/decorators';
import { WebhooksService } from './webhooks.service';

@Controller('webhooks')
export class WebhooksController {
  constructor(private readonly webhooks: WebhooksService) {}

  @Post('asaas')
  @Publico()
  @HttpCode(200)
  @ApiExcludeEndpoint()
  async asaas(
    @Headers('asaas-access-token') token: string | undefined,
    @Body() body: { id?: string; event?: string; payment?: { id?: string; externalReference?: string } },
  ): Promise<{ ok: true }> {
    // CT15: token errado → 401 e nada gravado (validar antes de gravar)
    this.webhooks.validarToken(token);
    const idEvento = body.id ?? body.payment?.id;
    if (!idEvento) {
      return { ok: true };
    }
    const tipo = body.event ?? 'UNKNOWN';
    // Grava primeiro, depois 200 (CONTEXTO / passo)
    await this.webhooks.receber(idEvento, tipo, body);
    return { ok: true };
  }
}
