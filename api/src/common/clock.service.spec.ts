import { ClockService } from './clock.service';

describe('ClockService', () => {
  it('converte o instante para a data em America/Sao_Paulo', () => {
    const clock = new ClockService();
    // 02:30 UTC de 15/11 ainda é 14/11 em São Paulo (UTC−3).
    expect(clock.dataNoFuso(new Date('2026-11-15T02:30:00.000Z'))).toBe('2026-11-14');
    expect(clock.dataNoFuso(new Date('2026-11-15T03:00:00.000Z'))).toBe('2026-11-15');
  });
});
