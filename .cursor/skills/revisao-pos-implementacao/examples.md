# Exemplos — revisao-pos-implementacao

## Exemplo A — Usuário cola o prompt canônico

**Entrada:** o parágrafo “revise minuciosamente…” + obs sobre funções.

**Ação:** inventariar diff da conversa → completar stubs → corrigir bugs →
adicionar testes da superfície (pytest / Jest / `flutter test`) → rodar o
comando do escopo → relatório curto. Sem Playwright.

## Exemplo B — Após fila CLI de feature

**Entrada:** “Roda a revisão pós-implementação no que a fila do juiz de partida fez.”

**Ação:** limitar ao diretório/feature da fila (`app/…`, `admin_frontend/…`,
`tests/…` relacionados); não varrer o monorepo inteiro.

## Exemplo C — Só pediu “tem ponta solta?”

**Entrada:** “Fecha as pontas do cadastro de campo.”

**Ação:** mesma skill; foco em completude + erros + testes mínimos; relatório
ainda obrigatório.

## Exemplo D — Função perdida

**Sinal:** rota chama `criar_campo` mas a função foi apagada no refactor.

**Ação:** restaurar/reimplementar + teste que quebra se sumir de novo; mencionar
em **Completude** no relatório.

## Exemplo E — Ambiente sem deps

**Sinal:** `pytest` falha por pacote não instalado.

**Ação:** corrigir código/testes mesmo assim; no relatório: comando tentado +
bloqueio; não fingir que passou.
