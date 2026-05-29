[CmdletBinding()]
param(
  [string]$VaultName = $env:AZURE_KEY_VAULT_NAME,
  [string[]]$SecretName,
  [switch]$FromEnv,
  [int]$ExpiresInDays = 180
)

$ErrorActionPreference = "Stop"

if (-not $VaultName) {
  throw "VaultName is required. Pass -VaultName or set AZURE_KEY_VAULT_NAME."
}

$secretMap = [ordered]@{
  "onmu-dev-database-url" = "DATABASE_URL"
  "onmu-dev-postgres-password" = "POSTGRES_PASSWORD"
  "onmu-dev-redis-url" = "REDIS_URL"
  "onmu-dev-object-storage-endpoint" = "OBJECT_STORAGE_ENDPOINT"
  "onmu-dev-object-storage-bucket" = "OBJECT_STORAGE_BUCKET"
  "onmu-dev-minio-root-user" = "MINIO_ROOT_USER"
  "onmu-dev-minio-root-password" = "MINIO_ROOT_PASSWORD"
  "onmu-dev-cloudflare-api-token" = "CLOUDFLARE_API_TOKEN"
  "onmu-dev-kakao-rest-api-key" = "KAKAO_REST_API_KEY"
  "onmu-dev-naver-client-id" = "NAVER_CLIENT_ID"
  "onmu-dev-naver-client-secret" = "NAVER_CLIENT_SECRET"
  "onmu-dev-google-maps-api-key" = "GOOGLE_MAPS_API_KEY"
  "onmu-dev-fcm-project-id" = "FCM_PROJECT_ID"
  "onmu-dev-apns-team-id" = "APNS_TEAM_ID"
  "onmu-dev-jira-email" = "JIRA_EMAIL"
  "onmu-dev-jira-api-token" = "JIRA_API_TOKEN"
  "onmu-dev-notion-token" = "NOTION_TOKEN"
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
  vault = $VaultName
  stored = @($stored)
  skipped = @($skipped)
  expiresUtc = $expires
} | ConvertTo-Json -Depth 4
