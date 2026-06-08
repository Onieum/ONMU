[CmdletBinding()]
param(
  [string]$Runtime,
  [switch]$DryRun,
  [int]$ApiPort = 8080,
  [string]$ApiHost = "127.0.0.1",
  [string]$PublicBaseUrl = $env:ONMU_DEV_API_BASE_URL,
  [string]$Client = "github-actions-cd",
  [switch]$SkipDependencyStart
)

$ErrorActionPreference = "Stop"

$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$LogsDir = Join-Path $RepoRoot "logs"
$DeployLogFile = Join-Path $LogsDir "deploy-dev-backend.log"
$PidFile = Join-Path $LogsDir "dev-backend-api.pid"
$StdoutLogFile = Join-Path $LogsDir "dev-backend-api.out.log"
$StderrLogFile = Join-Path $LogsDir "dev-backend-api.err.log"
$AccessLogFile = Join-Path $LogsDir "api-access.log"
$ComposeFile = Join-Path $RepoRoot "infra\compose\docker-compose.yml"
$SpringDir = Join-Path $RepoRoot "services\api-spring"
$RuntimeWasProvided = $PSBoundParameters.ContainsKey("Runtime")

if (-not $PublicBaseUrl) {
  $PublicBaseUrl = "https://dev-api.onmu.cloud"
}

function Write-DeployLog {
  param([string]$Message)

  if (-not (Test-Path $LogsDir)) {
    New-Item -ItemType Directory -Path $LogsDir -Force | Out-Null
  }

  $line = "[{0}] {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ssK"), $Message
  Write-Host $line
  $stream = $null
  try {
    $bytes = [System.Text.UTF8Encoding]::new($false).GetBytes("$line`r`n")
    $stream = [System.IO.FileStream]::new(
      $DeployLogFile,
      [System.IO.FileMode]::Append,
      [System.IO.FileAccess]::Write,
      [System.IO.FileShare]::ReadWrite
    )
    $stream.Write($bytes, 0, $bytes.Length)
  } catch {
    Write-Warning "Could not append to deploy log file: $($_.Exception.Message)"
  } finally {
    if ($stream) {
      $stream.Dispose()
    }
  }
}

function Resolve-BackendRuntime {
  if ($RuntimeWasProvided -and $Runtime) {
    $candidate = $Runtime
  } elseif ($env:ONMU_BACKEND_RUNTIME) {
    $candidate = $env:ONMU_BACKEND_RUNTIME
  } else {
    $candidate = "node-stub"
  }

  $candidate = $candidate.ToLowerInvariant()
  if ($candidate -notin @("node-stub", "spring")) {
    throw "Unsupported backend runtime '$candidate'. Use 'node-stub' or 'spring'."
  }

  return $candidate
}

function Assert-RepoRoot {
  Set-Location $RepoRoot

  $requiredPaths = @(
    ".git",
    "package.json",
    "services\api\server.mjs",
    "docs\operations\windows-backend-server.md"
  )

  foreach ($relativePath in $requiredPaths) {
    $path = Join-Path $RepoRoot $relativePath
    if (-not (Test-Path $path)) {
      throw "Repository root check failed. Missing: $relativePath"
    }
  }

  Write-DeployLog "Repository root: $RepoRoot"
}

function Invoke-NativeCommand {
  param(
    [string]$FilePath,
    [string[]]$ArgumentList,
    [string]$DryRunText
  )

  $display = if ($DryRunText) { $DryRunText } else { "$FilePath $($ArgumentList -join ' ')" }
  if ($DryRun) {
    Write-DeployLog "[dry-run] $display"
    return
  }

  Write-DeployLog "Running: $display"
  & $FilePath @ArgumentList
  $exitCode = $LASTEXITCODE
  if ($null -ne $exitCode -and $exitCode -ne 0) {
    throw "Command failed with exit code ${exitCode}: $display"
  }
}

