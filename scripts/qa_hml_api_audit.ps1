# Audita rotas da API HML Cristalins (sem pagar Pix real).
# Uso: powershell -File scripts/qa_hml_api_audit.ps1

$ErrorActionPreference = 'Stop'
$Base = 'https://apicristalins.peladeiro.cloud/api/v1'
$ts = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()

function New-Cpf {
  $n = 1..9 | ForEach-Object { Get-Random -Maximum 9 }
  $s = 0; for ($i = 0; $i -lt 9; $i++) { $s += $n[$i] * (10 - $i) }
  $d1 = 11 - ($s % 11); if ($d1 -ge 10) { $d1 = 0 }; $n += $d1
  $s = 0; for ($i = 0; $i -lt 10; $i++) { $s += $n[$i] * (11 - $i) }
  $d2 = 11 - ($s % 11); if ($d2 -ge 10) { $d2 = 0 }; $n += $d2
  return ($n -join '')
}

function Invoke-Api {
  param(
    [string]$Method,
    [string]$Path,
    [object]$Body = $null,
    [string]$Token = $null,
    [int[]]$Expect = @(200, 201)
  )
  $headers = @{ Accept = 'application/json' }
  if ($Token) { $headers['Authorization'] = "Bearer $Token" }
  $uri = "$Base$Path"
  try {
    if ($null -ne $Body) {
      $json = $Body | ConvertTo-Json -Depth 8 -Compress
      $r = Invoke-WebRequest -Uri $uri -Method $Method -Headers $headers -ContentType 'application/json' -Body $json -UseBasicParsing
    } else {
      $r = Invoke-WebRequest -Uri $uri -Method $Method -Headers $headers -UseBasicParsing
    }
    $ok = $Expect -contains [int]$r.StatusCode
    $parsed = $null
    try { $parsed = $r.Content | ConvertFrom-Json } catch {}
    [pscustomobject]@{
      Pass   = $ok
      Method = $Method
      Path   = $Path
      Status = [int]$r.StatusCode
      Detail = if ($parsed) { ($parsed | ConvertTo-Json -Compress -Depth 4).Substring(0, [Math]::Min(220, ($parsed | ConvertTo-Json -Compress -Depth 4).Length)) } else { $r.Content.Substring(0, [Math]::Min(120, $r.Content.Length)) }
    }
  } catch {
    $resp = $_.Exception.Response
    $code = if ($resp) { [int]$resp.StatusCode } else { 0 }
    $msg = $_.ErrorDetails.Message
    if (-not $msg) { $msg = $_.Exception.Message }
    $ok = $Expect -contains $code
    [pscustomobject]@{
      Pass   = $ok
      Method = $Method
      Path   = $Path
      Status = $code
      Detail = ($msg + '').Substring(0, [Math]::Min(220, ($msg + '').Length))
    }
  }
}

Write-Host "=== QA API HML Cristalins ===" -ForegroundColor Cyan
Write-Host "Base: $Base"
Write-Host ""

$rows = @()
$rows += Invoke-Api GET '/health' -Expect @(200)

$cpf = New-Cpf
$email = "qa.cristalins.$ts@example.com"
$cadastro = @{
  nome            = 'QA Browser Cristalins'
  cpfCnpj         = $cpf
  email           = $email
  dataNascimento  = '1995-05-10'
  senha           = 'senha-de-teste-123'
  aceiteTermos    = $true
  celular         = '21988887777'
  marketingOk     = $false
}
$reg = Invoke-Api POST '/clientes' -Body $cadastro -Expect @(201)
$rows += $reg

$token = $null
if ($reg.Pass) {
  $login = Invoke-Api POST '/auth/login' -Body @{ email = $email; senha = 'senha-de-teste-123' } -Expect @(200, 201)
  $rows += $login
  try {
    $lr = Invoke-WebRequest -Uri "$Base/auth/login" -Method POST -ContentType 'application/json' -Body (@{ email = $email; senha = 'senha-de-teste-123' } | ConvertTo-Json) -UseBasicParsing
    $lj = $lr.Content | ConvertFrom-Json
    $token = $lj.accessToken
    if (-not $token) { $token = $lj.tokens.accessToken }
  } catch {}
}

$rows += Invoke-Api POST '/auth/login' -Body @{ email = $email; senha = 'senha-errada' } -Expect @(401, 400, 422)
$rows += Invoke-Api POST '/auth/esqueci-senha' -Body @{ email = $email } -Expect @(200)

