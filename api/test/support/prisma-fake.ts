import { randomUUID } from 'node:crypto';
import type { Cliente } from '../../prisma/generated/prisma/client';

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
}
