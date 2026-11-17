# Deploy — homologação (AP2)

Roteiro para o **João** publicar a API e o **Flutter Web** no Coolify, e (opcional) instalar o APK `hml` no celular.  
**Não** contém segredos. Cole os valores só no painel do Coolify / Asaas / GitHub — nunca no repositório.

> **Registry / CI:** o envio automático da imagem Docker ao GitHub Container Registry (e o webhook de deploy no workflow) fica para quando o João pedir. Nesta fase o Coolify pode buildar a partir do repositório (`api/Dockerfile` e `app/Dockerfile`).

**URLs de demo (DNS `peladeiro.cloud`):**

| Papel | Host | Serviço Coolify |
| --- | --- | --- |
| UI web | `https://cristalins.peladeiro.cloud` | Flutter Web (`app/Dockerfile`, porta 80) |
| API | `https://apicristalins.peladeiro.cloud` | Nest (`api/Dockerfile`, porta 3000) |

O APK Android **não** precisa de DNS; só aponta para a URL da API via `--dart-define=API_URL=...`.

---

## 1. Pré-requisitos

- Conta Coolify na VPS (ex.: Hostinger) com IP público conhecido
- Domínio `peladeiro.cloud` (ou outro) com painel DNS
- Repositório Git acessível pelo Coolify (clone / deploy key)
- Conta Asaas **sandbox** (chave e token de webhook)
- Projeto Coolify **InfraestruturaCompartilhada** com `postgresql-cristalins` (dedicado; não reutilizar password do central via MCP)
- MinIO opcional na AP2 (fotos só em `cr-6`)

---

## 2. DNS (checklist)

No painel DNS do domínio (ex. Hostinger → Gerenciar registros DNS), crie **dois** registros `A` apontando para o **mesmo** IPv4 da VPS:

| Tipo | Nome | Valor | TTL |
| --- | --- | --- | --- |
| `A` | `apicristalins` | `<IPv4 da VPS>` | `14400` (ou `300` na 1ª vez) |
| `A` | `cristalins` | `<IPv4 da VPS>` | `14400` (ou `300` na 1ª vez) |

Resultado esperado:

- `apicristalins.peladeiro.cloud` → API
- `cristalins.peladeiro.cloud` → Flutter Web

Não use botões Shopify / Gmail / verificação Google para este app.  
Não escreva o domínio completo no campo Nome (o painel já sufixa `.peladeiro.cloud`).

Propagação: minutos a algumas horas. Confira com `nslookup apicristalins.peladeiro.cloud` / `nslookup cristalins.peladeiro.cloud`.

---

## 3. Coolify — projeto InfraestruturaCompartilhada

Homologação vive no projeto Coolify **InfraestruturaCompartilhada** (mesmo server/rede dos serviços partilhados). **Não** reiniciar nem apagar `postgresql-central` nem `redis-central`.

| Recurso | Nome no Coolify | Notas |
| --- | --- | --- |
| API | `apicristalins` | Dockerfile `api/`, porta `3000`, domain `https://apicristalins.peladeiro.cloud` |
| Web | `cristalins-web` | Dockerfile `app/`, porta `80`, domain `https://cristalins.peladeiro.cloud` |
| Postgres | `postgresql-cristalins` | DB dedicado Cristalins (isolado do central) |
| Intactos | `postgresql-central`, `redis-central` | Já existiam; não alterados por este deploy |

