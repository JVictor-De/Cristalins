import { HttpStatus } from '@nestjs/common';
import { RegraNegocioException } from '../common/regra-negocio.exception';
import { AsaasGateway } from './asaas.gateway';

describe('AsaasGateway', () => {
  const gateway = new AsaasGateway();
  const prevUrl = process.env.ASAAS_API_URL;
  const prevKey = process.env.ASAAS_API_KEY;

  afterEach(() => {
    process.env.ASAAS_API_URL = prevUrl;
    process.env.ASAAS_API_KEY = prevKey;
  });

  it('sem ASAAS_API_KEY lança PAGAMENTO_INDISPONIVEL (não Error cru)', async () => {
    process.env.ASAAS_API_URL = 'https://api-sandbox.asaas.com/v3';
    delete process.env.ASAAS_API_KEY;
    try {
      await gateway.criarCliente({ id: '1', nome: 'A', cpfCnpj: '52998224725', email: 'a@b.com' });
      fail('deveria ter lançado');
    } catch (e) {
      expect(e).toBeInstanceOf(RegraNegocioException);
      expect((e as RegraNegocioException).codigo).toBe('PAGAMENTO_INDISPONIVEL');
      expect((e as RegraNegocioException).getStatus()).toBe(HttpStatus.SERVICE_UNAVAILABLE);
    }
  });
});
