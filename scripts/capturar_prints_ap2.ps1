# Captura interativa dos 8 PNG da AP2 via adb screencap.
# Pré: emulador/aparelho conectado, ANDROID_HOME ok, API acessível.
# Uso (raiz do monorepo): .\scripts\capturar_prints_ap2.ps1

$ErrorActionPreference = "Stop"
$raiz = Split-Path -Parent $PSScriptRoot
$prints = Join-Path $raiz "docs\prints"
$app = Join-Path $raiz "app"

if (-not (Get-Command adb -ErrorAction SilentlyContinue)) {
    Write-Error "adb não encontrado no PATH. Instale o platform-tools e tente de novo."
}

$devices = adb devices | Select-String -Pattern "`tdevice$"
if (-not $devices) {
    Write-Error "Nenhum device 'device' no adb. Ligue o emulador ou conecte o aparelho."
}

$telas = @(
    @{ Arquivo = "01-boas-vindas.png"; Dica = "Onboarding / boas-vindas" },
    @{ Arquivo = "02-cadastro-login.png"; Dica = "Cadastro ou login" },
    @{ Arquivo = "03-quiz.png"; Dica = "Quiz (uma pergunta visível)" },
    @{ Arquivo = "04-resultado.png"; Dica = "Resultado do quiz" },
    @{ Arquivo = "05-catalogo-cesta.png"; Dica = "Catálogo ou sacola com itens" },
    @{ Arquivo = "06-endereco.png"; Dica = "Endereço" },
    @{ Arquivo = "07-plano-pagamento.png"; Dica = "Plano / pagamento Pix" },
    @{ Arquivo = "08-minha-assinatura.png"; Dica = "Minha assinatura" }
)

Write-Host "1) Em outro terminal, rode o app, por exemplo:"
Write-Host "   cd `"$app`""
Write-Host "   flutter run --flavor dev -t lib/main_dev.dart --dart-define=API_URL=http://10.0.2.2:3000"
Write-Host ""
Write-Host "2) Para cada tela: deixe a UI pronta no emulador e pressione Enter aqui."
Write-Host ""

New-Item -ItemType Directory -Force -Path $prints | Out-Null

foreach ($t in $telas) {
    $destino = Join-Path $prints $t.Arquivo
    Read-Host "Pronto para capturar [$($t.Dica)] -> $($t.Arquivo)? Enter"
    adb exec-out screencap -p > $destino
    $len = (Get-Item $destino).Length
    if ($len -lt 1000) {
        Write-Warning "Arquivo muito pequeno ($len bytes) — confira se o PNG não veio corrompido (PowerShell redirect)."
    } else {
        Write-Host "OK: $($t.Arquivo) ($len bytes)"
    }
}

Write-Host ""
Write-Host "Concluído. Remova os placeholders .md em docs/prints/ e retome ap2-3-prints-readme."
Get-ChildItem (Join-Path $prints "*.png") | Select-Object Name, Length
