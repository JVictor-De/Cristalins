import { Body, Controller, Post } from '@nestjs/common';
import { ApiCreatedResponse, ApiTags } from '@nestjs/swagger';
import { Publico } from '../auth/decorators';
import { EntrarListaEsperaDto, ListaEsperaResponse, ListaEsperaService } from './lista-espera.service';

@ApiTags('lista-espera')
@Publico()
@Controller('lista-espera')
export class ListaEsperaController {
  constructor(private readonly lista: ListaEsperaService) {}

  @Post()
  @ApiCreatedResponse({ type: ListaEsperaResponse })
  entrar(@Body() dto: EntrarListaEsperaDto): Promise<ListaEsperaResponse> {
    return this.lista.entrar(dto);
  }
}
