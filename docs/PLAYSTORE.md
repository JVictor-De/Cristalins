# Play Store — flavor `prod`

Roteiro para o **João** publicar o app Android. **Não publica sozinho** (nem o agente): sem Play Console, sem chave no repositório, sem `git push` desta fase.

Homologação APK: `docs/DEPLOY.md`. Produção API: `docs/LANCAMENTO.md`.

---

## 1. Flavor e identificação

| Item | Valor |
| --- | --- |
| Flavor | `prod` |
| Entrada | `lib/main_prod.dart` |
| `applicationId` | `br.com.cristalins.assinatura` (sem sufixo; `dev` / `hml` usam `.dev` / `.hml`) |
| Nome na loja | “Cristalins” (`resValue` no `build.gradle.kts`) |
| Versão | `pubspec.yaml` no formato `X.Y.Z+build` (hoje `0.1.0+1`); **build sempre crescente** |
| `minSdk` | 26 |
| `targetSdk` | o exigido pelo Play no ano da publicação (conferir no Console; Gradle usa `flutter.targetSdkVersion`) |

API e Sentry **só** por dart-define (nunca hardcoded):

```text
--dart-define=API_URL=https://<dominio-api-prod>
--dart-define=SENTRY_DSN=<dsn>          # opcional até haver projeto Sentry
--dart-define=SUPORTE_WHATSAPP=5521…   # default fictício no app; trocar pelo real na loja
```

---

## 2. Assinatura — Play App Signing

Estado atual do repo: `release` ainda usa `signingConfigs.debug` em `app/android/app/build.gradle.kts` (comentário aponta para cr-8). Em produção o João deve:

1. Gerar **upload keystore** **fora** do repositório (máquina local / cofre).
2. Ativar **Play App Signing** no Play Console (Google guarda a app signing key).
3. Configurar assinatura de release via `key.properties` **gitignored** ou segredos do CI — **nunca** commitar `.jks` / senhas / `key.properties` com valores.
4. Trocar o `signingConfig` de `debug` para o de upload **localmente** (ou no workflow) quando for gerar o AAB de loja.

Não há chave de upload neste repositório de propósito.

---

## 3. Ofuscação e símbolos Sentry

Anexo: ativar `--obfuscate` e enviar símbolos de depuração ao Sentry (RNF11).

### App Bundle (loja)

```powershell
cd C:\Users\João\Desktop\Cristalins\app
flutter pub get
flutter build appbundle --flavor prod -t lib/main_prod.dart `
  --obfuscate `
  --split-debug-info=build/app/symbols `
  --dart-define=API_URL=https://<dominio-api-prod> `
  --dart-define=SENTRY_DSN=<dsn>
```

Saída típica: `build/app/outputs/bundle/prodRelease/app-prod-release.aab`.

### APK (só teste lateral; loja prefere AAB)

```powershell
flutter build apk --flavor prod -t lib/main_prod.dart `
  --obfuscate `
  --split-debug-info=build/app/symbols `
  --dart-define=API_URL=https://<dominio-api-prod> `
  --dart-define=SENTRY_DSN=<dsn>
```

### Símbolos no Sentry

1. Pasta `build/app/symbols` gerada pelo `--split-debug-info`.
2. Upload com a CLI/plugin Sentry do projeto (token e org **fora** do Git; DSN já no dart-define).
3. Sem `SENTRY_DSN`, o app sobe sem crash reporting — ok em dev; prod deve ter DSN.

API: símbolos/source maps não se aplicam da mesma forma; erros vão via `@sentry/node` se `SENTRY_DSN` no Coolify.

---

## 4. Conta de desenvolvedor e trilhas

| Passo | Ação | Status |
| --- | --- | --- |
| Conta | Pessoal (CPF) **ou** organização (CNPJ + D-U-N-S). **Não inventar** CNPJ/D-U-N-S neste doc | **pendente** (João / Cristalins) |
| Ficha | Nome, descrição, ícone, prints, classificação etária (**18+**), formulário de segurança de dados, política de privacidade (URL pública) | URL hml: `https://cristalins.peladeiro.cloud/privacidade.html` — restante da ficha **pendente** |
| Trilha **interna** | Subir o AAB; testadores do time | **pendente** |
| Teste **fechado** | Se conta **pessoal** criada após 13/11/2023: ≥ **12 testadores inscritos** por **14 dias** seguidos antes de pedir produção ([política Google](https://support.google.com/googleplay/android-developer/answer/14151465)). Recrutar **15+** para não perder a contagem se alguém sair. Conta **organização** não tem essa exigência | **pendente** (se pessoal) |
| Produção | Pedir acesso à produção após o fechado (se aplicável) | **pendente** |
| Lançamento **gradual** | Começar em **~20%** dos usuários; ir a **100%** se sem erros críticos em **48 h** | **pendente** |
| Rollback app | Pausar o gradual no Console e publicar build maior | roteiro **feito** |

---

## 5. Ordem prática

1. API prod no ar + termos/privacidade em URL (`docs/LANCAMENTO.md`).
2. Configurar upload key + Play App Signing (chaves fora do Git).
3. Gerar AAB ofuscado com `API_URL` / `SENTRY_DSN` de prod; enviar símbolos.
4. Trilha interna → (se pessoal) teste fechado 14 dias / 12+ → produção gradual 20% → 100%.
5. Só depois: piloto 30–50 na Zona Sul (`docs/LANCAMENTO.md`).

---

## 6. O que não fazer

- Não commitar keystore, `key.properties` com segredos nem DSN/token no código
- Não publicar pela conta do agente / Coolify MCP
- Não inventar preço de vitrine, CNPJ, domínio nem D-U-N-S
