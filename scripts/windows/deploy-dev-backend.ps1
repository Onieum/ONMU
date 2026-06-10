[CmdletBinding()]
param(
  [ValidateSet("spring")]
  [string]$Runtime,
  [ValidateSet("dev", "integration")]
  [string]$Environment = "dev",
  [switch]$DryRun,
  [int]$ApiPort = 8080,
  [string]$ApiHost = "127.0.0.1",
  [string]$PublicBaseUrl = $env:ONMU_DEV_API_BASE_URL,
  [string]$Client = "github-actions-cd",
  [int]$HealthzWaitTimeoutSeconds = 60,
  [int]$HealthzWaitIntervalSeconds = 2,
  [switch]$SkipDependencyStart,
  [switch]$SkipPublicSmoke,
  [switch]$StopOnly
)

$ErrorActionPreference = "Stop"

$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$ApiPortWasProvided = $PSBoundParameters.ContainsKey("ApiPort")
$PublicBaseUrlWasProvided = $PSBoundParameters.ContainsKey("PublicBaseUrl")
$Environment = $Environment.ToLowerInvariant()

if ($Environment -eq "integration" -and -not $ApiPortWasProvided) {
  $ApiPort = 18080
}

$LogsDir = if ($Environment -eq "integration") {
  Join-Path $RepoRoot "logs\integration"
} else {
  Join-Path $RepoRoot "logs"
}
$DeployLogFile = Join-Path $LogsDir "deploy-$Environment-backend.log"
$PidFile = Join-Path $LogsDir "$Environment-backend-api.pid"
$StdoutLogFile = Join-Path $LogsDir "$Environment-backend-api.out.log"
$StderrLogFile = Join-Path $LogsDir "$Environment-backend-api.err.log"
$AccessLogFile = Join-Path $LogsDir "api-access.log"
$ComposeFile = if ($Environment -eq "integration") {
  Join-Path $RepoRoot "infra\compose\docker-compose.integration.yml"
} else {
  Join-Path $RepoRoot "infra\compose\docker-compose.yml"
}
$SpringDir = Join-Path $RepoRoot "services\api-spring"
$RuntimeWasProvided = $PSBoundParameters.ContainsKey("Runtime")
$SecretPrefix = if ($Environment -eq "integration") { "int" } else { "dev" }
$PostgresHostPort = if ($Environment -eq "integration") { 16432 } else { 15432 }
$RedisHostPort = if ($Environment -eq "integration") { 6380 } else { 6379 }
$MinioApiPort = if ($Environment -eq "integration") { 9100 } else { 9000 }
$DatabaseName = if ($Environment -eq "integration") { "onmu_integration" } else { "onmu" }
$DatabaseUser = if ($Environment -eq "integration") { "onmu_int" } else { "onmu" }
$DefaultOnmuEnv = if ($Environment -eq "integration") { "integration" } else { "local" }
$DefaultPublicBaseUrl = if ($Environment -eq "integration") {
  if ($env:ONMU_INT_API_BASE_URL) { $env:ONMU_INT_API_BASE_URL } else { "https://int-api.onmu.cloud" }
} else {
  if ($env:ONMU_DEV_API_BASE_URL) { $env:ONMU_DEV_API_BASE_URL } else { "https://dev-api.onmu.cloud" }
}

if (-not $PublicBaseUrl -or -not $PublicBaseUrlWasProvided) {
  $PublicBaseUrl = $DefaultPublicBaseUrl
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
  } elseif ($Environment -eq "integration") {
    $candidate = "spring"
  } else {
    $candidate = "spring"
  }

  $candidate = $candidate.ToLowerInvariant()
  if ($candidate -ne "spring") {
    throw "Unsupported backend runtime '$candidate'. Windows backend deployment supports spring only."
  }

  return $candidate
}

