[CmdletBinding()]
param(
  [ValidateSet("dev", "integration")]
  [string]$Environment = "dev",
  [string]$Hostname = "db-dev.onmu.cloud",
  [int]$LocalPort = 15433
)

$ErrorActionPreference = "Stop"

$cloudflared = Get-Command cloudflared -ErrorAction SilentlyContinue
if (-not $cloudflared) {
  throw "cloudflared is not installed. Install it with: winget install Cloudflare.cloudflared"
}

$HostnameWasProvided = $PSBoundParameters.ContainsKey("Hostname")
$LocalPortWasProvided = $PSBoundParameters.ContainsKey("LocalPort")
$databaseName = "onmu"
if ($Environment -eq "integration") {
  if (-not $HostnameWasProvided) {
    $Hostname = "db-int.onmu.cloud"
  }
  if (-not $LocalPortWasProvided) {
    $LocalPort = 16433
  }
  $databaseName = "onmu_integration"
}

$localUrl = "localhost:$LocalPort"

Write-Host "Starting Cloudflare Access TCP client tunnel."
Write-Host "Access hostname: $Hostname"
Write-Host "Local listener: $localUrl"
Write-Host "Keep this PowerShell window open while the DB client is connected."
Write-Host "Connect your DB client to host 'localhost', port '$LocalPort', database '$databaseName'."

cloudflared access tcp --hostname $Hostname --url $localUrl
