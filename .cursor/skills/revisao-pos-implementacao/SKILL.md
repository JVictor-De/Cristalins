---
name: revisao-pos-implementacao
description: >-
  Revisa minuciosamente o que foi implementado ou corrigido: lógica, nomenclatura,
  bugs, componentes desatualizados, pontas soltas, testes unitários, tratamentos
  de erro e funções incompletas/perdidas. Use when the user asks for revisão pós-
  implementação, QA de mudanças, "revisar o que foi feito", "pontas soltas",
  "nenhuma função se perdeu", unit tests após feature, or pastes the review
  prompt about logic/nomenclature/tests (setembro 2026+).
---

# Revisão pós-implementação

Skill de **auditoria + correção** do escopo recém-alterado (diff / arquivos da
conversa / feature citada). Não é code review genérico de PR: o agente **corrige**
o que achar errado e **completa** o que ficou pela metade.

## Prompt canônico (verbatim)

Ao aplicar esta skill, trate o pedido do usuário como equivalente a:

> Por favor, revise minuciosamente tudo o que foi implementado ou corrigido, garantindo que a lógica esteja correta e que a nomenclatura das variáveis esteja adequada. Corrija eventuais erros, bugs, componentes desatualizados e pendências (pontas soltas). Além disso, desenvolva os testes unitários necessários e tratamentos de erros. Nota: o código deve estar atualizado, pois estamos em setembro de 2026.
> obs: nenhuma função se perdeu certo ou não foi concluída?

## Quando aplicar

- Usuário cola/pede a revisão acima (ou equivalente)
- Fim de uma fase de implementação / fila CLI / prompt de feature
- “Fecha as pontas”, “faltou teste?”, “algo ficou pela metade?”

## Escopo

1. **Prioridade:** arquivos tocados nesta conversa / no diff local / na feature nomeada.
2. **Expandir só se necessário:** imports quebrados, callers órfãos, testes do mesmo módulo.
3. **Não** refatorar áreas não relacionadas nem “modernizar por modernizar”.
4. **Data de referência:** set/2026+ — libs, APIs e padrões do repo devem refletir o
   estado atual do projeto (não snippets antigos de docs desatualizados).

## Pipeline (obrigatório)

```
Task Progress:
- [ ] 1. Inventário do que mudou
- [ ] 2. Completude (funções perdidas / incompletas)
- [ ] 3. Lógica + nomenclatura
- [ ] 4. Bugs, componentes desatualizados, pontas soltas
- [ ] 5. Tratamento de erros
- [ ] 6. Testes unitários
- [ ] 7. Rodar testes relevantes
- [ ] 8. Relatório curto ao usuário
```

### 1) Inventário

- `git status` / `git diff` (e histórico da conversa) para listar arquivos no escopo.
- Anote intents: o que deveria existir (API, UI, service, schema, migration, teste).
- Confirme paths e símbolos com **grep/read no repo** — não invente nomes.

### 2) Completude — “nenhuma função se perdeu?”

Para cada item do inventário, verifique:

| Checagem | Falha típica |
|----------|----------------|
| Assinatura / export ainda usada | Função removida sem migrar callers |
| TODO / `pass` / `NotImplemented` / stub | Implementação pela metade |
| Rota/handler sem service (ou vice-versa) | Fatia vertical incompleta |
| Schema/model/migration desalinhados | Campo só num lado |
| UI sem wiring / hook órfão | Componente morto ou tela quebrada |
| Teste do happy path sem o novo comportamento | Cobertura ilusória |

**Ação:** reimplementar ou concluir o que estiver incompleto; restaurar o que foi
apagado por engano; remover dead code só se confirmado órfão.

### 3) Lógica + nomenclatura

- Fluxos corretos (authz, multi-tenant/clube, estados, edge cases).
- Nomes consistentes com o módulo vizinho (PT/EN do arquivo, não misturar sem motivo).
- Evitar variáveis enganosas (`data`, `tmp`, `result` genéricos em lógica de negócio).

### 4) Bugs, desatualizado, pontas soltas

- Componentes/APIs deprecated no próprio repo → migrar para o padrão atual.
- Imports mortos, flags mortas, comentários “depois faço”, docs que contradizem o código
  **no escopo** (só se a tarefa incluir doc ou o doc estiver claramente errado e for
  do mesmo feature).
- Contratos FE↔BE (tipos, status codes, campos).

Detalhes extras: [checklist.md](checklist.md).

### 5) Tratamento de erros

- Falhas esperadas: mensagem clara, status HTTP / resultado de domínio coerente.
- Não engolir exceção sem log/contexto.
- Validação de entrada alinhada ao schema existente do projeto.
- Em UI: estados de erro/loading/empty sem crash.

### 6) Testes unitários

Não é skill só de Flutter. Acrescentar/ajustar testes no **mesmo estilo** da
superfície tocada:

| Superfície | Onde | Comando típico |
|------------|------|----------------|
| API / `app/` | `tests/` | `pytest path/to/test_file.py -q` |
| Admin Next | `admin_frontend/src/__tests__` | `npm test -- --testPathPattern=nome` (Jest) |
| App Flutter | `flutter_app/test/` | `flutter test path/to/test.dart` |
| SAC | `sac/tests/` | `pytest` no pacote `sac` |

- Cobrir: happy path, 1–2 edge cases relevantes, erro/autorização se a mudança tocar nisso.
- Formulário/validação/a11y no admin → Jest; no app → `flutter test`. Sem Playwright nesta skill (E2E é backlog **G1**).
- Não criar suíte gigante fora do escopo.

### 7) Verificar

Rodar só o necessário, por exemplo:

```powershell
pytest path/to/test_file.py -q
# e/ou (admin)
npm test -- --testPathPattern=nome-relevante
# e/ou (Flutter)
flutter test test/presentation/widgets/ios_componentes_test.dart
```

Corrigir até ficar verde no escopo. Se o ambiente impedir (deps/serviço), diga o que
faltou rodar e por quê.

### 8) Relatório ao usuário (obrigatório, curto)

```markdown
## Revisão pós-implementação

**Escopo:** … (arquivos / feature)
**Completude:** OK | problemas corrigidos (lista)
**Correções:** bullets do que foi consertado
**Testes:** o que foi adicionado/alterado + comando + resultado
**Pendências restantes:** só se houver bloqueio externo (senão “nenhuma”)
```

## Regras do projeto

- Não ler/editar `.env` / secrets.
- Não commit/push a menos que o usuário peça.
- Não confundir SAC (`sac/`) com bot de produto (`app/bot/`).
- Mudanças mínimas fora do escopo da revisão.

## Anti-padrões

- Só listar problemas sem corrigir (esta skill **corrige**)
- Refatoração cosmética ampla
- Testes que só assertam mock sem comportamento
- Declarar “tudo OK” sem inventário de completude
- Atualizar dependências major sem necessidade da revisão

## Relação com as irmãs

| Alvo | Skill |
|------|--------|
| Código de produto (API, UI, services) | `revisao-pos-implementacao` (esta) |
| Docs, manuais, trackers | `revisao-pos-docs` |
| Corrigir / melhorar **prompts** no chat (sem relatório) | `analise-prompts` |

## Exemplos

Ver [examples.md](examples.md).
