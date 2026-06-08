$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectDir = Resolve-Path (Join-Path $scriptDir "..\..")
$propertiesPath = Join-Path $scriptDir "maven-wrapper.properties"
$properties = @{}

Get-Content -LiteralPath $propertiesPath | ForEach-Object {
  if ($_ -match "^\s*([^#][^=]+?)\s*=\s*(.+)\s*$") {
    $properties[$matches[1].Trim()] = $matches[2].Trim()
  }
}

$distributionUrl = $properties["distributionUrl"]
if (-not $distributionUrl) {
  throw "Missing distributionUrl in $propertiesPath"
}

$mavenVersion = [regex]::Match($distributionUrl, "apache-maven-(?<version>[^/]+)-bin\.zip").Groups["version"].Value
if (-not $mavenVersion) {
  throw "Could not determine Maven version from $distributionUrl"
}

$distsDir = Join-Path $scriptDir "dists"
$installDir = Join-Path $distsDir "apache-maven-$mavenVersion"
$archivePath = Join-Path $distsDir "apache-maven-$mavenVersion-bin.zip"
$mavenCmd = Join-Path $installDir "apache-maven-$mavenVersion\bin\mvn.cmd"

if (-not (Test-Path $mavenCmd)) {
  New-Item -ItemType Directory -Path $distsDir -Force | Out-Null

  if (-not (Test-Path $archivePath)) {
    Write-Host "Downloading Maven $mavenVersion..."
    Invoke-WebRequest -Uri $distributionUrl -OutFile $archivePath
  }

  if (Test-Path $installDir) {
    Remove-Item -LiteralPath $installDir -Recurse -Force
  }

  New-Item -ItemType Directory -Path $installDir -Force | Out-Null
  Expand-Archive -LiteralPath $archivePath -DestinationPath $installDir -Force
}

Push-Location $projectDir
try {
  & $mavenCmd @args
  exit $LASTEXITCODE
} finally {
  Pop-Location
}
