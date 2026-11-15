import { ApiProperty } from '@nestjs/swagger';
import { Injectable } from '@nestjs/common';
import { PrismaService } from '../common/prisma.service';
import { dec } from '../precos/preco.tipos';
import { TipoProduto } from '../../prisma/generated/prisma/client';

export class ProdutoResponse {
  @ApiProperty()
  id: string;
  @ApiProperty({ example: 'WP500' })
  codigo: string;
  @ApiProperty({ example: 'Water Protein (água com colágeno)' })
  nome: string;
  @ApiProperty({ enum: TipoProduto, example: TipoProduto.PRINCIPAL })
  tipo: TipoProduto;
  @ApiProperty({ example: 500 })
  volumeMl: number;
  @ApiProperty({ example: 1, description: 'Unidade equivalente (volume ÷ 500 ml)' })
  ue: number;
  @ApiProperty({ example: 6, description: 'Embalagem de venda: a quantidade precisa ser múltipla dela (RN04)' })
  embalagemQtd: number;
  @ApiProperty({ example: 9.9 })
  precoBase: number;
  @ApiProperty({ example: 7.5 })
  precoPiso: number;
  @ApiProperty({ example: 0.53 })
  pesoKg: number;
}

const num = (v: { toString(): string }) => dec(v).toNumber();

@Injectable()
export class ProdutosService {
  constructor(private readonly prisma: PrismaService) {}

  /** Produtos ativos, opcionalmente por tipo. Valores de exemplo do Anexo até a Cristalins confirmar. */
  async listar(tipo?: TipoProduto): Promise<ProdutoResponse[]> {
    const produtos = await this.prisma.produto.findMany({
      where: { ativo: true, ...(tipo && { tipo }) },
      orderBy: [{ tipo: 'asc' }, { codigo: 'asc' }],
    });
    return produtos.map((p) => ({
      id: p.id,
      codigo: p.codigo,
      nome: p.nome,
      tipo: p.tipo,
      volumeMl: p.volumeMl,
      ue: num(p.ue),
      embalagemQtd: p.embalagemQtd,
      precoBase: num(p.precoBase),
      precoPiso: num(p.precoPiso),
      pesoKg: num(p.pesoKg),
    }));
  }
}
