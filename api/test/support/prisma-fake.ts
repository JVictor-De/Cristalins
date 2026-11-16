/* eslint-disable @typescript-eslint/no-explicit-any -- dublê genérico do Prisma: linhas e filtros são dinâmicos por natureza */
import { randomUUID } from 'node:crypto';
import Decimal from 'decimal.js';
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

/**
 * PrismaService em memória para testes sem Postgres.
 *
 * Suporta o subconjunto da API do Prisma Client que os services usam: findUnique/findFirst/
 * findMany/count/create/createMany/update/updateMany/upsert/delete/deleteMany, `where` com
 * igualdade, operadores (in, notIn, lt, lte, gt, gte, not, startsWith), OR/AND/NOT, filtros por
 * relação (to-one e `some`), chaves compostas (`a_b`), `include`, `orderBy`, `increment`,
 * `$transaction` e unicidade das chaves do schema (erro P2002). Exclusão de ciclo apaga em cascata.
 */

type Linha = Record<string, any>;
type Where = Record<string, any>;

class ErroUnicidade extends Error {
  readonly code = 'P2002';
}

const OPERADORES = ['in', 'notIn', 'lt', 'lte', 'gt', 'gte', 'not', 'equals', 'startsWith', 'some', 'none', 'every'];

const ehObjetoSimples = (v: unknown): v is Record<string, any> =>
  typeof v === 'object' && v !== null && !(v instanceof Date) && !(v instanceof Decimal) && !Array.isArray(v) &&
  !(typeof (v as { toFixed?: unknown }).toFixed === 'function' && typeof (v as { d?: unknown }).d !== 'undefined');

function valorComparavel(v: unknown): unknown {
  if (v instanceof Date) return v.getTime();
  if (v !== null && typeof v === 'object' && typeof (v as { toString(): string }).toString === 'function' && 'd' in (v as object)) {
    return Number((v as { toString(): string }).toString());
  }
  return v;
}

function iguais(a: unknown, b: unknown): boolean {
  return valorComparavel(a) === valorComparavel(b);
}

interface Relacao {
  modelo: string;
  /** to-one: campo local → id remoto; to-many: campo remoto → id local. */
  tipo: 'um' | 'muitos' | 'umReverso';
  campo: string;
}

const RELACOES: Record<string, Record<string, Relacao>> = {
  cliente: {
    enderecos: { modelo: 'endereco', tipo: 'muitos', campo: 'clienteId' },
    assinaturas: { modelo: 'assinatura', tipo: 'muitos', campo: 'clienteId' },
  },
  endereco: {
    cliente: { modelo: 'cliente', tipo: 'um', campo: 'clienteId' },
    zona: { modelo: 'zona', tipo: 'um', campo: 'zonaId' },
    assinaturas: { modelo: 'assinatura', tipo: 'muitos', campo: 'enderecoId' },
    ciclos: { modelo: 'ciclo', tipo: 'muitos', campo: 'enderecoId' },
  },
  recomendacao: { kit: { modelo: 'kit', tipo: 'um', campo: 'kitId' } },
  assinatura: {
    cliente: { modelo: 'cliente', tipo: 'um', campo: 'clienteId' },
    endereco: { modelo: 'endereco', tipo: 'um', campo: 'enderecoId' },
    cupom: { modelo: 'cupom', tipo: 'um', campo: 'cupomId' },
    cartao: { modelo: 'cartao', tipo: 'um', campo: 'cartaoId' },
    itens: { modelo: 'itemAssinatura', tipo: 'muitos', campo: 'assinaturaId' },
    ciclos: { modelo: 'ciclo', tipo: 'muitos', campo: 'assinaturaId' },
  },
  itemAssinatura: { produto: { modelo: 'produto', tipo: 'um', campo: 'produtoId' } },
  ciclo: {
    assinatura: { modelo: 'assinatura', tipo: 'um', campo: 'assinaturaId' },
    endereco: { modelo: 'endereco', tipo: 'um', campo: 'enderecoId' },
    itens: { modelo: 'itemCiclo', tipo: 'muitos', campo: 'cicloId' },
    pagamentos: { modelo: 'pagamento', tipo: 'muitos', campo: 'cicloId' },
    calculoPreco: { modelo: 'calculoPreco', tipo: 'umReverso', campo: 'cicloId' },
    ocorrencias: { modelo: 'ocorrencia', tipo: 'muitos', campo: 'cicloId' },
  },
  ocorrencia: { ciclo: { modelo: 'ciclo', tipo: 'um', campo: 'cicloId' } },
  itemCiclo: { produto: { modelo: 'produto', tipo: 'um', campo: 'produtoId' } },
  calculoPreco: { ciclo: { modelo: 'ciclo', tipo: 'um', campo: 'cicloId' } },
  pagamento: { ciclo: { modelo: 'ciclo', tipo: 'um', campo: 'cicloId' } },
};

