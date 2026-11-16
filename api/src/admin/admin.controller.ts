import { Body, Controller, Get, Param, Post, Put, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiConflictResponse, ApiForbiddenResponse, ApiOkResponse, ApiQuery, ApiTags } from '@nestjs/swagger';
import { Papeis } from '../auth/decorators';
import { JobsService } from '../jobs/jobs.service';
import { AdminService } from './admin.service';
import { AtualizarStatusCicloDto, OperacaoService, StatusCicloResponse } from './operacao.service';
import { AtualizarFatorDto, AtualizarProdutoDto, AtualizarZonaDto } from './dto/admin.dto';

/** SEG03: todas as rotas /admin exigem papel ADMIN (cliente → 403 SEM_PERMISSAO). */
@ApiTags('admin')
@ApiBearerAuth()
@ApiForbiddenResponse({ description: 'SEM_PERMISSAO: só ADMIN' })
@Papeis('ADMIN')
@Controller('admin')
export class AdminController {
  constructor(
    private readonly admin: AdminService,
    private readonly jobs: JobsService,
    private readonly operacao: OperacaoService,
  ) {}

  @Put('produtos/:id')
  @ApiOkResponse({ description: 'Preço, piso, estoque e ativo do produto' })
  produto(@Param('id') id: string, @Body() dto: AtualizarProdutoDto) {
    return this.admin.atualizarProduto(id, dto);
  }

  @Put('fatores-preco')
  @ApiOkResponse({ description: 'Fator criado ou atualizado na vigência informada' })
  fator(@Body() dto: AtualizarFatorDto) {
    return this.admin.atualizarFator(dto);
  }

  @Put('zonas/:id')
  @ApiOkResponse({ description: 'Taxa, dias de entrega, bairros e ativa' })
  zona(@Param('id') id: string, @Body() dto: AtualizarZonaDto) {
    return this.admin.atualizarZona(id, dto);
  }

  @Post('jobs/gerar-cobrancas')
  @ApiOkResponse({ description: 'Dispara o job das 06:00 (cobranças com entrega em D+5)' })
  gerarCobrancas() {
    return this.jobs.gerarCobrancas();
  }

  @Get('separacao')
  @ApiQuery({ name: 'data', example: '2026-11-30', description: 'Dia da entrega (AAAA-MM-DD)' })
  @ApiOkResponse({ description: 'RF29: ciclos pagos do dia por zona, com trocas do RN06 e reposições do RN15' })
  separacao(@Query('data') data: string) {
    return this.operacao.separacao(data);
  }

  @Put('ciclos/:id/status')
  @ApiOkResponse({ type: StatusCicloResponse, description: 'RF31/RN17: separado, em rota, entregue ou falhou; avisa o cliente' })
  @ApiConflictResponse({ description: 'TRANSICAO_INVALIDA' })
  statusCiclo(@Param('id') id: string, @Body() dto: AtualizarStatusCicloDto): Promise<StatusCicloResponse> {
    return this.operacao.atualizarStatus(id, dto.status);
  }
}
