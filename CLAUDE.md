# Cristalins — Assinatura Water Protein (RJ)

App Android (Flutter) + API NestJS/Prisma/PostgreSQL para assinatura recorrente de bebidas Cristalins no município do Rio, com quiz, preço dinâmico e cobrança Asaas (Pix na AP2).
Monorepo: `app/`, `api/`, `docs/`, `docker-compose.yml`. Regra de negócio só na API; app coleta, chama e exibe.
Dinheiro com `decimal.js` / `Decimal(10,2)`; datas em `America/Sao_Paulo`; erros `{ codigo, mensagem, campo? }`; prefixo `/api/v1`; Swagger em `/docs`.
Não inventar regra fora do contexto; não commitar segredos; Conventional Commits em português; sem `git push` nem Coolify por conta do agente.
Spec completa: `super-prompt-cristalins.md` na raiz (Anexo incluso). Destilação da fila: `doc/prompts/features/cristalins_assinatura/CONTEXTO.md`.

@docs/flutter-rules.md

## graphify

This project has a knowledge graph at graphify-out/ with god nodes, community structure, and cross-file relationships.

Rules:
- When graphify-out/graph.json exists, run `graphify query "<question>"` before your first grep, search or source-file read for a codebase question, and put this rule in every subagent prompt that explores code. Read raw files only for lines the graph or an earlier read already located. Use `graphify path "<A>" "<B>"` for relationships and `graphify explain "<concept>"` for focused concepts. These return a scoped subgraph, usually much smaller than GRAPH_REPORT.md or raw grep output.
- If graphify-out/wiki/index.md exists, use it for broad navigation instead of raw source browsing.
- Read graphify-out/GRAPH_REPORT.md only for broad architecture review or when query/path/explain do not surface enough context.
- After modifying code, run `graphify update .` to keep the graph current (AST-only, no API cost).
- A committed graphify-out/graph.json is rewritten whole on every build, so a large diff to it in a pull request is expected. Do not flag it as churn or suggest skipping the graph rebuild or its hooks.
