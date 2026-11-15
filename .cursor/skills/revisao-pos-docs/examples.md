# Exemplos — revisao-pos-docs

## Exemplo A — Manual de câmeras

**Entrada:** “Revisa o MANUAL_CAMERA_PRODUCAO e as pontas com IMPORTANTE.”

**Ação:** checar seções incompletas, paths de script, cross-links; corrigir docs;
**não** escrever pytest.

## Exemplo B — Fila / prompt CLI

**Entrada:** “Revisão pós-docs na pasta da fila do cadastro de campo.”

**Ação:** alinhar `fila.json`, `TRACKER`, `ORQUESTRADOR`, passos e ids; validar
`--list` se útil; sem testes de produto.

## Exemplo C — Usuário cola o prompt de revisão em cima de markdown

**Entrada:** prompt canônico de revisão + arquivos só em `doc/`.

**Ação:** usar **esta** skill (não a de implementação); omitir testes e error
handling no relatório. Se o alvo for **só texto de prompt** (melhorar/alinhar
regras de negócio), preferir `analise-prompts`.

## Exemplo D — Mistura doc + código

**Entrada:** “Revisa o que fizemos” com diff em `app/` e `doc/`.

**Ação:** `revisao-pos-implementacao` no código; `revisao-pos-docs` só na parte
doc — ou uma passada só-doc se o usuário limitar a documentação.

## Exemplo E — Link quebrado

**Sinal:** README aponta para `doc/foo.md` que foi renomeado.

**Ação:** atualizar o link (e menções no escopo); reportar em Completude/Correções.
