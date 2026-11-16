import Decimal from 'decimal.js';
import { produtosSeed } from '../../test/support/catalogo';
import { planejarSeparacao, ProdutoEstoque } from './estoque.service';

/** CT21 / RN06: substituto do mesmo tipo e volume, valor igual ou menor; sem substituto → crédito. */
describe('planejarSeparacao (RN06, CT21)', () => {
  const catalogo = (estoques: Record<string, number | null> = {}): ProdutoEstoque[] =>
    produtosSeed().map((p) => ({ ...p, estoque: p.codigo in estoques ? estoques[p.codigo] : p.estoque }));
  const item = (cat: ProdutoEstoque[], codigo: string, quantidade: number, preco: string) => ({
    produto: cat.find((p) => p.codigo === codigo)!,
    quantidade,
    precoUnitario: new Decimal(preco),
  });

  it('CT21: Water Protein sem estoque → Flow Fiber (PRINCIPAL, 500 ml, base 8,90 ≤ 9,90)', () => {
    const cat = catalogo({ WP500: 0, FF500: 100 });
    const [d] = planejarSeparacao([item(cat, 'WP500', 24, '8.47')], cat);
    expect(d).toMatchObject({ acao: 'SUBSTITUIDO', quantidade: 24 });
    expect(d.acao === 'SUBSTITUIDO' && d.por.codigo).toBe('FF500');
  });

  it('não usa substituto mais caro: Flow Fiber sem estoque não vira Water Protein (9,90 > 8,90) → crédito', () => {
    const cat = catalogo({ FF500: 0, WP500: 100 });
    const [d] = planejarSeparacao([item(cat, 'FF500', 6, '8.19')], cat);
    expect(d).toMatchObject({ acao: 'PULADO', quantidade: 6, credito: '49.14' });
  });

  it('não troca de volume nem de tipo: AMC510 (510 ml) não substitui AMS500 (500 ml) → crédito', () => {
    const cat = catalogo({ AMS500: 0 });
    const [d] = planejarSeparacao([item(cat, 'AMS500', 12, '2.20')], cat);
    expect(d).toMatchObject({ acao: 'PULADO', credito: '26.40' });
  });

  it('estoque parcial não basta: o item inteiro troca; substituto também sem estoque → crédito', () => {
    const cat = catalogo({ WP500: 5, FF500: 10 });
    const [d] = planejarSeparacao([item(cat, 'WP500', 12, '9.90')], cat);
    expect(d).toMatchObject({ acao: 'PULADO', credito: '118.80' });
  });

  it('estoque nulo = sem controle (mantém); com estoque suficiente mantém', () => {
    const cat = catalogo({ WP500: 30 });
    const ds = planejarSeparacao([item(cat, 'WP500', 24, '8.47'), item(cat, 'AMN5000', 2, '9.90')], cat);
    expect(ds.map((d) => d.acao)).toEqual(['MANTIDO', 'MANTIDO']);
  });

  it('reserva entre ciclos do mesmo dia: o 2º ciclo já não encontra estoque', () => {
    const cat = catalogo({ WP500: 30, FF500: 12 });
    const reservado = new Map<string, number>();
    const a = planejarSeparacao([item(cat, 'WP500', 24, '8.47')], cat, reservado);
    const b = planejarSeparacao([item(cat, 'WP500', 12, '9.90')], cat, reservado);
    const c = planejarSeparacao([item(cat, 'WP500', 12, '9.90')], cat, reservado);
    expect([a[0].acao, b[0].acao, c[0].acao]).toEqual(['MANTIDO', 'SUBSTITUIDO', 'PULADO']);
  });

  it('produto inativo não serve de substituto', () => {
    const cat = catalogo({ WP500: 0, FF500: 100 }).map((p) => (p.codigo === 'FF500' ? { ...p, ativo: false } : p));
    expect(planejarSeparacao([item(cat, 'WP500', 6, '9.90')], cat)[0].acao).toBe('PULADO');
  });
});
