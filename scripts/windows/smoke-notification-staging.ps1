param(
  [string]$BaseUrl = "https://staging-api.onmu.cloud",
  [string]$AccessToken = $env:ONMU_STAGING_ACCESS_TOKEN,
  [string]$SyntheticPushToken = $env:ONMU_STAGING_SYNTHETIC_PUSH_TOKEN,
  [switch]$IncludeReadAll
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "lib\utf8.ps1")
Set-OnmuUtf8Console

if ([string]::IsNullOrWhiteSpace($AccessToken)) {
  throw "ONMU_STAGING_ACCESS_TOKEN 환경변수 또는 -AccessToken 값을 지정해야 합니다. 값은 출력하지 않습니다."
}

if ([string]::IsNullOrWhiteSpace($SyntheticPushToken)) {
  $SyntheticPushToken = "synthetic-dev-token-" + [Guid]::NewGuid().ToString("N")
}

$root = $BaseUrl.TrimEnd("/")
$headers = @{
  Authorization = "Bearer $AccessToken"
}

function Invoke-OnmuJson {
  param(
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
  return Invoke-RestMethod @params
}

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

$notifications = Invoke-OnmuJson -Method GET -Path "/api/v1/notifications?limit=10"
$items = @($notifications)
$unreadBefore = Invoke-OnmuJson -Method GET -Path "/api/v1/notifications/unread-count"

Write-Step -Name "notification-list" -Fields @{
  status = "ok"
  count = $items.Count
  unreadCount = $unreadBefore.unreadCount
}

if ($items.Count -gt 0) {
  $first = $items[0]
  $readResponse = Invoke-OnmuJson -Method PUT -Path "/api/v1/notifications/$($first.id)/read"
  $unreadAfterRead = Invoke-OnmuJson -Method GET -Path "/api/v1/notifications/unread-count"
  Write-Step -Name "notification-read-one" -Fields @{
    status = "ok"
    notificationType = $readResponse.notificationType
    read = $readResponse.isRead
    unreadCount = $unreadAfterRead.unreadCount
  }
} else {
  Write-Step -Name "notification-read-one" -Fields @{
    status = "skipped_no_notifications"
  }
}

if ($IncludeReadAll) {
  $readAll = Invoke-OnmuJson -Method PUT -Path "/api/v1/notifications/read-all"
  $unreadAfterReadAll = Invoke-OnmuJson -Method GET -Path "/api/v1/notifications/unread-count"
  Write-Step -Name "notification-read-all" -Fields @{
    status = "ok"
    updatedCount = $readAll.updatedCount
    unreadCount = $unreadAfterReadAll.unreadCount
  }
} else {
  Write-Step -Name "notification-read-all" -Fields @{
    status = "skipped_requires_fixture_or_dedicated_user"
  }
}

$preferences = Invoke-OnmuJson -Method GET -Path "/api/v1/notification-preferences"
Write-Step -Name "notification-preferences" -Fields @{
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

$register = Invoke-OnmuJson -Method POST -Path "/api/v1/devices/push-token" -Body $pushBody
Write-Step -Name "push-token-register" -Fields @{
  status = $register.status
  provider = $register.provider
  platform = $register.platform
  registered = $register.registered
  tokenLast4Present = -not [string]::IsNullOrWhiteSpace($register.tokenLast4)
}

$deactivate = Invoke-OnmuJson -Method DELETE -Path "/api/v1/devices/push-token" -Body $pushBody
Write-Step -Name "push-token-deactivate" -Fields @{
  status = $deactivate.status
  provider = $deactivate.provider
  platform = $deactivate.platform
  registered = $deactivate.registered
  tokenLast4Present = -not [string]::IsNullOrWhiteSpace($deactivate.tokenLast4)
}

Write-Step -Name "secret-hygiene" -Fields @{
  status = "ok"
  authorizationPrinted = $false
  rawTokenPrinted = $false
  rawBodyPrinted = $false
}