function Assert-RepoRoot {
  Set-Location $RepoRoot

  $requiredPaths = @(
    ".git",
    "package.json",
    "services\api-spring\pom.xml",
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
    $commandLine -match "com\.onmu\.api\.OnmuApiApplication" -or
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

  $childProcesses = @(
    Get-CimInstance Win32_Process -Filter "ParentProcessId = $ProcessId" -ErrorAction SilentlyContinue
  )
  foreach ($childProcess in $childProcesses) {
    $childProcessId = [int]$childProcess.ProcessId
    if (Test-OnmuBackendProcess -ProcessId $childProcessId) {
      Stop-OnmuBackendProcess -ProcessId $childProcessId
    } else {
      Write-DeployLog "Skipping child process $childProcessId because it does not look like an ONMU backend process."
    }
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
  $envNames = @(
    "ONMU_CORS_ORIGINS",
    "DATABASE_URL",
    "POSTGRES_PASSWORD",
    "REDIS_URL",
    "OBJECT_STORAGE_ENDPOINT",
    "OBJECT_STORAGE_BUCKET",
    "MINIO_ROOT_USER",
    "MINIO_ROOT_PASSWORD",
    "ONMU_ACCESS_TOKEN_SECRET",
    "NAVER_OAUTH_CLIENT_ID",
    "NAVER_OAUTH_CLIENT_SECRET",
    "KAKAO_REST_API_KEY",
    "NAVER_SEARCH_CLIENT_ID",
    "NAVER_SEARCH_CLIENT_SECRET"
  )
  if ($Environment -eq "dev") {
    $envNames += @(
      "ONMU_DEV_CORS_ORIGINS",
      "KAKAO_REST_API_KEY",
      "NAVER_CLIENT_ID",
      "NAVER_CLIENT_SECRET",
      "GOOGLE_MAPS_API_KEY",
      "FCM_PROJECT_ID",
      "APNS_TEAM_ID"
    )
  }

  $requiredEnv = if ($Environment -eq "integration") {
    @(
      "ONMU_ACCESS_TOKEN_SECRET",
      "DATABASE_URL",
      "POSTGRES_PASSWORD"
    )
  } else {
    @("ONMU_ACCESS_TOKEN_SECRET", "DATABASE_URL")
  }

  if (-not $env:AZURE_KEY_VAULT_NAME) {
    $missingRequiredEnv = @($requiredEnv | Where-Object { -not (Get-Item -Path "Env:$_" -ErrorAction SilentlyContinue) })
    if ($missingRequiredEnv.Count -gt 0) {
      throw "AZURE_KEY_VAULT_NAME is not set and required env vars are missing: $($missingRequiredEnv -join ', '). Secret values are not printed."
    }

    Write-DeployLog "AZURE_KEY_VAULT_NAME is not set. Using already configured required environment variables. Secret values are not printed."
    return
  }

  if ($DryRun) {
    Write-DeployLog "[dry-run] Load API and dependency environment variables from Azure Key Vault without printing secret values."
    return
  }

  Write-DeployLog "Loading API and dependency environment variables from Azure Key Vault. Secret values are not printed."

  . $loader `
    -VaultName $env:AZURE_KEY_VAULT_NAME `
    -SecretPrefix $SecretPrefix `
    -EnvName $envNames `
    -RequiredEnv $requiredEnv `
    -Quiet
}

function Start-LocalDependencies {
  if ($SkipDependencyStart) {
    Write-DeployLog "Skipping Docker dependency start because -SkipDependencyStart was provided."
    return
  }

  if ($Environment -eq "integration") {
    $env:INT_POSTGRES_HOST_PORT = [string]$PostgresHostPort
    $env:INT_POSTGRES_DB = $DatabaseName
    $env:INT_POSTGRES_USER = $DatabaseUser
    $env:INT_REDIS_HOST_PORT = [string]$RedisHostPort
    $env:INT_MINIO_API_HOST_PORT = [string]$MinioApiPort
    $env:INT_MINIO_CONSOLE_HOST_PORT = "9101"
    if ($env:POSTGRES_PASSWORD -and -not $env:INT_POSTGRES_PASSWORD) {
      $env:INT_POSTGRES_PASSWORD = $env:POSTGRES_PASSWORD
    }
    if (-not $env:INT_POSTGRES_PASSWORD) {
      $env:INT_POSTGRES_PASSWORD = "onmu-integration-local-only"
    }
    if ($env:MINIO_ROOT_USER -and -not $env:INT_MINIO_ROOT_USER) {
      $env:INT_MINIO_ROOT_USER = $env:MINIO_ROOT_USER
    }
    if (-not $env:INT_MINIO_ROOT_USER) {
      $env:INT_MINIO_ROOT_USER = "onmu-int"
    }
    if ($env:MINIO_ROOT_PASSWORD -and -not $env:INT_MINIO_ROOT_PASSWORD) {
      $env:INT_MINIO_ROOT_PASSWORD = $env:MINIO_ROOT_PASSWORD
    }
    if (-not $env:INT_MINIO_ROOT_PASSWORD) {
      $env:INT_MINIO_ROOT_PASSWORD = "onmu-integration-local-only"
    }
  } else {
    $env:POSTGRES_HOST_PORT = [string]$PostgresHostPort
  }
  Invoke-NativeCommand -FilePath "docker" -ArgumentList @("compose", "-f", $ComposeFile, "up", "-d", "postgres", "redis", "minio")
  Invoke-NativeCommand -FilePath "docker" -ArgumentList @("compose", "-f", $ComposeFile, "ps")
}

function Get-LocalProbeHost {
  if ($ApiHost -in @("0.0.0.0", "::")) {
    return "127.0.0.1"
  }

  return $ApiHost
}

function Wait-BackendHealthz {
  param(
    [int]$ProcessId,
    [string]$RuntimeName
  )

  $probeHost = Get-LocalProbeHost
  $healthzUrl = "http://${probeHost}:${ApiPort}/healthz"

  if ($DryRun) {
    Write-DeployLog "[dry-run] Wait up to ${HealthzWaitTimeoutSeconds}s for $healthzUrl after $RuntimeName start."
    return
  }

  $deadline = (Get-Date).AddSeconds($HealthzWaitTimeoutSeconds)
  $attempt = 0
  while ((Get-Date) -lt $deadline) {
    $attempt += 1

    if ($ProcessId -gt 0 -and -not (Get-Process -Id $ProcessId -ErrorAction SilentlyContinue)) {
      throw "$RuntimeName exited before /healthz became ready. Check stdout=$StdoutLogFile stderr=$StderrLogFile"
    }

    try {
      $response = Invoke-WebRequest -Uri $healthzUrl -Method GET -UseBasicParsing -TimeoutSec 3
      if ([int]$response.StatusCode -eq 200) {
        Write-DeployLog "$RuntimeName local healthz is ready after $attempt attempt(s)."
        return
      }

      Write-DeployLog "$RuntimeName local healthz attempt $attempt returned HTTP $($response.StatusCode)."
    } catch {
      Write-DeployLog "$RuntimeName local healthz attempt $attempt not ready: $($_.Exception.GetType().Name)"
    }

    Start-Sleep -Seconds $HealthzWaitIntervalSeconds
  }

  throw "$RuntimeName did not pass local /healthz within ${HealthzWaitTimeoutSeconds}s. Check stdout=$StdoutLogFile stderr=$StderrLogFile"
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
  $env:ONMU_ENV = if ($env:ONMU_ENV) { $env:ONMU_ENV } else { $DefaultOnmuEnv }
  if ($Environment -eq "integration" -and -not $env:SPRING_PROFILES_ACTIVE) {
    $env:SPRING_PROFILES_ACTIVE = "integration"
  }
  $env:SERVER_ADDRESS = $ApiHost
  $env:SERVER_PORT = [string]$ApiPort
  $env:API_HOST = $ApiHost
  $env:API_PORT = [string]$ApiPort
  if (-not $env:ONMU_ACCESS_LOG_PATH) {
    $env:ONMU_ACCESS_LOG_PATH = $AccessLogFile
  }
  if (-not $env:POSTGRES_HOST_PORT) {
    $env:POSTGRES_HOST_PORT = [string]$PostgresHostPort
  }
  if ($Environment -eq "integration") {
    if (-not $env:SPRING_DATASOURCE_URL -and -not $env:DATABASE_URL) {
      $env:SPRING_DATASOURCE_URL = "jdbc:postgresql://localhost:${PostgresHostPort}/${DatabaseName}"
    }
    if (-not $env:SPRING_DATASOURCE_USERNAME) {
      $env:SPRING_DATASOURCE_USERNAME = $DatabaseUser
    }
    if (-not $env:REDIS_URL) {
      $env:REDIS_URL = "redis://localhost:${RedisHostPort}/0"
    }
    if (-not $env:OBJECT_STORAGE_ENDPOINT -and -not $env:MINIO_ENDPOINT) {
      $env:OBJECT_STORAGE_ENDPOINT = "http://localhost:${MinioApiPort}"
    }
    if (-not $env:OBJECT_STORAGE_BUCKET) {
      $env:OBJECT_STORAGE_BUCKET = "onmu-integration"
    }
  }
  if (-not $env:SPRING_DATASOURCE_PASSWORD -and $env:POSTGRES_PASSWORD) {
    $env:SPRING_DATASOURCE_PASSWORD = $env:POSTGRES_PASSWORD
  }
  if ($Environment -eq "integration" -and -not $env:SPRING_DATASOURCE_PASSWORD) {
    if ($env:INT_POSTGRES_PASSWORD) {
      $env:SPRING_DATASOURCE_PASSWORD = $env:INT_POSTGRES_PASSWORD
    } else {
      $env:SPRING_DATASOURCE_PASSWORD = "onmu-integration-local-only"
    }
  }

  Set-SpringDatasourceFromDatabaseUrl
  Write-DeployLog "Spring environment prepared for $Environment on ${ApiHost}:${ApiPort}. Secret values are not printed."
}

function Clear-SpringGeneratedMigrationClasses {
  $migrationClassesDir = Join-Path $SpringDir "target\classes\db\migration"
  if ($DryRun) {
    Write-DeployLog "[dry-run] Remove stale generated migration classes at $migrationClassesDir"
    return
  }

  if (Test-Path $migrationClassesDir) {
    Write-DeployLog "Removing stale generated migration classes at $migrationClassesDir."
    Remove-Item -LiteralPath $migrationClassesDir -Recurse -Force
  }
}

function Start-SpringBackend {
  Import-KeyVaultEnvForBackend
  Start-LocalDependencies

  if ($DryRun) {
    Stop-ExistingBackend
    Write-DeployLog "[dry-run] Check services/api-spring for Maven executable project."
    Write-DeployLog "[dry-run] Prepare SERVER_ADDRESS/SERVER_PORT and Spring datasource env without printing secret values."
    if ($Environment -eq "integration") {
      Clear-SpringGeneratedMigrationClasses
      Write-DeployLog "[dry-run] services/api-spring/mvnw.cmd -DskipTests spring-boot:run"
    } else {
      Write-DeployLog "[dry-run] services/api-spring/mvnw.cmd -DskipTests clean package"
      Write-DeployLog "[dry-run] java -jar services/api-spring/target/onmu-api-spring-*.jar"
    }
    Write-DeployLog "[dry-run] Write PID to $PidFile"
    Wait-BackendHealthz -ProcessId 0 -RuntimeName "Spring Boot Main API"
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
  Stop-ExistingBackend

  if ($Environment -eq "integration") {
    Clear-SpringGeneratedMigrationClasses
    Write-DeployLog "Starting integration Spring Boot Main API with Maven spring-boot:run on ${ApiHost}:${ApiPort}."
    $process = Start-Process `
      -FilePath $mavenWrapper `
      -ArgumentList @("-DskipTests", "spring-boot:run") `
      -WorkingDirectory $SpringDir `
      -RedirectStandardOutput $StdoutLogFile `
      -RedirectStandardError $StderrLogFile `
      -PassThru `
      -WindowStyle Hidden

    Set-Content -LiteralPath $PidFile -Value $process.Id -Encoding ASCII
    Write-DeployLog "Integration Spring Boot Main API started via Maven. PID=$($process.Id). Stdout=$StdoutLogFile Stderr=$StderrLogFile"

    Wait-BackendHealthz -ProcessId $process.Id -RuntimeName "Spring Boot Main API"
    return
  }

  Push-Location $SpringDir
  try {
    Invoke-NativeCommand -FilePath $mavenWrapper -ArgumentList @("-DskipTests", "clean", "package")
  } finally {
    Pop-Location
  }

  $jar = Get-ChildItem -LiteralPath (Join-Path $SpringDir "target") -Filter "onmu-api-spring-*.jar" |
    Where-Object { $_.Name -notlike "*.original" -and $_.Name -notlike "*-integration.jar" } |
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

  Wait-BackendHealthz -ProcessId $process.Id -RuntimeName "Spring Boot Main API"
}

function New-TempJsonFile {
  param([string]$Json)

  $path = [System.IO.Path]::GetTempFileName()
  [System.IO.File]::WriteAllText($path, $Json, [System.Text.UTF8Encoding]::new($false))
  return $path
}

$script:SmokeBearerToken = ""

function ConvertTo-Base64Url {
  param([byte[]]$Bytes)

  return [Convert]::ToBase64String($Bytes).TrimEnd("=").Replace("+", "-").Replace("/", "_")
}

function New-SmokeAccessToken {
  if (-not $env:ONMU_ACCESS_TOKEN_SECRET) {
    throw "ONMU_ACCESS_TOKEN_SECRET is required to generate public smoke JWT. Secret values are not printed."
  }

  $secret = $env:ONMU_ACCESS_TOKEN_SECRET
  $issuer = if ($env:ONMU_AUTH_ISSUER) { $env:ONMU_AUTH_ISSUER } else { "onmu-api" }
  $audience = if ($env:ONMU_AUTH_AUDIENCE) { $env:ONMU_AUTH_AUDIENCE } else { "onmu-mobile" }
  $subject = if ($env:ONMU_SMOKE_USER_ID) { $env:ONMU_SMOKE_USER_ID } else { "user-me" }
  $now = [DateTimeOffset]::UtcNow

  $header = [ordered]@{
    alg = "HS256"
    typ = "JWT"
  } | ConvertTo-Json -Compress
  $payload = [ordered]@{
    iss = $issuer
    aud = $audience
    sub = $subject
    typ = "access"
    iat = $now.ToUnixTimeSeconds()
    exp = $now.AddMinutes(15).ToUnixTimeSeconds()
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

  Write-DeployLog "Generated short-lived access token for public authenticated smoke. Token value is not printed."
  return "$signingInput.$signaturePart"
}

function Get-SmokeBearerToken {
  if ($script:SmokeBearerToken) {
    return $script:SmokeBearerToken
  }

  if ($env:ONMU_SMOKE_BEARER_TOKEN) {
    $script:SmokeBearerToken = $env:ONMU_SMOKE_BEARER_TOKEN
  } else {
    $script:SmokeBearerToken = New-SmokeAccessToken
  }

  return $script:SmokeBearerToken
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
    [string]$Body,
    [switch]$UseApiAuth
  )

  $targetUrl = Add-SmokeClientQuery -Url $Url
  $responseFile = [System.IO.Path]::GetTempFileName()
  $bodyFile = $null

  try {
    $curlArgs = @("-sS", "-o", $responseFile, "-w", "%{http_code}", "-X", $Method, $targetUrl)
    $displayArgs = @("-sS", "-o", $responseFile, "-w", "%{http_code}", "-X", $Method, $targetUrl)
    if ($UseApiAuth) {
      $smokeBearerToken = Get-SmokeBearerToken
      if ($smokeBearerToken) {
        $curlArgs += @("-H", "Authorization: Bearer $smokeBearerToken")
      }
      $displayArgs += @("-H", "Authorization: Bearer <redacted>")
    }

    if ($Body) {
      $bodyFile = New-TempJsonFile -Json $Body
      $curlArgs += @("-H", "Content-Type: application/json", "--data-binary", "@$bodyFile")
      $displayArgs += @("-H", "Content-Type: application/json", "--data-binary", "@$bodyFile")
    }

    if ($DryRun) {
      Write-DeployLog "[dry-run] curl.exe $($displayArgs -join ' ')"
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

function Invoke-CorsPreflightSmoke {
  $base = $PublicBaseUrl.TrimEnd("/")
  $origin = if ($env:ONMU_SMOKE_CORS_ORIGIN) { $env:ONMU_SMOKE_CORS_ORIGIN } else { $base }
  $targetUrl = Add-SmokeClientQuery -Url "$base/api/v1/home/summary"
  $responseFile = [System.IO.Path]::GetTempFileName()

  try {
    $curlArgs = @(
      "-sS",
      "-o",
      $responseFile,
      "-w",
      "%{http_code}",
      "-X",
      "OPTIONS",
      $targetUrl,
      "-H",
      "Origin: $origin",
      "-H",
      "Access-Control-Request-Method: GET",
      "-H",
      "Access-Control-Request-Headers: Authorization, Content-Type"
    )

    if ($DryRun) {
      Write-DeployLog "[dry-run] curl.exe $($curlArgs -join ' ')"
      return
    }

    $statusText = & curl.exe @curlArgs
    if ($LASTEXITCODE -ne 0) {
      throw "curl failed for CORS preflight $targetUrl"
    }

    $status = [int]$statusText
    if (@(200, 204) -notcontains $status) {
      $responseBody = [System.IO.File]::ReadAllText($responseFile, [System.Text.Encoding]::UTF8)
      throw "CORS preflight failed: OPTIONS $targetUrl returned $status. Body=$responseBody"
    }

    Write-DeployLog "Smoke passed: OPTIONS $targetUrl -> $status"
  } finally {
    Remove-Item -LiteralPath $responseFile -ErrorAction SilentlyContinue
  }
}

function Invoke-SmokeTests {
  $base = $PublicBaseUrl.TrimEnd("/")
  Write-DeployLog "Running public smoke tests against $base with client=$Client."
  $useApiAuth = $true

  Invoke-SmokeRequest -Method "GET" -Url "$base/healthz" -ExpectedStatus @(200)
  Invoke-SmokeRequest -Method "GET" -Url "$base/readyz" -ExpectedStatus @(200)
  if ($useApiAuth) {
    Invoke-SmokeRequest -Method "GET" -Url "$base/api/v1/home/summary" -ExpectedStatus @(401)
    Invoke-CorsPreflightSmoke
  }
  Invoke-SmokeRequest -Method "GET" -Url "$base/api/v1/home/summary" -ExpectedStatus @(200) -UseApiAuth:$useApiAuth
  Invoke-SmokeRequest -Method "GET" -Url "$base/api/v1/groups/1/plans/101/place-candidates" -ExpectedStatus @(200) -UseApiAuth:$useApiAuth

  Invoke-SmokeRequest `
    -Method "POST" `
    -Url "$base/api/v1/place-search" `
    -ExpectedStatus @(200) `
    -Body '{ "query": "카페", "groupId": "1", "planId": "101" }' `
    -UseApiAuth:$useApiAuth

  Invoke-SmokeRequest `
    -Method "POST" `
    -Url "$base/api/v1/groups/1/votes" `
    -ExpectedStatus @(200, 201) `
    -Body '{ "voteType": "PLACE", "targetType": "PLAN", "targetId": "101", "title": "CD smoke vote", "options": ["A", "B"] }' `
    -UseApiAuth:$useApiAuth

  Invoke-SmokeRequest `
    -Method "POST" `
    -Url "$base/api/v1/groups/1/plans/101/settlements/preview" `
    -ExpectedStatus @(200) `
    -Body '{ "items": [{ "title": "Coffee", "amount": 12000, "payerName": "Jimin", "targetNames": ["Jimin", "Minsu"] }] }' `
    -UseApiAuth:$useApiAuth
}

Assert-RepoRoot
$selectedRuntime = Resolve-BackendRuntime
Write-DeployLog "Selected deploy environment: $Environment"
Write-DeployLog "Selected backend runtime: $selectedRuntime"
Write-DeployLog "Runtime priority: CLI -Runtime, then ONMU_BACKEND_RUNTIME, then environment default."
Write-DeployLog "Public base URL: $PublicBaseUrl"
Write-DeployLog "Logs directory: $LogsDir"
Write-DeployLog "DryRun: $DryRun"
Write-DeployLog "StopOnly: $StopOnly"

if ($StopOnly) {
  Stop-ExistingBackend
  Write-DeployLog "Windows $Environment backend stop finished."
  return
}

if ($Environment -eq "dev") {
  Sync-DevBranch
} else {
  Write-DeployLog "Skipping git dev branch sync for integration deployment; using current checkout."
}

Start-SpringBackend

if ($SkipPublicSmoke) {
  Write-DeployLog "Skipping public smoke tests because -SkipPublicSmoke was provided."
} else {
  Invoke-SmokeTests
}
Write-DeployLog "Windows $Environment backend deployment finished."
