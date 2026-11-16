import { mascararCpf, mascararEmail, mascararPii, mascararTelefone, mascararToken } from './mascarar';

describe('mascarar (SEG10)', () => {
  it('mascara e-mail, CPF, telefone e token', () => {
    expect(mascararEmail('ana.souza@cristalins.local')).toBe('a***@cristalins.local');
    expect(mascararCpf('52998224725')).toBe('***4725');
    expect(mascararTelefone('21999998888')).toBe('***8888');
    expect(mascararToken('abcdefghijklmnop')).toBe('abcd…mnop');
  });

  it('mascararPii limpa uma linha de log', () => {
    const bruto = 'Falha para ana@exemplo.com cpf 52998224725 tel 21987654321';
    const limpo = mascararPii(bruto);
    expect(limpo).not.toContain('ana@exemplo.com');
    expect(limpo).not.toContain('52998224725');
    expect(limpo).not.toContain('21987654321');
    expect(limpo).toContain('a***@exemplo.com');
    expect(limpo).toContain('***4725');
  });
});
