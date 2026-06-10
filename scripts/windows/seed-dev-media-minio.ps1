[CmdletBinding()]
param(
  [string]$ManifestPath = (Join-Path $PSScriptRoot "..\..\data\dev-media\record-media-manifest.json"),
  [string]$Endpoint = $(if ($env:OBJECT_STORAGE_ENDPOINT) { $env:OBJECT_STORAGE_ENDPOINT } else { "http://127.0.0.1:9000" }),
  [string]$Bucket = $(if ($env:OBJECT_STORAGE_BUCKET) { $env:OBJECT_STORAGE_BUCKET } else { "" }),
  [string]$AccessKeyEnvName = "MINIO_ROOT_USER",
  [string]$SecretKeyEnvName = "MINIO_ROOT_PASSWORD",
  [string]$McImage = "minio/mc:RELEASE.2025-04-16T18-13-26Z"
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

function Get-RequiredEnvironmentValue {
  param([string]$Name)

  $value = [Environment]::GetEnvironmentVariable($Name)
  if ([string]::IsNullOrWhiteSpace($value)) {
    throw "Required environment variable '$Name' is not set. Load MinIO credentials into the current process before running this script."
  }
  return $value
}

function Convert-ToContainerEndpoint {
  param([string]$Value)

  $uri = [Uri]$Value
  if (-not $uri.Scheme -or -not $uri.Host) {
    throw "Endpoint must include scheme and host."
  }

  $builder = [UriBuilder]::new($uri)
  if ($builder.Host -in @("localhost", "127.0.0.1", "::1")) {
    $builder.Host = "host.docker.internal"
  }
  return $builder.Uri.AbsoluteUri.TrimEnd("/")
}

function Invoke-DockerMc {
  param(
    [Parameter(Mandatory = $true)][string[]]$McArguments,
    [Parameter(Mandatory = $true)][string]$SeedDirectory
  )

  $mount = "${SeedDirectory}:/seed:ro"
  $dockerArgs = @(
    "run",
    "--rm",
    "-e",
    "MC_HOST_onmu",
    "-v",
    $mount,
    $McImage
  ) + $McArguments

  & docker @dockerArgs
  if ($LASTEXITCODE -ne 0) {
    throw "Docker minio/mc command failed."
  }
}

$resolvedManifestPath = (Resolve-Path -LiteralPath $ManifestPath).Path
$manifest = Get-Content -Raw -Encoding UTF8 -LiteralPath $resolvedManifestPath | ConvertFrom-Json
if ([string]::IsNullOrWhiteSpace($Bucket)) {
  $Bucket = [string]$manifest.bucket
}
if ([string]::IsNullOrWhiteSpace($Bucket)) {
  throw "Bucket is not set. Provide -Bucket, OBJECT_STORAGE_BUCKET, or manifest.bucket."
}

$accessKey = Get-RequiredEnvironmentValue -Name $AccessKeyEnvName
$secretKey = Get-RequiredEnvironmentValue -Name $SecretKeyEnvName
$containerEndpoint = Convert-ToContainerEndpoint -Value $Endpoint
$encodedAccessKey = [Uri]::EscapeDataString($accessKey)
$encodedSecretKey = [Uri]::EscapeDataString($secretKey)
$endpointUri = [Uri]$containerEndpoint
$mcHost = "$($endpointUri.Scheme)://$encodedAccessKey`:$encodedSecretKey@$($endpointUri.Authority)"
$repoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..\..")).Path

$previousMcHost = [Environment]::GetEnvironmentVariable("MC_HOST_onmu")
try {
  Write-Host "Seeding dev record media to MinIO endpoint $Endpoint bucket $Bucket"
  Write-Host "Credentials are read from environment variable names only and are not printed."
  [Environment]::SetEnvironmentVariable("MC_HOST_onmu", $mcHost, "Process")

  Invoke-DockerMc -SeedDirectory $repoRoot -McArguments @("mb", "--ignore-existing", "onmu/$Bucket")

  foreach ($item in $manifest.items) {
    $objectKey = [string]$item.objectKey
    $sourcePath = [string]$item.sourcePath
    if ([string]::IsNullOrWhiteSpace($sourcePath)) {
      throw "Manifest item for '$objectKey' is missing sourcePath."
    }
    $resolvedSourcePath = (Resolve-Path -LiteralPath (Join-Path $repoRoot $sourcePath)).Path
    if (-not $resolvedSourcePath.StartsWith($repoRoot, [StringComparison]::OrdinalIgnoreCase)) {
      throw "Source path for '$objectKey' must stay inside the repository."
    }
    $contentType = if ($item.contentType) { [string]$item.contentType } else { "image/png" }
    $containerSourcePath = "/seed/" + ($sourcePath -replace "\\", "/")

    Invoke-DockerMc `
      -SeedDirectory $repoRoot `
      -McArguments @("cp", "--attr", "Content-Type=$contentType", $containerSourcePath, "onmu/$Bucket/$objectKey")
    Write-Host "Uploaded $objectKey"
  }

  Write-Host "Seed media upload complete."
} finally {
  [Environment]::SetEnvironmentVariable("MC_HOST_onmu", $previousMcHost, "Process")
}