function Sync-DevBranch {
  Invoke-NativeCommand -FilePath "git" -ArgumentList @("fetch", "origin", "dev")

  if ($DryRun) {
    Write-DeployLog "[dry-run] git switch dev"
  } else {
    Write-DeployLog "Running: git switch dev"
    & git switch dev
    if ($LASTEXITCODE -ne 0) {
      Write-DeployLog "Local dev branch was not available. Trying: git switch --track origin/dev"
      & git switch --track origin/dev
      if ($LASTEXITCODE -ne 0) {
        throw "Could not switch to dev branch."
      }
    }
  }

  Invoke-NativeCommand -FilePath "git" -ArgumentList @("pull", "--ff-only", "origin", "dev")
}

function Get-CommandLineForProcess {
  param([int]$ProcessId)

  $processInfo = Get-CimInstance Win32_Process -Filter "ProcessId = $ProcessId" -ErrorAction SilentlyContinue
  if ($processInfo) {
    return [string]$processInfo.CommandLine
  }

  return ""
}

function Test-OnmuBackendProcess {
  param([int]$ProcessId)

  $commandLine = Get-CommandLineForProcess -ProcessId $ProcessId
  if (-not $commandLine) {
    return $false
  }

  $normalizedRoot = [regex]::Escape([string]$RepoRoot)
  return (
    $commandLine -match "services[\\/]+api[\\/]+server\.mjs" -or
    $commandLine -match "services[\\/]+api-spring" -or
    $commandLine -match $normalizedRoot
  )
}

function Stop-OnmuBackendProcess {
  param([int]$ProcessId)

  if ($ProcessId -le 0) {
    return
  }

  $process = Get-Process -Id $ProcessId -ErrorAction SilentlyContinue
  if (-not $process) {
    Write-DeployLog "Process $ProcessId is not running."
    return
  }

  if (-not (Test-OnmuBackendProcess -ProcessId $ProcessId)) {
    $commandLine = Get-CommandLineForProcess -ProcessId $ProcessId
    throw "Refusing to stop process $ProcessId because it does not look like an ONMU backend process. CommandLine=$commandLine"
  }

  if ($DryRun) {
    Write-DeployLog "[dry-run] Stop-Process -Id $ProcessId"
    return
  }

  Write-DeployLog "Stopping ONMU backend process $ProcessId."
  Stop-Process -Id $ProcessId -Force
}

function Stop-ExistingBackend {
  if (Test-Path $PidFile) {
    $pidText = (Get-Content -LiteralPath $PidFile -Raw).Trim()
    if ($pidText -match "^\d+$") {
      Stop-OnmuBackendProcess -ProcessId ([int]$pidText)
    }

    if ($DryRun) {
      Write-DeployLog "[dry-run] Remove-Item $PidFile"
    } else {
      Remove-Item -LiteralPath $PidFile -ErrorAction SilentlyContinue
    }
  }

  $listeners = Get-NetTCPConnection -LocalPort $ApiPort -State Listen -ErrorAction SilentlyContinue |
    Select-Object -ExpandProperty OwningProcess -Unique

  foreach ($ownerProcessId in $listeners) {
    Stop-OnmuBackendProcess -ProcessId ([int]$ownerProcessId)
  }
}

function Import-KeyVaultEnvForBackend {
  $loader = Join-Path $RepoRoot "scripts\load-key-vault-env.ps1"
  if (-not $env:AZURE_KEY_VAULT_NAME) {
    Write-DeployLog "AZURE_KEY_VAULT_NAME is not set. Backend will use current environment or local defaults."
    return
  }

  if ($DryRun) {
    Write-DeployLog "[dry-run] Load API and dependency environment variables from Azure Key Vault without printing secret values."
    return
  }

  Write-DeployLog "Loading API and dependency environment variables from Azure Key Vault. Secret values are not printed."
  . $loader `
    -VaultName $env:AZURE_KEY_VAULT_NAME `
    -EnvName @(
      "DATABASE_URL",
      "POSTGRES_PASSWORD",
      "REDIS_URL",
      "OBJECT_STORAGE_ENDPOINT",
      "OBJECT_STORAGE_BUCKET",
      "MINIO_ROOT_USER",
      "MINIO_ROOT_PASSWORD",
      "KAKAO_REST_API_KEY",
      "NAVER_CLIENT_ID",
      "NAVER_CLIENT_SECRET",
      "GOOGLE_MAPS_API_KEY",
      "FCM_PROJECT_ID",
      "APNS_TEAM_ID"
    ) `
    -RequiredEnv @("DATABASE_URL") `
    -Quiet
}

