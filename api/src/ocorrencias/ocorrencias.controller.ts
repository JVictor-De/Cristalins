import { Body, Controller, Get, Post, UploadedFile, UseInterceptors } from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import {
  ApiBearerAuth,
  ApiBody,
  ApiConsumes,
  ApiCreatedResponse,
  ApiForbiddenResponse,
  ApiOkResponse,
  ApiTags,
  ApiUnprocessableEntityResponse,
} from '@nestjs/swagger';
import { UsuarioAtual } from '../auth/decorators';
import type { UsuarioToken } from '../auth/token.service';
import {
  CriarOcorrenciaDto,
  FotoEnviada,
  OcorrenciaResponse,
  OcorrenciasService,
  TAMANHO_MAXIMO_FOTO,
} from './ocorrencias.service';

@ApiTags('ocorrencias')
@ApiBearerAuth()
@Controller('ocorrencias')
export class OcorrenciasController {
  constructor(private readonly ocorrencias: OcorrenciasService) {}

  @Post()
  @UseInterceptors(FileInterceptor('foto', { limits: { fileSize: TAMANHO_MAXIMO_FOTO + 1, files: 1 } }))
  @ApiConsumes('multipart/form-data')
  @ApiBody({
    schema: {
      type: 'object',
      required: ['foto', 'cicloId', 'tipo', 'produto', 'quantidade', 'solucao'],
      properties: {
        foto: { type: 'string', format: 'binary' },
        cicloId: { type: 'string', format: 'uuid' },
        tipo: { type: 'string', enum: ['AVARIA', 'FALTA'] },
        produto: { type: 'string', example: 'WP500' },
        quantidade: { type: 'integer', example: 2 },
        solucao: { type: 'string', enum: ['REPOSICAO', 'CREDITO'] },
      },
    },
  })
  @ApiCreatedResponse({ type: OcorrenciaResponse, description: 'RN15: foto no armazenamento privado; crédito na hora ou reposição na próxima entrega' })
  @ApiForbiddenResponse({ description: 'SEM_PERMISSAO' })
  @ApiUnprocessableEntityResponse({ description: 'OCORRENCIA_INVALIDA ou PRAZO_OCORRENCIA_ENCERRADO (24 h)' })
  criar(
    @UsuarioAtual() u: UsuarioToken,
    @Body() dto: CriarOcorrenciaDto,
    @UploadedFile() foto: FotoEnviada | undefined,
  ): Promise<OcorrenciaResponse> {
    return this.ocorrencias.criar(u.id, dto, foto);
  }

  @Get()
  @ApiOkResponse({ type: [OcorrenciaResponse] })
  listar(@UsuarioAtual() u: UsuarioToken): Promise<OcorrenciaResponse[]> {
    return this.ocorrencias.listar(u.id);
  }
}
