[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)]
  [ValidateSet("config", "up", "ps", "down")]
  [string]$Command,
  [switch]$UseKeyVault
)

$ErrorActionPreference = "Stop"

$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$ComposeFile = Join-Path $RepoRoot "infra\compose\docker-compose.integration.yml"
$KeyVaultLoader = Join-Path $RepoRoot "scripts\load-key-vault-env.ps1"

Set-Location $RepoRoot

$env:INT_POSTGRES_DB = if ($env:INT_POSTGRES_DB) { $env:INT_POSTGRES_DB } else { "onmu_integration" }
$env:INT_POSTGRES_USER = if ($env:INT_POSTGRES_USER) { $env:INT_POSTGRES_USER } else { "onmu_int" }
$env:INT_POSTGRES_HOST_PORT = if ($env:INT_POSTGRES_HOST_PORT) { $env:INT_POSTGRES_HOST_PORT } else { "16432" }
$env:INT_REDIS_HOST_PORT = if ($env:INT_REDIS_HOST_PORT) { $env:INT_REDIS_HOST_PORT } else { "6380" }
$env:INT_MINIO_API_HOST_PORT = if ($env:INT_MINIO_API_HOST_PORT) { $env:INT_MINIO_API_HOST_PORT } else { "9100" }
$env:INT_MINIO_CONSOLE_HOST_PORT = if ($env:INT_MINIO_CONSOLE_HOST_PORT) { $env:INT_MINIO_CONSOLE_HOST_PORT } else { "9101" }

if ($UseKeyVault) {
  . $KeyVaultLoader `
    -SecretPrefix int `
    -EnvName @(
      "POSTGRES_PASSWORD",
      "MINIO_ROOT_USER",
      "MINIO_ROOT_PASSWORD"
    ) `
    -RequiredEnv @("POSTGRES_PASSWORD") `
    -Quiet

  if ($env:POSTGRES_PASSWORD -and -not $env:INT_POSTGRES_PASSWORD) {
    $env:INT_POSTGRES_PASSWORD = $env:POSTGRES_PASSWORD
  }
  if ($env:MINIO_ROOT_USER -and -not $env:INT_MINIO_ROOT_USER) {
    $env:INT_MINIO_ROOT_USER = $env:MINIO_ROOT_USER
  }
  if ($env:MINIO_ROOT_PASSWORD -and -not $env:INT_MINIO_ROOT_PASSWORD) {
    $env:INT_MINIO_ROOT_PASSWORD = $env:MINIO_ROOT_PASSWORD
  }
}

$composeArgs = @("-f", $ComposeFile)
$services = @("postgres", "redis", "minio")

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
    docker compose @composeArgs down
  }
}
