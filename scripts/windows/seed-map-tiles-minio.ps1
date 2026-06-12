[CmdletBinding()]
param(
  [string]$MinioEndpoint = $(if ($env:OBJECT_STORAGE_ENDPOINT) { $env:OBJECT_STORAGE_ENDPOINT } elseif ($env:MINIO_ENDPOINT) { $env:MINIO_ENDPOINT } else { "http://localhost:9000" }),
  [string]$MinioAccessKey = $env:MINIO_ROOT_USER,
  [string]$MinioSecretKey = $env:MINIO_ROOT_PASSWORD,
  [string]$Bucket = $(if ($env:ONMU_TILE_BUCKET) { $env:ONMU_TILE_BUCKET } else { "onmu-tiles" }),
  [string]$PmtilesObjectKey = $(if ($env:ONMU_PMTILES_OBJECT_KEY) { $env:ONMU_PMTILES_OBJECT_KEY } else { "pmtiles/korea-dev.pmtiles" }),
  [string]$ManifestObjectKey = $(if ($env:ONMU_TILE_MANIFEST_OBJECT_KEY) { $env:ONMU_TILE_MANIFEST_OBJECT_KEY } else { "tiles/manifest.json" }),
  [string]$StyleObjectKey = $(if ($env:ONMU_TILE_STYLE_OBJECT_KEY) { $env:ONMU_TILE_STYLE_OBJECT_KEY } else { "styles/onmu-light.json" }),
  [string]$PmtilesSourceUrl = $env:ONMU_PMTILES_SOURCE_URL,
  [string]$PmtilesFile,
  [string]$LocalManifestUrl = $(if ($env:ONMU_TILE_LOCAL_MANIFEST_URL) { $env:ONMU_TILE_LOCAL_MANIFEST_URL } else { "http://localhost:9000/onmu-tiles/tiles/manifest.json" }),
  [string]$PublicManifestUrl = $(if ($env:ONMU_TILE_PUBLIC_MANIFEST_URL) { $env:ONMU_TILE_PUBLIC_MANIFEST_URL } else { "https://tiles.onmu.cloud/manifest.json" }),
  [string]$PublicTileBaseUrl = $(if ($env:ONMU_TILE_PUBLIC_BASE_URL) { $env:ONMU_TILE_PUBLIC_BASE_URL } else { "https://tiles.onmu.cloud" }),
  [string]$LocalTileBaseUrl,
  [string]$StyleTilesetUrl = $env:ONMU_TILE_STYLE_TILESET_URL,
  [string]$RollbackManifestUrl = $env:ONMU_TILE_ROLLBACK_MANIFEST_URL,
  [string]$CacheControl = $(if ($env:ONMU_TILE_CACHE_CONTROL) { $env:ONMU_TILE_CACHE_CONTROL } else { "public, max-age=3600" }),
  [int]$CacheMaxAgeSeconds = $(if ($env:ONMU_TILE_CACHE_MAX_AGE_SECONDS) { [int]$env:ONMU_TILE_CACHE_MAX_AGE_SECONDS } else { 3600 }),
  [string[]]$CorsAllowedOrigins = @(
    "http://localhost:5173",
    "http://127.0.0.1:5173",
    "https://dev-api.onmu.cloud",
    "https://int-api.onmu.cloud"
  ),
  [string]$McImage = $(if ($env:ONMU_MC_IMAGE) { $env:ONMU_MC_IMAGE } else { "minio/mc:latest" }),
  [switch]$DryRun,
  [switch]$KeepTemp
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

function Test-HasText {
  param([string]$Value)
  return -not [string]::IsNullOrWhiteSpace($Value)
}

function Join-ObjectUrl {
  param(
    [Parameter(Mandatory = $true)][string]$BaseUrl,
    [Parameter(Mandatory = $true)][string]$ObjectKey
  )

  $segments = @(
    foreach ($part in ($ObjectKey -replace "\\", "/" -split "/")) {
      if ($part) {
        [uri]::EscapeDataString($part)
      }
    }
  )
  return "$($BaseUrl.TrimEnd('/'))/$($segments -join '/')"
}

function Resolve-DockerEndpoint {
  param([Parameter(Mandatory = $true)][string]$Endpoint)

  $uri = [uri]$Endpoint
  if ($uri.Host -eq "localhost" -or $uri.Host -eq "127.0.0.1" -or $uri.Host -eq "::1") {
    $builder = [System.UriBuilder]::new($uri)
    $builder.Host = "host.docker.internal"
    return $builder.Uri.AbsoluteUri.TrimEnd("/")
  }
  return $Endpoint.TrimEnd("/")
}

function New-McHost {
  param(
    [Parameter(Mandatory = $true)][string]$Endpoint,
    [Parameter(Mandatory = $true)][string]$AccessKey,
    [Parameter(Mandatory = $true)][string]$SecretKey
  )

  $builder = [System.UriBuilder]::new([uri]$Endpoint)
  $builder.UserName = $AccessKey
  $builder.Password = $SecretKey
  return $builder.Uri.AbsoluteUri.TrimEnd("/")
}

function Hide-SensitiveText {
  param([string]$Value)

  $redacted = $Value
  foreach ($secret in @($MinioAccessKey, $MinioSecretKey)) {
    if (Test-HasText $secret) {
      $redacted = $redacted.Replace($secret, "[redacted]")
    }
  }
  return $redacted
}

function Write-JsonFile {
  param(
    [Parameter(Mandatory = $true)][string]$Path,
    [Parameter(Mandatory = $true)]$Value
  )

  $utf8NoBom = [System.Text.UTF8Encoding]::new($false)
  $json = $Value | ConvertTo-Json -Depth 30
  [System.IO.File]::WriteAllText($Path, "$json`n", $utf8NoBom)
}

function Write-TextFile {
  param(
    [Parameter(Mandatory = $true)][string]$Path,
    [Parameter(Mandatory = $true)][string]$Value
  )

  $utf8NoBom = [System.Text.UTF8Encoding]::new($false)
  [System.IO.File]::WriteAllText($Path, "$Value`n", $utf8NoBom)
}

function New-CorsPolicyXml {
  param([string[]]$AllowedOrigins)

  $originNodes = @($AllowedOrigins | ForEach-Object {
      "<AllowedOrigin>$([System.Security.SecurityElement]::Escape($_))</AllowedOrigin>"
    }) -join "`n    "

  return @"
<CORSConfiguration>
  <CORSRule>
    $originNodes
    <AllowedMethod>GET</AllowedMethod>
    <AllowedMethod>HEAD</AllowedMethod>
    <AllowedHeader>*</AllowedHeader>
    <ExposeHeader>ETag</ExposeHeader>
    <ExposeHeader>Content-Length</ExposeHeader>
    <ExposeHeader>Content-Type</ExposeHeader>
    <ExposeHeader>Cache-Control</ExposeHeader>
    <MaxAgeSeconds>$CacheMaxAgeSeconds</MaxAgeSeconds>
  </CORSRule>
</CORSConfiguration>
"@
}

function New-MapLibreStyle {
  param(
    [Parameter(Mandatory = $true)][string]$TilesetUrl,
    [Parameter(Mandatory = $true)][string]$GeneratedAt
  )

  return [ordered]@{
    version = 8
    name = "ONMU Light Korea Dev"
    metadata = [ordered]@{
      "onmu:generatedAt" = $GeneratedAt
      "onmu:tilesetUrl" = $TilesetUrl
      "onmu:basemapSchema" = "protomaps-compatible"
    }
    glyphs = "https://fonts.openmaptiles.org/{fontstack}/{range}.pbf"
    sources = [ordered]@{
      protomaps = [ordered]@{
        type = "vector"
        url = $TilesetUrl
        attribution = "Map data boundary managed by ONMU dev tile manifest"
      }
    }
    layers = @(
      [ordered]@{
        id = "background"
        type = "background"
        paint = [ordered]@{
          "background-color" = "#FFF8F0"
        }
      },
      [ordered]@{
        id = "earth"
        type = "fill"
        source = "protomaps"
        "source-layer" = "earth"
        paint = [ordered]@{
          "fill-color" = "#F9EFE4"
        }
      },
      [ordered]@{
        id = "landuse"
        type = "fill"
        source = "protomaps"
        "source-layer" = "landuse"
        paint = [ordered]@{
          "fill-color" = "#F4E6D5"
          "fill-opacity" = 0.55
        }
      },
      [ordered]@{
        id = "water"
        type = "fill"
        source = "protomaps"
        "source-layer" = "water"
        paint = [ordered]@{
          "fill-color" = "#B8D9E6"
        }
      },
      [ordered]@{
        id = "roads"
        type = "line"
        source = "protomaps"
        "source-layer" = "roads"
        paint = [ordered]@{
          "line-color" = "#F4A6A2"
          "line-width" = @("interpolate", @("linear"), @("zoom"), 5, 0.25, 10, 0.9, 14, 2.2)
          "line-opacity" = 0.78
        }
      },
      [ordered]@{
        id = "buildings"
        type = "fill"
        source = "protomaps"
        "source-layer" = "buildings"
        minzoom = 13
        paint = [ordered]@{
          "fill-color" = "#E8D4C2"
          "fill-opacity" = 0.72
        }
      },
      [ordered]@{
        id = "boundaries"
        type = "line"
        source = "protomaps"
        "source-layer" = "boundaries"
        paint = [ordered]@{
          "line-color" = "#D4BFAE"
          "line-width" = @("interpolate", @("linear"), @("zoom"), 4, 0.4, 9, 1.1)
          "line-opacity" = 0.65
        }
      },
      [ordered]@{
        id = "places"
        type = "symbol"
        source = "protomaps"
        "source-layer" = "places"
        minzoom = 5
        layout = [ordered]@{
          "text-field" = @("coalesce", @("get", "name:ko"), @("get", "name"))
          "text-font" = @("Noto Sans Regular")
          "text-size" = @("interpolate", @("linear"), @("zoom"), 5, 10, 12, 14)
        }
        paint = [ordered]@{
          "text-color" = "#4C3A35"
          "text-halo-color" = "#FFF8F0"
          "text-halo-width" = 1.2
        }
      }
    )
  }
}

function New-TileManifest {
  param(
    [Parameter(Mandatory = $true)]$PmtilesMetadata,
    [Parameter(Mandatory = $true)][string]$GeneratedAt,
    [Parameter(Mandatory = $true)][string]$LocalPmtilesUrl,
    [Parameter(Mandatory = $true)][string]$PublicPmtilesUrl,
    [Parameter(Mandatory = $true)][string]$LocalStyleUrl,
    [Parameter(Mandatory = $true)][string]$PublicStyleUrl,
    [Parameter(Mandatory = $true)][string]$CurrentTilesetUrl
  )

  return [ordered]@{
    schemaVersion = 1
    kind = "onmu.mapTilesManifest"
    generatedAt = $GeneratedAt
    bucket = $Bucket
    manifest = [ordered]@{
      objectKey = $ManifestObjectKey
      localUrl = $LocalManifestUrl
      publicUrl = $PublicManifestUrl
    }
    current = [ordered]@{
      id = "korea-dev"
      styleUrl = $PublicStyleUrl
      localStyleUrl = $LocalStyleUrl
      tileset = [ordered]@{
        objectKey = $PmtilesObjectKey
        url = $CurrentTilesetUrl
        localUrl = "pmtiles://$LocalPmtilesUrl"
        publicUrl = "pmtiles://$PublicPmtilesUrl"
        format = "pmtiles"
      }
      bounds = @(124.0, 33.0, 132.2, 39.8)
      center = @(127.8, 36.3, 5.8)
      cache = [ordered]@{
        cacheControl = $CacheControl
        maxAgeSeconds = $CacheMaxAgeSeconds
        etag = $PmtilesMetadata.etag
        sizeBytes = $PmtilesMetadata.sizeBytes
        sha256 = $PmtilesMetadata.sha256
      }
    }
    rollback = [ordered]@{
      previousManifestUrl = if (Test-HasText $RollbackManifestUrl) { $RollbackManifestUrl } else { $null }
      previousPmtilesObjectKey = $null
      note = "previousManifestUrl 또는 previousPmtilesObjectKey를 운영자가 채운 뒤 app manifest pointer를 되돌린다."
    }
  }
}

function Invoke-McContainer {
  param(
    [Parameter(Mandatory = $true)][string[]]$Arguments,
    [Parameter(Mandatory = $true)][string]$McHost,
    [Parameter(Mandatory = $true)][string]$WorkDir
  )

  $dockerArgs = @(
    "run",
    "--rm",
    "-e",
    "MC_HOST_onmu=$McHost",
    "-v",
    "$($WorkDir):/work",
    $McImage,
    "--no-color"
  ) + $Arguments

  $output = & docker @dockerArgs 2>&1
  if ($LASTEXITCODE -ne 0) {
    $commandName = if ($Arguments.Count -gt 0) { $Arguments[0] } else { "mc" }
    $safeOutput = Hide-SensitiveText -Value ($output -join "`n")
    throw "Docker minio/mc command failed during '$commandName'. Credential values are not printed. Output: $safeOutput"
  }
  return $output
}

function Get-McObjectMetadata {
  param(
    [Parameter(Mandatory = $true)][string]$ObjectKey,
    [Parameter(Mandatory = $true)][string]$McHost,
    [Parameter(Mandatory = $true)][string]$WorkDir,
    [Parameter(Mandatory = $true)][string]$Sha256
  )

  $target = "onmu/$Bucket/$ObjectKey"
  $output = Invoke-McContainer -McHost $McHost -WorkDir $WorkDir -Arguments @("stat", "--json", $target)
  $jsonLine = @($output | Where-Object { $_ -match "^\s*\{" } | Select-Object -First 1)
  if ($jsonLine.Count -eq 0) {
    throw "Unable to read object metadata for $ObjectKey. Credential values are not printed."
  }
  $stat = $jsonLine[0] | ConvertFrom-Json
  return [pscustomobject]@{
    bucket = $Bucket
    objectKey = $ObjectKey
    status = "uploaded"
    cache = $CacheControl
    etag = $stat.etag
    sizeBytes = $stat.size
    sha256 = $Sha256
  }
}

if ((Test-HasText $PmtilesFile) -and (Test-HasText $PmtilesSourceUrl)) {
  throw "Use either -PmtilesFile or -PmtilesSourceUrl, not both. Source URL value is not printed."
}

if (-not (Test-HasText $PmtilesFile) -and -not (Test-HasText $PmtilesSourceUrl)) {
  throw "PMTiles input is required. Pass -PmtilesFile or -PmtilesSourceUrl, or set ONMU_PMTILES_SOURCE_URL."
}

if (-not (Test-HasText $LocalTileBaseUrl)) {
  $LocalTileBaseUrl = "$($MinioEndpoint.TrimEnd('/'))/$Bucket"
}

$tempDir = Join-Path $env:TEMP "onmu-map-tiles-$PID"
New-Item -ItemType Directory -Force -Path $tempDir | Out-Null

try {
  $pmtilesWorkFile = Join-Path $tempDir "korea-dev.pmtiles"
  if (Test-HasText $PmtilesFile) {
    $resolvedPmtiles = Resolve-Path -LiteralPath $PmtilesFile -ErrorAction Stop
    Copy-Item -LiteralPath $resolvedPmtiles.Path -Destination $pmtilesWorkFile -Force
  } else {
    try {
      Invoke-WebRequest -Uri $PmtilesSourceUrl -OutFile $pmtilesWorkFile -UseBasicParsing | Out-Null
    } catch {
      throw "Failed to download PMTiles source URL. URL and credential-like query values are not printed."
    }
  }

  $pmtilesInfo = Get-Item -LiteralPath $pmtilesWorkFile
  if ($pmtilesInfo.Length -le 0) {
    throw "PMTiles input file is empty."
  }

  $generatedAt = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
  $localPmtilesUrl = Join-ObjectUrl -BaseUrl $LocalTileBaseUrl -ObjectKey $PmtilesObjectKey
  $publicPmtilesUrl = Join-ObjectUrl -BaseUrl $PublicTileBaseUrl -ObjectKey $PmtilesObjectKey
  $localStyleUrl = Join-ObjectUrl -BaseUrl $LocalTileBaseUrl -ObjectKey $StyleObjectKey
  $publicStyleUrl = Join-ObjectUrl -BaseUrl $PublicTileBaseUrl -ObjectKey $StyleObjectKey
  if (-not (Test-HasText $StyleTilesetUrl)) {
    $StyleTilesetUrl = "pmtiles://$publicPmtilesUrl"
  }

  $pmtilesHash = (Get-FileHash -LiteralPath $pmtilesWorkFile -Algorithm SHA256).Hash.ToLowerInvariant()
  $corsPath = Join-Path $tempDir "cors.xml"
  Write-TextFile -Path $corsPath -Value (New-CorsPolicyXml -AllowedOrigins $CorsAllowedOrigins)
  $corsStatus = if ($DryRun) { "dry-run" } else { "not-set" }

  if ($DryRun) {
    $pmtilesMetadata = [pscustomobject]@{
      bucket = $Bucket
      objectKey = $PmtilesObjectKey
      status = "dry-run"
      cache = $CacheControl
      etag = "dry-run-$($pmtilesHash.Substring(0, 12))"
      sizeBytes = $pmtilesInfo.Length
      sha256 = $pmtilesHash
    }
  } else {
    if (-not (Test-HasText $MinioAccessKey) -or -not (Test-HasText $MinioSecretKey)) {
      throw "MINIO_ROOT_USER and MINIO_ROOT_PASSWORD are required for upload. Values are not printed."
    }
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
      throw "Docker CLI is required because this script uses a temporary minio/mc container."
    }

    $dockerEndpoint = Resolve-DockerEndpoint -Endpoint $MinioEndpoint
    $mcHost = New-McHost -Endpoint $dockerEndpoint -AccessKey $MinioAccessKey -SecretKey $MinioSecretKey

    $null = Invoke-McContainer -McHost $mcHost -WorkDir $tempDir -Arguments @("mb", "--ignore-existing", "onmu/$Bucket")
    $null = Invoke-McContainer -McHost $mcHost -WorkDir $tempDir -Arguments @("anonymous", "set", "download", "onmu/$Bucket")
    try {
      $null = Invoke-McContainer -McHost $mcHost -WorkDir $tempDir -Arguments @("cors", "set", "onmu/$Bucket", "/work/cors.xml")
      $corsStatus = "set"
    } catch {
      $corsStatus = "unsupported"
      Write-Warning "MinIO CORS configuration was skipped because this backend does not support SetBucketCors. Secret values are not printed."
    }
    $null = Invoke-McContainer -McHost $mcHost -WorkDir $tempDir -Arguments @("cp", "--attr", "Cache-Control=$CacheControl", "/work/korea-dev.pmtiles", "onmu/$Bucket/$PmtilesObjectKey")
    $pmtilesMetadata = Get-McObjectMetadata -McHost $mcHost -WorkDir $tempDir -ObjectKey $PmtilesObjectKey -Sha256 $pmtilesHash
  }

  $stylePath = Join-Path $tempDir "onmu-light.json"
  $manifestPath = Join-Path $tempDir "manifest.json"
  Write-JsonFile -Path $stylePath -Value (New-MapLibreStyle -TilesetUrl $StyleTilesetUrl -GeneratedAt $generatedAt)
  Write-JsonFile -Path $manifestPath -Value (New-TileManifest `
      -PmtilesMetadata $pmtilesMetadata `
      -GeneratedAt $generatedAt `
      -LocalPmtilesUrl $localPmtilesUrl `
      -PublicPmtilesUrl $publicPmtilesUrl `
      -LocalStyleUrl $localStyleUrl `
      -PublicStyleUrl $publicStyleUrl `
      -CurrentTilesetUrl $StyleTilesetUrl)

  if ($DryRun) {
    $styleMetadata = [pscustomobject]@{
      bucket = $Bucket
      objectKey = $StyleObjectKey
      status = "dry-run"
      cache = $CacheControl
      etag = "dry-run-$((Get-FileHash -LiteralPath $stylePath -Algorithm SHA256).Hash.Substring(0, 12).ToLowerInvariant())"
      sizeBytes = (Get-Item -LiteralPath $stylePath).Length
    }
    $manifestMetadata = [pscustomobject]@{
      bucket = $Bucket
      objectKey = $ManifestObjectKey
      status = "dry-run"
      cache = $CacheControl
      etag = "dry-run-$((Get-FileHash -LiteralPath $manifestPath -Algorithm SHA256).Hash.Substring(0, 12).ToLowerInvariant())"
      sizeBytes = (Get-Item -LiteralPath $manifestPath).Length
    }
  } else {
    $null = Invoke-McContainer -McHost $mcHost -WorkDir $tempDir -Arguments @("cp", "--attr", "Cache-Control=$CacheControl", "/work/onmu-light.json", "onmu/$Bucket/$StyleObjectKey")
    $styleMetadata = Get-McObjectMetadata -McHost $mcHost -WorkDir $tempDir -ObjectKey $StyleObjectKey -Sha256 ((Get-FileHash -LiteralPath $stylePath -Algorithm SHA256).Hash.ToLowerInvariant())
    $null = Invoke-McContainer -McHost $mcHost -WorkDir $tempDir -Arguments @("cp", "--attr", "Cache-Control=$CacheControl", "/work/manifest.json", "onmu/$Bucket/$ManifestObjectKey")
    $manifestMetadata = Get-McObjectMetadata -McHost $mcHost -WorkDir $tempDir -ObjectKey $ManifestObjectKey -Sha256 ((Get-FileHash -LiteralPath $manifestPath -Algorithm SHA256).Hash.ToLowerInvariant())
  }

  [pscustomobject]@{
    bucket = $Bucket
    status = if ($DryRun) { "dry-run" } else { "uploaded" }
    manifest = [ordered]@{
      localUrl = $LocalManifestUrl
      publicUrl = $PublicManifestUrl
      object = $manifestMetadata
    }
    objects = @(
      $pmtilesMetadata,
      $styleMetadata,
      $manifestMetadata
    )
    anonymousDownload = if ($DryRun) { "dry-run" } else { "set" }
    cors = [ordered]@{
      status = $corsStatus
      allowedOrigins = $CorsAllowedOrigins
      maxAgeSeconds = $CacheMaxAgeSeconds
    }
  } | ConvertTo-Json -Depth 20
} finally {
  if (-not $KeepTemp -and (Test-Path -LiteralPath $tempDir)) {
    Remove-Item -LiteralPath $tempDir -Recurse -Force
  }
}
