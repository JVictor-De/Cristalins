import { dataIsoValida, idadeEm } from './datas';

describe('datas', () => {
  it('idade conta o aniversário no próprio dia', () => {
    expect(idadeEm('2008-11-14', '2026-11-14')).toBe(18);
    expect(idadeEm('2008-11-15', '2026-11-14')).toBe(17);
    expect(idadeEm('2008-12-01', '2026-11-14')).toBe(17);
    expect(idadeEm('2008-01-31', '2026-11-14')).toBe(18);
  });

  it('nascido em 29/02 completa anos em 01/03 nos anos comuns', () => {
    expect(idadeEm('2008-02-29', '2026-02-28')).toBe(17);
    expect(idadeEm('2008-02-29', '2026-03-01')).toBe(18);
  });

  it('valida datas reais no formato AAAA-MM-DD', () => {
    expect(dataIsoValida('1995-05-10')).toBe(true);
    expect(dataIsoValida('2026-02-30')).toBe(false);
    expect(dataIsoValida('10/05/1995')).toBe(false);
  });
});
