import { Body, Controller, Get, HttpCode, HttpStatus, Post, Put } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiConflictResponse,
  ApiCreatedResponse,
  ApiOkResponse,
  ApiTags,
  ApiUnauthorizedResponse,
  ApiUnprocessableEntityResponse,
} from '@nestjs/swagger';
import { Publico, UsuarioAtual } from '../auth/decorators';
import { TokenService, UsuarioToken } from '../auth/token.service';
import { ClientesService } from './clientes.service';
import { AtualizarClienteDto } from './dto/atualizar-cliente.dto';
import { CadastroResponse, ClienteResponse } from './dto/cliente.response';
import { CriarClienteDto } from './dto/criar-cliente.dto';

@ApiTags('clientes')
@Controller('clientes')
export class ClientesController {
  constructor(
    private readonly clientes: ClientesService,
    private readonly tokens: TokenService,
  ) {}

  @Post()
  @Publico()
  @HttpCode(HttpStatus.CREATED)
  @ApiCreatedResponse({ type: CadastroResponse, description: 'Conta criada; já devolve os tokens' })
  @ApiUnprocessableEntityResponse({
    description: 'CPF_INVALIDO ou MENOR_DE_IDADE (CT24)',
    schema: { example: { codigo: 'MENOR_DE_IDADE', mensagem: 'A assinatura é só para maiores de 18 anos.', campo: 'dataNascimento' } },
  })
  @ApiConflictResponse({ description: 'CPF_JA_CADASTRADO ou EMAIL_JA_CADASTRADO' })
  async criar(@Body() dto: CriarClienteDto): Promise<CadastroResponse> {
    const cliente = await this.clientes.criar(dto);
    const tokens = await this.tokens.emitir({ id: cliente.id, papel: cliente.papel });
    return { cliente: this.clientes.paraResposta(cliente), tokens };
  }

  @Get('me')
  @ApiBearerAuth()
  @ApiOkResponse({ type: ClienteResponse })
  @ApiUnauthorizedResponse({ description: 'NAO_AUTENTICADO' })
  async perfil(@UsuarioAtual() usuario: UsuarioToken): Promise<ClienteResponse> {
    return this.clientes.paraResposta(await this.clientes.buscarAtivo(usuario.id));
  }

  @Put('me')
  @ApiBearerAuth()
  @ApiOkResponse({ type: ClienteResponse })
  @ApiUnauthorizedResponse({ description: 'NAO_AUTENTICADO' })
  async atualizar(
    @UsuarioAtual() usuario: UsuarioToken,
    @Body() dto: AtualizarClienteDto,
  ): Promise<ClienteResponse> {
    return this.clientes.paraResposta(await this.clientes.atualizar(usuario.id, dto));
  }
}
