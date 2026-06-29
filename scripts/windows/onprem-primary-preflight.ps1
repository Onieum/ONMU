param(
  [string]$BaseUrl = "http://127.0.0.1:8080",
  [string]$EnvFile = "",
  [string]$RunDir = "",
  [switch]$SkipHttp,
  [switch]$RequireFullEnv
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "lib\utf8.ps1")
Set-OnmuUtf8Console

if ([string]::IsNullOrWhiteSpace($RunDir)) {
  $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
  $RunDir = Join-Path $env:USERPROFILE ".onmu\onprem-full-migration\preflight-$stamp"
} else {
  $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
}

New-Item -ItemType Directory -Force -Path $RunDir | Out-Null
$eventsPath = Join-Path $RunDir "onprem-primary-preflight.events.tsv"
$reportPath = Join-Path $RunDir "onprem-primary-preflight.md"
Write-Utf8NoBom -Path $eventsPath -Content ""

function Write-Event {
  param(
    [string]$Category,
    [string]$Name,
    [string]$Status,
    [string]$Detail = ""
  )
  Add-Content -Encoding UTF8 -Path $eventsPath -Value "$Category`t$Name`t$Status`t$Detail"
}

if (-not [string]::IsNullOrWhiteSpace($EnvFile)) {
  if (Test-Path -LiteralPath $EnvFile) {
    . $EnvFile
    Write-Event -Category "env-file" -Name $EnvFile -Status "present" -Detail "sourced_without_printing_values"
  } else {
    Write-Event -Category "env-file" -Name $EnvFile -Status "missing" -Detail "file_not_found"
  }
}

$toolStatus = "ok"
foreach ($tool in @("git", "java", "docker", "curl")) {
  $cmd = Get-Command $tool -ErrorAction SilentlyContinue
  if ($null -eq $cmd) {
    $toolStatus = "missing"
    Write-Event -Category "tool" -Name $tool -Status "missing" -Detail "not_in_path"
  } else {
    Write-Event -Category "tool" -Name $tool -Status "present" -Detail $cmd.Source
  }
}

foreach ($tool in @("pg_dump", "pg_restore", "psql", "openssl")) {
  $cmd = Get-Command $tool -ErrorAction SilentlyContinue
  if ($null -eq $cmd) {
    Write-Event -Category "optional-tool" -Name $tool -Status "missing" -Detail "install_before_db_or_tls_rehearsal"
  } else {
    Write-Event -Category "optional-tool" -Name $tool -Status "present" -Detail $cmd.Source
  }
}

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$branch = (& git -C $repoRoot branch --show-current) 2>$null
$head = (& git -C $repoRoot rev-parse --short HEAD) 2>$null
$dirty = ((& git -C $repoRoot status --short) 2>$null | Measure-Object).Count
Write-Event -Category "git" -Name "branch" -Status $branch -Detail "head=$head"
Write-Event -Category "git" -Name "dirty-count" -Status ([string]$dirty) -Detail "uncommitted_files"

$runtimeEnv = @(
  "SPRING_DATASOURCE_URL",
  "SPRING_DATASOURCE_PASSWORD",
  "SPRING_DATA_REDIS_URL",
  "ONMU_ACCESS_TOKEN_SECRET",
  "OBJECT_STORAGE_ENDPOINT",
  "OBJECT_STORAGE_BUCKET"
)

$providerEnv = @(
  "KAKAO_REST_API_KEY",
  "KAKAO_CLIENT_SECRET",
  "KAKAO_OAUTH_REDIRECT_URI",
  "KAKAO_OAUTH_MOBILE_CALLBACK_URI",
  "NAVER_OAUTH_CLIENT_ID",
  "NAVER_OAUTH_CLIENT_SECRET",
  "NAVER_OAUTH_REDIRECT_URI",
  "NAVER_OAUTH_MOBILE_CALLBACK_URI",
  "GOOGLE_OAUTH_CLIENT_ID",
  "GOOGLE_SERVER_CLIENT_ID",
  "NAVER_SEARCH_CLIENT_ID",
  "NAVER_SEARCH_CLIENT_SECRET",
  "OPENROUTESERVICE_API_KEY"
)

$notificationEnv = @(
  "ONMU_FCM_SERVICE_ACCOUNT_JSON",
  "ONMU_APNS_PRIVATE_KEY",
  "ONMU_APNS_KEY_ID",
  "ONMU_APNS_TEAM_ID",
  "ONMU_APNS_BUNDLE_ID",
  "ONMU_PUSH_PROVIDER_MODE"
)

