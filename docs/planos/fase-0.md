# Plano — Fase 0 (fundação)

## Esta etapa (`cr-0-repo`)

- Raiz do monorepo: `docker-compose.yml` (api, postgres 16, minio), `.env.example`, `.gitignore`, `.editorconfig`
- Docs iniciais: `CLAUDE.md`, `docs/DECISOES.md`, `docs/ESTUDO.md`, `docs/flutter-rules.md`
- Sem `api/src` e sem `app/lib` ainda

## Próximas etapas da fundação

| Fase | O que entrega |
| --- | --- |
| `cr-0-prisma` | Schema das 20 entidades, migração, seed (8 produtos, 4 kits, 5 zonas) |
| `cr-0-api` | NestJS com módulos vazios, `GET /api/v1/health`, Swagger em `/docs` |
| `cr-0-app` | Flutter flavors, tema Cupertino/Inter, Tela 1 (Boas-vindas) |
| `cr-0-ci` | GitHub Actions `api.yml` e `app.yml` |
| `cr-0-juncao` | `FUNDACAO.md` — aceite da fundação |

## Fora da Fase 0

Auth, preço, ciclo, Pix, telas 2–8 e deploy ficam em `cr-1-*` em diante.

## Esta etapa (`cr-0-prisma`)

- `api/prisma/schema.prisma`: 20 entidades do Anexo, 14 enums (status de assinatura/ciclo, plano, frequência, janela, forma e status de pagamento, ocorrência etc.), `@map`/`@@map` snake_case, dinheiro `Decimal(10,2)`
- Prisma 7.10.1 (generator `prisma-client`, saída `api/prisma/generated/prisma`, adaptador `@prisma/adapter-pg`), `api/prisma.config.ts` com seed `tsx prisma/seed.ts`
- Migração inicial `api/prisma/migrations/20261114230000_init` (gerada com `prisma migrate diff --from-empty`)
- Seed idempotente: 8 produtos, 4 kits, 5 zonas com bairros de exemplo, 7 fatores (volume, compromisso, fidelidade, verão +5% de 01/12/2026 a 31/03/2027), 1 admin, 2 clientes com endereço (`lat`/`lng` nulos), cupom `BEMVINDO10`
- `api/package.json` mínimo — `cr-0-api` completa o projeto Nest

## Esta etapa (`cr-0-api`)

- NestJS 11 em `api/src/`: `main.ts` (TZ padrão `America/Sao_Paulo`, CORS por `CORS_ORIGINS`), `configurar-app.ts` (prefixo `/api/v1`, `ValidationPipe`, filtro global, Swagger em `/docs` com Bearer e uma tag por módulo)
- `common/`: `ClockService`, `RegraNegocioException`, `FiltroExcecao` (`{ codigo, mensagem, campo? }`), `PrismaService` (adaptador pg), `CommonModule` global
- `health/`: `GET /api/v1/health` com `SELECT 1` no banco (200 `ok` ou 503 `SERVICO_INDISPONIVEL`)
- 16 módulos vazios na árvore do Anexo
- Jest (unitário + e2e com Supertest), ESLint 9 flat config, `nest build` → `dist/src/main.js`