1. Domínios com **HTTPS automático** (Let's Encrypt) nos dois apps acima.
2. Healthchecks:
   - API: `GET /api/v1/health`
   - Web: `GET /` (Nginx)
3. Deploy: build a partir dos Dockerfiles no repo `JVictor-De/Cristalins` (`main`). A API roda `prisma migrate deploy` no start.
4. A API Cristalins **não** usa Redis nesta fase; `redis-central` fica só para outros serviços do projeto.

### Build-args do serviço Web (`app/Dockerfile`)

| Arg | Uso |
| --- | --- |
| `API_URL` | Base da API **sem** `/api/v1`. Demo: `https://apicristalins.peladeiro.cloud` |
| `SUPORTE_WHATSAPP` | Opcional; default fictício `5521999999999` no app/Dockerfile; override com o número real |
| `URL_TERMOS` | Default `https://cristalins.peladeiro.cloud/termos.html` (`app/web/termos.html`) |
| `URL_PRIVACIDADE` | Default `https://cristalins.peladeiro.cloud/privacidade.html` |

### Variáveis da API no painel (só os **nomes** — sem valores neste doc)

| Nome | Uso |
| --- | --- |
| `DATABASE_URL` | Connection string do Postgres do projeto |
| `JWT_SECRET` | Assinatura do access token |
| `JWT_REFRESH_SECRET` | Assinatura do refresh token |
| `ASAAS_API_URL` | URL base do Asaas sandbox (ex. valor no painel Asaas / doc oficial) |
| `ASAAS_API_KEY` | Chave de API do sandbox |
| `ASAAS_WEBHOOK_TOKEN` | Token que a API exige no header `asaas-access-token` |
| `ASAAS_MODE` | Em homologação: **`sandbox`** (Pix real no sandbox). Plano B da apresentação: `fake` |
| `CORS_ORIGINS` | **Obrigatório para Flutter Web.** Ver seção 4 |
| `TZ` | `America/Sao_Paulo` (já default no Dockerfile; reforçar no painel se quiser) |
| `PORT` | Opcional; default `3000` |

Chaves listadas em `.env.example` e ainda não obrigatórias na AP2 (deixar vazias ou omitir):  
`SMTP_*`, `FCM_CREDENTIALS`, `S3_*`, `SENTRY_DSN`, e as do compose local (`POSTGRES_*`, `MINIO_*`) — no Coolify o Postgres costuma injetar `DATABASE_URL` direto.

**Não** commitar `.env` nem colar chaves neste arquivo / no chat.

---

## 4. CORS (Flutter Web)

O APK não usa CORS. O browser em `cristalins.peladeiro.cloud` **precisa**.

Na API (Coolify), defina:

```text
CORS_ORIGINS=https://cristalins.peladeiro.cloud
```

Várias origens: separadas por vírgula, sem espaço obrigatório (a API faz `trim`).  
Sem `CORS_ORIGINS`, a API **não** libera origem cruzada (`api/src/main.ts`).

Local (Chrome + API em `:3000`):

```text
CORS_ORIGINS=http://localhost:8080,http://127.0.0.1:8080
```

(ajuste à porta do `flutter run -d chrome`.)

---

## 5. Webhook Asaas (sandbox)

1. No painel Asaas sandbox, cadastre a URL:

   `https://apicristalins.peladeiro.cloud/api/v1/webhooks/asaas`

2. Configure o token de autenticação do webhook com o **mesmo valor** da variável `ASAAS_WEBHOOK_TOKEN` no Coolify.
3. A API valida o header `asaas-access-token`, grava o evento e responde 200; o processamento roda no job a cada 1 minuto.
4. Confirme `ASAAS_MODE=sandbox` e `ASAAS_API_URL` / `ASAAS_API_KEY` do sandbox.

Plano B (sem rede / demo): `ASAAS_MODE=fake` — Pix simulado; confirmação via fluxo Fake (sem webhook Asaas).

---

## 6. Conferência pós-deploy

```text
GET https://apicristalins.peladeiro.cloud/api/v1/health
→ 200 { status, banco, ... }

GET https://apicristalins.peladeiro.cloud/docs
→ Swagger

GET https://cristalins.peladeiro.cloud/
→ app Flutter Web (splash → onboarding marketplace; `/boas-vindas` é alias)
```

No browser: login / quiz / cesta / Pix.  
Limitações da demo web: push FCM desligado; foto de ocorrência via seletor de arquivo (sem câmera nativa).

---

## 7. Flutter Web — local e build

### Rodar no Chrome (dev)

```powershell
cd C:\Users\João\Desktop\Cristalins\app
flutter pub get
flutter run -d chrome -t lib/main_dev.dart
# API local: AppConfig usa http://localhost:3000 no web (dev).
# Ou force: --dart-define=API_URL=http://localhost:3000
```

### Build estático (igual ao Coolify)

```powershell
cd C:\Users\João\Desktop\Cristalins\app
flutter build web -t lib/main_hml.dart --release --base-href=/ `
  --dart-define=API_URL=https://apicristalins.peladeiro.cloud
```

Saída: `app/build/web/` (servir com Nginx ou `python -m http.server` só para inspeção).

### Smoke checklist (web)

1. `GET` health da API 200  
2. Abrir UI → onboarding (ou shell se já visto)  
3. Cadastro/login (quando for assinar / conta)  
4. Quiz → recomendação  
5. Endereço (CEP RJ) → cesta → plano → Pix / aguardando  
6. (Opcional) ocorrência com foto via arquivo  

---

## 8. APK `hml` (celular físico)

Não assinar com chave real de produção e **não** subir à Play Store nesta fase. O flavor `hml` já usa assinatura de debug no `build.gradle.kts`.

### Gerar

```powershell
cd C:\Users\João\Desktop\Cristalins\app
flutter pub get
flutter build apk --flavor hml -t lib/main_hml.dart --dart-define=API_URL=https://apicristalins.peladeiro.cloud
```

APK típico:

`app/build/app/outputs/flutter-apk/app-hml-release.apk`

(ajuste o nome se o Flutter gerar variante diferente; confira a pasta `flutter-apk`.)

### Instalar no celular

1. Ative “Fontes desconhecidas” / instalar via USB no Android.
2. USB: `adb install -r app\build\app\outputs\flutter-apk\app-hml-release.apk`
3. Ou copie o APK e abra no aparelho.
4. `applicationId`: `br.com.cristalins.assinatura.hml` (instala ao lado de `dev` / `prod`).

Opcional: `--dart-define=SUPORTE_WHATSAPP=5521…` (default fictício no código; trocar pelo real).

### Publicar no site (banner “Baixar app”)

1. Copie o APK para o static do Flutter Web:

```powershell
New-Item -ItemType Directory -Force -Path web\downloads | Out-Null
Copy-Item build\app\outputs\flutter-apk\app-hml-release.apk web\downloads\cristalins-hml.apk -Force
```

2. Rebuild/redeploy o **web** (Coolify app `cristalins` / domínio `cristalins.peladeiro.cloud`).  
   O `index.html` mostra um banner em **Android** se `GET /downloads/cristalins-hml.apk` retornar 200.  
   URL pública: `https://cristalins.peladeiro.cloud/downloads/cristalins-hml.apk`

3. Sem o arquivo no image do Coolify, o banner **não** aparece (HEAD falha de propósito).
4. O APK (~67 MB) está no `.gitignore` (`app/web/downloads/*.apk`). Para o Coolify incluir no build: copie o arquivo para `app/web/downloads/` **antes** do deploy (contexto Docker faz `COPY . .` e o `flutter build web` copia `web/` → `build/web/`). Ou force-add no git se preferir versionar.

---

## 9. Compose local (referência)

Com Docker Desktop ligado e `.env` preenchido a partir de `.env.example` (inclua `CORS_ORIGINS` se for testar web):

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

## 10. O que esta fase não faz

- Não chama Coolify, SSH nem webhook de deploy a partir do agente
- Não altera o workflow para push de imagem (aguardando pedido do João)
- Não publica na Play Store nem usa upload key de produção
- Não configura FCM Web (push continua só no Android quando Firebase estiver ok)
