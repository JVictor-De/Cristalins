import { Body, Controller, Delete, Get, HttpCode, HttpStatus, Param, Post, Put } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiConflictResponse,
  ApiCreatedResponse,
  ApiForbiddenResponse,
  ApiNotFoundResponse,
  ApiOkResponse,
  ApiTags,
  ApiUnprocessableEntityResponse,
} from '@nestjs/swagger';
import { UsuarioAtual } from '../auth/decorators';
import type { UsuarioToken } from '../auth/token.service';
import { AssinaturasService } from './assinaturas.service';
import { AlterarAssinaturaDto, CriarAssinaturaDto, PausarAssinaturaDto } from './dto/assinatura.dto';
import {
  AssinaturaAlteradaResponse,
  AssinaturaCanceladaResponse,
  AssinaturaCriadaResponse,
  AssinaturaResponse,
  CicloResponse,
  EntregaPuladaResponse,
} from './dto/assinatura.response';

@ApiTags('assinaturas')
@ApiBearerAuth()
@ApiForbiddenResponse({ description: 'SEM_PERMISSAO: assinatura de outro cliente (CT16)' })
@ApiNotFoundResponse({ description: 'NAO_ENCONTRADO' })
@Controller('assinaturas')
export class AssinaturasController {
  constructor(private readonly assinaturas: AssinaturasService) {}

  @Post()
  @ApiCreatedResponse({
    type: AssinaturaCriadaResponse,
    description: 'Status AGUARDANDO_PAGAMENTO, 1º ciclo, cálculo (CT02: 213,19) e ciclo.pix (QR + copia-e-cola).',
  })
  @ApiUnprocessableEntityResponse({ description: 'CESTA_*, EMBALAGEM_INVALIDA, CUPOM_INVALIDO, COBRANCA_VENCIDA (RN26)' })
  criar(@UsuarioAtual() u: UsuarioToken, @Body() dto: CriarAssinaturaDto): Promise<AssinaturaCriadaResponse> {
    return this.assinaturas.criar(u.id, dto);
  }

  @Get()
  @ApiOkResponse({ type: [AssinaturaResponse] })
  listar(@UsuarioAtual() u: UsuarioToken): Promise<AssinaturaResponse[]> {
    return this.assinaturas.listar(u.id);
  }

  @Get(':id')
  @ApiOkResponse({ type: AssinaturaResponse })
  buscar(@UsuarioAtual() u: UsuarioToken, @Param('id') id: string): Promise<AssinaturaResponse> {
    return this.assinaturas.buscar(u.id, id);
  }

  @Put(':id')
  @ApiOkResponse({ type: AssinaturaAlteradaResponse, description: 'Depois do corte, vale para a entrega seguinte (CT10)' })
  @ApiUnprocessableEntityResponse({ description: 'CESTA_*, EMBALAGEM_INVALIDA, CUPOM_INVALIDO, COBRANCA_VENCIDA, COMPROMISSO_VIGENTE' })
  @ApiConflictResponse({ description: 'TRANSICAO_INVALIDA (assinatura cancelada)' })
  alterar(
    @UsuarioAtual() u: UsuarioToken,
    @Param('id') id: string,
    @Body() dto: AlterarAssinaturaDto,
  ): Promise<AssinaturaAlteradaResponse> {
    return this.assinaturas.alterar(u.id, id, dto);
  }

  @Delete(':id')
  @ApiOkResponse({ type: AssinaturaCanceladaResponse, description: 'RN12/RN13 (CT17)' })
  @ApiConflictResponse({ description: 'TRANSICAO_INVALIDA (já cancelada)' })
  cancelar(@UsuarioAtual() u: UsuarioToken, @Param('id') id: string): Promise<AssinaturaCanceladaResponse> {
    return this.assinaturas.cancelar(u.id, id);
  }

  @Post(':id/pausar')
  @HttpCode(HttpStatus.OK)
  @ApiOkResponse({ type: AssinaturaResponse })
  @ApiUnprocessableEntityResponse({ description: 'LIMITE_PAUSAS (CT20)' })
  @ApiConflictResponse({ description: 'TRANSICAO_INVALIDA' })
  pausar(@UsuarioAtual() u: UsuarioToken, @Param('id') id: string, @Body() dto: PausarAssinaturaDto): Promise<AssinaturaResponse> {
    return this.assinaturas.pausar(u.id, id, dto.ciclos);
  }

  @Post(':id/retomar')
  @HttpCode(HttpStatus.OK)
  @ApiOkResponse({ type: AssinaturaResponse })
  @ApiConflictResponse({ description: 'TRANSICAO_INVALIDA' })
  retomar(@UsuarioAtual() u: UsuarioToken, @Param('id') id: string): Promise<AssinaturaResponse> {
    return this.assinaturas.retomar(u.id, id);
  }

  @Post(':id/pular-entrega')
  @HttpCode(HttpStatus.OK)
  @ApiOkResponse({ type: EntregaPuladaResponse })
  @ApiConflictResponse({ description: 'APOS_CORTE (CT09) ou TRANSICAO_INVALIDA' })
  @ApiUnprocessableEntityResponse({ description: 'LIMITE_PULOS' })
  pular(@UsuarioAtual() u: UsuarioToken, @Param('id') id: string): Promise<EntregaPuladaResponse> {
    return this.assinaturas.pularEntrega(u.id, id);
  }

  @Get(':id/ciclos')
  @ApiTags('ciclos')
  @ApiOkResponse({ type: [CicloResponse], description: 'Entregas, valores, status e cobrança' })
  ciclos(@UsuarioAtual() u: UsuarioToken, @Param('id') id: string): Promise<CicloResponse[]> {
    return this.assinaturas.ciclos(u.id, id);
  }
}