/** Chaves únicas do schema (além de `id`). */
const UNICOS: Record<string, string[][]> = {
  cliente: [['email'], ['cpfCnpj']],
  produto: [['codigo']],
  kit: [['codigo']],
  zona: [['nome']],
  cupom: [['codigo']],
  ciclo: [['assinaturaId', 'numero']],
  calculoPreco: [['cicloId']],
  itemCiclo: [['cicloId', 'produtoId']],
  itemAssinatura: [['assinaturaId', 'produtoId']],
  fatorPreco: [['chave', 'ativoDe']],
  pagamento: [['asaasPaymentId']],
  eventoWebhook: [['idEvento']],
};

/** Campos Decimal: gravados como decimal.js, como o Prisma devolve. */
const DECIMAIS: Record<string, string[]> = {
  produto: ['ue', 'precoBase', 'precoPiso', 'pesoKg'],
  zona: ['taxaEntrega'],
  recomendacao: ['ue', 'valorEstimado'],
  itemCiclo: ['precoUnitario'],
  calculoPreco: ['subtotal', 'frete', 'creditos', 'valorFinal'],
  pagamento: ['valor'],
  cupom: ['percentual'],
  fatorPreco: ['valor'],
  credito: ['valor'],
  endereco: ['lat', 'lng'],
};

/** Valores padrão do schema na criação. */
function padroes(modelo: string): Linha {
  const agora = new Date();
  const comuns = { id: randomUUID() };
  switch (modelo) {
    case 'cliente':
      return {
        ...comuns,
        celular: null,
        dataNascimento: null,
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
      };
    case 'endereco':
      return {
        ...comuns,
        apelido: null,
        complemento: null,
        referencia: null,
        instrucoes: null,
        lat: null,
        lng: null,
        principal: false,
        criadoEm: agora,
        atualizadoEm: agora,
      };
    case 'assinatura':
      return {
        ...comuns,
        formaPagamento: 'PIX',
        cartaoId: null,
        cupomId: null,
        status: 'AGUARDANDO_PAGAMENTO',
        inicio: null,
        fimCompromisso: null,
        criadoEm: agora,
        atualizadoEm: agora,
      };
    case 'ciclo':
      return { ...comuns, tentativasEntrega: 0, status: 'AGENDADO', criadoEm: agora, atualizadoEm: agora };
    case 'calculoPreco':
      return { ...comuns, creditos: new Decimal(0), criadoEm: agora };
    case 'pagamento':
      return { ...comuns, asaasPaymentId: null, linkPagamento: null, status: 'PENDENTE', pagoEm: null, criadoEm: agora, atualizadoEm: agora };
    case 'credito':
      return { ...comuns, expiraEm: null, usadoEm: null, criadoEm: agora };
    case 'cartao':
      return { ...comuns, criadoEm: agora };
    case 'ocorrencia':
      return { ...comuns, fotoUrl: null, produtoId: null, quantidade: null, solucao: null, status: 'ABERTA', criadoEm: agora };
    case 'cupom':
      return { ...comuns, validade: null, usosMax: null, usos: 0 };
    case 'eventoWebhook':
      return { ...comuns, processadoEm: null, erro: null, recebidoEm: agora };
    case 'recomendacao':
    case 'listaEspera':
      return { ...comuns, criadoEm: agora };
    case 'itemCiclo':
    case 'itemAssinatura':
    case 'kitItem':
      return {};
    default:
      return comuns;
  }
}

