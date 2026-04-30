param(
  [switch]$SkipClean,
  [switch]$SkipTests,
  [switch]$SkipApiChecks,
  [switch]$BuildApk,
  [string]$BackendUrl = 'https://coolimport.pythonanywhere.com',
  [string]$LocalApiUrl = 'http://192.168.1.34:5001',
  [string]$ReportPath = 'docs/reports/preflight_latest.md'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot '..')
$results = New-Object System.Collections.Generic.List[object]

function Add-Result {
  param(
    [string]$Step,
    [bool]$Ok,
    [string]$Detail,
    [double]$Seconds
  )

  $results.Add(
    [pscustomobject]@{
      Step = $Step
      Ok = $Ok
      Detail = $Detail
      Seconds = [math]::Round($Seconds, 1)
    }
  )
}

function Invoke-CommandCheck {
  param(
    [string]$Step,
    [string[]]$Command
  )

  Write-Host "`n==> $Step" -ForegroundColor Cyan
  $watch = [System.Diagnostics.Stopwatch]::StartNew()

  $exe = $Command[0]
  $args = @()
  if ($Command.Count -gt 1) {
    $args = $Command[1..($Command.Count - 1)]
  }

  $output = @()
  $exitCode = 0
  $invokeError = $null

  $previousPreference = $ErrorActionPreference
  $ErrorActionPreference = 'Continue'
  try {
    try {
      $output = & $exe @args *>&1
      $exitCode = $LASTEXITCODE
      if ($null -eq $exitCode) {
        $exitCode = 0
      }
    }
    catch {
      $invokeError = $_.Exception.Message
      $exitCode = 1
    }
  }
  finally {
    $ErrorActionPreference = $previousPreference
  }

  if ($invokeError) {
    $output = @($invokeError)
  }

  if ($output) {
    $output | ForEach-Object { Write-Host $_ }
  }

  $watch.Stop()
  $allOutput = ($output | ForEach-Object { "$_" }) -join "`n"
  $ok = $exitCode -eq 0
  $detail = if ($ok) { 'OK' } else { "Exit code $exitCode" }

  if (-not $ok -and $allOutput -match 'symlink support') {
    $detail = 'Symlink no habilitado. Activar Developer Mode (start ms-settings:developers).'
  }

  Add-Result -Step $Step -Ok $ok -Detail $detail -Seconds $watch.Elapsed.TotalSeconds
  return $ok
}

function Invoke-HttpCheck {
  param(
    [string]$Step,
    [string]$Uri,
    [string]$Method,
    [string]$Body = '',
    [int[]]$ExpectedStatusCodes = @()
  )

  Write-Host "`n==> $Step" -ForegroundColor Cyan
  $watch = [System.Diagnostics.Stopwatch]::StartNew()

  try {
    if ($Method -eq 'POST') {
      $response = Invoke-WebRequest -Method Post -Uri $Uri -Body $Body -ContentType 'application/json' -TimeoutSec 20 -UseBasicParsing
    }
    else {
      $response = Invoke-WebRequest -Method Get -Uri $Uri -TimeoutSec 12 -UseBasicParsing
    }

    $watch.Stop()
    $code = [int]$response.StatusCode
    $ok = if ($ExpectedStatusCodes.Count -gt 0) {
      $ExpectedStatusCodes -contains $code
    }
    else {
      $code -ge 200 -and $code -lt 500
    }
    Add-Result -Step $Step -Ok $ok -Detail "HTTP $code" -Seconds $watch.Elapsed.TotalSeconds
    return $ok
  }
  catch {
    $watch.Stop()

    $statusCode = $null
    if ($_.Exception.Response -and $_.Exception.Response.StatusCode) {
      $statusCode = [int]$_.Exception.Response.StatusCode.value__
    }

    if ($null -ne $statusCode) {
      $ok = if ($ExpectedStatusCodes.Count -gt 0) {
        $ExpectedStatusCodes -contains $statusCode
      }
      else {
        $statusCode -ge 200 -and $statusCode -lt 500
      }
      $detail = "HTTP $statusCode"
      if (-not $ok -and $statusCode -eq 404) {
        $detail = 'HTTP 404 (endpoint no encontrado para la base URL configurada)'
      }
      Add-Result -Step $Step -Ok $ok -Detail $detail -Seconds $watch.Elapsed.TotalSeconds
      return $ok
    }

    $detail = $_.Exception.Message
    if ($Uri -like 'http://192.168.*') {
      $detail = 'Sin acceso a red de planta o API local fuera de servicio'
    }
    Add-Result -Step $Step -Ok $false -Detail $detail -Seconds $watch.Elapsed.TotalSeconds
    return $false
  }
}

Push-Location $projectRoot
try {
  Write-Host "Proyecto: $projectRoot" -ForegroundColor Yellow

  if (-not $SkipClean) {
    [void](Invoke-CommandCheck -Step 'flutter clean' -Command @('flutter', 'clean'))
  }

  [void](Invoke-CommandCheck -Step 'flutter pub get' -Command @('flutter', 'pub', 'get'))
  [void](Invoke-CommandCheck -Step 'dart analyze' -Command @('dart', 'analyze'))

  if (-not $SkipTests) {
    [void](Invoke-CommandCheck -Step 'flutter test' -Command @('flutter', 'test'))
  }

  if ($BuildApk) {
    [void](Invoke-CommandCheck -Step 'flutter build apk --debug' -Command @('flutter', 'build', 'apk', '--debug'))
  }

  if (-not $SkipApiChecks) {
    [void](Invoke-HttpCheck -Step 'API principal /inicio_sesion (reachability)' -Uri "$BackendUrl/inicio_sesion" -Method 'POST' -Body '{"password":"health_check"}' -ExpectedStatusCodes @(200, 400, 401, 403, 422))
    [void](Invoke-HttpCheck -Step 'API local /health' -Uri "$LocalApiUrl/health" -Method 'GET' -ExpectedStatusCodes @(200))
  }
}
finally {
  Pop-Location
}

$reportFullPath = Join-Path $projectRoot $ReportPath
$reportDir = Split-Path -Parent $reportFullPath
if (-not (Test-Path $reportDir)) {
  New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
}

$now = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
$failed = @($results | Where-Object { -not $_.Ok })
$okTotal = ($results | Where-Object { $_.Ok }).Count
$total = $results.Count
$status = if ($failed.Count -eq 0) { 'GO PILOTO (preflight tecnico)' } else { 'NO-GO (hay checks en fallo)' }

$markdown = @()
$markdown += '# Reporte Preflight Piloto'
$markdown += ''
$markdown += "Generado: $now"
$markdown += "Estado: **$status**"
$markdown += ''
$markdown += '| Check | Estado | Detalle | Tiempo (s) |'
$markdown += '|---|---|---|---:|'

foreach ($item in $results) {
  $estado = if ($item.Ok) { 'OK' } else { 'FAIL' }
  $detail = ($item.Detail -replace '\|', '/')
  $markdown += "| $($item.Step) | $estado | $detail | $($item.Seconds) |"
}

$markdown += ''
$markdown += "Resumen: $okTotal/$total checks en verde."
if ($failed.Count -gt 0) {
  $markdown += ''
  $markdown += '## Bloqueos detectados'
  foreach ($item in $failed) {
    $markdown += "- $($item.Step): $($item.Detail)"
  }
}

$markdown -join "`r`n" | Set-Content -Path $reportFullPath -Encoding UTF8

Write-Host "`nReporte generado en: $reportFullPath" -ForegroundColor Green
Write-Host "Estado global: $status" -ForegroundColor Yellow

if ($failed.Count -gt 0) {
  exit 1
}
