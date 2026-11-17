# Como capturar os 8 PNG da AP2

**Status (2026-11-17):** **parcial — 3/8** canônicos no repo e no README (`01`, `02`, `05`).

Não gerar PNG fake. Extras marketplace (`home-inicio`, `pdp-*`, `sacola-checkout`) **não** substituem `03`, `04`, `06`–`08`.

> Nota rubrica Dontpad: **não exige quiz** (só exemplo de tema). Os 8 nomes abaixo são o checklist interno da entrega Cristalins; o enunciado pede prints no README, sem lista fixa de telas.

## Progresso

| # | Arquivo | Status |
| ---: | --- | --- |
| 1 | `01-boas-vindas.png` | **ok** |
| 2 | `02-cadastro-login.png` | **ok** |
| 3 | `03-quiz.png` | **falta** (opcional p/ Dontpad; útil p/ demo kit) |
| 4 | `04-resultado.png` | **falta** |
| 5 | `05-catalogo-cesta.png` | **ok** (sacola / cesta) |
| 6 | `06-endereco.png` | **falta** |
| 7 | `07-plano-pagamento.png` | **falta** |
| 8 | `08-minha-assinatura.png` | **falta** |

Extras: `home-inicio.png`, `pdp-water-protein.png`, `pdp-flow-fiber.png`, `sacola-checkout.png`.

## Pré-requisitos

1. Android Studio / SDK; `ANDROID_HOME` (ex.: `C:\Android\Sdk`).
2. Emulador AVD **ou** aparelho USB com debug.
3. API no ar (local ou `https://apicristalins.peladeiro.cloud`).

## Opção A — script

```powershell
.\scripts\capturar_prints_ap2.ps1
```

## Opção B — adb (só os que faltam)

```powershell
cd C:\Users\João\Desktop\Cristalins\app
flutter run --flavor hml -t lib/main_hml.dart --dart-define=API_URL=https://apicristalins.peladeiro.cloud
```

Outro terminal (`$out = docs\prints`):

```powershell
adb exec-out screencap -p > "$out\03-quiz.png"
adb exec-out screencap -p > "$out\04-resultado.png"
adb exec-out screencap -p > "$out\06-endereco.png"
adb exec-out screencap -p > "$out\07-plano-pagamento.png"
adb exec-out screencap -p > "$out\08-minha-assinatura.png"
```

## Depois dos PNG restantes

1. Apagar placeholders `.md` homônimos.
2. Embutir no README (seção Prints).
3. Atualizar `docs/AP2_MATRIZ_RUBRICA.md`.

## Conferência

```powershell
Get-ChildItem docs\prints\0[1-8]*.png | Select-Object Name, Length
```
