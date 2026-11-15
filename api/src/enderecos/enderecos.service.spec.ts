import { PrismaService } from '../common/prisma.service';
import { RegraNegocioException } from '../common/regra-negocio.exception';
import { ClockFixo } from '../../test/support/criar-app';
import { PrismaFake } from '../../test/support/prisma-fake';
import { CepService } from './cep.service';
import { EnderecosService } from './enderecos.service';
import { RespostaViaCep, ViaCepClient } from './viacep.client';

const CLIENTE = 'cliente-1';

/** ViaCEP falso: CEPs reais do Rio usados nos testes. */
class ViaCepFake extends ViaCepClient {
  chamadas: string[] = [];
  respostas: Record<string, RespostaViaCep | null> = {
    '22041001': { cep: '22041-001', logradouro: 'Avenida Nossa Senhora de Copacabana', bairro: 'Copacabana', localidade: 'Rio de Janeiro', uf: 'RJ' },
    '20550013': { cep: '20550-013', logradouro: 'Rua Barão de Mesquita', bairro: 'Grajaú', localidade: 'Rio de Janeiro', uf: 'RJ' },
    '20735040': { cep: '20735-040', logradouro: 'Rua Dias da Cruz', bairro: 'Méier', localidade: 'Rio de Janeiro', uf: 'RJ' },
    '23000000': null,
    '24020000': { cep: '24020-000', logradouro: 'Rua Qualquer', bairro: 'Centro', localidade: 'Niterói', uf: 'RJ' },
    '20000001': { cep: '20000-001', logradouro: '', bairro: 'Centro', localidade: 'Niterói', uf: 'RJ' },
  };

  override async buscar(cep: string): Promise<RespostaViaCep | null> {
    this.chamadas.push(cep);
    if (!(cep in this.respostas)) throw new Error('CEP não previsto no teste');
    return this.respostas[cep];
  }
}

async function codigo(p: Promise<unknown>): Promise<string> {
  try {
    await p;
  } catch (e) {
    if (e instanceof RegraNegocioException) return e.codigo;
    throw e;
  }
  throw new Error('esperava erro');
}

