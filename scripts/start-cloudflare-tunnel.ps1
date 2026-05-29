[CmdletBinding()]
param(
  [int]$ApiPort = 8080,
  [string]$Url,
  [string]$TunnelName = "onmu-dev-api",
  [string]$Hostname = "dev-api.onmu.cloud",
  [string]$ConfigFile,
  [switch]$AccessTcp,
  [switch]$Quick,
  [switch]$SkipHealthCheck
)

$ErrorActionPreference = "Stop"

$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
if (-not $ConfigFile) {
  $configName = if ($AccessTcp) { "cloudflared-access-tcp.yml" } else { "cloudflared-local.yml" }
  $ConfigFile = Join-Path $RepoRoot "infra\cloudflare\$configName"
}

if (-not (Test-Path -LiteralPath $ConfigFile)) {
  throw "Cloudflare config file not found: $ConfigFile"
}

if ($AccessTcp -and $env:CLOUDFLARE_ACCESS_TCP_POLICY_ACTIVE -ne "true") {
  throw "Cloudflare Access TCP mode requires an active Access application and team policy. After verifying the policy, set CLOUDFLARE_ACCESS_TCP_POLICY_ACTIVE=true for this PowerShell session."
}

$cloudflared = Get-Command cloudflared -ErrorAction SilentlyContinue
if (-not $cloudflared) {
  throw "cloudflared is not installed. Install it with: winget install Cloudflare.cloudflared"
}

if (-not $SkipHealthCheck) {
  $healthUrl = "http://localhost:$ApiPort/healthz"
  try {
    Invoke-WebRequest -Uri $healthUrl -UseBasicParsing -TimeoutSec 5 | Out-Null
    Write-Host "Health check passed: $healthUrl"
  } catch {
    Write-Warning "Health check did not pass at $healthUrl. Starting the tunnel anyway; stop it with Ctrl+C if the API is not ready."
  }

  if ($AccessTcp) {
    $dbReady = Test-NetConnection -ComputerName "localhost" -Port 15432 -InformationLevel Quiet
    if ($dbReady) {
      Write-Host "PostgreSQL TCP check passed: localhost:15432"
    } else {
      Write-Warning "PostgreSQL TCP check did not pass at localhost:15432. Start the Windows backend dependencies before sharing DB access."
    }
  }
}

if ($Quick) {
  if (-not $Url) {
    $Url = "http://localhost:$ApiPort"
  }
  Write-Host "Starting Cloudflare quick tunnel to $Url"
  Write-Host "Keep this PowerShell window open while the tunnel is needed."
  cloudflared --config $ConfigFile tunnel --url $Url
  exit
}

if ($Url) {
  Write-Host "Starting Cloudflare named tunnel '$TunnelName' to $Url"
} else {
  Write-Host "Starting Cloudflare named tunnel '$TunnelName' with ingress config: $ConfigFile"
}
Write-Host "Public hostname: https://$Hostname"
if ($AccessTcp) {
  Write-Host "Access TCP hostname: db-dev.onmu.cloud -> tcp://localhost:15432"
  Write-Host "Do not run this mode until the Cloudflare Access application and team policy are active."
}
Write-Host "Keep this PowerShell window open while the tunnel is needed."

if ($Url) {
  cloudflared --config $ConfigFile tunnel run --url $Url $TunnelName
} else {
  cloudflared --config $ConfigFile tunnel run $TunnelName
}
