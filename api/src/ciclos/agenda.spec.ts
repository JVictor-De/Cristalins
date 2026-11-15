import { DiaSemana, Frequencia } from '../../prisma/generated/prisma/client';
import { dataCorte, diaDaSemana, primeiraEntrega, proximaDataDaZona, proximaEntrega, somarDias, somarMeses } from './agenda';

const { SEG, TER, QUA, QUI, SEX, SAB } = DiaSemana;

describe('agenda de entregas', () => {
  it('dia da semana de uma data civil', () => {
    expect(diaDaSemana('2026-11-14')).toBe(SAB);
    expect(diaDaSemana('2026-11-16')).toBe(SEG);
    expect(diaDaSemana('2026-11-15')).toBe('DOM');
  });

  it('soma dias atravessando mês e ano', () => {
    expect(somarDias('2026-12-30', 3)).toBe('2027-01-02');
    expect(somarDias('2026-11-16', -2)).toBe('2026-11-14');
  });

  it('próxima data da zona igual ou posterior à data mínima', () => {
    expect(proximaDataDaZona('2026-11-16', [SEG, QUA, SEX])).toBe('2026-11-16');
    expect(proximaDataDaZona('2026-11-17', [SEG, QUA, SEX])).toBe('2026-11-18');
    expect(proximaDataDaZona('2026-11-15', [SAB])).toBe('2026-11-21');
  });

  it('zona sem dias de entrega não tem data', () => {
    expect(() => proximaDataDaZona('2026-11-16', [])).toThrow();
  });

  it('RN08 (estimativa): primeira entrega ≥ hoje + 2 dias no dia da zona', () => {
    // Sábado 14/11 + 2 = segunda 16/11 (Zona Sul) — exemplo do Anexo
    expect(primeiraEntrega('2026-11-14', [SEG, QUA, SEX])).toBe('2026-11-16');
    // Zona Norte (ter/qui): ≥ 16/11 → terça 17/11
    expect(primeiraEntrega('2026-11-14', [TER, QUI])).toBe('2026-11-17');
  });

  it('próximas entregas: anterior + 7/14/28 dias, ajustada ao dia da zona', () => {
    expect(proximaEntrega('2026-11-16', Frequencia.SEMANAL, [SEG, QUA, SEX])).toBe('2026-11-23');
    expect(proximaEntrega('2026-11-16', Frequencia.QUINZENAL, [SEG])).toBe('2026-11-30');
    expect(proximaEntrega('2026-11-16', Frequencia.MENSAL, [SEG])).toBe('2026-12-14');
    // zona mudou para ter/qui: 16/11 + 7 = 23/11 (seg) → 24/11 (ter)
    expect(proximaEntrega('2026-11-16', Frequencia.SEMANAL, [TER, QUI])).toBe('2026-11-24');
  });

  it('soma meses (fim do compromisso) sem estourar o mês', () => {
    expect(somarMeses('2026-11-16', 3)).toBe('2027-02-16');
    expect(somarMeses('2026-11-30', 3)).toBe('2027-02-28');
    expect(somarMeses('2027-08-31', 6)).toBe('2028-02-29');
  });

  it('RN07: corte = 23h59 de 2 dias antes da entrega, em São Paulo', () => {
    // entrega 16/11 → corte 14/11 23:59:59.999 em São Paulo = 15/11 02:59:59.999 UTC
    expect(dataCorte('2026-11-16').toISOString()).toBe('2026-11-15T02:59:59.999Z');
  });
});
