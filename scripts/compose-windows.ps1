[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)]
  [ValidateSet("config", "up", "ps")]
  [string]$Command,
  [switch]$IncludeEvents,
  [switch]$IncludeSearch
)

$ErrorActionPreference = "Stop"

$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$ComposeFile = Join-Path $RepoRoot "infra\compose\docker-compose.yml"

Set-Location $RepoRoot

$env:POSTGRES_HOST_PORT = "15432"

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
}
