# Cristalins — Assinatura Water Protein (RJ)

App Android (Flutter) + API NestJS/Prisma/PostgreSQL para assinatura recorrente de bebidas Cristalins no município do Rio, com quiz, preço dinâmico e cobrança Asaas (Pix na AP2).
Monorepo: `app/`, `api/`, `docs/`, `docker-compose.yml`. Regra de negócio só na API; app coleta, chama e exibe.
Dinheiro com `decimal.js` / `Decimal(10,2)`; datas em `America/Sao_Paulo`; erros `{ codigo, mensagem, campo? }`; prefixo `/api/v1`; Swagger em `/docs`.
Não inventar regra fora do contexto; não commitar segredos; Conventional Commits em português; sem `git push` nem Coolify por conta do agente.
Spec completa: `super-prompt-cristalins.md` na raiz (Anexo incluso). Destilação da fila: `doc/prompts/features/cristalins_assinatura/CONTEXTO.md`.

@docs/flutter-rules.md
