# Como capturar os 8 PNG da AP2

**Status (2026-11-17 retomada):** **parcial** — 2/8 obrigatórios ok; ainda **sem** Android SDK/emulador nesta sessão (`flutter devices` = Windows/Chrome/Edge).

Não gerar PNG fake. Extras marketplace (`home-inicio`, `pdp-*`, `sacola-checkout`) **não** substituem os nomes 02–04 e 06–08 da rubrica.

## Progresso

| # | Arquivo | Status |
| ---: | --- | --- |
| 1 | `01-boas-vindas.png` | **ok** (placeholder `.md` já removido) |
| 2 | `02-cadastro-login.png` | **falta** |
| 3 | `03-quiz.png` | **falta** |
| 4 | `04-resultado.png` | **falta** |
| 5 | `05-catalogo-cesta.png` | **ok** (placeholder `.md` já removido) |
| 6 | `06-endereco.png` | **falta** |
| 7 | `07-plano-pagamento.png` | **falta** |
| 8 | `08-minha-assinatura.png` | **falta** |

Extras (não contam para o checklist 01–08): `home-inicio.png`, `pdp-water-protein.png`, `pdp-flow-fiber.png`, `sacola-checkout.png`.

## Pré-requisitos

1. Android Studio / SDK; `ANDROID_HOME` (ex.: `%LOCALAPPDATA%\Android\Sdk`).
2. Emulador AVD **ou** aparelho USB com debug.
3. API no ar (local ou `https://apicristalins.peladeiro.cloud`).

## Opção A — script

```powershell
.\scripts\capturar_prints_ap2.ps1
```

(Pode pular Enter nas telas 01 e 05 se os PNG já existirem — ou sobrescrever.)

## Opção B — adb (só os que faltam)

```powershell
cd C:\Users\João\Desktop\Cristalins\app
flutter run --flavor dev -t lib/main_dev.dart --dart-define=API_URL=http://10.0.2.2:3000
```

Outro terminal (`$out = docs\prints`):

```powershell
adb exec-out screencap -p > "$out\02-cadastro-login.png"
adb exec-out screencap -p > "$out\03-quiz.png"
adb exec-out screencap -p > "$out\04-resultado.png"
adb exec-out screencap -p > "$out\06-endereco.png"
adb exec-out screencap -p > "$out\07-plano-pagamento.png"
adb exec-out screencap -p > "$out\08-minha-assinatura.png"
```

## Depois dos 6 PNG restantes

1. Apagar `02…04` e `06…08` `.md`.
2. Retomar:  
   `python doc/prompts/run_fila_prompts_cursor.py --dir features/ap2_fechamento --from ap2-3-prints-readme --no-login --model auto`  
   → README embute os 8; TRACKER → `feito`.

## Conferência

```powershell
Get-ChildItem docs\prints\0[1-8]*.png | Select-Object Name, Length
# Esperado: 8 arquivos
```
