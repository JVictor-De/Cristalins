import { Injectable } from '@nestjs/common';
import { ApiProperty } from '@nestjs/swagger';
import { PrismaService } from '../common/prisma.service';
import { dinheiro } from '../precos/preco.service';
import { dec } from '../precos/preco.tipos';
import { ObjetivoKit } from '../../prisma/generated/prisma/client';

export class ItemKitResponse {
  @ApiProperty({ example: 'WP500' })
  produto: string;
  @ApiProperty({ example: 12 })
  quantidade: number;
}

export class KitResponse {
  @ApiProperty()
  id: string;
  @ApiProperty({ example: 'KIT-TREINO' })
  codigo: string;
  @ApiProperty({ example: 'Kit Treino' })
  nome: string;
  @ApiProperty({ enum: ObjetivoKit, example: ObjetivoKit.TREINO })
  objetivo: ObjetivoKit;
  @ApiProperty({ type: [ItemKitResponse], description: 'Composição base (m = 1)' })
  itens: ItemKitResponse[];
  @ApiProperty({ example: 12, description: 'UE com m = 1' })
  ue: number;
  @ApiProperty({ example: 118.8, description: 'Σ preço base × quantidade com m = 1, antes dos descontos' })
  subtotalBase: number;
}

@Injectable()
export class KitsService {
  constructor(private readonly prisma: PrismaService) {}

  async listar(): Promise<KitResponse[]> {
    const kits = await this.prisma.kit.findMany({
      include: { itens: { include: { produto: true } } },
      orderBy: { codigo: 'asc' },
    });
    return kits.map((k) => ({
      id: k.id,
      codigo: k.codigo,
      nome: k.nome,
      objetivo: k.objetivo,
      itens: k.itens.map((i) => ({ produto: i.produto.codigo, quantidade: i.quantidade })),
      ue: k.itens.reduce((acc, i) => acc.plus(dec(i.produto.ue).times(i.quantidade)), dec(0)).toNumber(),
      subtotalBase: dinheiro(k.itens.reduce((acc, i) => acc.plus(dec(i.produto.precoBase).times(i.quantidade)), dec(0))),
    }));
  }
}
