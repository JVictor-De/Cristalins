# Plano — Fase 4 (deploy / homologação AP2)

## Objetivo

Imagem Docker da API e roteiro para o João publicar em homologação (Coolify + HTTPS + webhook Asaas sandbox). APK `hml` documentado para instalação no celular.

## Entregas desta fatia (`cr-4-deploy`)

1. `api/Dockerfile` — multi-stage Node 22 Alpine; `prisma generate` no build; `prisma migrate deploy` antes de subir; healthcheck em `/api/v1/health`; `TZ=America/Sao_Paulo`
2. `docs/DEPLOY.md` — Coolify (HTTPS, envs por nome, webhook), APK hml, nota de que push de imagem ao registry fica para quando o João pedir
3. Trust proxy (`trust proxy = 1`) em `main.ts` — IP real atrás do proxy Coolify (throttle do login / CT19)
4. Plano neste arquivo

## Fora desta fatia (outras fases da Fase 4)

- README com 7 itens, prints, ESTUDO, APRESENTACAO → `cr-4-docs`
- Acessibilidade das 8 telas → `cr-4-a11y`
- Checklist final AP2 → `cr-4-revisao`
- Push de imagem no workflow / Coolify write / SSH → **não** nesta fase
