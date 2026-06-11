[CmdletBinding()]
param(
  [string]$VaultName = $env:AZURE_KEY_VAULT_NAME,
  [ValidateSet("dev", "int")]
  [string]$SecretPrefix = "dev",
  [string[]]$SecretName,
  [switch]$FromEnv,
  [int]$ExpiresInDays = 180
)

$ErrorActionPreference = "Stop"

if (-not $VaultName) {
  throw "VaultName is required. Pass -VaultName or set AZURE_KEY_VAULT_NAME."
}

$secretMap = [ordered]@{
  # 기존 정적 token 이름이다. Spring JWT 인증은 ONMU_ACCESS_TOKEN_SECRET을 사용한다.
  "$SecretPrefix-api-access-token" = "ONMU_API_ACCESS_TOKEN"
  "$SecretPrefix-api-refresh-token" = "ONMU_API_REFRESH_TOKEN"
  "$SecretPrefix-cors-origins" = "ONMU_CORS_ORIGINS"
  "$SecretPrefix-database-url" = "DATABASE_URL"
  "$SecretPrefix-postgres-password" = "POSTGRES_PASSWORD"
  "$SecretPrefix-redis-url" = "REDIS_URL"
  "$SecretPrefix-object-storage-endpoint" = "OBJECT_STORAGE_ENDPOINT"
  "$SecretPrefix-object-storage-bucket" = "OBJECT_STORAGE_BUCKET"
  "$SecretPrefix-minio-root-user" = "MINIO_ROOT_USER"
  "$SecretPrefix-minio-root-password" = "MINIO_ROOT_PASSWORD"
  "$SecretPrefix-access-token-secret" = "ONMU_ACCESS_TOKEN_SECRET"
  "$SecretPrefix-naver-oauth-client-id" = "NAVER_OAUTH_CLIENT_ID"
  "$SecretPrefix-naver-oauth-client-secret" = "NAVER_OAUTH_CLIENT_SECRET"
  "$SecretPrefix-kakao-client-secret" = "KAKAO_CLIENT_SECRET"
}

if ($SecretPrefix -eq "dev") {
  $secretMap["dev-cloudflare-api-token"] = "CLOUDFLARE_API_TOKEN"
  $secretMap["dev-kakao-rest-api-key"] = "KAKAO_REST_API_KEY"
  # 기존 Naver 검색/지도/NCP 계열 이름과 OAuth 전용 이름을 혼용하지 않는다.
  $secretMap["dev-naver-client-id"] = "NAVER_CLIENT_ID"
  $secretMap["dev-naver-client-secret"] = "NAVER_CLIENT_SECRET"
  $secretMap["dev-google-maps-api-key"] = "GOOGLE_MAPS_API_KEY"
  $secretMap["dev-fcm-project-id"] = "FCM_PROJECT_ID"
  $secretMap["dev-apns-team-id"] = "APNS_TEAM_ID"
  $secretMap["dev-jira-email"] = "JIRA_EMAIL"
  $secretMap["dev-jira-api-token"] = "JIRA_API_TOKEN"
  $secretMap["dev-notion-token"] = "NOTION_TOKEN"
}

if (-not $SecretName -or $SecretName.Count -eq 0) {
  $SecretName = @($secretMap.Keys)
} else {
  $SecretName = @(
    foreach ($name in $SecretName) {
      foreach ($part in ($name -split ",")) {
        $trimmed = $part.Trim()
        if ($trimmed) {
          $trimmed
        }
      }
    }
  )
}

$expires = (Get-Date).ToUniversalTime().AddDays($ExpiresInDays).ToString("yyyy-MM-ddTHH:mm:ssZ")

function Set-SecretFromPlainText {
  param(
    [Parameter(Mandatory = $true)][string]$Name,
    [Parameter(Mandatory = $true)][string]$Value
  )

  $tempFile = Join-Path $env:TEMP "onmu-secret-$Name-$PID.txt"
  try {
    $utf8NoBom = [System.Text.UTF8Encoding]::new($false)
    [System.IO.File]::WriteAllText($tempFile, $Value, $utf8NoBom)
    az keyvault secret set `
      --vault-name $VaultName `
      --name $Name `
      --file $tempFile `
      --encoding utf-8 `
      --expires $expires `
      --output none
  } finally {
    if (Test-Path -LiteralPath $tempFile) {
      Remove-Item -LiteralPath $tempFile -Force
    }
  }
}

function ConvertTo-PlainText {
  param([Parameter(Mandatory = $true)][securestring]$SecureString)

  $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureString)
  try {
    [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
  } finally {
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
  }
}

$stored = New-Object System.Collections.Generic.List[string]
$skipped = New-Object System.Collections.Generic.List[string]

foreach ($name in $SecretName) {
  if (-not $secretMap.Contains($name)) {
    throw "Unknown secret '$name'. Allowed names: $($secretMap.Keys -join ', ')"
  }

  $envName = $secretMap[$name]
  $value = $null

  if ($FromEnv) {
    $value = [Environment]::GetEnvironmentVariable($envName)
    if (-not $value) {
      $skipped.Add("$name ($envName not set)")
      continue
    }
  } else {
    $secureValue = Read-Host "Enter value for $name from $envName, or press Enter to skip" -AsSecureString
    if ($secureValue.Length -eq 0) {
      $skipped.Add($name)
      continue
    }
    $value = ConvertTo-PlainText $secureValue
  }

  Set-SecretFromPlainText -Name $name -Value $value
  $stored.Add($name)
}

[pscustomobject]@{
  vault = "<configured>"
  stored = @($stored)
  skipped = @($skipped)
  expiresUtc = $expires
} | ConvertTo-Json -Depth 4
