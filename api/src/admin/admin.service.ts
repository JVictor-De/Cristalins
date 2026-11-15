import { HttpStatus, Injectable } from '@nestjs/common';
import { PrismaService } from '../common/prisma.service';
import { RegraNegocioException } from '../common/regra-negocio.exception';
import { dec } from '../precos/preco.tipos';
import { AtualizarFatorDto, AtualizarProdutoDto, AtualizarZonaDto } from './dto/admin.dto';

/** Chaves que o PrecoService entende (mais qualquer DEMANDA_*). */
export const CHAVES_FATOR = [
  'VOLUME_24_47',
  'VOLUME_48_MAIS',
  'COMPROMISSO_TRIMESTRAL',
  'COMPROMISSO_EMPRESA',
  'FIDELIDADE_POR_CICLO',
  'FIDELIDADE_MAXIMO',
];

const invalido = (mensagem: string, campo: string) =>
  new RegraNegocioException('DADOS_INVALIDOS', mensagem, HttpStatus.BAD_REQUEST, campo);
const naoEncontrado = (o: string) => new RegraNegocioException('NAO_ENCONTRADO', `${o} não encontrado.`, HttpStatus.NOT_FOUND);
const num = (v: { toString(): string } | null) => (v === null ? null : dec(v).toNumber());
const iso = (d: Date | null) => (d ? d.toISOString().slice(0, 10) : null);

/**
 * Administração sem tela (RF/Fase 1): preço, piso, estoque e ativo do produto; fatores do preço;
 * taxa, dias e bairros da zona. Valem para cálculos novos; cobrança já gerada mantém o preço (RN19).
 */
@Injectable()
export class AdminService {
  constructor(private readonly prisma: PrismaService) {}

  async atualizarProduto(id: string, dto: AtualizarProdutoDto) {
    const atual = await this.prisma.produto.findUnique({ where: { id } });
    if (!atual) throw naoEncontrado('Produto');
    const base = dto.precoBase ?? dec(atual.precoBase).toNumber();
    const piso = dto.precoPiso ?? dec(atual.precoPiso).toNumber();
    if (piso > base) throw invalido('O preço piso não pode ser maior que o preço base.', 'precoPiso');
    const p = await this.prisma.produto.update({
      where: { id },
      data: {
        ...(dto.precoBase !== undefined && { precoBase: String(dto.precoBase) }),
        ...(dto.precoPiso !== undefined && { precoPiso: String(dto.precoPiso) }),
        ...(dto.estoque !== undefined && { estoque: dto.estoque }),
        ...(dto.ativo !== undefined && { ativo: dto.ativo }),
      },
    });
    return { id: p.id, codigo: p.codigo, precoBase: num(p.precoBase), precoPiso: num(p.precoPiso), estoque: p.estoque, ativo: p.ativo };
  }

  /** Cria ou atualiza o fator da chave na vigência `ativoDe` (histórico preservado por vigência). */
  async atualizarFator(dto: AtualizarFatorDto) {
    if (!CHAVES_FATOR.includes(dto.chave) && !dto.chave.startsWith('DEMANDA_')) {
      throw invalido(`Chave desconhecida. Use ${CHAVES_FATOR.join(', ')} ou DEMANDA_*.`, 'chave');
    }
    if (!dto.chave.startsWith('DEMANDA_') && dto.valor < 0) {
      throw invalido('Descontos usam fração positiva (0,08 = 8%).', 'valor');
    }
    if (dto.ativoAte && dto.ativoAte < dto.ativoDe) throw invalido('O fim da vigência é antes do início.', 'ativoAte');
    const ativoDe = new Date(`${dto.ativoDe}T00:00:00.000Z`);
    const dados = {
      valor: String(dto.valor),
      ativoAte: dto.ativoAte ? new Date(`${dto.ativoAte}T00:00:00.000Z`) : null,
    };
    const f = await this.prisma.fatorPreco.upsert({
      where: { chave_ativoDe: { chave: dto.chave, ativoDe } },
      create: { chave: dto.chave, ativoDe, ...dados },
      update: dados,
    });
    return { id: f.id, chave: f.chave, valor: num(f.valor), ativoDe: iso(f.ativoDe), ativoAte: iso(f.ativoAte) };
  }

  async atualizarZona(id: string, dto: AtualizarZonaDto) {
    const atual = await this.prisma.zona.findUnique({ where: { id } });
    if (!atual) throw naoEncontrado('Zona');
    if (dto.diasEntrega && dto.diasEntrega.length === 0) {
      throw invalido('A zona precisa de pelo menos um dia de entrega.', 'diasEntrega');
    }
    const z = await this.prisma.zona.update({
      where: { id },
      data: {
        ...(dto.taxaEntrega !== undefined && { taxaEntrega: String(dto.taxaEntrega) }),
        ...(dto.diasEntrega !== undefined && { diasEntrega: dto.diasEntrega }),
        ...(dto.bairros !== undefined && { bairros: dto.bairros.map((b) => b.trim()) }),
        ...(dto.ativa !== undefined && { ativa: dto.ativa }),
      },
    });
    return { id: z.id, nome: z.nome, taxaEntrega: num(z.taxaEntrega), diasEntrega: z.diasEntrega, bairros: z.bairros, ativa: z.ativa };
  }
}
