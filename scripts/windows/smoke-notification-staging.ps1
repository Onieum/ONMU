param(
  [string]$BaseUrl = "https://staging-api.onmu.cloud",
  [string]$AccessToken = $env:ONMU_STAGING_ACCESS_TOKEN,
  [string]$SyntheticPushToken = $env:ONMU_STAGING_SYNTHETIC_PUSH_TOKEN,
  [switch]$IncludeReadOne,
  [string]$NotificationId,
  [switch]$IncludeReadAll
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "lib\utf8.ps1")
Set-OnmuUtf8Console

function Write-Step {
  param(
    [string]$Name,
    [hashtable]$Fields
  )

  $line = [ordered]@{ step = $Name }
  foreach ($key in $Fields.Keys) {
    $line[$key] = $Fields[$key]
  }
  Write-Output ($line | ConvertTo-Json -Compress)
}

function Exit-SanitizedFailure {
  param(
    [string]$Step,
    [string]$ErrorType,
    [Nullable[int]]$StatusCode = $null,
    [int]$ExitCode = 1
  )

  $fields = @{
    ok = $false
    status = "failed"
    errorType = $ErrorType
  }
  if ($null -ne $StatusCode) {
    $fields.statusCode = $StatusCode
  }
  Write-Step -Name $Step -Fields $fields
  exit $ExitCode
}

function Invoke-OnmuJson {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Step,

    [Parameter(Mandatory = $true)]
    [ValidateSet("GET", "PUT", "POST", "DELETE")]
    [string]$Method,

    [Parameter(Mandatory = $true)]
    [string]$Path,

    [object]$Body = $null
  )

  $uri = "$root$Path"
  $params = @{
    Method = $Method
    Uri = $uri
    Headers = $headers
    ContentType = "application/json"
  }
  if ($null -ne $Body) {
    $params.Body = ($Body | ConvertTo-Json -Depth 8 -Compress)
  }
  try {
    return Invoke-RestMethod @params
  } catch {
    $statusCode = $null
    if ($null -ne $_.Exception.Response -and $null -ne $_.Exception.Response.StatusCode) {
      $statusCode = [int]$_.Exception.Response.StatusCode
    }
    Exit-SanitizedFailure -Step $Step -StatusCode $statusCode -ErrorType $_.Exception.GetType().Name
  }
}

if ([string]::IsNullOrWhiteSpace($BaseUrl)) {
  Exit-SanitizedFailure -Step "parameter-validation" -ErrorType "missing_base_url" -ExitCode 2
}

if ([string]::IsNullOrWhiteSpace($AccessToken)) {
  Exit-SanitizedFailure -Step "parameter-validation" -ErrorType "missing_access_token" -ExitCode 2
}

if ([string]::IsNullOrWhiteSpace($SyntheticPushToken)) {
  $SyntheticPushToken = "synthetic-dev-token-" + [Guid]::NewGuid().ToString("N")
}

if ($SyntheticPushToken.Trim().Length -lt 8) {
  Exit-SanitizedFailure -Step "parameter-validation" -ErrorType "invalid_synthetic_push_token" -ExitCode 2
}

$targetNotificationId = $NotificationId
if (-not [string]::IsNullOrWhiteSpace($targetNotificationId)) {
  $parsedNotificationId = [Guid]::Empty
  if (-not [Guid]::TryParse($targetNotificationId, [ref]$parsedNotificationId)) {
    Exit-SanitizedFailure -Step "parameter-validation" -ErrorType "invalid_notification_id" -ExitCode 2
  }
}

$root = $BaseUrl.TrimEnd("/")
$headers = @{
  Authorization = "Bearer $AccessToken"
}

$notifications = Invoke-OnmuJson -Step "notification-list" -Method GET -Path "/api/v1/notifications?limit=10"
$items = @($notifications)
$unreadBefore = Invoke-OnmuJson -Step "notification-unread-count" -Method GET -Path "/api/v1/notifications/unread-count"

Write-Step -Name "notification-list" -Fields @{
  ok = $true
  status = "ok"
  count = $items.Count
  unreadCount = $unreadBefore.unreadCount
}

if ($IncludeReadOne -or -not [string]::IsNullOrWhiteSpace($targetNotificationId)) {
  if ([string]::IsNullOrWhiteSpace($targetNotificationId)) {
    if ($items.Count -gt 0) {
      $targetNotificationId = $items[0].id
    } else {
      Write-Step -Name "notification-read-one" -Fields @{
        ok = $true
        status = "skipped_no_notifications"
      }
    }
  }
  if (-not [string]::IsNullOrWhiteSpace($targetNotificationId)) {
    $readResponse = Invoke-OnmuJson -Step "notification-read-one" -Method PUT -Path "/api/v1/notifications/$targetNotificationId/read"
    $unreadAfterRead = Invoke-OnmuJson -Step "notification-unread-count-after-read-one" -Method GET -Path "/api/v1/notifications/unread-count"
    Write-Step -Name "notification-read-one" -Fields @{
      ok = $true
      status = "ok"
      notificationType = $readResponse.notificationType
      read = $readResponse.isRead
      unreadCount = $unreadAfterRead.unreadCount
    }
  }
} else {
  Write-Step -Name "notification-read-one" -Fields @{
    ok = $true
    status = "skipped_requires_include_read_one_or_notification_id"
  }
}

if ($IncludeReadAll) {
  $readAll = Invoke-OnmuJson -Step "notification-read-all" -Method PUT -Path "/api/v1/notifications/read-all"
  $unreadAfterReadAll = Invoke-OnmuJson -Step "notification-unread-count-after-read-all" -Method GET -Path "/api/v1/notifications/unread-count"
  Write-Step -Name "notification-read-all" -Fields @{
    ok = $true
    status = "ok"
    updatedCount = $readAll.updatedCount
    unreadCount = $unreadAfterReadAll.unreadCount
  }
} else {
  Write-Step -Name "notification-read-all" -Fields @{
    ok = $true
    status = "skipped_requires_fixture_or_dedicated_user"
  }
}

$preferences = Invoke-OnmuJson -Step "notification-preferences" -Method GET -Path "/api/v1/notification-preferences"
Write-Step -Name "notification-preferences" -Fields @{
  ok = $true
  status = "ok"
  count = @($preferences.preferences).Count
}

$pushBody = @{
  provider = "dev"
  token = $SyntheticPushToken
  platform = "android"
  appVersion = "staging-smoke"
  osVersion = "android-smoke"
  deviceLabel = "notification-smoke"
  deviceFingerprintHash = "notification-smoke-synthetic"
}

$register = Invoke-OnmuJson -Step "push-token-register" -Method POST -Path "/api/v1/devices/push-token" -Body $pushBody
Write-Step -Name "push-token-register" -Fields @{
  ok = $true
  status = $register.status
  provider = $register.provider
  platform = $register.platform
  registered = $register.registered
  tokenLast4Present = -not [string]::IsNullOrWhiteSpace($register.tokenLast4)
}

$deactivate = Invoke-OnmuJson -Step "push-token-deactivate" -Method DELETE -Path "/api/v1/devices/push-token" -Body $pushBody
Write-Step -Name "push-token-deactivate" -Fields @{
  ok = $true
  status = $deactivate.status
  provider = $deactivate.provider
  platform = $deactivate.platform
  registered = $deactivate.registered
  tokenLast4Present = -not [string]::IsNullOrWhiteSpace($deactivate.tokenLast4)
}

Write-Step -Name "secret-hygiene" -Fields @{
  ok = $true
  status = "ok"
  authorizationPrinted = $false
  rawTokenPrinted = $false
  rawBodyPrinted = $false
}
