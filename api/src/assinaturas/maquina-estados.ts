import { HttpStatus } from '@nestjs/common';
import { StatusAssinatura as SA, StatusCiclo as SC } from '../../prisma/generated/prisma/client';
import { RegraNegocioException } from '../common/regra-negocio.exception';

/**
 * Diagramas de status do Anexo. Toda mudança de status passa por `MaquinaEstadosService`,
 * que chama estas funções antes de gravar. Transição fora da tabela → 409 TRANSICAO_INVALIDA.
 */
const ASSINATURA: Record<SA, SA[]> = {
  [SA.AGUARDANDO_PAGAMENTO]: [SA.ATIVA, SA.CANCELADA],
  [SA.ATIVA]: [SA.PAUSADA, SA.SUSPENSA, SA.CANCELADA],
  [SA.PAUSADA]: [SA.ATIVA, SA.CANCELADA],
  [SA.SUSPENSA]: [SA.ATIVA, SA.CANCELADA],
  [SA.CANCELADA]: [],
};

const CICLO: Record<SC, SC[]> = {
  [SC.AGENDADO]: [SC.COBRADO, SC.PULADO],
  [SC.COBRADO]: [SC.PAGO, SC.CANCELADO],
  [SC.PAGO]: [SC.SEPARADO],
  [SC.SEPARADO]: [SC.EM_ROTA],
  [SC.EM_ROTA]: [SC.ENTREGUE, SC.FALHOU],
  [SC.FALHOU]: [SC.EM_ROTA],
  [SC.ENTREGUE]: [],
  [SC.PULADO]: [],
  [SC.CANCELADO]: [],
};

function invalida(tipo: string, de: string, para: string): RegraNegocioException {
  return new RegraNegocioException(
    'TRANSICAO_INVALIDA',
    `Não é possível passar ${tipo} de ${de} para ${para}.`,
    HttpStatus.CONFLICT,
  );
}

export function garantirTransicaoAssinatura(de: SA, para: SA): void {
  if (!ASSINATURA[de].includes(para)) throw invalida('a assinatura', de, para);
}

export function garantirTransicaoCiclo(de: SC, para: SC): void {
  if (!CICLO[de].includes(para)) throw invalida('o ciclo', de, para);
}

/** Ciclos que ainda vão acontecer (não pulados, cancelados nem entregues). */
export const CICLOS_EM_ABERTO: SC[] = [SC.AGENDADO, SC.COBRADO, SC.PAGO, SC.SEPARADO, SC.EM_ROTA, SC.FALHOU];
/** Ciclos já pagos (base do RN13 e da fidelidade). */
export const CICLOS_PAGOS: SC[] = [SC.PAGO, SC.SEPARADO, SC.EM_ROTA, SC.ENTREGUE, SC.FALHOU];
