/** Validação de CPF e CNPJ (RF03) pelos dígitos verificadores. */

export function somenteDigitos(valor: string): string {
  return valor.replace(/\D/g, '');
}

function todosIguais(digitos: string): boolean {
  return /^(\d)\1*$/.test(digitos);
}

export function cpfValido(valor: string): boolean {
  const cpf = somenteDigitos(valor);
  if (cpf.length !== 11 || todosIguais(cpf)) return false;
  const dv = (base: string, pesoInicial: number) => {
    let soma = 0;
    for (let i = 0; i < base.length; i++) soma += Number(base[i]) * (pesoInicial - i);
    const resto = soma % 11;
    return resto < 2 ? 0 : 11 - resto;
  };
  const d1 = dv(cpf.slice(0, 9), 10);
  const d2 = dv(cpf.slice(0, 10), 11);
  return cpf.endsWith(`${d1}${d2}`);
}

export function cnpjValido(valor: string): boolean {
  const cnpj = somenteDigitos(valor);
  if (cnpj.length !== 14 || todosIguais(cnpj)) return false;
  const dv = (base: string) => {
    const pesos = base.length === 12 ? [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2] : [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
    const soma = pesos.reduce((acc, peso, i) => acc + Number(base[i]) * peso, 0);
    const resto = soma % 11;
    return resto < 2 ? 0 : 11 - resto;
  };
  const d1 = dv(cnpj.slice(0, 12));
  const d2 = dv(cnpj.slice(0, 13));
  return cnpj.endsWith(`${d1}${d2}`);
}

/** CPF (11 dígitos) ou CNPJ (14 dígitos) válido. */
export function cpfOuCnpjValido(valor: string): boolean {
  const digitos = somenteDigitos(valor);
  return digitos.length === 11 ? cpfValido(digitos) : cnpjValido(digitos);
}
