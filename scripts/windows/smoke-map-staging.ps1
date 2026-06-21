param(
  [string]$BaseUrl = "https://staging-api.onmu.cloud",
  [string]$AccessToken = $env:ONMU_STAGING_ACCESS_TOKEN,
  [Parameter(Mandatory = $true)]
  [string]$GroupId,
  [Parameter(Mandatory = $true)]
  [string]$PlanId,
  [string]$Query = "성수",
  [string]$Category = "음식점",
  [string]$Filter = "",
  [double]$Latitude = 37.5446,
  [double]$Longitude = 127.0557,
  [int]$Radius = 1500,
  [double]$South = 37.50,
  [double]$West = 126.98,
  [double]$North = 37.59,
  [double]$East = 127.11,
  [int]$ClusterZoom = 13,
  [int]$PointZoom = 16,
  [switch]$IncludeRoute
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
    [ValidateSet("GET", "POST")]
    [string]$Method,

    [Parameter(Mandatory = $true)]
    [string]$Path,

    [object]$Body = $null,

    [switch]$Authenticated
  )

  $uri = "$root$Path"
  $params = @{
    Method = $Method
    Uri = $uri
    ContentType = "application/json"
  }
  if ($Authenticated) {
    $params.Headers = $headers
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

function Count-Items {
  param([object]$Value)
  if ($null -eq $Value) {
    return 0
  }
  return @($Value).Count
}

if ([string]::IsNullOrWhiteSpace($BaseUrl)) {
  Exit-SanitizedFailure -Step "parameter-validation" -ErrorType "missing_base_url" -ExitCode 2
}

if ([string]::IsNullOrWhiteSpace($AccessToken)) {
  Exit-SanitizedFailure -Step "parameter-validation" -ErrorType "missing_access_token" -ExitCode 2
}

if ([string]::IsNullOrWhiteSpace($GroupId) -or [string]::IsNullOrWhiteSpace($PlanId)) {
  Exit-SanitizedFailure -Step "parameter-validation" -ErrorType "missing_group_or_plan" -ExitCode 2
}

if ($South -ge $North -or $West -ge $East) {
  Exit-SanitizedFailure -Step "parameter-validation" -ErrorType "invalid_bounds" -ExitCode 2
}

$root = $BaseUrl.TrimEnd("/")
$headers = @{
  Authorization = "Bearer $AccessToken"
}

$null = Invoke-OnmuJson -Step "healthz" -Method GET -Path "/healthz"
Write-Step -Name "healthz" -Fields @{
  ok = $true
  status = "ok"
}

$null = Invoke-OnmuJson -Step "readyz" -Method GET -Path "/readyz"
Write-Step -Name "readyz" -Fields @{
  ok = $true
  status = "ok"
}

$placeSearchBody = @{
  groupId = $GroupId
  planId = $PlanId
  query = $Query
  category = $Category
  lat = $Latitude
  lng = $Longitude
  radius = $Radius
}

$firstSearch = Invoke-OnmuJson -Step "place-search-first" -Method POST -Path "/api/v1/place-search" -Body $placeSearchBody -Authenticated
Write-Step -Name "place-search-first" -Fields @{
  ok = $true
  status = "ok"
  resultCount = Count-Items $firstSearch.results
  coordinateCount = $firstSearch.coordinate_count
  providerCounts = $firstSearch.provider_counts
  sourceCounts = $firstSearch.source_counts
}

$secondSearch = Invoke-OnmuJson -Step "place-search-second" -Method POST -Path "/api/v1/place-search" -Body $placeSearchBody -Authenticated
Write-Step -Name "place-search-second" -Fields @{
  ok = $true
  status = "ok"
  resultCount = Count-Items $secondSearch.results
  coordinateCount = $secondSearch.coordinate_count
  providerCounts = $secondSearch.provider_counts
  sourceCounts = $secondSearch.source_counts
  sameCountAsFirst = ((Count-Items $secondSearch.results) -eq (Count-Items $firstSearch.results))
}

$catalogBaseBody = @{
  groupId = $GroupId
  planId = $PlanId
  category = $Category
  query = $Query
  bounds = @{
    south = $South
    west = $West
    north = $North
    east = $East
  }
}
if (-not [string]::IsNullOrWhiteSpace($Filter)) {
  $catalogBaseBody.filter = $Filter
}

$clusterBody = $catalogBaseBody.Clone()
$clusterBody.zoom = $ClusterZoom
$clusters = Invoke-OnmuJson -Step "map-points-clusters" -Method POST -Path "/api/v1/map-points" -Body $clusterBody -Authenticated
Write-Step -Name "map-points-clusters" -Fields @{
  ok = $true
  status = "ok"
  mode = $clusters.mode
  clusterCount = $clusters.cluster_count
  pointCount = $clusters.point_count
  schemaVersion = $clusters.schema_version
}

$pointBody = $catalogBaseBody.Clone()
$pointBody.zoom = $PointZoom
$points = Invoke-OnmuJson -Step "map-points-points" -Method POST -Path "/api/v1/map-points" -Body $pointBody -Authenticated
Write-Step -Name "map-points-points" -Fields @{
  ok = $true
  status = "ok"
  mode = $points.mode
  clusterCount = $points.cluster_count
  pointCount = $points.point_count
  schemaVersion = $points.schema_version
}

if ($IncludeRoute) {
  $routeBody = @{
    groupId = $GroupId
    planId = $PlanId
    travelMode = "walk"
  }
  $route = Invoke-OnmuJson -Step "route-recommendation" -Method POST -Path "/api/v1/routes/recommend" -Body $routeBody -Authenticated
  Write-Step -Name "route-recommendation" -Fields @{
    ok = $true
    status = "ok"
    provider = $route.provider
    providerIsLive = ($route.provider -ne "dev-mock")
    stopCount = Count-Items $route.stops
    geometryCount = Count-Items $route.geometry
    distancePresent = ($null -ne $route.distanceMeters)
    durationPresent = ($null -ne $route.durationSeconds)
  }
} else {
  Write-Step -Name "route-recommendation" -Fields @{
    ok = $true
    status = "skipped"
  }
}

Write-Step -Name "secret-hygiene" -Fields @{
  ok = $true
  status = "ok"
  authorizationPrinted = $false
  rawTokenPrinted = $false
  rawBodyPrinted = $false
  rawProviderBodyPrinted = $false
  rawRedisValuePrinted = $false
}
