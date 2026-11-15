import { ApiProperty } from '@nestjs/swagger';
import { IsBoolean, IsEnum, IsIn } from 'class-validator';
import { ObjetivoKit } from '../../../prisma/generated/prisma/client';

/** Faixa de dias por semana → d (pergunta 2 do quiz). */
export const DIAS_POR_FAIXA = { '1-2': 2, '3-4': 4, '5-7': 6 } as const;
/** Pessoas → p (pergunta 3 do quiz). */
export const PESSOAS_POR_FAIXA = { '1': 1, '2': 2, '3': 3, '4': 4, '5-10': 8, '11-20': 15 } as const;

export type FaixaDias = keyof typeof DIAS_POR_FAIXA;
export type FaixaPessoas = keyof typeof PESSOAS_POR_FAIXA;

/** As 5 respostas do quiz (Anexo, "Quiz de recomendação"). */
export class CriarRecomendacaoDto {
  @ApiProperty({ enum: ObjetivoKit, example: ObjetivoKit.TREINO, description: 'Treino, Rotina equilibrada, Casa e família, Escritório' })
  @IsEnum(ObjetivoKit, { message: 'Escolha um objetivo.' })
  objetivo: ObjetivoKit;

  @ApiProperty({ enum: Object.keys(DIAS_POR_FAIXA), example: '5-7', description: 'Dias da semana de consumo' })
  @IsIn(Object.keys(DIAS_POR_FAIXA), { message: 'Escolha quantos dias por semana.' })
  diasSemana: FaixaDias;

  @ApiProperty({ enum: Object.keys(PESSOAS_POR_FAIXA), example: '1', description: 'Pessoas que vão consumir' })
  @IsIn(Object.keys(PESSOAS_POR_FAIXA), { message: 'Escolha quantas pessoas.' })
  pessoas: FaixaPessoas;

  @ApiProperty({ example: false, description: 'Incluir Flow Fiber' })
  @IsBoolean()
  flowFiber: boolean;

  @ApiProperty({ example: false, description: 'Água com gás no complemento' })
  @IsBoolean()
  comGas: boolean;
}
