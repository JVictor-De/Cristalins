/**
 * Textos de vitrine (catálogo do site `catalogo-data-fast`), sem promessa de saúde.
 * Prisma ainda não tem coluna `descricao` — montados na resposta de GET /produtos.
 */
export const DESCRICOES_PRODUTO: Record<string, string> = {
  WP500: 'Cristalins com colágeno em garrafa de 500 ml.',
  FF500: 'Água com fibras prebióticas em garrafa de 500 ml. Consulte o rótulo para informações completas.',
  AMS500: 'Água mineral natural sem gás em garrafa de 500 ml.',
  AMC510: 'Água mineral com gás em garrafa de 510 ml.',
  AMN1500: 'Água mineral sem gás em garrafa de 1,5 litro.',
  AMN5000: 'Água mineral sem gás em galão de 5 litros.',
  AMC200: 'Água mineral sem gás em copo de 200 ml.',
  GUA2000: 'Refrigerante de guaraná em garrafa de 2 litros.',
};

/*
 * Mapas de DEMONSTRAÇÃO (AP2), sem coluna Prisma: valores de exemplo até a Cristalins
 * confirmar preço de balcão e rótulo. Ver docs/DECISOES.md ("Gates demo AP2").
 * Nenhum texto alega registro na ANVISA nem benefício terapêutico.
 */

/** Preço unitário da compra avulsa (fora da assinatura). Sem canal avulso: ausente (null). */
export const PRECOS_AVULSO: Record<string, string> = {
  WP500: '11.90',
  FF500: '10.90',
  AMS500: '2.60',
  AMC510: '3.40',
  AMN1500: '4.50',
  AMN5000: '11.90',
  GUA2000: '9.50',
};

export const CLAIMS_PRODUTO: Record<string, string[]> = {
  WP500: ['5 g de proteína', 'Com colágeno', 'Zero açúcar', 'Zero gordura'],
  FF500: ['5 g de fibras prebióticas'],
};

export interface TabelaNutricionalDemo {
  porcao: string;
  linhas: { nutriente: string; valor: string }[];
}

/** Só o que os claims acima sustentam; o resto fica no rótulo da embalagem. */
export const TABELAS_NUTRICIONAIS: Record<string, TabelaNutricionalDemo> = {
  WP500: {
    porcao: '500 ml (1 garrafa)',
    linhas: [
      { nutriente: 'Valor energético', valor: '20 kcal' },
      { nutriente: 'Carboidratos', valor: '0 g' },
      { nutriente: 'Açúcares totais', valor: '0 g' },
      { nutriente: 'Proteínas', valor: '5 g' },
      { nutriente: 'Gorduras totais', valor: '0 g' },
    ],
  },
  FF500: {
    porcao: '500 ml (1 garrafa)',
    linhas: [{ nutriente: 'Fibras alimentares (prebióticas)', valor: '5 g' }],
  },
};
