[CmdletBinding()]
param(
  [ValidateSet("spring")]
  [string]$Runtime = "spring",
  [switch]$DryRun,
  [int]$ApiPort = 18080,
  [string]$ApiHost = "127.0.0.1",
  [string]$PublicBaseUrl = $env:ONMU_INT_API_BASE_URL,
  [string]$Client = "github-actions-integration-cd",
  [int]$HealthzWaitTimeoutSeconds = 60,
  [int]$HealthzWaitIntervalSeconds = 2,
  [switch]$SkipDependencyStart,
  [switch]$SkipPublicSmoke,
  [switch]$StopOnly
)

$ErrorActionPreference = "Stop"

if (-not $PublicBaseUrl) {
  $PublicBaseUrl = "https://int-api.onmu.cloud"
}

$deployScript = Join-Path $PSScriptRoot "deploy-dev-backend.ps1"
$deployArgs = @{
  Environment = "integration"
  Runtime = $Runtime
  ApiPort = $ApiPort
  ApiHost = $ApiHost
  PublicBaseUrl = $PublicBaseUrl
  Client = $Client
  HealthzWaitTimeoutSeconds = $HealthzWaitTimeoutSeconds
  HealthzWaitIntervalSeconds = $HealthzWaitIntervalSeconds
}

if ($DryRun) {
  $deployArgs.DryRun = $true
}
if ($SkipDependencyStart) {
  $deployArgs.SkipDependencyStart = $true
}
if ($SkipPublicSmoke) {
  $deployArgs.SkipPublicSmoke = $true
}
if ($StopOnly) {
  $deployArgs.StopOnly = $true
}

& $deployScript @deployArgs
