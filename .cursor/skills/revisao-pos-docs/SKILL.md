---
name: revisao-pos-docs
description: >-
  Revisa minuciosamente documentação, manuais, trackers e artefatos sem código:
  lógica do conteúdo, nomenclatura, links/paths quebrados, trechos desatualizados
  e pontas soltas — sem testes unitários nem tratamento de erros. Para corrigir
  um prompt colado no chat (com regras de negócio), preferir analise-prompts.
  Também após scaffold de fila (`prompt-super-x`). Use when reviewing docs,
  markdown, VISÃO, manuais, ORQUESTRADOR/TRACKER/CONTEXTO, READMEs, "revisão de
  documentação", or when unit tests / error handling do not apply.
---

# Revisão pós-docs (sem testes / sem error handling)

Variante de `revisao-pos-implementacao` para **documentação e artefatos
não-executáveis** (markdown, manuais, trackers, filas, índices).

**Fora de escopo desta skill:** escrever testes unitários, tratamento de
exceções, pytest/jest. Se o alvo for código de produto, use
`revisao-pos-implementacao`. Se o alvo for só corrigir um prompt no chat, use
`analise-prompts`.

## Prompt canônico (adaptado)

Ao aplicar esta skill, trate o pedido como equivalente a:

> Por favor, revise minuciosamente tudo o que foi escrito ou corrigido na documentação (ou artefato equivalente), garantindo que a lógica/conteúdo esteja correto e que a nomenclatura esteja adequada. Corrija eventuais erros, trechos desatualizados e pendências (pontas soltas). Nota: o material deve estar atualizado, pois estamos em setembro de 2026.
> obs: nenhuma seção, passo ou referência se perdeu certo ou não foi concluída?

## Quando aplicar

- Docs em `doc/`, manuais, VISÃO, IMPORTANTE, filas CLI (artefatos da pasta)
- README / TRACKER / ORQUESTRADOR / CONTEXTO / CONSOLIDACAO / TECNICAS
- Skills, rules, checklists, guias de campo
- Qualquer revisão em que **não cabe** teste unitário nem error handling de runtime

**Não usar** (preferir `analise-prompts`) quando o pedido for só corrigir/melhorar
um prompt colado no chat e devolver o texto pronto.

## Escopo

1. **Prioridade:** arquivos tocados nesta conversa / diff / doc nomeado.
2. **Expandir só se necessário:** links para paths citados, docs irmãos do mesmo
   feature, índice que aponta para o arquivo.
3. **Não** reescrever o monorepo de docs nem “melhorar prosa” fora do escopo.
4. **Data de referência:** set/2026+ — comandos, paths e status devem bater com o
   repo atual (grep/read; não confiar só na memória do texto).

## Pipeline (obrigatório)

```
Task Progress:
- [ ] 1. Inventário do que mudou
- [ ] 2. Completude (seções / passos / refs perdidas ou incompletas)
- [ ] 3. Lógica do conteúdo + nomenclatura
- [ ] 4. Erros factuais, desatualizado, pontas soltas
- [ ] 5. Validar paths / links / símbolos no repo
- [ ] 6. Relatório curto ao usuário
```

### 1) Inventário

- Listar docs/artefatos no escopo (`git status` / diff / conversa).
- Anote o que deveria existir: seções, passos da fila, links, comandos, índices.
- Confirme nomes reais no repo — não invente paths ou símbolos.

### 2) Completude — “nada se perdeu / ficou pela metade?”

| Checagem | Falha típica |
|----------|----------------|
| Seção/passo citado no índice ou no tracker | Sumiu ou ficou `TODO` vazio |
| Prompt de fase sem critério de done | Incompleto |
| Link relativo / path de arquivo | 404 no repo |
| Comando PowerShell/python documentado | Sintaxe errada ou script inexistente |
| Cross-ref entre VISÃO / IMPORTANTE / manual | Um lado atualizado, o outro não |
| Tabela/matriz com célula vazia crítica | Ponta solta |

**Ação:** completar seções faltantes; restaurar o que sumiu; remover stubs só se
confirmado obsoleto; alinhar índices (`README`, `03_PROMPTS_A_RODAR`, etc.) quando
fizerem parte do mesmo escopo.

### 3) Lógica + nomenclatura

- Ordem dos passos faz sentido; dependências explícitas.
- Termos consistentes com o projeto (SAC ≠ bot de produto; nomes de apps/pastas).
- Evitar instruções contraditórias no mesmo doc ou entre docs irmãos do escopo.
- Títulos/ids (`slug`, fase `ui-1-…`) estáveis e alinhados à pasta real.

### 4) Desatualizado e pontas soltas

- Datas, versões, “próximo passo”, status de fase vs. o que o repo mostra.
- Snippets que copiam APIs/componentes já trocados no código.
- Placeholders perigosos no PowerShell (`<ID>` → redirect); preferir `CHAT_ID` ou UUID.
- Duplicatas de pasta/asset (dois “canônicos” para o mesmo artefato).

Detalhes: [checklist.md](checklist.md).

### 5) Validar no repo

Para cada path/comando/símbolo importante citado:

1. Arquivo/pasta existe?
2. Símbolo/nome bate com o código ou com a fila?
3. Se estiver errado → **corrigir o doc** (e o índice, se no escopo).

Não rode suíte de testes unitários. Opcional: `--list` / dry-run de fila **só** se
o artefato for uma fila CLI e isso validar completude.

### 6) Relatório ao usuário (obrigatório, curto)

```markdown
## Revisão pós-docs

**Escopo:** … (arquivos)
**Completude:** OK | problemas corrigidos (lista)
**Correções:** bullets do que foi consertado
**Validação:** paths/links checados (resumo)
**Pendências restantes:** só se houver bloqueio externo (senão “nenhuma”)
```

## Regras do projeto

- Não ler/editar `.env` / secrets.
- Não commit/push a menos que o usuário peça.
- Não confundir SAC (`sac/`) com bot de produto (`app/bot/`).
- Mudanças mínimas fora do escopo.
- **Não** inventar testes nem blocos de error handling “por completude”.

## Anti-padrões

- Só listar problemas sem corrigir (esta skill **corrige**)
- Aplicar checklist de código (pytest, try/except) a markdown
- Reescrever tom/estilo de docs inteiros sem necessidade
- Declarar “tudo OK” sem checar paths citados
- Criar doc paralelo duplicado em vez de corrigir o canônico

## Exemplos

Ver [examples.md](examples.md).

## Relação com as irmãs

| Alvo | Skill |
|------|--------|
| Código de produto (API, UI, services) | `revisao-pos-implementacao` |
| Docs, manuais, trackers, fila **após** scaffold | `revisao-pos-docs` (esta) |
| Corrigir / melhorar **prompts** no chat (sem relatório) | `analise-prompts` |
| Scaffold fila Cursor Agent a partir de prompt | `prompt-super-x` |
