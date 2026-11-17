# Matriz rubrica AP2 × evidências (Cristalins)

Fila `ap2_fechamento` · fase `ap2-5-matriz-revisao` · **2026-11-17**  
Fontes: `CONTEXTO.md`, inventário, SPEC, `AP2_ACTIVITIES_INTENTS.md`, `AP2_BONUS_CHECKLIST.md`, Manifest/README.  
Status: **Atende** | **Parcial** | **Não atende** — sem “Atende” sem path/comando.

---

## Critérios pontuados

| Critério | Pontos | Status | Evidência |
| --- | ---: | --- | --- |
| Funcionamento geral | 1,0 | **Atende** | Fluxo quiz→resultado→cesta→endereço→Pix→Minha assinatura; `AppRoutes` em `app/lib/core/routes.dart`; README § Proposta |
| ≥5 Activities nativas | 1,5 | **Atende** | **9** `<activity>` em `app/android/app/src/main/AndroidManifest.xml` (`MainActivity` + 8 cascas). Classes: `…/assinatura/{MainActivity,RotaFlutterActivity,CristalinsEngine}.kt`. Teste: `app/test/android_activities_manifest_test.dart` |
| Intents (explícitas + implícitas) | 1,0 | **Atende** | **Explícita:** `CristalinsEngine.abrirActivity` + `NavegacaoNativa` (`app/lib/core/intents/navegacao_nativa.dart`); channel `br.com.cristalins.assinatura/navegacao`; doc `docs/AP2_ACTIVITIES_INTENTS.md`. **Implícita:** `AbridorLinks` / `Compartilhador`; site onboarding; share `resultado_screen.dart`; `geo:` `endereco_screen.dart`; Manifest `<queries>` VIEW/SEND/geo |
| UX/UI (≥6 widgets + feedback) | 1,0 | **Atende** | `app/lib/core/widgets/` (≥20: `BotaoPrincipal`, `CardProduto`, `StepperQuantidade`, `Estados`, `Controles`, `TelaTituloGrande`, …); loading/erro/sucesso nas telas do fluxo |
| API REST + Swagger | 1,0 | **Atende** | Nest + `@nestjs/swagger`; `api/src/configurar-app.ts`; CRUD em controllers (`assinaturas`, `enderecos`, `clientes`, …). Local `/docs`; público `https://apicristalins.peladeiro.cloud/docs` (200 em 2026-11-17) |
| BD relacional via API | 1,0 | **Atende** | `api/prisma/schema.prisma` + PostgreSQL; app só via `ApiClient` / repositórios |
| Qualidade de código | 1,0 | **Parcial** | CI `.github/workflows/{api,app}.yml`; Jest + Flutter tests (ex. Manifest/channel); regra de negócio na API. Sem meta de cobertura 70% nesta fila |
| Oral | 2,5 | **Parcial / preparado** | `docs/APRESENTACAO.md` + `docs/ESTUDO.md` + demo Activities/Intents. Falta João ensaiar com device; prints **3/8** |
| Bônus | +0,5 | **Atende** | API na nuvem — `docs/AP2_BONUS_CHECKLIST.md`; health/docs/web 200. Play fora. APK físico opcional (pendente João) |

---

## Entrega / README (enunciado)

| Item README / entrega | Status | Evidência |
| --- | --- | --- |
| Título | **Atende** | README L1 |
| Proposta | **Atende** | README § Proposta |
| Tecnologias | **Atende** | README § Tecnologias |
| Execução (API + app) | **Atende** | README §§ Como rodar |
| Prints (8 PNG embutidos) | **Parcial** | **3/8** canônicos: `01`, `02`, `05` no README. Extras: `home-inicio`, `sacola-checkout`, `pdp-*`. Faltam `03`, `04`, `06`–`08` |
| Descrição da API | **Atende** | README § Descrição da API |
| Link Swagger | **Atende** | README § Swagger: localhost + `https://apicristalins.peladeiro.cloud/docs` |
| GitHub público | **Atende** | https://github.com/JVictor-De/Cristalins |

---

## Aceite global (CONTEXTO §11) — checklist

- [x] Manifest ≥5 Activities AP2 + launcher — **9** activities  
- [x] Intent explícita Activity→Activity demonstrável — channel + doc oral  
- [x] ≥1 Intent implícita — share / geo / site  
- [ ] 8 PNG em `docs/prints/` no README — **3/8** (`01`, `02`, `05`); faltam `03`, `04`, `06`–`08` (João)  
- [x] README 7 itens **exceto prints PNG** + Swagger local/público  
- [x] `AP2_ACTIVITIES_INTENTS.md` + esta matriz + `AP2_BONUS_CHECKLIST.md`  
- [x] App/API arquitetura no ar (hml 200); smoke Manifest/channel tests OK  
- [x] Matriz sem linha obrigatória em branco  

---

## Revisão pós-implementação (1 passagem)

| Achado | Severidade | Ação |
| --- | --- | --- |
| Prints 3/8 PNG | Parcial (README prints) | Completar `03`, `04`, `06`–`08`; não inventar. Guia `COMO_CAPTURAR.md` |
| Inventário (`artefatos/INVENTARIO.md`) desatualizado (ainda fala 1 Activity) | Baixa (artefato histórico) | Não reescrever inventário nesta fase; matriz é a fonte atual |
| Oral sem bloco Activities no roteiro 5 min | Média | **Correção única:** acrescentar demo 30–60s em `docs/APRESENTACAO.md` |
| Qualidade / cobertura 70% | Fora de escopo fila | Status Parcial honesto |

### Comandos de revalidação

```powershell
Select-String -Path app\android\app\src\main\AndroidManifest.xml -Pattern '<activity'
(Get-ChildItem docs\prints\*.png -ErrorAction SilentlyContinue).Count  # esperado 8 após João
cd app; flutter test test/android_activities_manifest_test.dart test/core/intents/navegacao_nativa_test.dart
Invoke-WebRequest https://apicristalins.peladeiro.cloud/api/v1/health -UseBasicParsing
```

---

## Pendências honestas para o João

1. Capturar 8 PNG e retomar `ap2-3-prints-readme` (embeds no README).  
2. Opcional: APK `hml` no físico + ensaiar oral com `dumpsys activity`.  
3. Não Coolify write sem pedido explícito.