function Start-LocalDependencies {
  if ($SkipDependencyStart) {
    Write-DeployLog "Skipping Docker dependency start because -SkipDependencyStart was provided."
    return
  }

  $env:POSTGRES_HOST_PORT = "15432"
  Invoke-NativeCommand -FilePath "docker" -ArgumentList @("compose", "-f", $ComposeFile, "up", "-d", "postgres", "redis", "minio")
  Invoke-NativeCommand -FilePath "docker" -ArgumentList @("compose", "-f", $ComposeFile, "ps")
}

function Start-NodeStubBackend {
  Import-KeyVaultEnvForBackend
  Start-LocalDependencies
  Stop-ExistingBackend

  $env:ONMU_ENV = if ($env:ONMU_ENV) { $env:ONMU_ENV } else { "local" }
  $env:API_HOST = $ApiHost
  $env:HOST = $ApiHost
  $env:API_PORT = [string]$ApiPort
  $env:PORT = [string]$ApiPort
  if (-not $env:ACCESS_LOG_FILE) {
    $env:ACCESS_LOG_FILE = $AccessLogFile
  }
  if (-not $env:ACCESS_LOG_ENABLED) {
    $env:ACCESS_LOG_ENABLED = "true"
  }

  if ($DryRun) {
    Write-DeployLog "[dry-run] Start node services/api/server.mjs on ${ApiHost}:${ApiPort}"
    Write-DeployLog "[dry-run] Write PID to $PidFile"
    return
  }

  Write-DeployLog "Starting Node smoke/contract stub on ${ApiHost}:${ApiPort}."
  $process = Start-Process `
    -FilePath "node" `
    -ArgumentList @("services/api/server.mjs") `
    -WorkingDirectory $RepoRoot `
    -RedirectStandardOutput $StdoutLogFile `
    -RedirectStandardError $StderrLogFile `
    -PassThru `
    -WindowStyle Hidden

  Set-Content -LiteralPath $PidFile -Value $process.Id -Encoding ASCII
  Write-DeployLog "Node stub started. PID=$($process.Id). Stdout=$StdoutLogFile Stderr=$StderrLogFile"

  Start-Sleep -Seconds 2
  $startedProcess = Get-Process -Id $process.Id -ErrorAction SilentlyContinue
  if (-not $startedProcess) {
    $stderr = if (Test-Path $StderrLogFile) { Get-Content -LiteralPath $StderrLogFile -Tail 20 } else { @() }
    throw "Node stub exited during startup. Recent stderr: $($stderr -join ' ')"
  }
}

function Test-SpringExecutableProject {
  $gradleWrapper = Join-Path $SpringDir "gradlew.bat"
  $gradleBuild = Join-Path $SpringDir "build.gradle"
  $gradleKtsBuild = Join-Path $SpringDir "build.gradle.kts"
  $mavenWrapper = Join-Path $SpringDir "mvnw.cmd"
  $mavenPom = Join-Path $SpringDir "pom.xml"

  return (
    (Test-Path $gradleWrapper) -or
    (Test-Path $gradleBuild) -or
    (Test-Path $gradleKtsBuild) -or
    (Test-Path $mavenWrapper) -or
    (Test-Path $mavenPom)
  )
}

function Set-SpringDatasourceFromDatabaseUrl {
  if (-not $env:DATABASE_URL) {
    return
  }

  $uri = [System.Uri]::new($env:DATABASE_URL)
  if ($uri.Scheme -notin @("postgres", "postgresql")) {
    throw "DATABASE_URL must use postgres or postgresql scheme for Spring runtime."
  }

  $databaseName = $uri.AbsolutePath.TrimStart("/")
  if (-not $databaseName) {
    throw "DATABASE_URL must include a database name for Spring runtime."
  }

  $port = if ($uri.Port -gt 0) { $uri.Port } else { 5432 }
  $env:SPRING_DATASOURCE_URL = "jdbc:postgresql://$($uri.Host):${port}/${databaseName}$($uri.Query)"

  if ($uri.UserInfo) {
    $parts = $uri.UserInfo.Split(":", 2)
    if ($parts.Length -ge 1 -and $parts[0]) {
      $env:SPRING_DATASOURCE_USERNAME = [System.Uri]::UnescapeDataString($parts[0])
    }
    if ($parts.Length -ge 2 -and $parts[1]) {
      $env:SPRING_DATASOURCE_PASSWORD = [System.Uri]::UnescapeDataString($parts[1])
    }
  }
}

function Set-SpringEnvironment {
  $env:ONMU_ENV = if ($env:ONMU_ENV) { $env:ONMU_ENV } else { "local" }
  $env:SERVER_ADDRESS = $ApiHost
  $env:SERVER_PORT = [string]$ApiPort
  $env:API_HOST = $ApiHost
  $env:API_PORT = [string]$ApiPort
  if (-not $env:POSTGRES_HOST_PORT) {
    $env:POSTGRES_HOST_PORT = "15432"
  }
  if (-not $env:SPRING_DATASOURCE_PASSWORD -and $env:POSTGRES_PASSWORD) {
    $env:SPRING_DATASOURCE_PASSWORD = $env:POSTGRES_PASSWORD
  }

  Set-SpringDatasourceFromDatabaseUrl
  Write-DeployLog "Spring environment prepared for ${ApiHost}:${ApiPort}. Secret values are not printed."
}

function Start-SpringBackend {
  Import-KeyVaultEnvForBackend
  Start-LocalDependencies

  if ($DryRun) {
    Stop-ExistingBackend
    Write-DeployLog "[dry-run] Check services/api-spring for Maven executable project."
    Write-DeployLog "[dry-run] Prepare SERVER_ADDRESS/SERVER_PORT and Spring datasource env without printing secret values."
    Write-DeployLog "[dry-run] services/api-spring/mvnw.cmd -DskipTests package"
    Write-DeployLog "[dry-run] java -jar services/api-spring/target/onmu-api-spring-*.jar"
    Write-DeployLog "[dry-run] Write PID to $PidFile"
    return
  }

  if (-not (Test-SpringExecutableProject)) {
    throw "Spring runtime scaffold exists, but executable Spring Boot app is not implemented yet."
  }

  $mavenWrapper = Join-Path $SpringDir "mvnw.cmd"
  $mavenPom = Join-Path $SpringDir "pom.xml"
  if (-not (Test-Path $mavenWrapper) -or -not (Test-Path $mavenPom)) {
    throw "Spring runtime currently expects Maven wrapper files at services/api-spring/mvnw.cmd and pom.xml."
  }

  Set-SpringEnvironment

  Push-Location $SpringDir
  try {
    Invoke-NativeCommand -FilePath $mavenWrapper -ArgumentList @("-DskipTests", "package")
  } finally {
    Pop-Location
  }

  Stop-ExistingBackend

  $jar = Get-ChildItem -LiteralPath (Join-Path $SpringDir "target") -Filter "onmu-api-spring-*.jar" |
    Where-Object { $_.Name -notlike "*.original" } |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1

  if (-not $jar) {
    throw "Spring Boot jar was not found after Maven package."
  }

  Write-DeployLog "Starting Spring Boot Main API on ${ApiHost}:${ApiPort}."
  $process = Start-Process `
    -FilePath "java" `
    -ArgumentList @("-jar", $jar.FullName) `
    -WorkingDirectory $SpringDir `
    -RedirectStandardOutput $StdoutLogFile `
    -RedirectStandardError $StderrLogFile `
    -PassThru `
    -WindowStyle Hidden

  Set-Content -LiteralPath $PidFile -Value $process.Id -Encoding ASCII
  Write-DeployLog "Spring Boot Main API started. PID=$($process.Id). Stdout=$StdoutLogFile Stderr=$StderrLogFile"

  Start-Sleep -Seconds 5
  $startedProcess = Get-Process -Id $process.Id -ErrorAction SilentlyContinue
  if (-not $startedProcess) {
    $stderr = if (Test-Path $StderrLogFile) { Get-Content -LiteralPath $StderrLogFile -Tail 40 } else { @() }
    throw "Spring Boot Main API exited during startup. Recent stderr: $($stderr -join ' ')"
  }
}

