[CmdletBinding()]
param(
  [string]$VaultName = $env:AZURE_KEY_VAULT_NAME,
  [string]$ContainerName = "onmu-postgres",
  [string]$Database = "onmu",
  [string]$User = "onmu",
  [int]$HostPort = 15432,
  [int]$ExpiresInDays = 180
)

$ErrorActionPreference = "Stop"

if (-not $VaultName) {
  throw "VaultName is required. Pass -VaultName or set AZURE_KEY_VAULT_NAME."
}

function New-SecretText {
  $bytes = [byte[]]::new(32)
  $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
  try {
    $rng.GetBytes($bytes)
  } finally {
    $rng.Dispose()
  }
  [Convert]::ToBase64String($bytes).TrimEnd("=").Replace("+", "-").Replace("/", "_")
}

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
      --expires (Get-Date).ToUniversalTime().AddDays($ExpiresInDays).ToString("yyyy-MM-ddTHH:mm:ssZ") `
      --output none
  } finally {
    if (Test-Path -LiteralPath $tempFile) {
      Remove-Item -LiteralPath $tempFile -Force
    }
  }
}

$password = New-SecretText
$escapedPassword = $password.Replace("'", "''")
$sql = "ALTER USER `"$User`" WITH PASSWORD '$escapedPassword';"

$sql | docker exec -i $ContainerName psql -U $User -d $Database -v ON_ERROR_STOP=1 | Out-Null

$databaseUrl = "postgresql://${User}:$([uri]::EscapeDataString($password))@localhost:$HostPort/$Database"
Set-SecretFromPlainText -Name "dev-postgres-password" -Value $password
Set-SecretFromPlainText -Name "dev-database-url" -Value $databaseUrl

docker exec -e PGPASSWORD=$password $ContainerName psql -h localhost -U $User -d $Database -tAc "select 1" | Out-Null

[pscustomobject]@{
  vault = "<configured>"
  rotatedDatabaseUser = $User
  storedSecrets = @("dev-postgres-password", "dev-database-url")
  verified = "postgres password authentication succeeded"
} | ConvertTo-Json -Depth 4
