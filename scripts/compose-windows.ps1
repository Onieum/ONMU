[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)]
  [ValidateSet("config", "up", "ps")]
  [string]$Command
)

$ErrorActionPreference = "Stop"

$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$ComposeFile = Join-Path $RepoRoot "infra\compose\docker-compose.yml"

Set-Location $RepoRoot

$env:POSTGRES_HOST_PORT = "15432"

switch ($Command) {
  "config" {
    docker compose -f $ComposeFile config
  }
  "up" {
    docker compose -f $ComposeFile up -d postgres redis minio
  }
  "ps" {
    docker compose -f $ComposeFile ps
  }
}
