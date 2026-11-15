import { Body, Controller, HttpCode, HttpStatus, Post } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiForbiddenResponse,
  ApiNotFoundResponse,
  ApiOkResponse,
  ApiTags,
  ApiUnprocessableEntityResponse,
} from '@nestjs/swagger';
import { UsuarioAtual } from '../auth/decorators';
import type { UsuarioToken } from '../auth/token.service';
import { SimulacaoResponse } from './dto/simulacao.response';
import { SimularPrecoDto } from './dto/simular-preco.dto';
import { PrecoService } from './preco.service';

@ApiTags('precos')
@ApiBearerAuth()
@Controller('precos')
export class PrecosController {
  constructor(private readonly preco: PrecoService) {}

  @Post('simular')
  @HttpCode(HttpStatus.OK)
  @ApiOkResponse({ type: SimulacaoResponse, description: 'Exemplo: CT02 (R$ 213,19)' })
  @ApiUnprocessableEntityResponse({
    description: 'CESTA_ABAIXO_MINIMO (CT06), CESTA_ACIMA_MAXIMO (CT07), EMBALAGEM_INVALIDA (CT25), CUPOM_INVALIDO',
    schema: { example: { codigo: 'CESTA_ABAIXO_MINIMO', mensagem: 'A cesta precisa ter pelo menos 12 UE por entrega (sem contar o Guaraná).', campo: 'itens' } },
  })
  @ApiForbiddenResponse({ description: 'SEM_PERMISSAO: endereço ou ciclo de outro cliente' })
  @ApiNotFoundResponse({ description: 'NAO_ENCONTRADO: produto, zona, endereço ou ciclo' })
  simular(@UsuarioAtual() usuario: UsuarioToken, @Body() dto: SimularPrecoDto): Promise<SimulacaoResponse> {
    return this.preco.simular(usuario.id, dto);
  }
}
