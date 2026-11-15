import { Controller, Get, Query } from '@nestjs/common';
import { ApiOkResponse, ApiPropertyOptional, ApiTags } from '@nestjs/swagger';
import { IsEnum, IsOptional } from 'class-validator';
import { Publico } from '../auth/decorators';
import { TipoProduto } from '../../prisma/generated/prisma/client';
import { ProdutoResponse, ProdutosService } from './produtos.service';

export class ListarProdutosQuery {
  @ApiPropertyOptional({ enum: TipoProduto })
  @IsOptional()
  @IsEnum(TipoProduto)
  tipo?: TipoProduto;
}

@ApiTags('produtos')
@Publico()
@Controller('produtos')
export class ProdutosController {
  constructor(private readonly produtos: ProdutosService) {}

  @Get()
  @ApiOkResponse({ type: [ProdutoResponse] })
  listar(@Query() query: ListarProdutosQuery): Promise<ProdutoResponse[]> {
    return this.produtos.listar(query.tipo);
  }
}
