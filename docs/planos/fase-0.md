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
