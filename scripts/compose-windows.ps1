[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)]
  [ValidateSet("config", "up", "ps", "down")]
  [string]$Command,
  [ValidateSet("dev", "integration")]
  [string]$Environment = "dev",
  [switch]$IncludeEvents,
  [switch]$IncludeSearch,
  [switch]$RemoveVolumes
)

$ErrorActionPreference = "Stop"

$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$ComposeFile = if ($Environment -eq "integration") {
  Join-Path $RepoRoot "infra\compose\docker-compose.integration.yml"
} else {
  Join-Path $RepoRoot "infra\compose\docker-compose.yml"
}

Set-Location $RepoRoot

if ($Environment -eq "integration") {
  if ($IncludeEvents -or $IncludeSearch) {
    throw "integration-staging compose supports PostgreSQL, Redis, and MinIO only."
  }

  $env:INT_POSTGRES_DB = "onmu_integration"
  $env:INT_POSTGRES_USER = "onmu_int"
  $env:INT_POSTGRES_HOST_PORT = "16432"
  $env:INT_REDIS_HOST_PORT = "6380"
  $env:INT_MINIO_API_HOST_PORT = "9100"
  $env:INT_MINIO_CONSOLE_HOST_PORT = "9101"
} else {
  $env:POSTGRES_HOST_PORT = "15432"
}

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

switch ($Command) {
  "config" {
    docker compose @composeArgs config
  }
  "up" {
    docker compose @composeArgs up -d @services
  }
  "ps" {
    docker compose @composeArgs ps
  }
  "down" {
    $downArgs = @("compose") + $composeArgs + @("down")
    if ($RemoveVolumes) {
      $downArgs += "-v"
    }
    docker @downArgs
  }
}