export class PrismaFake {
  // Tabelas públicas: os testes podem ler e montar cenários direto nelas.
  clientes: Linha[] = [];
  produtos: ProdutoTeste[] = [];
  kits: KitTeste[] = [];
  fatores: FatorTeste[] = [];
  cupons: Linha[] = [];
  zonas: Linha[] = [];
  enderecos: Linha[] = [];
  recomendacoes: Linha[] = [];
  assinaturas: Linha[] = [];
  itensAssinatura: Linha[] = [];
  ciclos: Linha[] = [];
  itensCiclo: Linha[] = [];
  calculos: Linha[] = [];
  pagamentos: Linha[] = [];
  eventosWebhook: Linha[] = [];
  creditos: Linha[] = [];
  cartoes: Linha[] = [];
  ocorrencias: Linha[] = [];
  filaEspera: Linha[] = [];

  $queryRaw = jest.fn().mockResolvedValue([{ '?column?': 1 }]);
  $disconnect = jest.fn();

  private tabela(modelo: string): Linha[] {
    const mapa: Record<string, keyof PrismaFake> = {
      cliente: 'clientes',
      produto: 'produtos',
      kit: 'kits',
      fatorPreco: 'fatores',
      cupom: 'cupons',
      zona: 'zonas',
      endereco: 'enderecos',
      recomendacao: 'recomendacoes',
      assinatura: 'assinaturas',
      itemAssinatura: 'itensAssinatura',
      ciclo: 'ciclos',
      itemCiclo: 'itensCiclo',
      calculoPreco: 'calculos',
      pagamento: 'pagamentos',
      eventoWebhook: 'eventosWebhook',
      credito: 'creditos',
      cartao: 'cartoes',
      ocorrencia: 'ocorrencias',
      listaEspera: 'filaEspera',
    };
    return this[mapa[modelo]] as unknown as Linha[];
  }

  /** Carrega o mesmo catálogo do seed. */
  carregarCatalogo(): this {
    this.produtos = produtosSeed();
    this.kits = kitsSeed(this.produtos);
    this.fatores = fatoresSeed();
    this.cupons = [cupomSeed()];
    this.zonas = zonasSeed().map((z) => ({ ...z, diasEntrega: DIAS_DO_SEED[z.nome] ?? [] }));
    return this;
  }

  /** Atalho para os testes criarem clientes direto (ex.: admin do seed). */
  inserir(dados: Partial<Cliente>): Promise<Cliente> {
    return this.cliente.create({ data: dados }) as Promise<Cliente>;
  }

  async $transaction<T>(arg: ((tx: this) => Promise<T>) | Promise<unknown>[]): Promise<T | unknown[]> {
    return typeof arg === 'function' ? arg(this) : Promise.all(arg);
  }

  // ---------- Núcleo genérico ----------

  private relacionado(modelo: string, linha: Linha, nome: string): Linha | Linha[] | null | undefined {
    // Compatibilidade: cenários antigos embutem `itens`/`assinatura` no próprio ciclo.
    if (modelo === 'ciclo' && nome === 'itens' && Array.isArray(linha.itens)) return linha.itens;
    if (modelo === 'kit' && nome === 'itens') return linha.itens;
    const rel = RELACOES[modelo]?.[nome];
    if (!rel) return undefined;
    const remota = this.tabela(rel.modelo);
    if (rel.tipo === 'um') {
      const achado = remota.find((r) => r.id === linha[rel.campo]) ?? null;
      if (!achado && modelo === 'ciclo' && nome === 'assinatura' && linha.assinatura) return linha.assinatura;
      return achado;
    }
    if (rel.tipo === 'umReverso') return remota.find((r) => r[rel.campo] === linha.id) ?? null;
    return remota.filter((r) => r[rel.campo] === linha.id);
  }