$missingRuntime = 0
foreach ($name in $runtimeEnv) {
  if ([string]::IsNullOrWhiteSpace([Environment]::GetEnvironmentVariable($name))) {
    $missingRuntime += 1
    Write-Event -Category "runtime-env" -Name $name -Status "missing" -Detail "value_not_loaded"
  } else {
    Write-Event -Category "runtime-env" -Name $name -Status "present" -Detail "value_redacted"
  }
}

$missingProvider = 0
foreach ($name in $providerEnv) {
  if ([string]::IsNullOrWhiteSpace([Environment]::GetEnvironmentVariable($name))) {
    $missingProvider += 1
    Write-Event -Category "provider-env" -Name $name -Status "missing" -Detail "value_not_loaded"
  } else {
    Write-Event -Category "provider-env" -Name $name -Status "present" -Detail "value_redacted"
  }
}

$missingNotification = 0
foreach ($name in $notificationEnv) {
  if ([string]::IsNullOrWhiteSpace([Environment]::GetEnvironmentVariable($name))) {
    $missingNotification += 1
    Write-Event -Category "notification-env" -Name $name -Status "missing" -Detail "value_not_loaded"
  } else {
    Write-Event -Category "notification-env" -Name $name -Status "present" -Detail "value_redacted"
  }
}

$httpStatus = "skipped"
if (-not $SkipHttp) {
  $root = $BaseUrl.TrimEnd("/")
  foreach ($path in @("/healthz", "/readyz", "/api/v1/users/me")) {
    $expected = if ($path -eq "/api/v1/users/me") { 401 } else { 200 }
    try {
      $response = Invoke-WebRequest -Method GET -Uri "$root$path" -SkipHttpErrorCheck
      $code = [int]$response.StatusCode
    } catch {
      $code = 0
    }
    if ($code -eq $expected) {
      Write-Event -Category "http" -Name $path -Status "ok" -Detail "status=$code"
    } else {
      $httpStatus = "failed"
      Write-Event -Category "http" -Name $path -Status "unexpected" -Detail "status=$code expected=$expected"
    }
  }
  if ($httpStatus -ne "failed") {
    $httpStatus = "ok"
  }
}

$envStatus = "ok"
if ($missingRuntime -gt 0) {
  $envStatus = "runtime-missing"
}
if ($RequireFullEnv -and $missingProvider -gt 0) {
  $envStatus = "provider-missing"
}
if ($RequireFullEnv -and $missingNotification -gt 0) {
  $envStatus = "notification-missing"
}

$decision = "GO"
if ($toolStatus -ne "ok" -or $envStatus -ne "ok" -or $httpStatus -eq "failed") {
  $decision = "NO-GO"
}

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("# ONMU on-prem primary preflight")
$lines.Add("")
$lines.Add("- run id: ``$stamp``")
$lines.Add("- repo: ``$repoRoot``")
$lines.Add("- branch: ``$branch``")
$lines.Add("- head: ``$head``")
$lines.Add("- dirty count: ``$dirty``")
$lines.Add("- base url: ``$BaseUrl``")
$lines.Add("- decision: ``$decision``")
$lines.Add("")
$lines.Add("## Summary")
$lines.Add("")
$lines.Add("- tool status: ``$toolStatus``")
$lines.Add("- runtime env missing count: ``$missingRuntime``")
$lines.Add("- provider env missing count: ``$missingProvider``")
$lines.Add("- notification env missing count: ``$missingNotification``")
$lines.Add("- http status: ``$httpStatus``")
$lines.Add("")
$lines.Add("## Events")
$lines.Add("")
$lines.Add("| category | name | status | detail |")
$lines.Add("| --- | --- | --- | --- |")
foreach ($eventLine in Get-Content -LiteralPath $eventsPath -Encoding UTF8) {
  if ([string]::IsNullOrWhiteSpace($eventLine)) {
    continue
  }
  $parts = $eventLine.Split("`t")
  $lines.Add("| ``$($parts[0])`` | ``$($parts[1])`` | ``$($parts[2])`` | ``$($parts[3])`` |")
}
$lines.Add("")
$lines.Add("## Secret Safety")
$lines.Add("")
$lines.Add("No secret values, OAuth code/state/idToken, bearer token, DB password, or user raw data are printed by this report.")

Write-Utf8NoBom -Path $reportPath -Content ($lines -join "`n")

"report=$reportPath"
"events=$eventsPath"
"decision=$decision"

if ($decision -ne "GO") {
  exit 1
}