function New-TempJsonFile {
  param([string]$Json)

  $path = [System.IO.Path]::GetTempFileName()
  [System.IO.File]::WriteAllText($path, $Json, [System.Text.UTF8Encoding]::new($false))
  return $path
}

function Add-SmokeClientQuery {
  param([string]$Url)

  $separator = if ($Url.Contains("?")) { "&" } else { "?" }
  return "${Url}${separator}client=${Client}"
}

function Invoke-SmokeRequest {
  param(
    [string]$Method,
    [string]$Url,
    [int[]]$ExpectedStatus,
    [string]$Body
  )

  $targetUrl = Add-SmokeClientQuery -Url $Url
  $responseFile = [System.IO.Path]::GetTempFileName()
  $bodyFile = $null

  try {
    $curlArgs = @("-sS", "-o", $responseFile, "-w", "%{http_code}", "-X", $Method, $targetUrl)
    if ($Body) {
      $bodyFile = New-TempJsonFile -Json $Body
      $curlArgs += @("-H", "Content-Type: application/json", "--data-binary", "@$bodyFile")
    }

    if ($DryRun) {
      Write-DeployLog "[dry-run] curl.exe $($curlArgs -join ' ')"
      return
    }

    $statusText = & curl.exe @curlArgs
    if ($LASTEXITCODE -ne 0) {
      throw "curl failed for $Method $targetUrl"
    }

    $status = [int]$statusText
    $responseBody = [System.IO.File]::ReadAllText($responseFile, [System.Text.Encoding]::UTF8)
    if ($ExpectedStatus -notcontains $status) {
      throw "Smoke failed: $Method $targetUrl returned $status. Body=$responseBody"
    }

    Write-DeployLog "Smoke passed: $Method $targetUrl -> $status"
  } finally {
    Remove-Item -LiteralPath $responseFile -ErrorAction SilentlyContinue
    if ($bodyFile) {
      Remove-Item -LiteralPath $bodyFile -ErrorAction SilentlyContinue
    }
  }
}

