[CmdletBinding()]
param(
  [int]$ApiPort = 8080,
  [string]$KeyVaultName = $env:AZURE_KEY_VAULT_NAME,
  [switch]$UseKeyVault,
  [switch]$AllowLan,
  [switch]$IncludeEvents,
  [switch]$IncludeSearch
)

$ErrorActionPreference = "Stop"

$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$ComposeFile = Join-Path $RepoRoot "infra\compose\docker-compose.yml"
$env:POSTGRES_HOST_PORT = "15432"

Set-Location $RepoRoot

if ($UseKeyVault) {
  $loader = Join-Path $PSScriptRoot "load-key-vault-env.ps1"
  . $loader -VaultName $KeyVaultName -EnvName @("DATABASE_URL", "POSTGRES_PASSWORD", "MINIO_ROOT_USER", "MINIO_ROOT_PASSWORD") -RequiredEnv @("DATABASE_URL", "POSTGRES_PASSWORD")
}

Write-Host "Starting ONMU local dependencies..."
$composeArgs = @("-f", $ComposeFile)
$services = @("postgres", "redis", "minio")

if ($IncludeEvents) {
  $composeArgs += @("--profile", "events")
  $services += "redpanda"
}

if ($IncludeSearch) {
  $composeArgs += @("--profile", "search")
  $services += "opensearch"
}

docker compose @composeArgs up -d @services

Write-Host ""
Write-Host "Current compose status:"
docker compose @composeArgs ps

if ($AllowLan) {
  $ruleName = "ONMU API $ApiPort"
  $principal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
  $isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

  if (-not $isAdmin) {
    Write-Warning "LAN access needs an inbound firewall rule. Re-run this script from an Administrator PowerShell with -AllowLan."
  } else {
    $existingRule = Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue
    if ($existingRule) {
      Write-Host "Firewall rule already exists: $ruleName"
    } else {
      New-NetFirewallRule -DisplayName $ruleName -Direction Inbound -Protocol TCP -LocalPort $ApiPort -Action Allow | Out-Null
      Write-Host "Created firewall rule: $ruleName"
    }
  }
}

$lanIps = Get-NetIPAddress -AddressFamily IPv4 |
  Where-Object {
    $_.IPAddress -notlike "127.*" -and
    $_.IPAddress -notlike "169.254.*" -and
    $_.InterfaceAlias -notmatch "Loopback"
  } |
  Select-Object InterfaceAlias, IPAddress

Write-Host ""
Write-Host "API runtime target:"
if ($AllowLan) {
  Write-Host "  HOST=0.0.0.0"
  Write-Host "  PORT=$ApiPort"
  if ($UseKeyVault) {
    Write-Host "  Run: powershell -NoProfile -ExecutionPolicy Bypass -File scripts\windows\deploy-dev-backend.ps1 -ApiHost 0.0.0.0 -ApiPort $ApiPort"
  } else {
    Write-Host "  Run: `$env:API_HOST='0.0.0.0'; `$env:HOST='0.0.0.0'; npm run api:dev"
  }
  Write-Host ""
  Write-Host "LAN URLs:"
  foreach ($ip in $lanIps) {
    Write-Host "  http://$($ip.IPAddress):$ApiPort/healthz  ($($ip.InterfaceAlias))"
  }
} else {
  Write-Host "  HOST=127.0.0.1"
  Write-Host "  PORT=$ApiPort"
  if ($UseKeyVault) {
    Write-Host "  Run: powershell -NoProfile -ExecutionPolicy Bypass -File scripts\windows\deploy-dev-backend.ps1 -ApiPort $ApiPort"
  } else {
    Write-Host "  Run: npm run api:dev"
  }
  Write-Host "  Use scripts\start-cloudflare-tunnel.ps1 after the API is running."
}

Write-Host ""
Write-Host "Local dependency endpoints stay bound to 127.0.0.1:"
Write-Host "  PostgreSQL  localhost:15432"
Write-Host "  Redis       localhost:6379"
Write-Host "  MinIO API   http://localhost:9000"
Write-Host "  MinIO UI    http://localhost:9001"
if ($IncludeEvents) {
  Write-Host "  Redpanda    localhost:9092  (Event Hubs/Kafka compatibility tests only)"
}
if ($IncludeSearch) {
  Write-Host "  OpenSearch  http://localhost:9200  (search/RAG experiments only)"
}

Write-Host ""
if ($UseKeyVault) {
  Write-Host "Key Vault env loaded:"
  Write-Host "  AZURE_KEY_VAULT_NAME=<configured>"
  Write-Host "  DATABASE_URL=<loaded from Key Vault>"
  Write-Host "  POSTGRES_PASSWORD=<loaded from Key Vault>"
} else {
  Write-Host "Recommended local-only env:"
  Write-Host "  Use throwaway local values in .env for single-developer tests."
  Write-Host "  Use npm run host:windows:keyvault for the shared Windows dev server."
}
Write-Host "  ONMU_ENV=local"
Write-Host "  REDIS_URL=redis://localhost:6379/0"
Write-Host "  OBJECT_STORAGE_ENDPOINT=http://localhost:9000"
