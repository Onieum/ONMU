[CmdletBinding()]
param(
  [string]$VaultName = $env:AZURE_KEY_VAULT_NAME,
  [ValidateSet("dev", "int")]
  [string]$SecretPrefix = "dev",
  [string[]]$EnvName = @(),
  [string[]]$RequiredEnv = @(),
  [switch]$Quiet
)

$ErrorActionPreference = "Stop"

if (-not $VaultName) {
  throw "VaultName is required. Pass -VaultName or set AZURE_KEY_VAULT_NAME."
}

$secretMap = [ordered]@{
  # 기존 정적 token 이름이다. Spring JWT 인증은 ONMU_ACCESS_TOKEN_SECRET을 사용한다.
  ONMU_API_ACCESS_TOKEN = "$SecretPrefix-api-access-token"
  ONMU_API_REFRESH_TOKEN = "$SecretPrefix-api-refresh-token"
  ONMU_CORS_ORIGINS = "$SecretPrefix-cors-origins"
  DATABASE_URL = "$SecretPrefix-database-url"
  POSTGRES_PASSWORD = "$SecretPrefix-postgres-password"
  REDIS_URL = "$SecretPrefix-redis-url"
  OBJECT_STORAGE_ENDPOINT = "$SecretPrefix-object-storage-endpoint"
  OBJECT_STORAGE_BUCKET = "$SecretPrefix-object-storage-bucket"
  MINIO_ROOT_USER = "$SecretPrefix-minio-root-user"
  MINIO_ROOT_PASSWORD = "$SecretPrefix-minio-root-password"
  ONMU_ACCESS_TOKEN_SECRET = "$SecretPrefix-access-token-secret"
  NAVER_OAUTH_CLIENT_ID = "$SecretPrefix-naver-oauth-client-id"
  NAVER_OAUTH_CLIENT_SECRET = "$SecretPrefix-naver-oauth-client-secret"
  KAKAO_CLIENT_SECRET = "$SecretPrefix-kakao-client-secret"
  KAKAO_REST_API_KEY = "$SecretPrefix-kakao-rest-api-key"
  NAVER_SEARCH_CLIENT_ID = "$SecretPrefix-naver-search-client-id"
  NAVER_SEARCH_CLIENT_SECRET = "$SecretPrefix-naver-search-client-secret"
  OPENROUTESERVICE_API_KEY = "$SecretPrefix-openrouteservice-api-key"
}

if ($SecretPrefix -eq "dev") {
  # 기존 정적 token 이름이다. Flutter API mode는 발급한 JWT를 사용한다.
  $secretMap.ONMU_DEV_ACCESS_TOKEN = "dev-api-access-token"
  $secretMap.ONMU_DEV_REFRESH_TOKEN = "dev-api-refresh-token"
  $secretMap.ONMU_DEV_CORS_ORIGINS = "dev-cors-origins"
  $secretMap.CLOUDFLARE_API_TOKEN = "dev-cloudflare-api-token"
  $secretMap.KAKAO_REST_API_KEY = "dev-kakao-rest-api-key"
  # 기존 Naver 검색/지도/NCP 계열 이름과 OAuth 전용 이름을 혼용하지 않는다.
  $secretMap.NAVER_CLIENT_ID = "dev-naver-client-id"
  $secretMap.NAVER_CLIENT_SECRET = "dev-naver-client-secret"
  $secretMap.GOOGLE_MAPS_API_KEY = "dev-google-maps-api-key"
  $secretMap.FCM_PROJECT_ID = "dev-fcm-project-id"
  $secretMap.APNS_TEAM_ID = "dev-apns-team-id"
  $secretMap.JIRA_EMAIL = "dev-jira-email"
  $secretMap.JIRA_API_TOKEN = "dev-jira-api-token"
  $secretMap.NOTION_TOKEN = "dev-notion-token"
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
    Write-Host "Loaded environment variables from the configured Key Vault: $($loaded -join ', ')"
  } else {
    Write-Warning "No mapped secrets were loaded from the configured Key Vault."
  }
}