  private casa(modelo: string, linha: Linha, where: Where | undefined): boolean {
    if (!where) return true;
    for (const [chave, esperado] of Object.entries(where)) {
      if (esperado === undefined) continue;
      if (chave === 'OR') {
        if (!(esperado as Where[]).some((w) => this.casa(modelo, linha, w))) return false;
        continue;
      }
      if (chave === 'AND') {
        if (!(esperado as Where[]).every((w) => this.casa(modelo, linha, w))) return false;
        continue;
      }
      if (chave === 'NOT') {
        if (this.casa(modelo, linha, esperado)) return false;
        continue;
      }
      // Chave composta: { assinaturaId_numero: { assinaturaId, numero } }
      if (chave.includes('_') && ehObjetoSimples(esperado) && !(chave in linha)) {
        if (!this.casa(modelo, linha, esperado)) return false;
        continue;
      }
      const rel = RELACOES[modelo]?.[chave] ?? (modelo === 'ciclo' && chave === 'assinatura' ? { modelo: 'assinatura', tipo: 'um' as const, campo: 'assinaturaId' } : undefined);
      if (rel) {
        const alvo = this.relacionado(modelo, linha, chave);
        if (rel.tipo === 'muitos') {
          const lista = (alvo as Linha[]) ?? [];
          if (esperado.some && !lista.some((r) => this.casa(rel.modelo, r, esperado.some))) return false;
          if (esperado.none && lista.some((r) => this.casa(rel.modelo, r, esperado.none))) return false;
          if (esperado.every && !lista.every((r) => this.casa(rel.modelo, r, esperado.every))) return false;
        } else {
          if (esperado === null) {
            if (alvo) return false;
          } else if (!alvo || !this.casa(rel.modelo, alvo as Linha, esperado)) return false;
        }
        continue;
      }
      const atual = linha[chave];
      if (ehObjetoSimples(esperado) && Object.keys(esperado).some((k) => OPERADORES.includes(k))) {
        const ops = esperado;
        if ('equals' in ops && !iguais(atual, ops.equals)) return false;
        if ('in' in ops && !ops.in.some((v: unknown) => iguais(atual, v))) return false;
        if ('notIn' in ops && ops.notIn.some((v: unknown) => iguais(atual, v))) return false;
        if ('not' in ops && (ehObjetoSimples(ops.not) ? this.casa(modelo, linha, { [chave]: ops.not }) : iguais(atual, ops.not))) return false;
        if ('startsWith' in ops && !(typeof atual === 'string' && atual.startsWith(ops.startsWith))) return false;
        const a = valorComparavel(atual) as number;
        if ('lt' in ops && !(atual !== null && a < (valorComparavel(ops.lt) as number))) return false;
        if ('lte' in ops && !(atual !== null && a <= (valorComparavel(ops.lte) as number))) return false;
        if ('gt' in ops && !(atual !== null && a > (valorComparavel(ops.gt) as number))) return false;
        if ('gte' in ops && !(atual !== null && a >= (valorComparavel(ops.gte) as number))) return false;
        continue;
      }
      if (Array.isArray(atual) && ehObjetoSimples(esperado) && 'has' in esperado) {
        if (!atual.includes(esperado.has)) return false;
        continue;
      }
      if (!iguais(atual, esperado)) return false;
    }
    return true;
  }

  private ordenar(lista: Linha[], orderBy: unknown): Linha[] {
    const criterios = (Array.isArray(orderBy) ? orderBy : orderBy ? [orderBy] : []) as Record<string, 'asc' | 'desc'>[];
    if (!criterios.length) return lista;
    return [...lista].sort((x, y) => {
      for (const c of criterios) {
        const [campo, dir] = Object.entries(c)[0];
        const a = valorComparavel(x[campo]) as any;
        const b = valorComparavel(y[campo]) as any;
        if (a === b) continue;
        const r = a < b ? -1 : 1;
        return dir === 'desc' ? -r : r;
      }
      return 0;
    });
  }

