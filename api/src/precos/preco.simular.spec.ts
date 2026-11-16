import Decimal from 'decimal.js';
import { PrismaService } from '../common/prisma.service';
import { RegraNegocioException } from '../common/regra-negocio.exception';
import { ClockFixo } from '../../test/support/criar-app';
import { PrismaFake } from '../../test/support/prisma-fake';
import { SimularPrecoDto } from './dto/simular-preco.dto';
import { PrecoService } from './preco.service';

const CLIENTE = 'cliente-1';
const ZONA_SUL = 'zona-Zona-Sul';
const d = (iso: string) => new Date(`${iso}T00:00:00.000Z`);

function dto(extra: Partial<SimularPrecoDto> = {}): SimularPrecoDto {
  return {
    itens: [{ produto: 'WP500', quantidade: 24 }],
    frequencia: 'QUINZENAL',
    plano: 'TRIMESTRAL',
    ...extra,
  } as SimularPrecoDto;
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

describe('PrecoService.simular', () => {
  let prisma: PrismaFake;
  let service: PrecoService;

  beforeEach(() => {
    prisma = new PrismaFake().carregarCatalogo();
    // 14/11/2026 12:00 em São Paulo (fora do verão)
    service = new PrecoService(prisma as unknown as PrismaService, new ClockFixo());
  });

  it('CT02 pela API: 24 WP500, Trimestral, 1º ciclo, novembro, Zona Sul → 213,19', async () => {
    const r = await service.simular(CLIENTE, dto({ zonaId: ZONA_SUL, dataEntrega: '2026-11-16' }));
    expect(r).toMatchObject({
      dataEntrega: '2026-11-16',
      subtotal: 203.29,
      frete: 9.9,
      creditos: 0,
      total: 213.19,
      ue: 24,
      fatores: { volume: 8, compromisso: 7, fidelidade: 0, demanda: 0, cupom: 0 },
      zona: { id: ZONA_SUL, nome: 'Zona Sul' },
      ueMinima: 12,
      ueMaxima: 120,
      faltaUeParaMinimo: 0,
      freteGratisAcima: 250,
      faltaParaFreteGratis: 46.71,
      economiaPlano: 15.3,
    });
    expect(r.detalhePreco).toEqual([
      { fator: 'VOLUME', percentual: -8 },
      { fator: 'COMPROMISSO', percentual: -7 },
      { fator: 'FRETE', valor: 9.9 },
    ]);
    expect(r.itens).toEqual([
      { produto: 'WP500', quantidade: 24, precoBase: 9.9, precoUnitario: 8.47, regra: null },
    ]);
  });

  it('anônimo: sem fidelidade/ciclo; frete por zonaId; metas da cesta', async () => {
    prisma.ciclos.push({
      id: 'c1',
      assinaturaId: 'a1',
      numero: 1,
      assinatura: { clienteId: CLIENTE },
      itens: [{ produtoId: 'prod-WP500', quantidade: 24, precoUnitario: new Decimal('8.39') }],
    });
    prisma.pagamentos.push({
      id: 'p1',
      cicloId: 'c1',
      status: 'PAGO',
      vencimento: d('2026-12-01'),
      pagoEm: new Date('2026-12-01T20:00:00Z'),
    });
    const r = await service.simular(undefined, dto({
      zonaId: ZONA_SUL,
      dataEntrega: '2026-11-16',
      cicloAnteriorId: 'c1',
      enderecoId: 'e-qualquer',
    }));
    expect(r).toMatchObject({
      total: 213.19,
      fatores: { fidelidade: 0 },
      zona: { id: ZONA_SUL, nome: 'Zona Sul' },
      economiaPlano: 15.3,
      faltaParaFreteGratis: 46.71,
    });
  });

  it('plano Flex: economiaPlano 0; freteGratisAcima 250', async () => {
    const r = await service.simular(CLIENTE, dto({
      plano: 'FLEX',
      zonaId: ZONA_SUL,
      itens: [{ produto: 'WP500', quantidade: 12 }],
    }));
    expect(r).toMatchObject({
      subtotal: 118.8,
      economiaPlano: 0,
      ueMinima: 12,
      freteGratisAcima: 250,
      faltaParaFreteGratis: 131.2,
    });
  });

  it('CT01 pela API: ciclo anterior com 2 ciclos pagos em dia, verão, Zona Sul → 219,09', async () => {
    prisma.ciclos.push(
      { id: 'c1', assinaturaId: 'a1', numero: 1, assinatura: { clienteId: CLIENTE }, itens: [] },
      {
        id: 'c2',
        assinaturaId: 'a1',
        numero: 2,
        assinatura: { clienteId: CLIENTE },
        itens: [{ produtoId: 'prod-WP500', quantidade: 24, precoUnitario: new Decimal('8.39') }],
      },
    );
    prisma.pagamentos.push(
      { id: 'p1', cicloId: 'c1', status: 'PAGO', vencimento: d('2026-12-01'), pagoEm: new Date('2026-12-01T20:00:00Z') },
      { id: 'p2', cicloId: 'c2', status: 'PAGO', vencimento: d('2026-12-15'), pagoEm: new Date('2026-12-14T12:00:00Z') },
    );
    const r = await service.simular(
      CLIENTE,
      dto({ zonaId: ZONA_SUL, dataEntrega: '2027-01-15', cicloAnteriorId: 'c2' }),
    );
    expect(r.fatores).toEqual({ volume: 8, compromisso: 7, fidelidade: 2, demanda: 5, cupom: 0 });
    expect(r.total).toBe(219.09);
  });

  it('fidelidade só conta ciclo pago até o vencimento (data de São Paulo)', async () => {
    prisma.ciclos.push({
      id: 'c1',
      assinaturaId: 'a1',
      numero: 1,
      assinatura: { clienteId: CLIENTE },
      itens: [],
    });
    prisma.pagamentos.push(
      // 02/12 01:00 UTC = 01/12 22:00 em São Paulo → em dia
      { id: 'p1', cicloId: 'c1', status: 'PAGO', vencimento: d('2026-12-01'), pagoEm: new Date('2026-12-02T01:00:00Z') },
    );
    expect((await service.simular(CLIENTE, dto({ cicloAnteriorId: 'c1' }))).fatores.fidelidade).toBe(1);

    prisma.pagamentos[0].pagoEm = new Date('2026-12-02T12:00:00Z'); // atrasado
    expect((await service.simular(CLIENTE, dto({ cicloAnteriorId: 'c1' }))).fatores.fidelidade).toBe(0);
  });

  it('CT11 pela API: unitário do ciclo anterior trava a alta em +10%', async () => {
    prisma.ciclos.push({
      id: 'c1',
      assinaturaId: 'a1',
      numero: 1,
      assinatura: { clienteId: CLIENTE },
      itens: [{ produtoId: 'prod-WP500', quantidade: 12, precoUnitario: new Decimal('8.61') }],
    });
    const r = await service.simular(
      CLIENTE,
      dto({ itens: [{ produto: 'WP500', quantidade: 12 }], plano: 'FLEX', cicloAnteriorId: 'c1' }),
    );
    expect(r.itens[0]).toMatchObject({ precoUnitario: 9.47, regra: 'TRAVA_MAXIMA' });
    expect(r.total).toBe(113.65);
  });

  it('ciclo anterior de outro cliente → SEM_PERMISSAO; inexistente → NAO_ENCONTRADO', async () => {
    prisma.ciclos.push({ id: 'c9', assinaturaId: 'a9', numero: 1, assinatura: { clienteId: 'outro' }, itens: [] });
    expect(await codigo(service.simular(CLIENTE, dto({ cicloAnteriorId: 'c9' })))).toBe('SEM_PERMISSAO');
    expect(await codigo(service.simular(CLIENTE, dto({ cicloAnteriorId: 'nao-existe' })))).toBe('NAO_ENCONTRADO');
  });

  it('frete pela zona do endereço do próprio cliente', async () => {
    prisma.enderecos.push({ id: 'e1', clienteId: CLIENTE, zonaId: 'zona-Zona-Oeste' });
    const r = await service.simular(CLIENTE, dto({ enderecoId: 'e1', plano: 'FLEX', itens: [{ produto: 'WP500', quantidade: 12 }] }));
    expect(r).toMatchObject({ frete: 19.9, total: 138.7, zona: { nome: 'Zona Oeste' } });
  });

  it('endereço de outro cliente → SEM_PERMISSAO; zona inexistente → NAO_ENCONTRADO', async () => {
    prisma.enderecos.push({ id: 'e9', clienteId: 'outro', zonaId: ZONA_SUL });
    expect(await codigo(service.simular(CLIENTE, dto({ enderecoId: 'e9' })))).toBe('SEM_PERMISSAO');
    expect(await codigo(service.simular(CLIENTE, dto({ enderecoId: 'nao-existe' })))).toBe('NAO_ENCONTRADO');
    expect(await codigo(service.simular(CLIENTE, dto({ zonaId: 'nao-existe' })))).toBe('NAO_ENCONTRADO');
  });

  it('sem zona: frete 0 e sem linha FRETE no detalhe', async () => {
    const r = await service.simular(CLIENTE, dto());
    expect(r.frete).toBe(0);
    expect(r.zona).toBeNull();
    expect(r.detalhePreco.find((x) => x.fator === 'FRETE')).toBeUndefined();
  });

  it('CT13 pela API: subtotal acima de R$ 250 → frete zero mesmo com zona', async () => {
    const r = await service.simular(
      CLIENTE,
      dto({ plano: 'FLEX', zonaId: ZONA_SUL, itens: [{ produto: 'WP500', quantidade: 24 }, { produto: 'FF500', quantidade: 6 }] }),
    );
    expect(r).toMatchObject({ subtotal: 267.72, frete: 0, total: 267.72 });
    expect(r.detalhePreco).toContainEqual({ fator: 'FRETE', valor: 0 });
  });

  it('cupom válido entra no fator; inválido, vencido ou esgotado → CUPOM_INVALIDO', async () => {
    const ok = await service.simular(CLIENTE, dto({ plano: 'FLEX', itens: [{ produto: 'WP500', quantidade: 12 }], cupom: 'bemvindo10' }));
    expect(ok).toMatchObject({ total: 106.92, fatores: { cupom: 10 } });
    expect(ok.detalhePreco).toContainEqual({ fator: 'CUPOM', percentual: -10 });

    expect(await codigo(service.simular(CLIENTE, dto({ cupom: 'NAOEXISTE' })))).toBe('CUPOM_INVALIDO');
    expect(await codigo(service.simular(CLIENTE, dto({ cupom: 'BEMVINDO10', dataEntrega: '2028-01-01' })))).toBe(
      'CUPOM_INVALIDO',
    );
    prisma.cupons[0].usos = 100;
    expect(await codigo(service.simular(CLIENTE, dto({ cupom: 'BEMVINDO10' })))).toBe('CUPOM_INVALIDO');
  });

  it('demanda pela data de entrega; sem data, usa hoje em São Paulo', async () => {
    const hoje = await service.simular(CLIENTE, dto());
    expect(hoje.dataEntrega).toBe('2026-11-14');
    expect(hoje.fatores.demanda).toBe(0);
    const verao = await service.simular(CLIENTE, dto({ dataEntrega: '2026-12-01' }));
    expect(verao.fatores.demanda).toBe(5);
    expect(verao.detalhePreco).toContainEqual({ fator: 'DEMANDA', percentual: 5 });
  });

  it('itens repetidos são somados antes da validação (caixa mista 3 + 3)', async () => {
    const r = await service.simular(
      CLIENTE,
      dto({
        plano: 'FLEX',
        itens: [
          { produto: 'WP500', quantidade: 3 },
          { produto: 'FF500', quantidade: 3 },
          { produto: 'AMN5000', quantidade: 1 },
          { produto: 'AMN5000', quantidade: 1 },
        ],
      }),
    );
    expect(r.total).toBe(70.1);
    expect(r.itens.map((i) => [i.produto, i.quantidade])).toEqual([
      ['WP500', 3],
      ['FF500', 3],
      ['AMN5000', 2],
    ]);
  });

  it('CT06, CT07 e CT25 pela API', async () => {
    expect(await codigo(service.simular(CLIENTE, dto({ itens: [{ produto: 'WP500', quantidade: 11 }] })))).toBe(
      'CESTA_ABAIXO_MINIMO',
    );
    expect(
      await codigo(
        service.simular(CLIENTE, dto({ itens: [{ produto: 'AMN5000', quantidade: 12 }, { produto: 'WP500', quantidade: 1 }] })),
      ),
    ).toBe('CESTA_ACIMA_MAXIMO');
    expect(
      await codigo(
        service.simular(CLIENTE, dto({ itens: [{ produto: 'WP500', quantidade: 5 }, { produto: 'AMS500', quantidade: 12 }] })),
      ),
    ).toBe('EMBALAGEM_INVALIDA');
  });

  it('produto inexistente ou inativo → NAO_ENCONTRADO em itens', async () => {
    expect(await codigo(service.simular(CLIENTE, dto({ itens: [{ produto: 'ULTRA355', quantidade: 12 }] })))).toBe(
      'NAO_ENCONTRADO',
    );
    prisma.produtos.find((p) => p.codigo === 'WP500')!.ativo = false;
    expect(await codigo(service.simular(CLIENTE, dto()))).toBe('NAO_ENCONTRADO');
  });
});
