[CmdletBinding()]
param(
  [ValidateSet("dev", "integration")]
  [string]$Environment = "dev",
  [string]$VaultName = $env:AZURE_KEY_VAULT_NAME,
  [string]$UserPublicId = "user-me",
  [int]$ExpiresInMinutes = 120,
  [string]$Issuer = $env:ONMU_AUTH_ISSUER,
  [string]$Audience = $env:ONMU_AUTH_AUDIENCE,
  [string]$ApiBaseUrl,
  [string]$OutputPath,
  [switch]$IncludeKakaoOAuth,
  [string]$KakaoOAuthRedirectUri
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$secretPrefix = if ($Environment -eq "integration") { "int" } else { "dev" }
$secretName = "$secretPrefix-access-token-secret"
$vaultNameWasProvided = $PSBoundParameters.ContainsKey("VaultName")

if (-not $Issuer) {
  $Issuer = "onmu-api"
}
if (-not $Audience) {
  $Audience = "onmu-mobile"
}
if (-not $ApiBaseUrl) {
  $ApiBaseUrl = if ($Environment -eq "integration") {
    "https://int-api.onmu.cloud"
  } else {
    "https://dev-api.onmu.cloud"
  }
}
if (-not $OutputPath) {
  $fileName = if ($Environment -eq "integration") {
    "onmu-integration-api.defines.json"
  } else {
    "onmu-dev-api.defines.json"
  }
  $OutputPath = Join-Path $repoRoot "apps\mobile-flutter\.dart_tool\$fileName"
}
if ($IncludeKakaoOAuth -and -not $KakaoOAuthRedirectUri) {
  $KakaoOAuthRedirectUri = "$($ApiBaseUrl.TrimEnd('/'))/api/v1/auth/oauth/kakao/callback"
}

if ($ExpiresInMinutes -lt 5 -or $ExpiresInMinutes -gt 1440) {
  throw "ExpiresInMinutes must be between 5 and 1440."
}
if (-not $UserPublicId -or $UserPublicId.Trim().Length -eq 0) {
  throw "UserPublicId is required."
}

if ($VaultName -and ($vaultNameWasProvided -or -not $env:ONMU_ACCESS_TOKEN_SECRET)) {
  $loadKeyVaultEnv = Join-Path $repoRoot "scripts\load-key-vault-env.ps1"
  & $loadKeyVaultEnv `
    -VaultName $VaultName `
    -SecretPrefix $secretPrefix `
    -EnvName ONMU_ACCESS_TOKEN_SECRET `
    -RequiredEnv ONMU_ACCESS_TOKEN_SECRET `
    -Quiet
} elseif (-not $env:ONMU_ACCESS_TOKEN_SECRET) {
  throw "ONMU_ACCESS_TOKEN_SECRET is not set. Set it for local testing or pass -VaultName to load $secretName from Key Vault."
}

if ($IncludeKakaoOAuth -and -not $env:KAKAO_REST_API_KEY) {
  if (-not $VaultName) {
    throw "KAKAO_REST_API_KEY is not set. Set it for local testing or pass -VaultName to load $secretPrefix-kakao-rest-api-key from Key Vault."
  }
  $loadKeyVaultEnv = Join-Path $repoRoot "scripts\load-key-vault-env.ps1"
  & $loadKeyVaultEnv `
    -VaultName $VaultName `
    -SecretPrefix $secretPrefix `
    -EnvName KAKAO_REST_API_KEY `
    -RequiredEnv KAKAO_REST_API_KEY `
    -Quiet
}

$secret = $env:ONMU_ACCESS_TOKEN_SECRET
if (-not $secret) {
  throw "ONMU_ACCESS_TOKEN_SECRET could not be loaded."
}

function ConvertTo-Base64Url {
  param([byte[]]$Bytes)

  return [Convert]::ToBase64String($Bytes).TrimEnd("=").Replace("+", "-").Replace("/", "_")
}

$now = [DateTimeOffset]::UtcNow
$expiresAt = $now.AddMinutes($ExpiresInMinutes)

$header = [ordered]@{
  alg = "HS256"
  typ = "JWT"
} | ConvertTo-Json -Compress

$payload = [ordered]@{
  iss = $Issuer
  aud = $Audience
  sub = $UserPublicId.Trim()
  typ = "access"
  iat = $now.ToUnixTimeSeconds()
  exp = $expiresAt.ToUnixTimeSeconds()
} | ConvertTo-Json -Compress

$headerPart = ConvertTo-Base64Url -Bytes ([System.Text.Encoding]::UTF8.GetBytes($header))
$payloadPart = ConvertTo-Base64Url -Bytes ([System.Text.Encoding]::UTF8.GetBytes($payload))
$signingInput = "$headerPart.$payloadPart"
$hmac = [System.Security.Cryptography.HMACSHA256]::new([System.Text.Encoding]::UTF8.GetBytes($secret))
try {
  $signaturePart = ConvertTo-Base64Url -Bytes ($hmac.ComputeHash([System.Text.Encoding]::ASCII.GetBytes($signingInput)))
} finally {
  $hmac.Dispose()
}

$accessToken = "$signingInput.$signaturePart"
$defines = [ordered]@{
  ONMU_API_BASE_URL = $ApiBaseUrl
  ONMU_API_ACCESS_JWT = $accessToken
  ONMU_DEV_ACCESS_TOKEN = $accessToken
}
if ($IncludeKakaoOAuth) {
  if (-not $env:KAKAO_REST_API_KEY) {
    throw "KAKAO_REST_API_KEY could not be loaded."
  }
  $defines.KAKAO_REST_API_KEY = $env:KAKAO_REST_API_KEY.Trim()
  $defines.KAKAO_OAUTH_REDIRECT_URI = $KakaoOAuthRedirectUri
}

$outputDirectory = Split-Path -Parent $OutputPath
if (-not (Test-Path -LiteralPath $outputDirectory)) {
  New-Item -ItemType Directory -Path $outputDirectory | Out-Null
}

$utf8NoBom = [System.Text.UTF8Encoding]::new($false)
[System.IO.File]::WriteAllText($OutputPath, ($defines | ConvertTo-Json -Depth 4), $utf8NoBom)

Write-Host "Wrote Flutter dart-define file: $OutputPath"
Write-Host "JWT subject: $($UserPublicId.Trim())"
Write-Host "JWT expires at UTC: $($expiresAt.ToString("yyyy-MM-ddTHH:mm:ssZ"))"
Write-Host "Token value is stored only in the local ignored dart-define file and is not printed."
if ($IncludeKakaoOAuth) {
  Write-Host "Included Kakao OAuth dart-define keys without printing their values."
}
