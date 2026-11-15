import { Body, Controller, Delete, Get, HttpCode, HttpStatus, Param, Post, Put } from '@nestjs/common';
import {
  ApiBadGatewayResponse,
  ApiBearerAuth,
  ApiConflictResponse,
  ApiCreatedResponse,
  ApiNoContentResponse,
  ApiOkResponse,
  ApiTags,
  ApiUnprocessableEntityResponse,
} from '@nestjs/swagger';
import { Publico, UsuarioAtual } from '../auth/decorators';
import type { UsuarioToken } from '../auth/token.service';
import { CepConsultado, CepService } from './cep.service';
import { AtualizarEnderecoDto, CriarEnderecoDto } from './dto/endereco.dto';
import { EnderecoResponse, EnderecosService } from './enderecos.service';

const ERROS_AREA = {
  description: 'CEP_FORA_AREA (CT08) ou BAIRRO_NAO_ATENDIDO (CT23; ofereça POST /lista-espera)',
  schema: { example: { codigo: 'CEP_FORA_AREA', mensagem: 'Por enquanto entregamos só no município do Rio de Janeiro.', campo: 'cep' } },
};

@ApiTags('enderecos')
@Controller()
export class EnderecosController {
  constructor(
    private readonly cep: CepService,
    private readonly enderecos: EnderecosService,
  ) {}

  @Get('cep/:cep')
  @Publico()
  @ApiOkResponse({
    description: 'Endereço do ViaCEP com zona, taxa e dias de entrega',
    schema: {
      example: {
        cep: '22041001',
        logradouro: 'Avenida Nossa Senhora de Copacabana',
        bairro: 'Copacabana',
        localidade: 'Rio de Janeiro',
        uf: 'RJ',
        zona: { id: '…', nome: 'Zona Sul', taxaEntrega: 9.9, diasEntrega: ['SEG', 'QUA', 'SEX'] },
      },
    },
  })
  @ApiUnprocessableEntityResponse(ERROS_AREA)
  @ApiBadGatewayResponse({ description: 'GATEWAY_INDISPONIVEL: ViaCEP fora do ar' })
  consultar(@Param('cep') cep: string): Promise<CepConsultado> {
    return this.cep.consultar(cep);
  }

  @Post('enderecos')
  @ApiBearerAuth()
  @ApiCreatedResponse({ type: EnderecoResponse })
  @ApiUnprocessableEntityResponse(ERROS_AREA)
  criar(@UsuarioAtual() usuario: UsuarioToken, @Body() dto: CriarEnderecoDto): Promise<EnderecoResponse> {
    return this.enderecos.criar(usuario.id, dto);
  }

  @Get('enderecos')
  @ApiBearerAuth()
  @ApiOkResponse({ type: [EnderecoResponse] })
  listar(@UsuarioAtual() usuario: UsuarioToken): Promise<EnderecoResponse[]> {
    return this.enderecos.listar(usuario.id);
  }

  @Put('enderecos/:id')
  @ApiBearerAuth()
  @ApiOkResponse({ type: EnderecoResponse })
  @ApiConflictResponse({ description: 'APOS_CORTE: entrega com este endereço já passou do corte' })
  atualizar(
    @UsuarioAtual() usuario: UsuarioToken,
    @Param('id') id: string,
    @Body() dto: AtualizarEnderecoDto,
  ): Promise<EnderecoResponse> {
    return this.enderecos.atualizar(usuario.id, id, dto);
  }

  @Delete('enderecos/:id')
  @ApiBearerAuth()
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiNoContentResponse({ description: 'Removido' })
  @ApiUnprocessableEntityResponse({ description: 'ENDERECO_PRINCIPAL' })
  @ApiConflictResponse({ description: 'ENDERECO_EM_USO' })
  remover(@UsuarioAtual() usuario: UsuarioToken, @Param('id') id: string): Promise<void> {
    return this.enderecos.remover(usuario.id, id);
  }
}
