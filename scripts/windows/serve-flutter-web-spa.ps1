param(
  [string]$WebRoot,
  [int]$Port = 5173,
  [string]$BindHost = "127.0.0.1"
)

$ErrorActionPreference = "Stop"

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Resolve-Path -LiteralPath (Join-Path $scriptRoot "..\..")

if ([string]::IsNullOrWhiteSpace($WebRoot)) {
  $WebRoot = Join-Path $repoRoot "apps\mobile-flutter\build\web"
}

$resolvedRoot = (Resolve-Path -LiteralPath $WebRoot).Path
$indexPath = Join-Path $resolvedRoot "index.html"

if (-not (Test-Path -LiteralPath $indexPath -PathType Leaf)) {
  throw "index.html not found under WebRoot: $resolvedRoot"
}

$mimeTypes = @{
  ".html" = "text/html; charset=utf-8"
  ".js" = "application/javascript; charset=utf-8"
  ".mjs" = "application/javascript; charset=utf-8"
  ".json" = "application/json; charset=utf-8"
  ".wasm" = "application/wasm"
  ".css" = "text/css; charset=utf-8"
  ".png" = "image/png"
  ".jpg" = "image/jpeg"
  ".jpeg" = "image/jpeg"
  ".gif" = "image/gif"
  ".svg" = "image/svg+xml"
  ".ico" = "image/x-icon"
  ".ttf" = "font/ttf"
  ".otf" = "font/otf"
  ".woff" = "font/woff"
  ".woff2" = "font/woff2"
  ".map" = "application/json; charset=utf-8"
}

function Write-Response {
  param(
    [System.Net.HttpListenerContext]$Context,
    [int]$StatusCode,
    [string]$Body
  )

  $bytes = [System.Text.Encoding]::UTF8.GetBytes($Body)
  $Context.Response.StatusCode = $StatusCode
  $Context.Response.ContentType = "text/plain; charset=utf-8"
  $Context.Response.ContentLength64 = $bytes.Length
  $Context.Response.OutputStream.Write($bytes, 0, $bytes.Length)
}

function Get-StaticFilePath {
  param([System.Uri]$Url)

  $requestPath = [Uri]::UnescapeDataString($Url.AbsolutePath)
  $relativePath = $requestPath.TrimStart("/") -replace "/", "\"

  if ([string]::IsNullOrWhiteSpace($relativePath)) {
    return $indexPath
  }

  $candidate = [System.IO.Path]::GetFullPath((Join-Path $resolvedRoot $relativePath))

  if (-not $candidate.StartsWith($resolvedRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
    return $null
  }

  if (Test-Path -LiteralPath $candidate -PathType Container) {
    $candidate = Join-Path $candidate "index.html"
  }

  if (Test-Path -LiteralPath $candidate -PathType Leaf) {
    return $candidate
  }

  if ([string]::IsNullOrEmpty([System.IO.Path]::GetExtension($relativePath))) {
    return $indexPath
  }

  return ""
}

$listener = [System.Net.HttpListener]::new()
$prefix = "http://${BindHost}:$Port/"
$listener.Prefixes.Add($prefix)
$listener.Start()

Write-Host "Serving Flutter Web SPA from $resolvedRoot"
Write-Host "Listening on $prefix"
Write-Host "SPA fallback: extensionless missing routes return index.html"

try {
  while ($listener.IsListening) {
    $context = $listener.GetContext()

    try {
      if ($context.Request.HttpMethod -notin @("GET", "HEAD")) {
        Write-Response -Context $context -StatusCode 405 -Body "Method not allowed"
        continue
      }

      $filePath = Get-StaticFilePath -Url $context.Request.Url

      if ($null -eq $filePath) {
        Write-Response -Context $context -StatusCode 403 -Body "Forbidden"
        continue
      }

      if ($filePath -eq "") {
        Write-Response -Context $context -StatusCode 404 -Body "Not found"
        continue
      }

      $extension = [System.IO.Path]::GetExtension($filePath).ToLowerInvariant()
      $contentType = $mimeTypes[$extension]
      if ([string]::IsNullOrWhiteSpace($contentType)) {
        $contentType = "application/octet-stream"
      }

      $bytes = [System.IO.File]::ReadAllBytes($filePath)
      $context.Response.StatusCode = 200
      $context.Response.ContentType = $contentType
      $context.Response.ContentLength64 = $bytes.Length
      $context.Response.Headers["Cache-Control"] = "no-store"

      if ($context.Request.HttpMethod -eq "GET") {
        $context.Response.OutputStream.Write($bytes, 0, $bytes.Length)
      }
    } catch {
      Write-Response -Context $context -StatusCode 500 -Body $_.Exception.Message
    } finally {
      $context.Response.OutputStream.Close()
    }
  }
} finally {
  $listener.Stop()
  $listener.Close()
}