  private incluir(modelo: string, linha: Linha, include: Record<string, any> | undefined): Linha {
    const copia: Linha = { ...linha };
    if (!include) return copia;
    for (const [nome, opcao] of Object.entries(include)) {
      if (!opcao) continue;
      const rel = RELACOES[modelo]?.[nome];
      // Sem relação declarada (ex.: produto embutido no item do kit do seed): mantém o que já está na linha.
      const alvo = this.relacionado(modelo, linha, nome) ?? linha[nome];
      const sub = typeof opcao === 'object' ? opcao.include : undefined;
      const modeloAlvo = rel?.modelo ?? (nome === 'itens' ? (modelo === 'ciclo' ? 'itemCiclo' : 'kitItem') : nome);
      if (Array.isArray(alvo)) {
        let lista = alvo;
        if (typeof opcao === 'object' && opcao.where) lista = lista.filter((r) => this.casa(modeloAlvo, r, opcao.where));
        if (typeof opcao === 'object' && opcao.orderBy) lista = this.ordenar(lista, opcao.orderBy);
        copia[nome] = lista.map((r) => this.incluir(modeloAlvo, r, sub));
      } else {
        copia[nome] = alvo ? this.incluir(modeloAlvo, alvo, sub) : alvo ?? null;
      }
    }
    return copia;
  }

  private normalizar(modelo: string, dados: Linha, atual?: Linha): Linha {
    const saida: Linha = {};
    for (const [k, v] of Object.entries(dados)) {
      if (v === undefined) continue;
      if (ehObjetoSimples(v) && ('increment' in v || 'decrement' in v)) {
        const base = Number(atual?.[k] ?? 0);
        saida[k] = 'increment' in v ? base + v.increment : base - v.decrement;
        continue;
      }
      saida[k] = DECIMAIS[modelo]?.includes(k) && v !== null ? new Decimal(v.toString()) : v;
    }
    return saida;
  }

  private garantirUnico(modelo: string, linha: Linha, ignorar?: Linha): void {
    for (const campos of UNICOS[modelo] ?? []) {
      if (campos.some((c) => linha[c] === null || linha[c] === undefined)) continue;
      const conflito = this.tabela(modelo).find((r) => r !== ignorar && campos.every((c) => iguais(r[c], linha[c])));
      if (conflito) throw new ErroUnicidade(`Unique constraint failed: ${modelo}(${campos.join(', ')})`);
    }
  }

  private apagarEmCascata(modelo: string, linha: Linha): void {
    if (modelo === 'ciclo') {
      for (const filho of ['itemCiclo', 'calculoPreco', 'pagamento']) {
        const t = this.tabela(filho);
        for (let i = t.length - 1; i >= 0; i--) if (t[i].cicloId === linha.id) t.splice(i, 1);
      }
    }
    if (modelo === 'assinatura') {
      for (const c of this.ciclos.filter((x) => x.assinaturaId === linha.id)) this.apagarEmCascata('ciclo', c);
      this.ciclos = this.ciclos.filter((x) => x.assinaturaId !== linha.id);
      this.itensAssinatura = this.itensAssinatura.filter((x) => x.assinaturaId !== linha.id);
    }
  }

