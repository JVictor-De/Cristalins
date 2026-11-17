# AP2 — Checklist bônus (+0,5)

Rubrica Dontpad: bônus por **aparelho físico** **ou** Play beta **ou** **API na nuvem**.  
Esta entrega usa **API na nuvem** (já no ar). Play Store = fora de escopo.

Revalidado em **2026-11-17** (fase `ap2-4-bonus`). Sem Coolify deploy/restart nesta fase.

## Itens

| Item | Status | Evidência / comando |
| --- | --- | --- |
| API na nuvem (Coolify hml) | [x] **feito** | `https://apicristalins.peladeiro.cloud` — roteiro `docs/DEPLOY.md` |
| Health público 200 | [x] **feito** | `GET https://apicristalins.peladeiro.cloud/api/v1/health` → 200 |
| Swagger público 200 | [x] **feito** | `https://apicristalins.peladeiro.cloud/docs` → 200 |
| Web Flutter hml 200 | [x] **feito** | `https://cristalins.peladeiro.cloud/` → 200 |
| Link Swagger no README | [x] **feito** | README § Swagger: localhost + URL pública |
| APK `hml` gerado | [x] **feito** (2026-11-17) | `app/web/downloads/cristalins-hml.apk` (~67 MB); build com API nuvem |
| Banner “Baixar app” no web | [ ] pendente redeploy | `app/web/index.html` + nginx `/downloads/`; sobe após Coolify do web |
| APK `hml` no aparelho físico | [ ] pendente João | instalar do site ou `adb install` (`docs/DEPLOY.md` §8) |
| Demo oral (nuvem + app) | [ ] pendente João | Roteiro `docs/APRESENTACAO.md`; Intents em `docs/AP2_ACTIVITIES_INTENTS.md` |
| Play Store / Play beta | [ ] **fora de escopo** | Não fazer nesta fila |

## Como provar o bônus “API na nuvem” na oral (30 s)

1. Abrir no projetor: health → JSON/200.  
2. Abrir Swagger público → listar um GET (ex. produtos) ou health.  
3. Opcional: web `cristalins.peladeiro.cloud` ou APK apontando para a mesma API.

## O que não fazer

- Não redeploy Coolify sem pedido explícito do João.  
- Não colar tokens Asaas/Coolify/webhook no repo nem nos slides.  
- Não publicar na Play Store.
