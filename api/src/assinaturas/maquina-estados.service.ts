import { Injectable } from '@nestjs/common';
import { Prisma, StatusAssinatura, StatusCiclo } from '../../prisma/generated/prisma/client';
import { garantirTransicaoAssinatura, garantirTransicaoCiclo } from './maquina-estados';

export type Db = Prisma.TransactionClient;

/**
 * Único ponto do código que grava `status` de Assinatura e Ciclo (CONTEXTO: "só pelos métodos da
 * máquina de estados"). Transição inválida → 409 TRANSICAO_INVALIDA. Webhook e jobs (`cr-3`) usam
 * estes mesmos métodos.
 */
@Injectable()
export class MaquinaEstadosService {
  async assinatura(db: Db, registro: { id: string; status: StatusAssinatura }, para: StatusAssinatura): Promise<void> {
    garantirTransicaoAssinatura(registro.status, para);
    await db.assinatura.update({ where: { id: registro.id }, data: { status: para } });
    registro.status = para;
  }

  async ciclo(db: Db, registro: { id: string; status: StatusCiclo }, para: StatusCiclo): Promise<void> {
    garantirTransicaoCiclo(registro.status, para);
    await db.ciclo.update({ where: { id: registro.id }, data: { status: para } });
    registro.status = para;
  }
}
