import { cnpjValido, cpfOuCnpjValido, cpfValido } from './documento';

describe('documento', () => {
  it.each(['52998224725', '529.982.247-25', '11144477735', '00000000191'])('CPF válido: %s', (cpf) => {
    expect(cpfValido(cpf)).toBe(true);
  });

  it.each(['52998224726', '11111111111', '1234567890', ''])('CPF inválido: %s', (cpf) => {
    expect(cpfValido(cpf)).toBe(false);
  });

  it('CNPJ: dígitos verificadores e repetidos', () => {
    expect(cnpjValido('11.222.333/0001-81')).toBe(true);
    expect(cnpjValido('11222333000182')).toBe(false);
    expect(cnpjValido('00000000000000')).toBe(false);
  });

  it('cpfOuCnpjValido escolhe pelo tamanho', () => {
    expect(cpfOuCnpjValido('52998224725')).toBe(true);
    expect(cpfOuCnpjValido('11222333000181')).toBe(true);
    expect(cpfOuCnpjValido('529982247')).toBe(false);
  });
});
