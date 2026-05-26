[CmdletBinding()]
param(
  [int]$ApiPort = 8080,
  [string]$Url,
  [string]$TunnelName = "onmu-dev-api",
  [string]$Hostname = "dev-api.onmu.cloud",
  [switch]$Quick,
  [switch]$SkipHealthCheck
)

$ErrorActionPreference = "Stop"

if (-not $Url) {
  $Url = "http://localhost:$ApiPort"
}

$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$ConfigFile = Join-Path $RepoRoot "infra\cloudflare\cloudflared-local.yml"

$cloudflared = Get-Command cloudflared -ErrorAction SilentlyContinue
if (-not $cloudflared) {
  throw "cloudflared is not installed. Install it with: winget install Cloudflare.cloudflared"
}

if (-not $SkipHealthCheck) {
  $healthUrl = "$($Url.TrimEnd('/'))/healthz"
  try {
    Invoke-WebRequest -Uri $healthUrl -UseBasicParsing -TimeoutSec 5 | Out-Null
    Write-Host "Health check passed: $healthUrl"
  } catch {
    Write-Warning "Health check did not pass at $healthUrl. Starting the tunnel anyway; stop it with Ctrl+C if the API is not ready."
  }
}

if ($Quick) {
  Write-Host "Starting Cloudflare quick tunnel to $Url"
  Write-Host "Keep this PowerShell window open while the tunnel is needed."
  cloudflared --config $ConfigFile tunnel --url $Url
  exit
}

Write-Host "Starting Cloudflare named tunnel '$TunnelName' to $Url"
Write-Host "Public hostname: https://$Hostname"
Write-Host "Keep this PowerShell window open while the tunnel is needed."
cloudflared --config $ConfigFile tunnel run --url $Url $TunnelName
