import { Injectable } from '@nestjs/common';
import { ApiProperty } from '@nestjs/swagger';
import { ClockService } from '../common/clock.service';
import { PrismaService } from '../common/prisma.service';
import { dinheiro } from '../precos/preco.service';
import { dec, Dec } from '../precos/preco.tipos';
import { Prisma } from '../../prisma/generated/prisma/client';

type Db = Prisma.TransactionClient;

/** RN20: créditos valem 90 dias. */
export const VALIDADE_CREDITO_DIAS = 90;
/** RN22: crédito de indicação. */
export const VALOR_INDICACAO = '15.00';
export const MOTIVO_INDICACAO = 'INDICACAO';

export class CreditoResponse {
  @ApiProperty() id: string;
  @ApiProperty({ example: 15 }) valor: number;
  @ApiProperty({ example: 'INDICACAO' }) motivo: string;
  @ApiProperty({ example: '2027-02-12T15:00:00.000Z', nullable: true, type: String }) expiraEm: string | null;
}

@Injectable()
export class CreditosService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly clock: ClockService,
  ) {}

  /** Créditos ainda não usados e dentro da validade, os que vencem antes primeiro. */
  async validos(clienteId: string, db: Db = this.prisma) {
    const agora = this.clock.agora();
    const lista = await db.credito.findMany({
      where: { clienteId, usadoEm: null },
      orderBy: { expiraEm: 'asc' },
    });
    return lista.filter((c) => !c.expiraEm || c.expiraEm > agora);
  }

  async listar(clienteId: string): Promise<CreditoResponse[]> {
    return (await this.validos(clienteId)).map((c) => ({
      id: c.id,
      valor: dinheiro(dec(c.valor)),
      motivo: c.motivo,
      expiraEm: c.expiraEm?.toISOString() ?? null,
    }));
  }

  async conceder(db: Db, clienteId: string, valor: string, motivo: string): Promise<void> {
    const expiraEm = new Date(this.clock.agora().getTime() + VALIDADE_CREDITO_DIAS * 24 * 60 * 60 * 1000);
    await db.credito.create({ data: { clienteId, valor, motivo, expiraEm } });
  }

  /**
   * Usa créditos válidos até `maximo` (o total do ciclo). O que sobrar de um crédito vira outro
   * crédito com a mesma validade. Devolve quanto foi abatido; o total nunca fica negativo.
   */
  async consumir(db: Db, clienteId: string, maximo: Dec): Promise<Dec> {
    let restante = maximo;
    let usado = dec(0);
    for (const c of await this.validos(clienteId, db)) {
      if (restante.lte(0)) break;
      const valor = dec(c.valor);
      const parte = Dec.min(valor, restante);
      await db.credito.update({ where: { id: c.id }, data: { usadoEm: this.clock.agora() } });
      if (valor.gt(parte)) {
        await db.credito.create({
          data: { clienteId, valor: valor.minus(parte).toFixed(2), motivo: `${c.motivo}:SALDO`, expiraEm: c.expiraEm },
        });
      }
      restante = restante.minus(parte);
      usado = usado.plus(parte);
    }
    return usado;
  }

  /**
   * RN22: R$ 15 para quem indicou, depois do 1º ciclo pago do indicado. Idempotente: um crédito
   * por indicado (motivo `INDICACAO:<idDoIndicado>`).
   */
  async concederIndicacao(db: Db, indicadoId: string): Promise<boolean> {
    const indicado = await db.cliente.findUnique({ where: { id: indicadoId } });
    if (!indicado?.indicadoPorId) return false;
    const motivo = `${MOTIVO_INDICACAO}:${indicadoId}`;
    const ja = await db.credito.findFirst({ where: { clienteId: indicado.indicadoPorId, motivo } });
    if (ja) return false;
    await this.conceder(db, indicado.indicadoPorId, VALOR_INDICACAO, motivo);
    return true;
  }
}
