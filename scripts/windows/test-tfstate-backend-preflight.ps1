param(
  [string]$SubscriptionName = "대한상공회의소 Data School",
  [string]$ResourceGroupName = "3dt-final-team1",
  [string]$Location = "koreacentral",
  [string]$StorageAccountName = "stonmutfstatekrc001",
  [string]$ContainerName = "tfstate"
)

$ErrorActionPreference = "Stop"

function Write-Check {
  param(
    [string]$Name,
    [string]$Status,
    [string]$Detail
  )
  Write-Host ("[{0}] {1}: {2}" -f $Status, $Name, $Detail)
}

function Invoke-AzJson {
  param([string[]]$Arguments)
  $output = & az @Arguments --only-show-errors --output json
  if ($LASTEXITCODE -ne 0) {
    throw "az command failed: az $($Arguments -join ' ')"
  }
  if ([string]::IsNullOrWhiteSpace($output)) {
    return $null
  }
  return $output | ConvertFrom-Json
}

if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
  throw "Azure CLI 'az' was not found on PATH."
}

$account = Invoke-AzJson @("account", "show")
if ($account.name -ne $SubscriptionName) {
  throw "Active Azure subscription does not match expected subscription name. Expected '$SubscriptionName'."
}
Write-Check "subscription" "OK" $SubscriptionName

$resourceGroup = Invoke-AzJson @("group", "show", "--name", $ResourceGroupName)
if ($resourceGroup.location -ne $Location) {
  throw "Resource group location mismatch. Expected '$Location'."
}
Write-Check "resource_group" "OK" ("{0} / {1}" -f $ResourceGroupName, $Location)

$nameCheck = Invoke-AzJson @("storage", "account", "check-name", "--name", $StorageAccountName)
if ($nameCheck.nameAvailable -eq $true) {
  Write-Check "storage_account_name" "OK" ("available: {0}" -f $StorageAccountName)
}
else {
  try {
    $storageAccount = Invoke-AzJson @(
      "storage", "account", "show",
      "--resource-group", $ResourceGroupName,
      "--name", $StorageAccountName
    )
  }
  catch {
    throw "Storage account name is unavailable and was not readable in the expected resource group."
  }

  if ($storageAccount.resourceGroup -ne $ResourceGroupName) {
    throw "Storage account exists outside the expected resource group."
  }
  if ($storageAccount.allowBlobPublicAccess -ne $false) {
    throw "Existing storage account allows public blob access."
  }
  if ($storageAccount.allowSharedKeyAccess -ne $false) {
    throw "Existing storage account still allows shared key access."
  }
  if ($storageAccount.minimumTlsVersion -ne "TLS1_2") {
    throw "Existing storage account minimum TLS version is not TLS1_2."
  }
  Write-Check "storage_account_name" "OK" ("existing in target resource group: {0}" -f $StorageAccountName)
}

Write-Check "container_name" "INFO" ("expected private container: {0}" -f $ContainerName)
Write-Check "data_plane_rbac" "INFO" "verify the Terraform execution principal has Storage Blob Data Contributor or equivalent before apply"
Write-Check "principal_inputs" "INFO" "actual apply plan must include approved operator or GitHub Actions principal object ids"
Write-Check "terraform_apply" "INFO" "not executed by this preflight script"
