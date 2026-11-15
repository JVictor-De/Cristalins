import { Body, Controller, Param, Put } from '@nestjs/common';
import { ApiBearerAuth, ApiForbiddenResponse, ApiOkResponse, ApiTags } from '@nestjs/swagger';
import { Papeis } from '../auth/decorators';
import { AdminService } from './admin.service';
import { AtualizarFatorDto, AtualizarProdutoDto, AtualizarZonaDto } from './dto/admin.dto';

/** SEG03: todas as rotas /admin exigem papel ADMIN (cliente → 403 SEM_PERMISSAO). */
@ApiTags('admin')
@ApiBearerAuth()
@ApiForbiddenResponse({ description: 'SEM_PERMISSAO: só ADMIN' })
@Papeis('ADMIN')
@Controller('admin')
export class AdminController {
  constructor(private readonly admin: AdminService) {}

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
}
