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
  [string]$GlyphsUrlTemplate = $(if ($env:ONMU_TILE_GLYPHS_URL_TEMPLATE) { $env:ONMU_TILE_GLYPHS_URL_TEMPLATE } else { "https://demotiles.maplibre.org/font/{fontstack}/{range}.pbf" }),
  [string]$RollbackManifestUrl = $env:ONMU_TILE_ROLLBACK_MANIFEST_URL,
  [string]$CacheControl = $(if ($env:ONMU_TILE_CACHE_CONTROL) { $env:ONMU_TILE_CACHE_CONTROL } else { "public, max-age=3600" }),
  [int]$CacheMaxAgeSeconds = $(if ($env:ONMU_TILE_CACHE_MAX_AGE_SECONDS) { [int]$env:ONMU_TILE_CACHE_MAX_AGE_SECONDS } else { 3600 }),
  [string[]]$CorsAllowedOrigins = @(
    "http://localhost:5173",
    "http://127.0.0.1:5173",
    "http://localhost:5174",
    "http://127.0.0.1:5174",
    "http://localhost:5175",
    "http://127.0.0.1:5175",
    "https://staging-api.onmu.cloud"
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
    [Parameter(Mandatory = $true)][string]$GeneratedAt,
    [Parameter(Mandatory = $true)][string]$GlyphsUrlTemplate
  )

  $labelFont = @("Noto Sans Regular")
  $labelTextField = @("coalesce", @("get", "name:ko"), @("get", "name"), @("get", "name:en"))

  return [ordered]@{
    version = 8
    name = "ONMU Light Korea Dev"
    metadata = [ordered]@{
      "onmu:generatedAt" = $GeneratedAt
      "onmu:tilesetUrl" = $TilesetUrl
      "onmu:basemapSchema" = "protomaps-compatible"
      "onmu:fontstack" = $labelFont[0]
      "onmu:glyphsUrlTemplate" = $GlyphsUrlTemplate
    }
    glyphs = $GlyphsUrlTemplate
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
        id = "landuse-park"
        type = "fill"
        source = "protomaps"
        "source-layer" = "landuse"
        minzoom = 10
        filter = @(
          "any",
          @("in", "kind", "park", "nature_reserve", "forest", "grass", "cemetery", "garden"),
          @("in", "kind_detail", "park", "nature_reserve", "forest", "grass", "garden")
        )
        paint = [ordered]@{
          "fill-color" = "#DDEED6"
          "fill-opacity" = @("interpolate", @("linear"), @("zoom"), 10, 0.24, 13, 0.52, 15, 0.68)
        }
      },
      [ordered]@{
        id = "water"
        type = "fill"
        source = "protomaps"
        "source-layer" = "water"
        filter = @(
          "all",
          @("==", '$type', "Polygon"),
          @(
            "any",
            @("in", "kind", "ocean", "bay", "lake"),
            @("in", "kind_detail", "lake", "reservoir")
          )
        )
        paint = [ordered]@{
          "fill-color" = "#B8D9E6"
          "fill-opacity" = 0.64
        }
      },
      [ordered]@{
        id = "water-river-area"
        type = "fill"
        source = "protomaps"
        "source-layer" = "water"
        minzoom = 12
        filter = @(
          "all",
          @("==", '$type', "Polygon"),
          @(
            "any",
            @("in", "kind", "river", "stream", "canal"),
            @("in", "kind_detail", "river", "stream", "canal")
          )
        )
        paint = [ordered]@{
          "fill-color" = "#A8D4E1"
          "fill-opacity" = @("interpolate", @("linear"), @("zoom"), 12, 0.14, 14, 0.3)
        }
      },
      [ordered]@{
        id = "water-river-line"
        type = "line"
        source = "protomaps"
        "source-layer" = "water"
        minzoom = 9
        filter = @(
          "all",
          @("==", '$type', "LineString"),
          @(
            "any",
            @("in", "kind", "river", "stream", "canal"),
            @("in", "kind_detail", "river", "stream", "canal")
          )
        )
        paint = [ordered]@{
          "line-color" = "#8CC7D9"
          "line-width" = @("interpolate", @("linear"), @("zoom"), 9, 0.35, 12, 0.85, 14, 1.5)
          "line-opacity" = 0.5
        }
      },
      [ordered]@{
        id = "roads"
        type = "line"
        source = "protomaps"
        "source-layer" = "roads"
        paint = [ordered]@{
          "line-color" = "#EBA098"
          "line-width" = @("interpolate", @("linear"), @("zoom"), 5, 0.35, 10, 0.9, 14, 2.4, 16, 4.4)
          "line-opacity" = @("interpolate", @("linear"), @("zoom"), 5, 0.42, 11, 0.72, 15, 0.82)
        }
      },
      [ordered]@{
        id = "transit-rail"
        type = "line"
        source = "protomaps"
        "source-layer" = "roads"
        minzoom = 10
        filter = @(
          "any",
          @("in", "kind", "rail", "railway", "subway", "light_rail"),
          @("in", "kind_detail", "rail", "subway", "light_rail")
        )
        paint = [ordered]@{
          "line-color" = "#84B6D8"
          "line-width" = @("interpolate", @("linear"), @("zoom"), 10, 0.45, 13, 1.1, 16, 2.0)
          "line-opacity" = 0.72
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
        id = "road-labels"
        type = "symbol"
        source = "protomaps"
        "source-layer" = "roads"
        minzoom = 11.5
        filter = @(
          "all",
          @("has", "name"),
          @("!", @("in", @("get", "kind"), @("literal", @("path", "rail", "ferry", "aerialway", "aeroway"))))
        )
        layout = [ordered]@{
          "symbol-placement" = "line"
          "text-field" = $labelTextField
          "text-font" = $labelFont
          "text-size" = @("interpolate", @("linear"), @("zoom"), 11.5, 8.5, 13, 10, 16, 12)
          "text-padding" = 2
          "text-rotation-alignment" = "map"
          "text-pitch-alignment" = "viewport"
        }
        paint = [ordered]@{
          "text-color" = "#7A554B"
          "text-halo-color" = "#FFF8F0"
          "text-halo-width" = 1.15
          "text-opacity" = @("interpolate", @("linear"), @("zoom"), 11.5, 0.58, 13, 0.82, 15, 0.95)
        }
      },
      [ordered]@{
        id = "place-city-labels"
        type = "symbol"
        source = "protomaps"
        "source-layer" = "places"
        minzoom = 5
        filter = @(
          "any",
          @("in", "kind", "country", "region", "county", "locality", "municipality", "city", "town"),
          @("in", "kind_detail", "city", "town", "locality")
        )
        layout = [ordered]@{
          "text-field" = $labelTextField
          "text-font" = $labelFont
          "text-size" = @("interpolate", @("linear"), @("zoom"), 5, 10, 10, 13, 14, 15)
          "text-padding" = 4
        }
        paint = [ordered]@{
          "text-color" = "#4C3A35"
          "text-halo-color" = "#FFF8F0"
          "text-halo-width" = 1.2
        }
      },
      [ordered]@{
        id = "place-neighborhood-labels"
        type = "symbol"
        source = "protomaps"
        "source-layer" = "places"
        minzoom = 10
        filter = @(
          "any",
          @("in", "kind", "macrohood", "neighbourhood", "neighborhood", "suburb", "quarter", "village"),
          @("in", "kind_detail", "macrohood", "neighbourhood", "neighborhood", "suburb", "quarter", "village")
        )
        layout = [ordered]@{
          "text-field" = $labelTextField
          "text-font" = $labelFont
          "text-size" = @("interpolate", @("linear"), @("zoom"), 10, 9, 12, 10.5, 14, 12)
          "text-padding" = 4
        }
        paint = [ordered]@{
          "text-color" = "#6D5248"
          "text-halo-color" = "#FFF8F0"
          "text-halo-width" = 1.1
        }
      },
      [ordered]@{
        id = "earth-labels"
        type = "symbol"
        source = "protomaps"
        "source-layer" = "earth"
        minzoom = 9
        filter = @("has", "name")
        layout = [ordered]@{
          "text-field" = $labelTextField
          "text-font" = $labelFont
          "text-size" = @("interpolate", @("linear"), @("zoom"), 9, 9, 13, 11)
          "text-padding" = 4
          "text-optional" = $true
        }
        paint = [ordered]@{
          "text-color" = "#8A6B5E"
          "text-halo-color" = "#FFF8F0"
          "text-halo-width" = 1.1
          "text-opacity" = 0.72
        }
      },
      [ordered]@{
        id = "water-line-labels"
        type = "symbol"
        source = "protomaps"
        "source-layer" = "water"
        minzoom = 10
        filter = @(
          "all",
          @("has", "name"),
          @("in", @("get", "kind"), @("literal", @("river", "stream", "canal")))
        )
        layout = [ordered]@{
          "symbol-placement" = "line"
          "text-field" = $labelTextField
          "text-font" = $labelFont
          "text-size" = @("interpolate", @("linear"), @("zoom"), 10, 8.5, 13, 10.5, 16, 12)
          "text-padding" = 3
          "text-optional" = $true
        }
        paint = [ordered]@{
          "text-color" = "#4F8EA6"
          "text-halo-color" = "#FFF8F0"
          "text-halo-width" = 1.05
          "text-opacity" = @("interpolate", @("linear"), @("zoom"), 10, 0.45, 13, 0.74, 15, 0.86)
        }
      },
      [ordered]@{
        id = "water-area-labels"
        type = "symbol"
        source = "protomaps"
        "source-layer" = "water"
        minzoom = 11
        filter = @(
          "all",
          @("has", "name"),
          @("!", @("in", @("get", "kind"), @("literal", @("river", "stream", "canal"))))
        )
        layout = [ordered]@{
          "text-field" = $labelTextField
          "text-font" = $labelFont
          "text-size" = @("interpolate", @("linear"), @("zoom"), 11, 8.5, 14, 11)
          "text-padding" = 4
          "text-optional" = $true
        }
        paint = [ordered]@{
          "text-color" = "#4F8EA6"
          "text-halo-color" = "#FFF8F0"
          "text-halo-width" = 1.05
          "text-opacity" = 0.68
        }
      },
      [ordered]@{
        id = "park-mountain-labels"
        type = "symbol"
        source = "protomaps"
        "source-layer" = "pois"
        minzoom = 11
        filter = @(
          "all",
          @("has", "name"),
          @("in", @("get", "kind"), @("literal", @("park", "garden", "wood", "forest", "nature_reserve", "peak", "mountain", "volcano", "golf_course")))
        )
        layout = [ordered]@{
          "text-field" = $labelTextField
          "text-font" = $labelFont
          "text-size" = @("interpolate", @("linear"), @("zoom"), 11, 8.5, 14, 10.5, 16, 11.5)
          "text-padding" = 4
          "text-offset" = @(0, 0.25)
          "text-optional" = $true
        }
        paint = [ordered]@{
          "text-color" = "#5C7C4C"
          "text-halo-color" = "#FFF8F0"
          "text-halo-width" = 1.1
          "text-opacity" = @("interpolate", @("linear"), @("zoom"), 11, 0.46, 13, 0.72, 15, 0.84)
        }
      },
      [ordered]@{
        id = "transit-station-labels"
        type = "symbol"
        source = "protomaps"
        "source-layer" = "pois"
        minzoom = 11
        filter = @(
          "any",
          @("in", "kind", "station", "subway", "railway", "train_station", "bus_station"),
          @("in", "kind_detail", "station", "subway", "railway", "train_station", "bus_station")
        )
        layout = [ordered]@{
          "text-field" = $labelTextField
          "text-font" = $labelFont
          "text-size" = @("interpolate", @("linear"), @("zoom"), 11, 8.5, 13, 10, 15, 11.5, 17, 12.5)
          "text-padding" = 5
          "text-offset" = @(0, 0.35)
          "text-optional" = $true
        }
        paint = [ordered]@{
          "text-color" = "#336F9E"
          "text-halo-color" = "#FFF8F0"
          "text-halo-width" = 1.2
          "text-opacity" = @("interpolate", @("linear"), @("zoom"), 11, 0.48, 13, 0.74, 15, 0.88)
        }
      },
      [ordered]@{
        id = "poi-labels"
        type = "symbol"
        source = "protomaps"
        "source-layer" = "pois"
        minzoom = 12
        filter = @(
          "all",
          @("has", "name"),
          @("!", @("in", @("get", "kind"), @("literal", @("station", "subway", "railway", "train_station", "bus_station", "park", "garden", "wood", "forest", "nature_reserve", "peak", "mountain", "volcano", "golf_course")))),
          @("!", @("in", @("get", "kind_detail"), @("literal", @("station", "subway", "railway", "train_station", "bus_station"))))
        )
        layout = [ordered]@{
          "text-field" = $labelTextField
          "text-font" = $labelFont
          "text-size" = @("interpolate", @("linear"), @("zoom"), 12, 8, 14, 9.5, 17, 11.5)
          "text-padding" = 4
          "text-offset" = @(0, 0.4)
          "text-optional" = $true
        }
        paint = [ordered]@{
          "text-color" = "#7A6258"
          "text-halo-color" = "#FFF8F0"
          "text-halo-width" = 1.1
          "text-opacity" = @("interpolate", @("linear"), @("zoom"), 12, 0.28, 14, 0.58, 17, 0.78)
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
  if (-not (Test-HasText $GlyphsUrlTemplate)) {
    throw "GlyphsUrlTemplate is required and must include {fontstack} and {range} placeholders."
  }
  if ($GlyphsUrlTemplate -notlike "*{fontstack}*" -or $GlyphsUrlTemplate -notlike "*{range}*") {
    throw "GlyphsUrlTemplate must include {fontstack} and {range} placeholders."
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
  $styleJson = New-MapLibreStyle -TilesetUrl $StyleTilesetUrl -GeneratedAt $generatedAt -GlyphsUrlTemplate $GlyphsUrlTemplate
  Write-JsonFile -Path $stylePath -Value $styleJson
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
      glyphsUrlTemplate = $styleJson.glyphs
      fontstack = $styleJson.metadata["onmu:fontstack"]
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
