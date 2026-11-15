import { HttpStatus, Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../common/prisma.service';
import { RegraNegocioException } from '../common/regra-negocio.exception';
import { DiaSemana } from '../../prisma/generated/prisma/client';
import { ViaCepClient } from './viacep.client';

/** Faixa de CEP do município do Rio de Janeiro (CONTEXTO, "Endereço"). */
export const CEP_RIO = { inicio: 20000000, fim: 23799999 };
const CIDADE = 'Rio de Janeiro';
const UF = 'RJ';

export interface ZonaDoCep {
  id: string;
  nome: string;
  taxaEntrega: number;
  diasEntrega: DiaSemana[];
}

export interface CepConsultado {
  cep: string;
  logradouro: string;
  bairro: string;
  localidade: string;
  uf: string;
  zona: ZonaDoCep;
}

/** Compara bairros sem acento, caixa nem espaços extras ("Méier" = "meier"). */
export function normalizarBairro(bairro: string): string {
  return bairro.normalize('NFD').replace(/[̀-ͯ]/g, '').trim().toLowerCase().replace(/\s+/g, ' ');
}

@Injectable()
export class CepService {
  private readonly logger = new Logger(CepService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly viaCep: ViaCepClient,
  ) {}

  /**
   * Ordem: formato → faixa do Rio (sem rede, CT08) → ViaCEP → cidade/UF → zona pelo bairro (CT23).
   */
  async consultar(cepInformado: string): Promise<CepConsultado> {
    const cep = cepInformado.replace(/\D/g, '');
    if (cep.length !== 8) {
      throw new RegraNegocioException('CEP_INVALIDO', 'Informe um CEP com 8 dígitos.', HttpStatus.BAD_REQUEST, 'cep');
    }
    const numero = Number(cep);
    if (numero < CEP_RIO.inicio || numero > CEP_RIO.fim) throw this.foraDaArea();

    let dados;
    try {
      dados = await this.viaCep.buscar(cep);
    } catch (erro) {
      this.logger.warn(`ViaCEP indisponível: ${(erro as Error).message}`);
      throw new RegraNegocioException(
        'GATEWAY_INDISPONIVEL',
        'Não conseguimos consultar o CEP agora. Tente de novo em instantes.',
        HttpStatus.BAD_GATEWAY,
        'cep',
      );
    }
    if (!dados) {
      throw new RegraNegocioException('CEP_INVALIDO', 'CEP não encontrado. Confira os números.', HttpStatus.BAD_REQUEST, 'cep');
    }
    if (dados.localidade !== CIDADE || dados.uf !== UF) throw this.foraDaArea();

    const zona = await this.zonaDoBairro(dados.bairro);
    if (!zona) {
      throw new RegraNegocioException(
        'BAIRRO_NAO_ATENDIDO',
        `Ainda não entregamos em ${dados.bairro || 'este bairro'}. Deixe seu e-mail na lista de espera.`,
        HttpStatus.UNPROCESSABLE_ENTITY,
        'bairro',
      );
    }
    return {
      cep,
      logradouro: dados.logradouro,
      bairro: dados.bairro,
      localidade: dados.localidade,
      uf: dados.uf,
      zona,
    };
  }

  /** Zona ativa que lista o bairro (mapa do seed; lista oficial em `cr-8-bairros`). */
  async zonaDoBairro(bairro: string): Promise<ZonaDoCep | null> {
    if (!bairro) return null;
    const alvo = normalizarBairro(bairro);
    const zonas = await this.prisma.zona.findMany({ where: { ativa: true } });
    const zona = zonas.find((z) => z.bairros.some((b) => normalizarBairro(b) === alvo));
    if (!zona) return null;
    return {
      id: zona.id,
      nome: zona.nome,
      taxaEntrega: Number(zona.taxaEntrega.toString()),
      diasEntrega: zona.diasEntrega,
    };
  }

  private foraDaArea(): RegraNegocioException {
    return new RegraNegocioException(
      'CEP_FORA_AREA',
      'Por enquanto entregamos só no município do Rio de Janeiro.',
      HttpStatus.UNPROCESSABLE_ENTITY,
      'cep',
    );
  }
}
