# AP2 — Activities nativas e Intents

Documentação para a oral e para a rubrica Dontpad. Implementação: fila `ap2_fechamento` / fase `ap2-2-activities`.

## Tabela Activity ↔ rota Flutter

| Activity Kotlin | Rota (`AppRoutes`) | Manifest |
| --- | --- | --- |
| `MainActivity` (launcher) | `/` (splash) | `exported=true` + MAIN/LAUNCHER |
| `BoasVindasActivity` | `/boas-vindas` | `exported=false` |
| `CadastroLoginActivity` | `/cadastro-login` | `exported=false` |
| `QuizActivity` | `/quiz` | `exported=false` |
| `ResultadoActivity` | `/resultado` | `exported=false` |
| `CatalogoActivity` | `/catalogo` | `exported=false` |
| `EnderecoActivity` | `/endereco` | `exported=false` |
| `PlanoPagamentoActivity` | `/plano-pagamento` | `exported=false` |
| `MinhaAssinaturaActivity` | `/minha-assinatura` | `exported=false` |

**Total: 9 Activities** (≥5 da rubrica). Package: `br.com.cristalins.assinatura`.

Código: `app/android/app/src/main/kotlin/br/com/cristalins/assinatura/` (`MainActivity`, `RotaFlutterActivity`, `CristalinsEngine`).

## Intent explícita (Activity → Activity)

1. Dart chama `NavegacaoNativa.abrir` (`app/lib/core/intents/navegacao_nativa.dart`).
2. Navigator Flutter atualiza a rota (engine compartilhado `cristalins_engine`).
3. MethodChannel `br.com.cristalins.assinatura/navegacao` → método `abrirActivity`.
4. Kotlin faz `startActivity(Intent(this, XActivity::class.java))` — **component explícito** (whitelist).

### Como demonstrar na oral (~1 min)

1. Abrir o app (MainActivity / splash → onboarding).
2. Em “Descobrir meu kit” → sobe `QuizActivity` (Logcat: `START ... QuizActivity`).
3. Concluir o quiz → `ResultadoActivity`; “Montar minha cesta” → `CatalogoActivity`.
4. No Android Studio / `adb shell dumpsys activity activities`, apontar a Activity no topo da task.

Comando útil:

```powershell
adb shell dumpsys activity activities | Select-String -Pattern "cristalins"
```

## Intent implícita (≥1 — já existia; preservar)

| Caso | Como | Evidência |
| --- | --- | --- |
| Site da marca | `AbridorLinks` + `https://` | Onboarding “Conhecer o site…” |
| Compartilhar resultado | `Compartilhador` / `share_plus` | Resultado do quiz |
| Mapa | `geo:` | Tela endereço |
| WhatsApp | `https://wa.me/…` (se `SUPORTE_WHATSAPP`) | Home / perfil |

Manifest `<queries>`: VIEW https, VIEW geo, SEND text/plain.

### Como demonstrar na oral

No resultado do quiz, tocar **Compartilhar resultado** (chooser do sistema) **ou** no endereço, abrir no mapa (`geo:`).

## O que continua só no Navigator Flutter

Shell, sacola, PDP (`/produto`), aguardando Pix, esqueci senha, ocorrência — sem Activity dedicada nesta entrega.

## Teste rápido

```powershell
cd app
flutter test test/android_activities_manifest_test.dart test/core/intents/navegacao_nativa_test.dart
# Opcional build:
flutter build apk --flavor dev -t lib/main_dev.dart
```
