[CmdletBinding()]
param(
  [int]$ApiPort = 8080,
  [switch]$AllowLan
)

$ErrorActionPreference = "Stop"

$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$ComposeFile = Join-Path $RepoRoot "infra\compose\docker-compose.yml"
$env:POSTGRES_HOST_PORT = "15432"

Set-Location $RepoRoot

Write-Host "Starting ONMU local dependencies..."
docker compose -f $ComposeFile up -d postgres redis minio

Write-Host ""
Write-Host "Current compose status:"
docker compose -f $ComposeFile ps

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
  Write-Host "  Run: `$env:API_HOST='0.0.0.0'; `$env:HOST='0.0.0.0'; npm run api:dev"
  Write-Host ""
  Write-Host "LAN URLs:"
  foreach ($ip in $lanIps) {
    Write-Host "  http://$($ip.IPAddress):$ApiPort/healthz  ($($ip.InterfaceAlias))"
  }
} else {
  Write-Host "  HOST=127.0.0.1"
  Write-Host "  PORT=$ApiPort"
  Write-Host "  Run: npm run api:dev"
  Write-Host "  Use scripts\start-cloudflare-tunnel.ps1 after the API is running."
}

Write-Host ""
Write-Host "Local dependency endpoints stay bound to 127.0.0.1:"
Write-Host "  PostgreSQL  localhost:15432"
Write-Host "  Redis       localhost:6379"
Write-Host "  MinIO API   http://localhost:9000"
Write-Host "  MinIO UI    http://localhost:9001"
