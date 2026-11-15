import { Body, Controller, Get, Param, ParseUUIDPipe, Post } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiCreatedResponse,
  ApiForbiddenResponse,
  ApiNotFoundResponse,
  ApiOkResponse,
  ApiTags,
} from '@nestjs/swagger';
import { UsuarioAtual } from '../auth/decorators';
import type { UsuarioToken } from '../auth/token.service';
import { RegraNegocioException } from '../common/regra-negocio.exception';
import { CriarRecomendacaoDto } from './dto/criar-recomendacao.dto';
import { RecomendacaoResponse } from './dto/recomendacao.response';
import { RecomendacaoService } from './recomendacao.service';

const idValido = new ParseUUIDPipe({
  exceptionFactory: () => new RegraNegocioException('NAO_ENCONTRADO', 'Recomendação não encontrada.', 404),
});

@ApiTags('recomendacoes')
@ApiBearerAuth()
@Controller('recomendacoes')
export class RecomendacoesController {
  constructor(private readonly recomendacoes: RecomendacaoService) {}

  @Post()
  @ApiCreatedResponse({ type: RecomendacaoResponse, description: 'Exemplo: caso A (KIT-TREINO, R$ 118,80)' })
  criar(@UsuarioAtual() usuario: UsuarioToken, @Body() dto: CriarRecomendacaoDto): Promise<RecomendacaoResponse> {
    return this.recomendacoes.recomendar(usuario.id, dto);
  }

  @Get()
  @ApiOkResponse({ type: [RecomendacaoResponse] })
  listar(@UsuarioAtual() usuario: UsuarioToken): Promise<RecomendacaoResponse[]> {
    return this.recomendacoes.listar(usuario.id);
  }

  @Get(':id')
  @ApiOkResponse({ type: RecomendacaoResponse })
  @ApiNotFoundResponse({ description: 'NAO_ENCONTRADO' })
  @ApiForbiddenResponse({ description: 'SEM_PERMISSAO: recomendação de outro cliente' })
  buscar(@UsuarioAtual() usuario: UsuarioToken, @Param('id', idValido) id: string): Promise<RecomendacaoResponse> {
    return this.recomendacoes.buscar(usuario.id, id);
  }
}
