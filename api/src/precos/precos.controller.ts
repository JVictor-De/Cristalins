import { Body, Controller, HttpCode, HttpStatus, Post, UseGuards } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiForbiddenResponse,
  ApiNotFoundResponse,
  ApiOkResponse,
  ApiTags,
  ApiTooManyRequestsResponse,
  ApiUnprocessableEntityResponse,
} from '@nestjs/swagger';
import { SkipThrottle, ThrottlerGuard } from '@nestjs/throttler';
import { Publico, UsuarioAtual } from '../auth/decorators';
import type { UsuarioToken } from '../auth/token.service';
import { SimulacaoResponse } from './dto/simulacao.response';
import { SimularPrecoDto } from './dto/simular-preco.dto';
import { PrecoService } from './preco.service';

@ApiTags('precos')
@Controller('precos')
export class PrecosController {
  constructor(private readonly preco: PrecoService) {}

  @Post('simular')
  @Publico()
  @SkipThrottle({ login: true })
  @UseGuards(ThrottlerGuard)
  @HttpCode(HttpStatus.OK)
  @ApiBearerAuth()
  @ApiOkResponse({
    type: SimulacaoResponse,
    description: 'Exemplo: CT02 (R$ 213,19). Sem Bearer: anônimo (sem fidelidade/ciclo). Com Bearer: comportamento autenticado.',
  })
  @ApiTooManyRequestsResponse({
    description: 'Throttle por IP (60/min)',
    schema: { example: { codigo: 'MUITAS_TENTATIVAS', mensagem: 'Muitas tentativas de login. Aguarde um minuto e tente de novo.' } },
  })
  @ApiUnprocessableEntityResponse({
    description: 'CESTA_ABAIXO_MINIMO (CT06), CESTA_ACIMA_MAXIMO (CT07), EMBALAGEM_INVALIDA (CT25), CUPOM_INVALIDO',
    schema: { example: { codigo: 'CESTA_ABAIXO_MINIMO', mensagem: 'A cesta precisa ter pelo menos 12 UE por entrega (sem contar o Guaraná).', campo: 'itens' } },
  })
  @ApiForbiddenResponse({ description: 'SEM_PERMISSAO: endereço ou ciclo de outro cliente' })
  @ApiNotFoundResponse({ description: 'NAO_ENCONTRADO: produto, zona, endereço ou ciclo' })
  simular(
    @UsuarioAtual() usuario: UsuarioToken | undefined,
    @Body() dto: SimularPrecoDto,
  ): Promise<SimulacaoResponse> {
    return this.preco.simular(usuario?.id, dto);
  }
}
