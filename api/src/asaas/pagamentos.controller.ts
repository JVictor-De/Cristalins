import { Body, Controller, Get, HttpCode, HttpStatus, Param, Post, Put, Req } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiConflictResponse,
  ApiCreatedResponse,
  ApiForbiddenResponse,
  ApiOkResponse,
  ApiTags,
  ApiUnprocessableEntityResponse,
} from '@nestjs/swagger';
import type { Request } from 'express';
import { UsuarioAtual } from '../auth/decorators';
import type { UsuarioToken } from '../auth/token.service';
import { CadastrarCartaoDto, CartaoResponse, CartaoService } from './cartao.service';
import {
  ArrependimentoResponse,
  FaturaResponse,
  FaturasService,
  FormaResponse,
  TrocarFormaDto,
} from './faturas.service';

/** Cartões, faturas, forma de pagamento e arrependimento (cr-5-cobranca). */
@ApiTags('asaas')
@ApiBearerAuth()
@ApiForbiddenResponse({ description: 'SEM_PERMISSAO: recurso de outro cliente' })
@Controller()
export class PagamentosController {
  constructor(
    private readonly cartoes: CartaoService,
    private readonly faturas: FaturasService,
  ) {}

  @Post('cartoes')
  @ApiCreatedResponse({ type: CartaoResponse, description: 'Tokeniza no Asaas; guarda só token, bandeira e 4 últimos dígitos' })
  @ApiUnprocessableEntityResponse({ description: 'CARTAO_RECUSADO' })
  cadastrarCartao(@UsuarioAtual() u: UsuarioToken, @Body() dto: CadastrarCartaoDto, @Req() req: Request): Promise<CartaoResponse> {
    return this.cartoes.cadastrar(u.id, dto, req.ip ?? '0.0.0.0');
  }

  @Get('cartoes')
  @ApiOkResponse({ type: [CartaoResponse] })
  listarCartoes(@UsuarioAtual() u: UsuarioToken): Promise<CartaoResponse[]> {
    return this.cartoes.listar(u.id);
  }

  @Get('faturas')
  @ApiOkResponse({ type: [FaturaResponse] })
  listarFaturas(@UsuarioAtual() u: UsuarioToken): Promise<FaturaResponse[]> {
    return this.faturas.listar(u.id);
  }

  @Get('faturas/:id/comprovante')
  @ApiOkResponse({ schema: { example: { url: 'https://www.asaas.com/comprovantes/...' } } })
  @ApiUnprocessableEntityResponse({ description: 'COMPROVANTE_INDISPONIVEL' })
  comprovante(@UsuarioAtual() u: UsuarioToken, @Param('id') id: string): Promise<{ url: string }> {
    return this.faturas.comprovante(u.id, id);
  }

  @Get('assinaturas/:id/forma-pagamento')
  @ApiOkResponse({ type: FormaResponse })
  forma(@UsuarioAtual() u: UsuarioToken, @Param('id') id: string): Promise<FormaResponse> {
    return this.faturas.forma(u.id, id);
  }

  @Put('assinaturas/:id/forma-pagamento')
  @ApiOkResponse({ type: FormaResponse, description: 'Vale para a próxima cobrança' })
  @ApiConflictResponse({ description: 'TRANSICAO_INVALIDA (cancelada)' })
  trocarForma(@UsuarioAtual() u: UsuarioToken, @Param('id') id: string, @Body() dto: TrocarFormaDto): Promise<FormaResponse> {
    return this.faturas.trocarForma(u.id, id, dto);
  }

  @Post('assinaturas/:id/arrependimento')
  @HttpCode(HttpStatus.OK)
  @ApiOkResponse({ type: ArrependimentoResponse, description: 'RN14: até 7 dias da assinatura' })
  @ApiUnprocessableEntityResponse({ description: 'PRAZO_ARREPENDIMENTO_ENCERRADO' })
  arrepender(@UsuarioAtual() u: UsuarioToken, @Param('id') id: string): Promise<ArrependimentoResponse> {
    return this.faturas.arrepender(u.id, id);
  }
}
