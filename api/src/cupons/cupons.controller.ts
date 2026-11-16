import { Body, Controller, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiConflictResponse, ApiCreatedResponse, ApiForbiddenResponse, ApiTags } from '@nestjs/swagger';
import { Papeis } from '../auth/decorators';
import { CriarCupomDto, CupomResponse, CuponsService } from './cupons.service';

@ApiTags('cupons')
@ApiBearerAuth()
@Papeis('ADMIN')
@Controller('admin/cupons')
export class CuponsController {
  constructor(private readonly cupons: CuponsService) {}

  @Post()
  @ApiCreatedResponse({ type: CupomResponse })
  @ApiConflictResponse({ description: 'CUPOM_JA_EXISTE' })
  @ApiForbiddenResponse({ description: 'SEM_PERMISSAO: só ADMIN' })
  criar(@Body() dto: CriarCupomDto): Promise<CupomResponse> {
    return this.cupons.criar(dto);
  }
}