  private delegado(modelo: string) {
    const encontrar = (where: Where) => this.tabela(modelo).find((r) => this.casa(modelo, r, where));
    return {
      findUnique: async ({ where, include }: { where: Where; include?: Linha }) => {
        const r = encontrar(where);
        return r ? this.incluir(modelo, r, include) : null;
      },
      findFirst: async ({ where, orderBy, include }: { where?: Where; orderBy?: unknown; include?: Linha } = {}) => {
        const r = this.ordenar(this.tabela(modelo).filter((x) => this.casa(modelo, x, where)), orderBy)[0];
        return r ? this.incluir(modelo, r, include) : null;
      },
      findMany: async ({ where, orderBy, include, take }: { where?: Where; orderBy?: unknown; include?: Linha; take?: number } = {}) => {
        let lista = this.ordenar(this.tabela(modelo).filter((x) => this.casa(modelo, x, where)), orderBy);
        if (take !== undefined) lista = lista.slice(0, take);
        return lista.map((r) => this.incluir(modelo, r, include));
      },
      count: async ({ where }: { where?: Where } = {}) => this.tabela(modelo).filter((x) => this.casa(modelo, x, where)).length,
      create: async ({ data, include }: { data: Linha; include?: Linha }) => {
        const linha = { ...padroes(modelo), ...this.normalizar(modelo, data) };
        this.garantirUnico(modelo, linha);
        this.tabela(modelo).push(linha);
        return this.incluir(modelo, linha, include);
      },
      createMany: async ({ data }: { data: Linha[] }) => {
        for (const d of data) {
          const linha = { ...padroes(modelo), ...this.normalizar(modelo, d) };
          this.garantirUnico(modelo, linha);
          this.tabela(modelo).push(linha);
        }
        return { count: data.length };
      },
      update: async ({ where, data, include }: { where: Where; data: Linha; include?: Linha }) => {
        const r = encontrar(where);
        if (!r) throw Object.assign(new Error(`Registro não encontrado em ${modelo}`), { code: 'P2025' });
        const novo = { ...r, ...this.normalizar(modelo, data, r) };
        if ('atualizadoEm' in r) novo.atualizadoEm = new Date();
        this.garantirUnico(modelo, novo, r);
        Object.assign(r, novo);
        return this.incluir(modelo, r, include);
      },
      updateMany: async ({ where, data }: { where?: Where; data: Linha }) => {
        const alvos = this.tabela(modelo).filter((x) => this.casa(modelo, x, where));
        for (const r of alvos) Object.assign(r, this.normalizar(modelo, data, r));
        return { count: alvos.length };
      },
      upsert: async ({ where, create, update }: { where: Where; create: Linha; update: Linha }) => {
        const r = encontrar(where);
        if (r) {
          Object.assign(r, this.normalizar(modelo, update, r));
          return { ...r };
        }
        const linha = { ...padroes(modelo), ...this.normalizar(modelo, create) };
        this.garantirUnico(modelo, linha);
        this.tabela(modelo).push(linha);
        return { ...linha };
      },
      delete: async ({ where }: { where: Where }) => {
        const t = this.tabela(modelo);
        const i = t.findIndex((x) => this.casa(modelo, x, where));
        if (i < 0) throw Object.assign(new Error(`Registro não encontrado em ${modelo}`), { code: 'P2025' });
        const [r] = t.splice(i, 1);
        this.apagarEmCascata(modelo, r);
        return r;
      },
      deleteMany: async ({ where }: { where?: Where } = {}) => {
        const t = this.tabela(modelo);
        const alvos = t.filter((x) => this.casa(modelo, x, where));
        for (const r of alvos) {
          t.splice(t.indexOf(r), 1);
          this.apagarEmCascata(modelo, r);
        }
        return { count: alvos.length };
      },
    };
  }

  cliente = this.delegado('cliente');
  produto = this.delegado('produto');
  kit = this.delegado('kit');
  fatorPreco = this.delegado('fatorPreco');
  cupom = this.delegado('cupom');
  zona = this.delegado('zona');
  endereco = this.delegado('endereco');
  recomendacao = this.delegado('recomendacao');
  assinatura = this.delegado('assinatura');
  itemAssinatura = this.delegado('itemAssinatura');
  ciclo = this.delegado('ciclo');
  itemCiclo = this.delegado('itemCiclo');
  calculoPreco = this.delegado('calculoPreco');
  pagamento = this.delegado('pagamento');
  eventoWebhook = this.delegado('eventoWebhook');
  credito = this.delegado('credito');
  cartao = this.delegado('cartao');
  ocorrencia = this.delegado('ocorrencia');
  listaEspera = this.delegado('listaEspera');
}

/** Dias de entrega das zonas, iguais ao seed. */
const DIAS_DO_SEED: Record<string, string[]> = {
  Centro: ['SEG', 'QUA', 'SEX'],
  'Zona Sul': ['SEG', 'QUA', 'SEX'],
  'Barra e Recreio': ['TER', 'QUI', 'SAB'],
  'Zona Norte': ['TER', 'QUI'],
  'Zona Oeste': ['SAB'],
};

export type { Linha as LinhaFake };
