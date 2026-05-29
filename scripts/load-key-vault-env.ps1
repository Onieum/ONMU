[CmdletBinding()]
param(
  [string]$VaultName = $env:AZURE_KEY_VAULT_NAME,
  [string[]]$EnvName = @(),
  [string[]]$RequiredEnv = @(),
  [switch]$Quiet
)

$ErrorActionPreference = "Stop"

if (-not $VaultName) {
  throw "VaultName is required. Pass -VaultName or set AZURE_KEY_VAULT_NAME."
}

$secretMap = [ordered]@{
  DATABASE_URL = "onmu-dev-database-url"
  POSTGRES_PASSWORD = "onmu-dev-postgres-password"
  REDIS_URL = "onmu-dev-redis-url"
  OBJECT_STORAGE_ENDPOINT = "onmu-dev-object-storage-endpoint"
  OBJECT_STORAGE_BUCKET = "onmu-dev-object-storage-bucket"
  MINIO_ROOT_USER = "onmu-dev-minio-root-user"
  MINIO_ROOT_PASSWORD = "onmu-dev-minio-root-password"
  CLOUDFLARE_API_TOKEN = "onmu-dev-cloudflare-api-token"
  KAKAO_REST_API_KEY = "onmu-dev-kakao-rest-api-key"
  NAVER_CLIENT_ID = "onmu-dev-naver-client-id"
  NAVER_CLIENT_SECRET = "onmu-dev-naver-client-secret"
  GOOGLE_MAPS_API_KEY = "onmu-dev-google-maps-api-key"
  FCM_PROJECT_ID = "onmu-dev-fcm-project-id"
  APNS_TEAM_ID = "onmu-dev-apns-team-id"
  JIRA_EMAIL = "onmu-dev-jira-email"
  JIRA_API_TOKEN = "onmu-dev-jira-api-token"
  NOTION_TOKEN = "onmu-dev-notion-token"
}

$loaded = New-Object System.Collections.Generic.List[string]
$missing = New-Object System.Collections.Generic.List[string]
$targetEnvNames = New-Object System.Collections.Generic.List[string]

if ($EnvName.Count -gt 0) {
  foreach ($name in $EnvName) {
    if (-not $secretMap.Contains($name)) {
      throw "Unknown env name '$name'. Allowed names: $($secretMap.Keys -join ', ')"
    }
    if (-not $targetEnvNames.Contains($name)) {
      $targetEnvNames.Add($name)
    }
  }
} else {
  foreach ($name in $secretMap.Keys) {
    $targetEnvNames.Add($name)
  }
}

foreach ($name in $RequiredEnv) {
  if (-not $secretMap.Contains($name)) {
    throw "Unknown required env name '$name'. Allowed names: $($secretMap.Keys -join ', ')"
  }
  if (-not $targetEnvNames.Contains($name)) {
    $targetEnvNames.Add($name)
  }
}

foreach ($envName in $targetEnvNames) {
  $secretName = $secretMap[$envName]
  $previousErrorActionPreference = $ErrorActionPreference
  $ErrorActionPreference = "Continue"
  $value = az keyvault secret show `
    --vault-name $VaultName `
    --name $secretName `
    --query value `
    -o tsv 2>$null
  $secretExitCode = $LASTEXITCODE
  $ErrorActionPreference = $previousErrorActionPreference

  if ($secretExitCode -eq 0 -and $value) {
    Set-Item -Path "Env:$envName" -Value $value
    $loaded.Add($envName)
    continue
  }

  if ($RequiredEnv -contains $envName) {
    $missing.Add("$envName ($secretName)")
  }
}

if ($missing.Count -gt 0) {
  throw "Required Key Vault secrets are missing: $($missing -join ', ')"
}

if (-not $Quiet) {
  if ($loaded.Count -gt 0) {
    Write-Host "Loaded environment variables from Key Vault '$VaultName': $($loaded -join ', ')"
  } else {
    Write-Warning "No mapped secrets were loaded from Key Vault '$VaultName'."
  }
}
