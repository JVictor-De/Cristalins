import { Injectable } from '@nestjs/common';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Transform } from 'class-transformer';
import { IsEmail, IsOptional, IsString, Matches, MaxLength } from 'class-validator';
import { PrismaService } from '../common/prisma.service';

export class EntrarListaEsperaDto {
  @ApiProperty({ example: 'ana@exemplo.com' })
  @Transform(({ value }) => (typeof value === 'string' ? value.trim().toLowerCase() : value))
  @IsEmail({}, { message: 'Informe um e-mail válido.' })
  @MaxLength(254)
  email: string;

  @ApiProperty({ example: '20550-013', description: 'CEP consultado (obrigatório no schema)' })
  @Matches(/^\d{5}-?\d{3}$/, { message: 'Informe o CEP com 8 dígitos.' })
  cep: string;

  @ApiPropertyOptional({ example: 'Grajaú' })
  @IsOptional()
  @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value))
  @IsString()
  @MaxLength(80)
  bairro?: string;
}

export class ListaEsperaResponse {
  @ApiProperty() id: string;
  @ApiProperty({ example: 'ana@exemplo.com' }) email: string;
  @ApiProperty({ example: '20550013' }) cep: string;
  @ApiPropertyOptional({ nullable: true, type: String, example: 'Grajaú' }) bairro: string | null;
  @ApiProperty() criadoEm: string;
}

/** CT23: quem está fora da área deixa o contato (CEP ou bairro ainda não atendido). */
@Injectable()
export class ListaEsperaService {
  constructor(private readonly prisma: PrismaService) {}

  async entrar(dto: EntrarListaEsperaDto): Promise<ListaEsperaResponse> {
    const r = await this.prisma.listaEspera.create({
      data: { email: dto.email, cep: dto.cep.replace(/\D/g, ''), bairro: dto.bairro ?? null },
    });
    return { id: r.id, email: r.email, cep: r.cep, bairro: r.bairro, criadoEm: r.criadoEm.toISOString() };
  }
}