$recId = $null
if ($token) {
  $rows += Invoke-Api GET '/clientes/me' -Token $token -Expect @(200)
  $rows += Invoke-Api GET '/produtos' -Token $token -Expect @(200)
  $rows += Invoke-Api GET '/kits' -Token $token -Expect @(200)
  $rows += Invoke-Api GET '/cep/22041001' -Expect @(200)
  $rows += Invoke-Api GET '/cep/01310100' -Expect @(422, 400)

  $recBody = @{
    objetivo   = 'TREINO'
    diasSemana = '5-7'
    pessoas    = '1'
    flowFiber  = $false
    comGas     = $false
  }
  try {
    $rr = Invoke-WebRequest -Uri "$Base/recomendacoes" -Method POST -Headers @{ Authorization = "Bearer $token" } -ContentType 'application/json' -Body ($recBody | ConvertTo-Json) -UseBasicParsing
    $rj = $rr.Content | ConvertFrom-Json
    $recId = $rj.id
    $rows += [pscustomobject]@{ Pass = $true; Method = 'POST'; Path = '/recomendacoes'; Status = 201; Detail = "kit=$($rj.kit) valor=$($rj.valorEstimado) id=$recId" }
  } catch {
    $rows += Invoke-Api POST '/recomendacoes' -Body $recBody -Token $token -Expect @(201)
  }

  $sim = @{
    itens      = @(@{ produto = 'WP500'; quantidade = 12 })
    frequencia = 'QUINZENAL'
    plano      = 'FLEX'
  }
  $rows += Invoke-Api POST '/precos/simular' -Body $sim -Token $token -Expect @(200, 201)

  $endId = $null
  try {
    $er = Invoke-WebRequest -Uri "$Base/enderecos" -Method POST -Headers @{ Authorization = "Bearer $token" } -ContentType 'application/json' -Body (@{
        cep       = '22041-001'
        numero    = '100'
        complemento = ''
        apelido   = 'Casa'
      } | ConvertTo-Json) -UseBasicParsing
    $ej = $er.Content | ConvertFrom-Json
    $endId = $ej.id
    $rows += [pscustomobject]@{ Pass = $true; Method = 'POST'; Path = '/enderecos'; Status = 201; Detail = "id=$endId zona=$($ej.zona.nome)" }
  } catch {
    $rows += Invoke-Api POST '/enderecos' -Body @{ cep = '22041-001'; numero = '100'; apelido = 'Casa' } -Token $token -Expect @(201)
  }

  if ($endId) {
    try {
      $ar = Invoke-WebRequest -Uri "$Base/assinaturas" -Method POST -Headers @{ Authorization = "Bearer $token" } -ContentType 'application/json' -Body (@{
          recomendacaoId = $recId
          itens          = @(@{ produto = 'WP500'; quantidade = 12 })
          frequencia     = 'QUINZENAL'
          plano          = 'FLEX'
          enderecoId     = $endId
          janela         = 'MANHA'
          formaPagamento = 'PIX'
        } | ConvertTo-Json -Depth 5) -UseBasicParsing
      $aj = $ar.Content | ConvertFrom-Json
      $rows += [pscustomobject]@{
        Pass   = $true
        Method = 'POST'
        Path   = '/assinaturas'
        Status = 201
        Detail = "id=$($aj.id) status=$($aj.status) pix=$([bool]$aj.pixCodigo -or [bool]$aj.cobranca)"
      }
      if ($aj.id) {
        $rows += Invoke-Api GET "/assinaturas/$($aj.id)" -Token $token -Expect @(200)
      }
    } catch {
      $rows += [pscustomobject]@{
        Pass   = $false
        Method = 'POST'
        Path   = '/assinaturas'
        Status = 0
        Detail = $_.Exception.Message
      }
    }
  }

  $rows += Invoke-Api GET '/assinaturas' -Token $token -Expect @(200)
}

Write-Host ""
$rows | Format-Table -AutoSize Pass, Status, Method, Path, Detail
$failed = @($rows | Where-Object { -not $_.Pass })
Write-Host ""
Write-Host "Conta: $email / senha-de-teste-123 / CPF $cpf"
Write-Host ("Resultado: {0} pass / {1} fail de {2}" -f ($rows.Count - $failed.Count), $failed.Count, $rows.Count)
if ($failed.Count -gt 0) { exit 1 } else { exit 0 }
