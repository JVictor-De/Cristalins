import { HttpStatus, Injectable } from '@nestjs/common';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Transform } from 'class-transformer';
import { IsInt, IsNumber, IsOptional, Matches, Max, Min } from 'class-validator';
import { PrismaService } from '../common/prisma.service';
import { RegraNegocioException } from '../common/regra-negocio.exception';

export class CriarCupomDto {
  @ApiProperty({ example: 'VERAO10' })
  @Transform(({ value }) => (typeof value === 'string' ? value.trim().toUpperCase() : value))
  @Matches(/^[A-Z0-9]{3,40}$/, { message: 'Use de 3 a 40 letras ou números, sem espaço.' })
  codigo: string;

  @ApiProperty({ example: 10, description: 'Percentual (10 = 10%). Aplicado item a item, sem furar o piso (RN21)' })
  @IsNumber({ maxDecimalPlaces: 2 })
  @Min(0.01)
  @Max(100)
  percentual: number;

  @ApiPropertyOptional({ example: '2027-03-31', description: 'Última data de entrega em que vale' })
  @IsOptional()
  @Matches(/^\d{4}-\d{2}-\d{2}$/, { message: 'Use a data no formato AAAA-MM-DD.' })
  validade?: string;

  @ApiPropertyOptional({ example: 100 })
  @IsOptional()
  @IsInt()
  @Min(1)
  usosMax?: number;
}

export class CupomResponse {
  @ApiProperty() id: string;
  @ApiProperty({ example: 'VERAO10' }) codigo: string;
  @ApiProperty({ example: 10 }) percentual: number;
  @ApiPropertyOptional({ nullable: true, type: String, example: '2027-03-31' }) validade: string | null;
  @ApiPropertyOptional({ nullable: true, type: Number, example: 100 }) usosMax: number | null;
  @ApiProperty({ example: 0 }) usos: number;
}

/** RN21: criação de cupom pelo admin. A aplicação no preço é do `PrecoService` (fator, com piso). */
@Injectable()
export class CuponsService {
  constructor(private readonly prisma: PrismaService) {}

  async criar(dto: CriarCupomDto): Promise<CupomResponse> {
    const existente = await this.prisma.cupom.findUnique({ where: { codigo: dto.codigo } });
    if (existente) {
      throw new RegraNegocioException('CUPOM_JA_EXISTE', 'Já existe um cupom com esse código.', HttpStatus.CONFLICT, 'codigo');
    }
    const c = await this.prisma.cupom.create({
      data: {
        codigo: dto.codigo,
        percentual: String(dto.percentual),
        validade: dto.validade ? new Date(`${dto.validade}T00:00:00.000Z`) : null,
        usosMax: dto.usosMax ?? null,
      },
    });
    return {
      id: c.id,
      codigo: c.codigo,
      percentual: Number(c.percentual.toString()),
      validade: c.validade ? c.validade.toISOString().slice(0, 10) : null,
      usosMax: c.usosMax,
      usos: c.usos,
    };
  }
}
