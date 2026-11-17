import { ArgumentsHost, HttpStatus } from '@nestjs/common';
import { FiltroExcecao } from './filtro-excecao.filter';
import { RegraNegocioException } from './regra-negocio.exception';

function hostComResposta() {
  const json = jest.fn();
  const status = jest.fn().mockReturnValue({ json });
  const host = {
    switchToHttp: () => ({
      getResponse: () => ({ status }),
    }),
  } as unknown as ArgumentsHost;
  return { host, status, json };
}

describe('FiltroExcecao', () => {
  const filtro = new FiltroExcecao();
  const prevNode = process.env.NODE_ENV;
  const prevMode = process.env.ASAAS_MODE;

  afterEach(() => {
    process.env.NODE_ENV = prevNode;
    process.env.ASAAS_MODE = prevMode;
  });

  it('repassa RegraNegocioException (ex.: PAGAMENTO_INDISPONIVEL do Asaas)', () => {
    const { host, status, json } = hostComResposta();
    filtro.catch(
      new RegraNegocioException(
        'PAGAMENTO_INDISPONIVEL',
        'Não conseguimos falar com o pagamento agora. Tente de novo em instantes.',
        HttpStatus.SERVICE_UNAVAILABLE,
      ),
      host,
    );
    expect(status).toHaveBeenCalledWith(HttpStatus.SERVICE_UNAVAILABLE);
    expect(json).toHaveBeenCalledWith(
      expect.objectContaining({
        codigo: 'PAGAMENTO_INDISPONIVEL',
        mensagem: expect.stringContaining('pagamento'),
      }),
    );
  });

  it('em ASAAS_MODE=sandbox inclui detalhe no ERRO_INTERNO mesmo com NODE_ENV=production', () => {
    process.env.NODE_ENV = 'production';
    process.env.ASAAS_MODE = 'sandbox';
    const { host, status, json } = hostComResposta();
    filtro.catch(new Error('Asaas 401: invalid_token'), host);
    expect(status).toHaveBeenCalledWith(HttpStatus.INTERNAL_SERVER_ERROR);
    expect(json).toHaveBeenCalledWith(
      expect.objectContaining({
        codigo: 'ERRO_INTERNO',
        mensagem: 'Erro inesperado. Tente de novo.',
        detalhe: expect.stringContaining('Asaas 401'),
      }),
    );
  });

  it('em produção real (ASAAS_MODE=producao) omite detalhe', () => {
    process.env.NODE_ENV = 'production';
    process.env.ASAAS_MODE = 'producao';
    const { host, json } = hostComResposta();
    filtro.catch(new Error('segredo interno'), host);
    const corpo = json.mock.calls[0][0] as { detalhe?: string };
    expect(corpo.detalhe).toBeUndefined();
  });
});
