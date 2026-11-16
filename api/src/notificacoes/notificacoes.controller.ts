import { Body, Controller, HttpCode, HttpStatus, Post, Put } from '@nestjs/common';
import {
  ApiBadRequestResponse,
  ApiBearerAuth,
  ApiNoContentResponse,
  ApiOkResponse,
  ApiTags,
  ApiTooManyRequestsResponse,
} from '@nestjs/swagger';
import { Publico, UsuarioAtual } from '../auth/decorators';
import type { UsuarioToken } from '../auth/token.service';
import { NotificacoesService, PushTokenDto } from './notificacoes.service';
import { EsqueciSenhaDto, MensagemResponse, RecuperacaoSenhaService, RedefinirSenhaDto } from './recuperacao-senha.service';

@ApiTags('notificacoes')
@ApiBearerAuth()
@Controller('notificacoes')
export class NotificacoesController {
  constructor(private readonly notificacoes: NotificacoesService) {}

  @Put('push-token')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiNoContentResponse({ description: 'Token do aparelho salvo (push só de cobrança, pagamento, separação, entrega e aumento)' })
  async pushToken(@UsuarioAtual() u: UsuarioToken, @Body() dto: PushTokenDto): Promise<void> {
    await this.notificacoes.registrarPushToken(u.id, dto.token);
  }
}

/** RF52: recuperação de senha por e-mail (rotas públicas em /auth). */
@ApiTags('auth')
@Controller('auth')
export class RecuperacaoSenhaController {
  constructor(private readonly senha: RecuperacaoSenhaService) {}

  @Post('esqueci-senha')
  @Publico()
  @HttpCode(HttpStatus.OK)
  @ApiOkResponse({ type: MensagemResponse, description: 'Sempre 200: não revela se o e-mail tem cadastro' })
  esqueci(@Body() dto: EsqueciSenhaDto): Promise<MensagemResponse> {
    return this.senha.esqueci(dto.email);
  }

  @Post('redefinir-senha')
  @Publico()
  @HttpCode(HttpStatus.OK)
  @ApiOkResponse({ type: MensagemResponse })
  @ApiBadRequestResponse({ description: 'CODIGO_INVALIDO' })
  @ApiTooManyRequestsResponse({ description: 'MUITAS_TENTATIVAS: 5 códigos errados' })
  redefinir(@Body() dto: RedefinirSenhaDto): Promise<MensagemResponse> {
    return this.senha.redefinir(dto);
  }
}
