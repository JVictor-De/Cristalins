import { Injectable } from '@nestjs/common';

export interface RespostaViaCep {
  cep: string;
  logradouro: string;
  bairro: string;
  localidade: string;
  uf: string;
  complemento?: string;
}

const URL_VIACEP = 'https://viacep.com.br/ws';
const TIMEOUT_MS = 5000;

/** Cliente HTTP do ViaCEP (`https://viacep.com.br/ws/{cep}/json/`). Substituído por um fake nos testes. */
@Injectable()
export class ViaCepClient {
  /** `null` quando o ViaCEP responde `{ erro: true }` (CEP inexistente). Lança erro em falha de rede. */
  async buscar(cep: string): Promise<RespostaViaCep | null> {
    const resposta = await fetch(`${URL_VIACEP}/${cep}/json/`, {
      signal: AbortSignal.timeout(TIMEOUT_MS),
      headers: { Accept: 'application/json' },
    });
    if (resposta.status === 400) return null;
    if (!resposta.ok) throw new Error(`ViaCEP respondeu ${resposta.status}`);
    const corpo = (await resposta.json()) as RespostaViaCep & { erro?: boolean | string };
    if (corpo.erro) return null;
    return corpo;
  }
}