function Invoke-SmokeTests {
  $base = $PublicBaseUrl.TrimEnd("/")
  Write-DeployLog "Running public smoke tests against $base with client=$Client."

  Invoke-SmokeRequest -Method "GET" -Url "$base/healthz" -ExpectedStatus @(200)
  Invoke-SmokeRequest -Method "GET" -Url "$base/readyz" -ExpectedStatus @(200)
  Invoke-SmokeRequest -Method "GET" -Url "$base/api/v1/home/summary" -ExpectedStatus @(200)

  Invoke-SmokeRequest `
    -Method "POST" `
    -Url "$base/api/v1/place-search" `
    -ExpectedStatus @(200) `
    -Body '{ "query": "카페", "groupId": "1", "planId": "101" }'

  Invoke-SmokeRequest `
    -Method "POST" `
    -Url "$base/api/v1/groups/1/votes" `
    -ExpectedStatus @(200, 201) `
    -Body '{ "voteType": "PLACE", "targetType": "PLAN", "targetId": "101", "title": "CD smoke vote", "options": ["A", "B"] }'
}

Assert-RepoRoot
$selectedRuntime = Resolve-BackendRuntime
Write-DeployLog "Selected backend runtime: $selectedRuntime"
Write-DeployLog "Runtime priority: CLI -Runtime, then ONMU_BACKEND_RUNTIME, then node-stub."
Write-DeployLog "DryRun: $DryRun"

Sync-DevBranch

switch ($selectedRuntime) {
  "node-stub" {
    Start-NodeStubBackend
  }
  "spring" {
    Start-SpringBackend
  }
}

Invoke-SmokeTests
Write-DeployLog "Windows dev backend deployment finished."
