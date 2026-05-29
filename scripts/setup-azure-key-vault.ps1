[CmdletBinding()]
param(
  [string]$ResourceGroup = $env:AZURE_RESOURCE_GROUP,
  [string]$Location = $(if ($env:AZURE_LOCATION) { $env:AZURE_LOCATION } else { "koreacentral" }),
  [string]$VaultName = $env:AZURE_KEY_VAULT_NAME,
  [string]$WorkspaceName = $env:AZURE_LOG_ANALYTICS_WORKSPACE,
  [int]$LogRetentionDays = 30,
  [switch]$SkipSelfSecretOfficerRole
)

$ErrorActionPreference = "Stop"

$az = Get-Command az -ErrorAction SilentlyContinue
if (-not $az) {
  throw "Azure CLI is not installed. Install it with: winget install Microsoft.AzureCLI"
}

$account = az account show | ConvertFrom-Json
if (-not $account.id) {
  throw "Azure CLI is not logged in. Run: az login"
}

if (-not $VaultName) {
  throw "VaultName is required. Pass -VaultName or set AZURE_KEY_VAULT_NAME."
}

if (-not $ResourceGroup) {
  throw "ResourceGroup is required. Pass -ResourceGroup or set AZURE_RESOURCE_GROUP."
}

if (-not $WorkspaceName) {
  throw "WorkspaceName is required. Pass -WorkspaceName or set AZURE_LOG_ANALYTICS_WORKSPACE."
}

az group show --name $ResourceGroup --output none

$workspaceExists = az monitor log-analytics workspace list `
  --resource-group $ResourceGroup `
  --query "[?name=='$WorkspaceName'].name | [0]" `
  -o tsv

if (-not $workspaceExists) {
  az monitor log-analytics workspace create `
    --resource-group $ResourceGroup `
    --workspace-name $WorkspaceName `
    --location $Location `
    --retention-time $LogRetentionDays `
    --output none
}

$vaultExists = az keyvault list `
  --resource-group $ResourceGroup `
  --query "[?name=='$VaultName'].name | [0]" `
  -o tsv

if (-not $vaultExists) {
  az keyvault create `
    --name $VaultName `
    --resource-group $ResourceGroup `
    --location $Location `
    --enable-rbac-authorization true `
    --enable-purge-protection true `
    --retention-days 90 `
    --output none
}

$vaultId = az keyvault show --name $VaultName --resource-group $ResourceGroup --query id -o tsv
$workspaceId = az monitor log-analytics workspace show `
  --resource-group $ResourceGroup `
  --workspace-name $WorkspaceName `
  --query id `
  -o tsv

if (-not $SkipSelfSecretOfficerRole) {
  $userId = az ad signed-in-user show --query id -o tsv
  $existingRole = az role assignment list `
    --assignee $userId `
    --scope $vaultId `
    --role "Key Vault Secrets Officer" `
    --query "[0].id" `
    -o tsv

  if (-not $existingRole) {
    az role assignment create `
      --assignee-object-id $userId `
      --assignee-principal-type User `
      --role "Key Vault Secrets Officer" `
      --scope $vaultId `
      --output none
  }
}

$logsJson = '[{"category":"AuditEvent","enabled":true,"retentionPolicy":{"enabled":false,"days":0}}]'
$diagName = "onmu-keyvault-audit"
$diagExists = az monitor diagnostic-settings list `
  --resource $vaultId `
  --query "[?name=='$diagName'].name | [0]" `
  -o tsv

if ($diagExists) {
  az monitor diagnostic-settings update `
    --resource $vaultId `
    --name $diagName `
    --workspace $workspaceId `
    --logs $logsJson `
    --output none
} else {
  az monitor diagnostic-settings create `
    --resource $vaultId `
    --name $diagName `
    --workspace $workspaceId `
    --logs $logsJson `
    --output none
}

$vault = az keyvault show `
  --name $VaultName `
  --resource-group $ResourceGroup `
  --query "{name:name,resourceGroup:resourceGroup,location:location,enableRbacAuthorization:properties.enableRbacAuthorization,enablePurgeProtection:properties.enablePurgeProtection,softDeleteRetentionInDays:properties.softDeleteRetentionInDays,publicNetworkAccess:properties.publicNetworkAccess}" |
  ConvertFrom-Json

[pscustomobject]@{
  keyVault = "<configured>"
  resourceGroup = "<configured>"
  location = $vault.location
  rbac = $vault.enableRbacAuthorization
  purgeProtection = $vault.enablePurgeProtection
  softDeleteRetentionInDays = $vault.softDeleteRetentionInDays
  publicNetworkAccess = $vault.publicNetworkAccess
  logAnalyticsWorkspace = "<configured>"
  diagnosticSetting = $diagName
} | ConvertTo-Json -Depth 4