describe('CEP e endereços', () => {
  let prisma: PrismaFake;
  let viaCep: ViaCepFake;
  let cep: CepService;
  let enderecos: EnderecosService;

  beforeEach(() => {
    prisma = new PrismaFake().carregarCatalogo();
    viaCep = new ViaCepFake();
    cep = new CepService(prisma as unknown as PrismaService, viaCep);
    enderecos = new EnderecosService(prisma as unknown as PrismaService, cep, new ClockFixo());
  });

  describe('CepService', () => {
    it('CT08: CEP de São Paulo (01310-100) → CEP_FORA_AREA sem consultar o ViaCEP', async () => {
      expect(await codigo(cep.consultar('01310-100'))).toBe('CEP_FORA_AREA');
      expect(viaCep.chamadas).toEqual([]);
    });

    it('CEP na faixa mas de outra cidade → CEP_FORA_AREA', async () => {
      expect(await codigo(cep.consultar('20000-001'))).toBe('CEP_FORA_AREA');
    });

    it('CEP fora da faixa 20000-000 a 23799-999 (ex.: Niterói 24020-000) → CEP_FORA_AREA', async () => {
      expect(await codigo(cep.consultar('24020-000'))).toBe('CEP_FORA_AREA');
    });

    it('formato inválido → 400 CEP_INVALIDO; inexistente no ViaCEP → CEP_INVALIDO', async () => {
      expect(await codigo(cep.consultar('2204'))).toBe('CEP_INVALIDO');
      expect(await codigo(cep.consultar('23000-000'))).toBe('CEP_INVALIDO');
    });

    it('CT23: bairro do Rio sem zona (Grajaú) → BAIRRO_NAO_ATENDIDO', async () => {
      const erro = await cep.consultar('20550-013').catch((e: RegraNegocioException) => e);
      expect(erro).toBeInstanceOf(RegraNegocioException);
      expect((erro as RegraNegocioException).getResponse()).toMatchObject({
        codigo: 'BAIRRO_NAO_ATENDIDO',
        campo: 'bairro',
      });
    });

    it('bairro atendido devolve endereço, zona, taxa e dias', async () => {
      await expect(cep.consultar('22041001')).resolves.toMatchObject({
        cep: '22041001',
        logradouro: 'Avenida Nossa Senhora de Copacabana',
        bairro: 'Copacabana',
        localidade: 'Rio de Janeiro',
        uf: 'RJ',
        zona: { nome: 'Zona Sul', taxaEntrega: 9.9, diasEntrega: ['SEG', 'QUA', 'SEX'] },
      });
    });

    it('compara bairro sem acento nem caixa (Méier)', async () => {
      await expect(cep.consultar('20735-040')).resolves.toMatchObject({ zona: { nome: 'Zona Norte' } });
    });

    it('zona inativa não atende', async () => {
      prisma.zonas.find((z) => z.nome === 'Zona Sul')!.ativa = false;
      expect(await codigo(cep.consultar('22041-001'))).toBe('BAIRRO_NAO_ATENDIDO');
    });

    it('ViaCEP fora do ar → 502 GATEWAY_INDISPONIVEL', async () => {
      viaCep.buscar = async () => {
        throw new Error('timeout');
      };
      expect(await codigo(cep.consultar('22041-001'))).toBe('GATEWAY_INDISPONIVEL');
    });
  });

  describe('EnderecosService', () => {
    const novo = { cep: '22041-001', numero: '100', apelido: 'Casa' };

    it('cria com logradouro, bairro e zona do CEP; lat/lng nulos; o primeiro é principal', async () => {
      const e = await enderecos.criar(CLIENTE, novo);
      expect(e).toMatchObject({
        cep: '22041001',
        logradouro: 'Avenida Nossa Senhora de Copacabana',
        bairro: 'Copacabana',
        numero: '100',
        principal: true,
        lat: null,
        lng: null,
        zona: { nome: 'Zona Sul' },
      });
    });

    it('CEP fora da área ou bairro sem zona não cria endereço', async () => {
      expect(await codigo(enderecos.criar(CLIENTE, { ...novo, cep: '01310-100' }))).toBe('CEP_FORA_AREA');
      expect(await codigo(enderecos.criar(CLIENTE, { ...novo, cep: '20550-013' }))).toBe('BAIRRO_NAO_ATENDIDO');
      expect(prisma.enderecos).toHaveLength(0);
    });

    it('novo principal desmarca o anterior; lista só os do cliente', async () => {
      const a = await enderecos.criar(CLIENTE, novo);
      const b = await enderecos.criar(CLIENTE, { ...novo, cep: '20735-040', principal: true });
      await enderecos.criar('outro', novo);
      const lista = await enderecos.listar(CLIENTE);
      expect(lista).toHaveLength(2);
      expect(lista.find((x) => x.id === a.id)!.principal).toBe(false);
      expect(lista.find((x) => x.id === b.id)!.principal).toBe(true);
    });

    it('alterar e remover exigem ser o dono (SEM_PERMISSAO) e existir (NAO_ENCONTRADO)', async () => {
      const e = await enderecos.criar(CLIENTE, novo);
      expect(await codigo(enderecos.atualizar('outro', e.id, { numero: '9' }))).toBe('SEM_PERMISSAO');
      expect(await codigo(enderecos.remover('outro', e.id))).toBe('SEM_PERMISSAO');
      expect(await codigo(enderecos.atualizar(CLIENTE, 'nao-existe', { numero: '9' }))).toBe('NAO_ENCONTRADO');
    });

    it('alterar o CEP recalcula bairro e zona', async () => {
      const e = await enderecos.criar(CLIENTE, novo);
      const r = await enderecos.atualizar(CLIENTE, e.id, { cep: '20735-040', numero: '5' });
      expect(r).toMatchObject({ bairro: 'Méier', numero: '5', zona: { nome: 'Zona Norte' } });
    });

    it('não remove o principal nem endereço usado por assinatura', async () => {
      const principal = await enderecos.criar(CLIENTE, novo);
      const outro = await enderecos.criar(CLIENTE, { ...novo, cep: '20735-040' });
      expect(await codigo(enderecos.remover(CLIENTE, principal.id))).toBe('ENDERECO_PRINCIPAL');
      prisma.assinaturas.push({ id: 'a1', clienteId: CLIENTE, enderecoId: outro.id, status: 'ATIVA' });
      expect(await codigo(enderecos.remover(CLIENTE, outro.id))).toBe('ENDERECO_EM_USO');
      prisma.assinaturas = [];
      await enderecos.remover(CLIENTE, outro.id);
      expect(prisma.enderecos).toHaveLength(1);
    });

    it('APOS_CORTE: não muda CEP/número de endereço de entrega já travada no corte', async () => {
      const e = await enderecos.criar(CLIENTE, novo);
      // Entrega 16/11 → corte 14/11 23:59; o relógio fixo está em 14/11 12:00 (antes do corte)
      prisma.ciclos.push({ id: 'c1', assinaturaId: 'a1', numero: 1, enderecoId: e.id, status: 'PAGO', dataEntrega: new Date('2026-11-16T00:00:00Z'), dataCorte: new Date('2026-11-15T02:59:59.999Z') });
      await enderecos.atualizar(CLIENTE, e.id, { numero: '101' });
      // Entrega 15/11 → corte 13/11 23:59 (já passou)
      prisma.ciclos.push({ id: 'c2', assinaturaId: 'a1', numero: 2, enderecoId: e.id, status: 'PAGO', dataEntrega: new Date('2026-11-15T00:00:00Z'), dataCorte: new Date('2026-11-14T02:59:59.999Z') });
      expect(await codigo(enderecos.atualizar(CLIENTE, e.id, { numero: '102' }))).toBe('APOS_CORTE');
      // Campos que não mudam a entrega continuam livres
      await expect(enderecos.atualizar(CLIENTE, e.id, { instrucoes: 'Portaria 24h' })).resolves.toMatchObject({ instrucoes: 'Portaria 24h' });
    });
  });
});
