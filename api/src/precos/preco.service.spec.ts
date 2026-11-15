import { ClockService } from '../common/clock.service';
import { PrismaService } from '../common/prisma.service';
import { RegraNegocioException } from '../common/regra-negocio.exception';
import { Plano } from '../../prisma/generated/prisma/client';
import { fatoresSeed, porCodigo, produtosSeed } from '../../test/support/catalogo';
import { PrecoService } from './preco.service';
import { dec, Dec, EntradaCalculo, ItemCesta } from './preco.tipos';

const P = porCodigo(produtosSeed());
const VERAO = '2027-01-15';
const NOVEMBRO = '2026-11-16';
const ZONA_SUL = dec('9.90');

const cesta = (itens: Record<string, number>): ItemCesta[] =>
  Object.entries(itens).map(([codigo, quantidade]) => ({ produto: P[codigo], quantidade }));

function codigoDoErro(fn: () => unknown): string {
  try {
    fn();
  } catch (e) {
    if (e instanceof RegraNegocioException) return e.codigo;
    throw e;
  }
  throw new Error('esperava RegraNegocioException');
}

describe('PrecoService', () => {
  const service = new PrecoService({} as PrismaService, new ClockService());

  function entrada(
    itens: ItemCesta[],
    extra: Partial<EntradaCalculo> & { data?: string } = {},
  ): EntradaCalculo {
    const { data = NOVEMBRO, ...resto } = extra;
    return {
      itens,
      plano: Plano.FLEX,
      parametros: service.parametrosDe(fatoresSeed(), data),
      ciclosPagosEmDia: 0,
      taxaZona: null,
      creditos: dec(0),
      precosAnteriores: new Map(),
      ...resto,
    };
  }

  const total = (e: EntradaCalculo) => service.calcular(e).total.toFixed(2);

  describe('casos do Anexo', () => {
    it('CT01: 24 WP500, Trimestral, 2 ciclos pagos, verão, Zona Sul → 219,09', () => {
      const e = entrada(cesta({ WP500: 24 }), {
        data: VERAO,
        plano: Plano.TRIMESTRAL,
        ciclosPagosEmDia: 2,
        taxaZona: ZONA_SUL,
      });
      expect(total(e)).toBe('219.09');
    });

    it('CT01 com o ciclo anterior dentro da trava continua 219,09', () => {
      const e = entrada(cesta({ WP500: 24 }), {
        data: VERAO,
        plano: Plano.TRIMESTRAL,
        ciclosPagosEmDia: 2,
        taxaZona: ZONA_SUL,
        precosAnteriores: new Map([[P.WP500.id, dec('8.39')]]),
      });
      expect(total(e)).toBe('219.09');
    });

    it('CT02: mesma cesta, 1º ciclo, entrega em novembro → 213,19', () => {
      const e = entrada(cesta({ WP500: 24 }), { plano: Plano.TRIMESTRAL, taxaZona: ZONA_SUL });
      expect(total(e)).toBe('213.19');
    });

    it('caso A (preço do quiz): 12 WP500, Flex, sem frete → 118,80', () => {
      expect(total(entrada(cesta({ WP500: 12 })))).toBe('118.80');
    });

    it('caso B (preço do quiz): 3 WP500 + 3 FF500 + 2 AMN5000 → 70,10 (−8% de volume com 26 UE)', () => {
      const r = service.calcular(entrada(cesta({ WP500: 3, FF500: 3, AMN5000: 2 })));
      expect(r.ueSemAddon.toNumber()).toBe(26);
      expect(r.fatores.volume.toNumber()).toBe(0.08);
      expect(r.total.toFixed(2)).toBe('70.10');
    });
  });

  describe('fatores', () => {
    it('desconto de volume por faixa de UE: 12–23 → 0%, 24–47 → 8%, 48+ → 12%', () => {
      const vol = (n: number) => service.calcular(entrada(cesta({ WP500: n }))).fatores.volume.toNumber();
      expect(vol(18)).toBe(0);
      expect(vol(24)).toBe(0.08);
      expect(vol(42)).toBe(0.08);
      expect(vol(48)).toBe(0.12);
    });

    it('compromisso: Flex 0%, Trimestral 7%, Empresa 10%', () => {
      const comp = (plano: Plano, n = 12) =>
        service.calcular(entrada(cesta({ WP500: n }), { plano })).fatores.compromisso.toNumber();
      expect(comp(Plano.FLEX)).toBe(0);
      expect(comp(Plano.TRIMESTRAL)).toBe(0.07);
      expect(comp(Plano.EMPRESA, 48)).toBe(0.1);
    });

    it('fidelidade: 1% por ciclo pago em dia, no máximo 5%', () => {
      const fid = (n: number) =>
        service.calcular(entrada(cesta({ WP500: 12 }), { ciclosPagosEmDia: n })).fatores.fidelidade.toNumber();
      expect(fid(0)).toBe(0);
      expect(fid(3)).toBe(0.03);
      expect(fid(9)).toBe(0.05);
    });

    it('demanda: verão +5% de 01/12 a 31/03 pela data da entrega', () => {
      const dem = (data: string) => service.parametrosDe(fatoresSeed(), data).demanda.toNumber();
      expect(dem('2026-11-30')).toBe(0);
      expect(dem('2026-12-01')).toBe(0.05);
      expect(dem('2027-03-31')).toBe(0.05);
      expect(dem('2027-04-01')).toBe(0);
    });

    it('demanda soma os fatores DEMANDA_* vigentes e fica entre −5% e +8%', () => {
      const extra = [
        { chave: 'DEMANDA_EVENTO', valor: dec('0.06'), ativoDe: new Date('2027-01-01T00:00:00Z'), ativoAte: null },
        { chave: 'DEMANDA_BAIXA', valor: dec('-0.05'), ativoDe: new Date('2027-06-01T00:00:00Z'), ativoAte: null },
      ];
      const crise = { chave: 'DEMANDA_CRISE', valor: dec('-0.20'), ativoDe: new Date('2027-06-01T00:00:00Z'), ativoAte: null };
      // verão 5% + evento 6% = 11% → teto 8%
      expect(service.parametrosDe([...fatoresSeed(), ...extra], VERAO).demanda.toNumber()).toBe(0.08);
      // junho: evento 6% − baixa 5% = 1%
      expect(service.parametrosDe([...fatoresSeed(), ...extra], '2027-06-10').demanda.toNumber()).toBe(0.01);
      // −20% → piso −5%
      expect(service.parametrosDe([crise], '2027-06-10').demanda.toNumber()).toBe(-0.05);
    });

    it('usa o valor mais recente quando a mesma chave tem duas vigências', () => {
      const novo = { chave: 'COMPROMISSO_TRIMESTRAL', valor: dec('0.06'), ativoDe: new Date('2026-11-01T00:00:00Z'), ativoAte: null };
      expect(service.parametrosDe([...fatoresSeed(), novo], NOVEMBRO).compromissoTrimestral.toNumber()).toBe(0.06);
      expect(service.parametrosDe([...fatoresSeed(), novo], '2026-10-31').compromissoTrimestral.toNumber()).toBe(0.07);
    });

    it('sem FatorPreco no banco, usa os percentuais do contexto', () => {
      const p = service.parametrosDe([], NOVEMBRO);
      expect(p.volume24a47.toNumber()).toBe(0.08);
      expect(p.compromissoEmpresa.toNumber()).toBe(0.1);
      expect(p.fidelidadeMaxima.toNumber()).toBe(0.05);
      expect(p.demanda.toNumber()).toBe(0);
    });

    it('cupom entra no fator de cada item (RN21)', () => {
      const r = service.calcular(entrada(cesta({ WP500: 12 }), { cupom: dec('0.10') }));
      expect(r.fatores.cupom.toNumber()).toBe(0.1);
      expect(r.total.toFixed(2)).toBe('106.92');
    });
  });

  describe('travas', () => {
    it('CT12: descontos que levam o item abaixo do piso → cobra o piso', () => {
      // 48 AMS500: 2,20 × 0,88 × 0,90 × 0,95 × 0,90 = 1,4897 < piso 1,50
      const r = service.calcular(
        entrada(cesta({ AMS500: 48 }), { plano: Plano.EMPRESA, ciclosPagosEmDia: 5, cupom: dec('0.10') }),
      );
      expect(r.itens[0].precoUnitario.toFixed(2)).toBe('1.50');
      expect(r.itens[0].regra).toBe('PISO');
      expect(r.total.toFixed(2)).toBe('72.00');
    });

    it('cupom não fura o piso (RN21)', () => {
      const r = service.calcular(entrada(cesta({ AMS500: 12 }), { cupom: dec('0.50') }));
      expect(r.itens[0].precoUnitario.equals(dec('1.50'))).toBe(true);
    });

    it('CT11: item 15% acima do ciclo anterior → limitado a +10%', () => {
      // Sem desconto o WP500 sai 9,90; anterior 8,61 → 9,90 é ~15% acima; trava em 8,61 × 1,10 = 9,471
      const r = service.calcular(
        entrada(cesta({ WP500: 12 }), { precosAnteriores: new Map([[P.WP500.id, dec('8.61')]]) }),
      );
      expect(r.itens[0].precoUnitario.toString()).toBe('9.471');
      expect(r.itens[0].regra).toBe('TRAVA_MAXIMA');
      expect(r.total.toFixed(2)).toBe('113.65');
    });

    it('trava também limita a queda a −10%', () => {
      const r = service.calcular(
        entrada(cesta({ WP500: 24 }), {
          plano: Plano.TRIMESTRAL,
          precosAnteriores: new Map([[P.WP500.id, dec('9.90')]]),
        }),
      );
      expect(r.itens[0].precoUnitario.toString()).toBe('8.91');
      expect(r.itens[0].regra).toBe('TRAVA_MINIMA');
    });

    it('o piso vence a trava: teto de +10% abaixo do piso volta ao piso', () => {
      // Anterior 6,00 (ex.: piso antigo) → teto 6,60 < piso 7,50 → 7,50
      const r = service.calcular(
        entrada(cesta({ WP500: 12 }), { precosAnteriores: new Map([[P.WP500.id, dec('6.00')]]) }),
      );
      expect(r.itens[0].precoUnitario.toFixed(2)).toBe('7.50');
      expect(r.itens[0].regra).toBe('PISO');
    });

    it('produto que não estava no ciclo anterior não sofre trava', () => {
      const r = service.calcular(
        entrada(cesta({ WP500: 12 }), { precosAnteriores: new Map([[P.FF500.id, dec('1.00')]]) }),
      );
      expect(r.itens[0].precoUnitario.toFixed(2)).toBe('9.90');
      expect(r.itens[0].regra).toBeNull();
    });

    it('GUA2000 entra pelo preço base, sem desconto nem trava e fora da UE do volume', () => {
      const r = service.calcular(
        entrada(cesta({ WP500: 24, GUA2000: 2 }), {
          data: VERAO,
          plano: Plano.TRIMESTRAL,
          ciclosPagosEmDia: 2,
          cupom: dec('0.10'),
          precosAnteriores: new Map([[P.GUA2000.id, dec('5.00')]]),
        }),
      );
      const gua = r.itens.find((i) => i.produto.codigo === 'GUA2000')!;
      expect(gua.precoUnitario.toFixed(2)).toBe('7.90');
      expect(gua.regra).toBe('ADDON');
      expect(r.ueSemAddon.toNumber()).toBe(24);
      expect(r.ueTotal.toNumber()).toBe(32);
    });
  });

  describe('frete, créditos e arredondamento', () => {
    it('CT13: subtotal acima de R$ 250 após descontos → frete zero', () => {
      // 24 WP500 + 6 FF500 (30 UE, −8%): 218,592 + 49,128 = 267,72
      const r = service.calcular(entrada(cesta({ WP500: 24, FF500: 6 }), { taxaZona: dec('19.90') }));
      expect(r.subtotal.toFixed(2)).toBe('267.72');
      expect(r.frete.toNumber()).toBe(0);
      expect(r.total.toFixed(2)).toBe('267.72');
    });

    it('subtotal de exatamente R$ 250 ainda paga frete (só acima de 250 é grátis)', () => {
      // 10 × 25,00 (10 UE: sem desconto de volume) = 250,00
      const exato = { ...P.WP500, id: 'x', precoBase: dec('25'), precoPiso: dec(1) };
      const r = service.calcular(entrada([{ produto: exato, quantidade: 10 }], { taxaZona: ZONA_SUL }));
      expect(r.subtotal.equals(dec(250))).toBe(true);
      expect(r.frete.toFixed(2)).toBe('9.90');
    });

    it('sem zona informada, frete fica zero na simulação', () => {
      expect(service.calcular(entrada(cesta({ WP500: 12 }))).frete.toNumber()).toBe(0);
    });

    it('créditos abatem o total, que nunca fica negativo', () => {
      expect(total(entrada(cesta({ WP500: 12 }), { creditos: dec('18.80') }))).toBe('100.00');
      expect(total(entrada(cesta({ WP500: 12 }), { creditos: dec('500') }))).toBe('0.00');
    });

    it('arredonda só o total, meio para cima, mantendo o unitário sem arredondar', () => {
      const r = service.calcular(entrada(cesta({ WP500: 24 }), { plano: Plano.TRIMESTRAL }));
      expect(r.itens[0].precoUnitario.toString()).toBe('8.47044');
      expect(r.subtotal.toString()).toBe('203.29056');
      expect(r.total.toString()).toBe('203.29');
      // 12,025 → 12,03 (meio para cima; o arredondamento bancário daria 12,02)
      const um = { ...P.WP500, id: 'm', precoBase: dec('1'), precoPiso: dec(0) };
      const r2 = service.calcular(entrada([{ produto: um, quantidade: 12 }], { taxaZona: dec('0.025') }));
      expect(r2.total.toFixed(2)).toBe('12.03');
    });

    it('não usa ponto flutuante: 0,1 + 0,2 exato', () => {
      const a = { ...P.WP500, id: 'a', precoBase: dec('0.1'), precoPiso: dec(0), embalagemQtd: 1 };
      const b = { ...P.FF500, id: 'b', precoBase: dec('0.2'), precoPiso: dec(0), embalagemQtd: 1 };
      const r = service.calcular(entrada([{ produto: a, quantidade: 6 }, { produto: b, quantidade: 6 }]));
      expect(r.subtotal.equals(new Dec('1.8'))).toBe(true);
    });
  });

  describe('validação da cesta', () => {
    const validar = (itens: Record<string, number>, plano: Plano = Plano.FLEX) =>
      codigoDoErro(() => service.validarCesta(cesta(itens), plano));

    it('CT06: cesta com 11 UE → CESTA_ABAIXO_MINIMO', () => {
      expect(validar({ WP500: 11 })).toBe('CESTA_ABAIXO_MINIMO');
    });

    it('add-on não conta para a cesta mínima (RN02)', () => {
      expect(validar({ WP500: 6, GUA2000: 2 })).toBe('CESTA_ABAIXO_MINIMO');
    });

    it('CT07: cesta com 121 UE → CESTA_ACIMA_MAXIMO', () => {
      // 12 AMN5000 (120 UE) + 1 WP500 = 121 UE
      expect(validar({ AMN5000: 12, WP500: 1 })).toBe('CESTA_ACIMA_MAXIMO');
    });

    it('acima de 60 kg → CESTA_ACIMA_MAXIMO mesmo abaixo de 120 UE', () => {
      // 114 WP500 = 114 UE e 60,42 kg
      expect(validar({ WP500: 114 })).toBe('CESTA_ACIMA_MAXIMO');
    });

    it('CT25: cesta com 5 WP500 → EMBALAGEM_INVALIDA', () => {
      expect(validar({ WP500: 5, AMS500: 12 })).toBe('EMBALAGEM_INVALIDA');
    });

    it('caixa mista: WP500 + FF500 somando múltiplo de 6 é válida (RN04)', () => {
      expect(() => service.validarCesta(cesta({ WP500: 3, FF500: 3, AMN5000: 2 }), Plano.FLEX)).not.toThrow();
      expect(() => service.validarCesta(cesta({ WP500: 7, FF500: 5 }), Plano.FLEX)).not.toThrow();
      expect(validar({ WP500: 7, FF500: 6 })).toBe('EMBALAGEM_INVALIDA');
    });

    it('demais produtos em múltiplos da própria embalagem', () => {
      expect(validar({ WP500: 12, AMS500: 6 })).toBe('EMBALAGEM_INVALIDA');
      expect(() => service.validarCesta(cesta({ WP500: 12, AMS500: 24, AMN5000: 1 }), Plano.FLEX)).not.toThrow();
    });

    it('plano Empresa exige 48 UE e não tem teto de 120 UE (comercial)', () => {
      expect(validar({ WP500: 42 }, Plano.EMPRESA)).toBe('CESTA_ABAIXO_MINIMO');
      expect(() => service.validarCesta(cesta({ WP500: 96, AMC200: 384 }), Plano.EMPRESA)).not.toThrow();
    });

    it('quantidade precisa ser inteira e positiva', () => {
      expect(validar({ WP500: 12, FF500: -6 })).toBe('DADOS_INVALIDOS');
    });
  });
});
