import { StatusAssinatura as SA, StatusCiclo as SC } from '../../prisma/generated/prisma/client';
import { RegraNegocioException } from '../common/regra-negocio.exception';
import { garantirTransicaoAssinatura, garantirTransicaoCiclo } from './maquina-estados';

const codigo = (fn: () => void) => {
  try {
    fn();
  } catch (e) {
    return (e as RegraNegocioException).codigo;
  }
  return null;
};

describe('máquina de estados', () => {
  describe('assinatura (diagrama do Anexo)', () => {
    it.each([
      [SA.AGUARDANDO_PAGAMENTO, SA.ATIVA],
      [SA.AGUARDANDO_PAGAMENTO, SA.CANCELADA],
      [SA.ATIVA, SA.PAUSADA],
      [SA.PAUSADA, SA.ATIVA],
      [SA.ATIVA, SA.SUSPENSA],
      [SA.SUSPENSA, SA.ATIVA],
      [SA.SUSPENSA, SA.CANCELADA],
      [SA.ATIVA, SA.CANCELADA],
      [SA.PAUSADA, SA.CANCELADA],
    ])('%s → %s é permitida', (de, para) => {
      expect(codigo(() => garantirTransicaoAssinatura(de, para))).toBeNull();
    });

    it.each([
      [SA.AGUARDANDO_PAGAMENTO, SA.PAUSADA],
      [SA.PAUSADA, SA.SUSPENSA],
      [SA.CANCELADA, SA.ATIVA],
      [SA.CANCELADA, SA.CANCELADA],
      [SA.ATIVA, SA.AGUARDANDO_PAGAMENTO],
    ])('%s → %s → 409 TRANSICAO_INVALIDA', (de, para) => {
      expect(codigo(() => garantirTransicaoAssinatura(de, para))).toBe('TRANSICAO_INVALIDA');
    });
  });

  describe('ciclo (diagrama do Anexo)', () => {
    it.each([
      [SC.AGENDADO, SC.COBRADO],
      [SC.AGENDADO, SC.PULADO],
      [SC.COBRADO, SC.PAGO],
      [SC.COBRADO, SC.CANCELADO],
      [SC.PAGO, SC.SEPARADO],
      [SC.SEPARADO, SC.EM_ROTA],
      [SC.EM_ROTA, SC.ENTREGUE],
      [SC.EM_ROTA, SC.FALHOU],
      [SC.FALHOU, SC.EM_ROTA],
    ])('%s → %s é permitida', (de, para) => {
      expect(codigo(() => garantirTransicaoCiclo(de, para))).toBeNull();
    });

    it.each([
      [SC.PULADO, SC.AGENDADO],
      [SC.AGENDADO, SC.PAGO],
      [SC.ENTREGUE, SC.EM_ROTA],
      [SC.CANCELADO, SC.COBRADO],
      [SC.AGENDADO, SC.CANCELADO],
    ])('%s → %s → 409 TRANSICAO_INVALIDA', (de, para) => {
      expect(codigo(() => garantirTransicaoCiclo(de, para))).toBe('TRANSICAO_INVALIDA');
    });
  });
});
