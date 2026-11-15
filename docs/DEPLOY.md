# Deploy — homologação (AP2)

Roteiro para o **João** publicar a API no Coolify e instalar o APK `hml` no celular.  
**Não** contém segredos. Cole os valores só no painel do Coolify / Asaas / GitHub — nunca no repositório.

> **Registry / CI:** o envio automático da imagem Docker ao GitHub Container Registry (e o webhook de deploy no workflow) fica para quando o João pedir. Nesta fase o Coolify pode buildar a partir do repositório (`api/Dockerfile`).

---

## 1. Pré-requisitos

- Conta Coolify na VPS (ex.: Hostinger) com domínio apontando para a VPS
- Repositório Git acessível pelo Coolify (clone / deploy key)
- Conta Asaas **sandbox** (chave e token de webhook)
- PostgreSQL 16 (serviço Coolify ou externo) — MinIO opcional na AP2 (fotos só em `cr-6`)

---

## 2. Coolify — projeto de homologação

1. Crie um **projeto** (ex.: `cristalins-hml`) com:
   - serviço **API** (Dockerfile em `api/`, contexto `api/`)
   - serviço **PostgreSQL 16**
   - (opcional) MinIO
2. Domínio da API com **HTTPS automático** (Let's Encrypt), ex.: `https://api-hml.seu-dominio.com`
3. Porta do container: `3000` (variável `PORT` se precisar mudar)
4. Healthcheck do Coolify: `GET /api/v1/health` (ou use o `HEALTHCHECK` do Dockerfile)
5. Deploy: build a partir do `api/Dockerfile` (multi-stage; no start roda `prisma migrate deploy` e sobe a API)

### Variáveis a colar no painel (só os **nomes** — sem valores neste doc)

| Nome | Uso |
| --- | --- |
| `DATABASE_URL` | Connection string do Postgres do projeto |
| `JWT_SECRET` | Assinatura do access token |
| `JWT_REFRESH_SECRET` | Assinatura do refresh token |
| `ASAAS_API_URL` | URL base do Asaas sandbox (ex. valor no painel Asaas / doc oficial) |
| `ASAAS_API_KEY` | Chave de API do sandbox |
| `ASAAS_WEBHOOK_TOKEN` | Token que a API exige no header `asaas-access-token` |
| `ASAAS_MODE` | Em homologação: **`sandbox`** (Pix real no sandbox). Plano B da apresentação: `fake` |
| `CORS_ORIGINS` | Origens permitidas (se houver web); app mobile não depende de CORS |
| `TZ` | `America/Sao_Paulo` (já default no Dockerfile; reforçar no painel se quiser) |
| `PORT` | Opcional; default `3000` |

Chaves listadas em `.env.example` e ainda não obrigatórias na AP2 (deixar vazias ou omitir):  
`SMTP_*`, `FCM_CREDENTIALS`, `S3_*`, `SENTRY_DSN`, e as do compose local (`POSTGRES_*`, `MINIO_*`) — no Coolify o Postgres costuma injetar `DATABASE_URL` direto.

**Não** commitar `.env` nem colar chaves neste arquivo / no chat.

---

## 3. Webhook Asaas (sandbox)

1. No painel Asaas sandbox, cadastre a URL:

   `https://<seu-dominio-api-hml>/api/v1/webhooks/asaas`

2. Configure o token de autenticação do webhook com o **mesmo valor** da variável `ASAAS_WEBHOOK_TOKEN` no Coolify.
3. A API valida o header `asaas-access-token`, grava o evento e responde 200; o processamento roda no job a cada 1 minuto.
4. Confirme `ASAAS_MODE=sandbox` e `ASAAS_API_URL` / `ASAAS_API_KEY` do sandbox.

Plano B (sem rede / demo): `ASAAS_MODE=fake` — Pix simulado; confirmação via fluxo Fake (sem webhook Asaas).

---

## 4. Conferência pós-deploy

```text
GET https://<seu-dominio-api-hml>/api/v1/health
→ 200 { status, banco, ... }

GET https://<seu-dominio-api-hml>/docs
→ Swagger
```

App flavor `hml` deve apontar para essa URL via `--dart-define=API_URL=...`.

---

## 5. APK `hml` (celular físico)

Não assinar com chave real de produção e **não** subir à Play Store nesta fase. O flavor `hml` já usa assinatura de debug no `build.gradle.kts`.

### Gerar

```powershell
cd C:\Users\João\Desktop\Cristalins\app
flutter pub get
flutter build apk --flavor hml -t lib/main_hml.dart --dart-define=API_URL=https://<seu-dominio-api-hml>
```

APK típico:

`app/build/app/outputs/flutter-apk/app-hml-release.apk`

(ajuste o nome se o Flutter gerar variante diferente; confira a pasta `flutter-apk`.)

### Instalar no celular

1. Ative “Fontes desconhecidas” / instalar via USB no Android.
2. USB: `adb install -r app\build\app\outputs\flutter-apk\app-hml-release.apk`
3. Ou copie o APK e abra no aparelho.
4. `applicationId`: `br.com.cristalins.assinatura.hml` (instala ao lado de `dev` / `prod`).

Opcional: `--dart-define=SUPORTE_WHATSAPP=` (vazio até haver número; não inventar).

---

## 6. Compose local (referência)

Com Docker Desktop ligado e `.env` preenchido a partir de `.env.example`:

```powershell
cd C:\Users\João\Desktop\Cristalins
docker compose up -d --build
# Health: http://localhost:3000/api/v1/health
# Swagger: http://localhost:3000/docs
```

Seed (homologação/local, não produção):

```powershell
cd api
npx prisma db seed
```

---

## 7. O que esta fase não faz

- Não chama Coolify, SSH nem webhook de deploy a partir do agente
- Não altera o workflow para push de imagem (aguardando pedido do João)
- Não publica na Play Store nem usa upload key de produção
