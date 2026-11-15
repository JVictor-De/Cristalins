import { randomUUID } from 'node:crypto';
import type Decimal from 'decimal.js';
import type { Cliente } from '../../prisma/generated/prisma/client';
import {
  cupomSeed,
  FatorTeste,
  fatoresSeed,
  KitTeste,
  kitsSeed,
  ProdutoTeste,
  produtosSeed,
  zonasSeed,
} from './catalogo';

type ChaveUnica = { id?: string; email?: string; cpfCnpj?: string };

/** Erro com o mesmo `code` que o Prisma usa para violação de unicidade. */
class ErroUnicidade extends Error {
  readonly code = 'P2002';
}

/**
 * PrismaService em memória, só com o que auth/clientes usam. Respeita as chaves únicas
 * (email, cpfCnpj) do schema. Os testes e2e rodam sem Postgres.
 */
export class PrismaFake {
  private readonly clientes = new Map<string, Cliente>();

  $queryRaw = jest.fn().mockResolvedValue([{ '?column?': 1 }]);
  $disconnect = jest.fn();

  cliente = {
    findUnique: async ({ where }: { where: ChaveUnica }): Promise<Cliente | null> => {
      for (const c of this.clientes.values()) {
        if (
          (where.id !== undefined && c.id === where.id) ||
          (where.email !== undefined && c.email === where.email) ||
          (where.cpfCnpj !== undefined && c.cpfCnpj === where.cpfCnpj)
        ) {
          return { ...c };
        }
      }
      return null;
    },

    create: async ({ data }: { data: Partial<Cliente> }): Promise<Cliente> => {
      for (const c of this.clientes.values()) {
        if (c.email === data.email || c.cpfCnpj === data.cpfCnpj) throw new ErroUnicidade();
      }
      const agora = new Date();
      const cliente: Cliente = {
        id: randomUUID(),
        nome: '',
        cpfCnpj: '',
        email: '',
        celular: null,
        dataNascimento: null,
        senhaHash: '',
        papel: 'CLIENTE',
        asaasCustomerId: null,
        aceiteTermosEm: null,
        marketingOk: false,
        codigoIndicacao: null,
        indicadoPorId: null,
        pushToken: null,
        excluidoEm: null,
        criadoEm: agora,
        atualizadoEm: agora,
        ...data,
      } as Cliente;
      this.clientes.set(cliente.id, cliente);
      return { ...cliente };
    },

    update: async ({ where, data }: { where: { id: string }; data: Partial<Cliente> }) => {
      const atual = this.clientes.get(where.id);
      if (!atual) throw new Error('Registro não encontrado');
      const novo = { ...atual, ...data, atualizadoEm: new Date() };
      this.clientes.set(novo.id, novo);
      return { ...novo };
    },
  };

  /** Atalho para os testes criarem usuários direto (ex.: admin do seed). */
  inserir(dados: Partial<Cliente>): Promise<Cliente> {
    return this.cliente.create({ data: dados });
  }

  // ---------- Catálogo, preço e quiz (cr-1-preco) ----------

  produtos: ProdutoTeste[] = [];
  kits: KitTeste[] = [];
  fatores: FatorTeste[] = [];
  cupons: CupomFake[] = [];
  zonas: ZonaFake[] = [];
  enderecos: EnderecoFake[] = [];
  ciclos: CicloFake[] = [];
  pagamentos: PagamentoFake[] = [];
  recomendacoes: RecomendacaoFake[] = [];

  /** Carrega o mesmo catálogo do seed. */
  carregarCatalogo(): this {
    this.produtos = produtosSeed();
    this.kits = kitsSeed(this.produtos);
    this.fatores = fatoresSeed();
    this.cupons = [cupomSeed()];
    this.zonas = zonasSeed();
    return this;
  }

  produto = {
    findMany: async ({
      where = {},
    }: { where?: { ativo?: boolean; tipo?: string; codigo?: { in: string[] } }; orderBy?: unknown } = {}) =>
      this.produtos
        .filter((p) => where.ativo === undefined || p.ativo === where.ativo)
        .filter((p) => where.tipo === undefined || p.tipo === where.tipo)
        .filter((p) => !where.codigo || where.codigo.in.includes(p.codigo))
        .sort((a, b) => a.tipo.localeCompare(b.tipo) || a.codigo.localeCompare(b.codigo))
        .map((p) => ({ ...p })),
  };

