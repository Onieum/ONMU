[CmdletBinding()]
param(
  [int]$ApiPort = 8080,
  [ValidateSet("dev", "integration")]
  [string]$Environment = "dev",
  [string]$Url,
  [string]$TunnelName = "onmu-dev-api",
  [string]$Hostname = "dev-api.onmu.cloud",
  [string]$AccessTcpHostname = "db-dev.onmu.cloud",
  [int]$AccessTcpPort = 15432,
  [string]$ConfigFile,
  [switch]$AccessTcp,
  [switch]$Quick,
  [switch]$SkipHealthCheck
)

$ErrorActionPreference = "Stop"

$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$ApiPortWasProvided = $PSBoundParameters.ContainsKey("ApiPort")
$TunnelNameWasProvided = $PSBoundParameters.ContainsKey("TunnelName")
$HostnameWasProvided = $PSBoundParameters.ContainsKey("Hostname")
$AccessTcpHostnameWasProvided = $PSBoundParameters.ContainsKey("AccessTcpHostname")
$AccessTcpPortWasProvided = $PSBoundParameters.ContainsKey("AccessTcpPort")

if ($Environment -eq "integration") {
  if (-not $ApiPortWasProvided) {
    $ApiPort = 18080
  }
  if (-not $TunnelNameWasProvided) {
    $TunnelName = "onmu-int-api"
  }
  if (-not $HostnameWasProvided) {
    $Hostname = "int-api.onmu.cloud"
  }
  if (-not $AccessTcpHostnameWasProvided) {
    $AccessTcpHostname = "db-int.onmu.cloud"
  }
  if (-not $AccessTcpPortWasProvided) {
    $AccessTcpPort = 16432
  }
}

if (-not $ConfigFile) {
  $configName = if ($Environment -eq "integration") {
    if ($AccessTcp) { "cloudflared-integration-access-tcp.yml" } else { "cloudflared-integration.yml" }
  } else {
    if ($AccessTcp) { "cloudflared-access-tcp.yml" } else { "cloudflared-local.yml" }
  }
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
    $dbReady = Test-NetConnection -ComputerName "localhost" -Port $AccessTcpPort -InformationLevel Quiet
    if ($dbReady) {
      Write-Host "PostgreSQL TCP check passed: localhost:$AccessTcpPort"
    } else {
      Write-Warning "PostgreSQL TCP check did not pass at localhost:$AccessTcpPort. Start the Windows backend dependencies before sharing DB access."
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
  Write-Host "Access TCP hostname: $AccessTcpHostname -> tcp://localhost:$AccessTcpPort"
  Write-Host "Do not run this mode until the Cloudflare Access application and team policy are active."
}
Write-Host "Keep this PowerShell window open while the tunnel is needed."

if ($Url) {
  cloudflared --config $ConfigFile tunnel run --url $Url $TunnelName
} else {
  cloudflared --config $ConfigFile tunnel run $TunnelName
}
