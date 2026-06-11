[CmdletBinding()]
param(
  [int]$Port = $(if ($env:ONMU_TILE_GATEWAY_PORT) { [int]$env:ONMU_TILE_GATEWAY_PORT } else { 19100 }),
  [string]$MinioEndpoint = $(if ($env:OBJECT_STORAGE_ENDPOINT) { $env:OBJECT_STORAGE_ENDPOINT } elseif ($env:MINIO_ENDPOINT) { $env:MINIO_ENDPOINT } else { "http://localhost:9000" }),
  [string]$Bucket = $(if ($env:ONMU_TILE_BUCKET) { $env:ONMU_TILE_BUCKET } else { "onmu-tiles" }),
  [string]$AllowedOrigins = $(if ($env:ONMU_TILE_ALLOWED_ORIGINS) { $env:ONMU_TILE_ALLOWED_ORIGINS } else { "http://localhost:5173,http://127.0.0.1:5173,https://dev-api.onmu.cloud,https://int-api.onmu.cloud" }),
  [string]$LogPath,
  [switch]$Foreground
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$gatewayScript = Join-Path $repoRoot "scripts\map-tiles-gateway.js"
if (-not (Test-Path -LiteralPath $gatewayScript)) {
  throw "Map tiles gateway script not found: $gatewayScript"
}

$node = Get-Command node -ErrorAction SilentlyContinue
if (-not $node) {
  throw "node is required to run the map tiles gateway."
}

if (-not $LogPath) {
  $LogPath = Join-Path $repoRoot "logs\map-tiles-gateway.log"
}
$logDirectory = Split-Path -Parent $LogPath
if (-not (Test-Path -LiteralPath $logDirectory)) {
  New-Item -ItemType Directory -Path $logDirectory | Out-Null
}

$env:ONMU_TILE_GATEWAY_PORT = "$Port"
$env:OBJECT_STORAGE_ENDPOINT = $MinioEndpoint
$env:ONMU_TILE_BUCKET = $Bucket
$env:ONMU_TILE_ALLOWED_ORIGINS = $AllowedOrigins

if ($Foreground) {
  Write-Host "Starting ONMU map tiles gateway in foreground: http://127.0.0.1:$Port"
  Write-Host "MinIO endpoint: $MinioEndpoint"
  Write-Host "Bucket: $Bucket"
  & $node.Source $gatewayScript
  exit $LASTEXITCODE
}

$stderrPath = [System.IO.Path]::ChangeExtension($LogPath, ".err.log")
$process = Start-Process `
  -FilePath $node.Source `
  -ArgumentList @($gatewayScript) `
  -WindowStyle Hidden `
  -RedirectStandardOutput $LogPath `
  -RedirectStandardError $stderrPath `
  -PassThru

Write-Host "Started ONMU map tiles gateway PID: $($process.Id)"
Write-Host "Local URL: http://127.0.0.1:$Port"
Write-Host "Log: $LogPath"
Write-Host "Error log: $stderrPath"
Write-Host "Secret values are not printed by this script."
