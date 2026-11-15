import * as bcrypt from 'bcrypt';

/** SEG02: bcrypt com custo 10. */
const CUSTO_BCRYPT = 10;

// Hash válido de uma senha qualquer: compara mesmo quando o e-mail não existe,
// para o tempo de resposta não revelar quais e-mails têm conta.
const HASH_FICTICIO = '$2b$10$wt5QCC9WULE2QQIRi.OKt.6np.oVIqZch26Pt.7s2.prgRVupFOLy';

export function gerarHashSenha(senha: string): Promise<string> {
  return bcrypt.hash(senha, CUSTO_BCRYPT);
}

export function conferirSenha(senha: string, hash: string | null | undefined): Promise<boolean> {
  return bcrypt.compare(senha, hash ?? HASH_FICTICIO);
}
