import { Controller, Get } from '@nestjs/common';
import { ApiOkResponse, ApiTags } from '@nestjs/swagger';
import { Publico } from '../auth/decorators';
import { KitResponse, KitsService } from './kits.service';

@ApiTags('kits')
@Publico()
@Controller('kits')
export class KitsController {
  constructor(private readonly kits: KitsService) {}

  @Get()
  @ApiOkResponse({ type: [KitResponse] })
  listar(): Promise<KitResponse[]> {
    return this.kits.listar();
  }
}