  kit = {
    findMany: async () => this.kits.map((k) => ({ ...k, itens: k.itens.map((i) => ({ ...i })) })),
    findUnique: async ({ where }: { where: { objetivo?: string; codigo?: string } }) => {
      const k = this.kits.find((x) => x.objetivo === where.objetivo || x.codigo === where.codigo);
      return k ? { ...k, itens: k.itens.map((i) => ({ ...i })) } : null;
    },
  };

  fatorPreco = {
    findMany: async ({ where }: { where?: { ativoDe?: { lte: Date } } } = {}) =>
      this.fatores.filter((f) => !where?.ativoDe || f.ativoDe <= where.ativoDe.lte),
  };

  cupom = {
    findUnique: async ({ where }: { where: { codigo: string } }) =>
      this.cupons.find((c) => c.codigo === where.codigo) ?? null,
  };

  zona = {
    findUnique: async ({ where }: { where: { id: string } }) => this.zonas.find((z) => z.id === where.id) ?? null,
  };

  endereco = {
    findUnique: async ({ where }: { where: { id: string } }) => {
      const e = this.enderecos.find((x) => x.id === where.id);
      return e ? { ...e, zona: this.zonas.find((z) => z.id === e.zonaId) ?? null } : null;
    },
  };

  ciclo = {
    findUnique: async ({ where }: { where: { id: string } }) => {
      const c = this.ciclos.find((x) => x.id === where.id);
      return c ? { ...c, itens: [...c.itens] } : null;
    },
  };

  pagamento = {
    findMany: async ({
      where,
    }: {
      where: { status?: string; ciclo?: { assinaturaId?: string; numero?: { lte: number } } };
    }) =>
      this.pagamentos
        .filter((p) => !where.status || p.status === where.status)
        .filter((p) => {
          const c = this.ciclos.find((x) => x.id === p.cicloId);
          if (!c) return false;
          if (where.ciclo?.assinaturaId && c.assinaturaId !== where.ciclo.assinaturaId) return false;
          return !where.ciclo?.numero || c.numero <= where.ciclo.numero.lte;
        })
        .map((p) => ({ ...p })),
  };

  recomendacao = {
    create: async ({ data }: { data: Omit<RecomendacaoFake, 'id' | 'criadoEm'> }) => {
      const r: RecomendacaoFake = { id: randomUUID(), criadoEm: new Date(), ...data };
      this.recomendacoes.push(r);
      return { ...r, kit: this.kits.find((k) => k.id === r.kitId) ?? null };
    },
    findMany: async ({ where }: { where: { clienteId: string }; orderBy?: unknown }) =>
      this.recomendacoes
        .filter((r) => r.clienteId === where.clienteId)
        .sort((a, b) => b.criadoEm.getTime() - a.criadoEm.getTime())
        .map((r) => ({ ...r, kit: this.kits.find((k) => k.id === r.kitId) ?? null })),
    findUnique: async ({ where }: { where: { id: string } }) => {
      const r = this.recomendacoes.find((x) => x.id === where.id);
      return r ? { ...r, kit: this.kits.find((k) => k.id === r.kitId) ?? null } : null;
    },
  };
}

export interface CupomFake {
  id: string;
  codigo: string;
  percentual: Decimal;
  validade: Date | null;
  usosMax: number | null;
  usos: number;
}

export interface ZonaFake {
  id: string;
  nome: string;
  bairros: string[];
  taxaEntrega: Decimal;
  diasEntrega: string[];
  ativa: boolean;
}

export interface EnderecoFake {
  id: string;
  clienteId: string;
  zonaId: string;
}

export interface CicloFake {
  id: string;
  assinaturaId: string;
  numero: number;
  assinatura: { clienteId: string; cupomId?: string | null };
  itens: { produtoId: string; quantidade: number; precoUnitario: Decimal }[];
}

export interface PagamentoFake {
  id: string;
  cicloId: string;
  status: string;
  vencimento: Date;
  pagoEm: Date | null;
}

export interface RecomendacaoFake {
  id: string;
  clienteId: string;
  respostas: unknown;
  kitId: string | null;
  multiplicador: number | null;
  frequencia: string | null;
  itens: unknown;
  ue: Decimal;
  valorEstimado: Decimal | null;
  perfilEmpresa: boolean;
  criadoEm: Date;
}
