[CmdletBinding()]
param(
  [string]$VaultName = $env:AZURE_KEY_VAULT_NAME,
  [int]$ApiPort = 8080,
  [string]$ApiHost = "127.0.0.1"
)

$ErrorActionPreference = "Stop"

$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$loader = Join-Path $PSScriptRoot "load-key-vault-env.ps1"
$apiEnvNames = @(
  "DATABASE_URL",
  "REDIS_URL",
  "OBJECT_STORAGE_ENDPOINT",
  "OBJECT_STORAGE_BUCKET",
  "GOOGLE_CLIENT_ID",
  "KAKAO_NATIVE_APP_KEY",
  "KAKAO_JAVASCRIPT_KEY",
  "KAKAO_REST_API_KEY",
  "NAVER_CLIENT_ID",
  "NAVER_CLIENT_SECRET",
  "GOOGLE_MAPS_API_KEY",
  "FCM_PROJECT_ID",
  "APNS_TEAM_ID"
)

. $loader -VaultName $VaultName -EnvName $apiEnvNames -RequiredEnv @("DATABASE_URL")

$env:ONMU_ENV = if ($env:ONMU_ENV) { $env:ONMU_ENV } else { "local" }
$env:API_PORT = "$ApiPort"
$env:API_HOST = $ApiHost

Set-Location $RepoRoot
npm run api:dev
