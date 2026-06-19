param(
    [string]$ResourceGroup = "3dt-final-team1",
    [string]$WorkspaceName = "mlw-onmu-staging-krc-001",
    [string]$KeyVaultName = "onmu-dev-kv-27db5e",
    [string]$EndpointName = "onmu-staging-ootd-generation",
    [string]$DeploymentName = "blue",
    [string]$InstanceType = "Standard_NC4as_T4_v3",
    [ValidateSet("true", "false")]
    [string]$DryRun = "true",
    [switch]$Apply,
    [switch]$WriteEndpointSecrets,
    [switch]$RecreateDeployment
)

$ErrorActionPreference = "Stop"

function Require-Command {
    param([string]$Name)
    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "Required command '$Name' was not found. Install it before running this script."
    }
}

function Get-KeyVaultSecretValue {
    param(
        [string]$VaultName,
        [string]$SecretName,
        [bool]$Required = $true
    )

    $value = az keyvault secret show `
        --vault-name $VaultName `
        --name $SecretName `
        --query value `
        -o tsv 2>$null

    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($value)) {
        if ($Required) {
            throw "Key Vault secret '$SecretName' was not found in '$VaultName'."
        }
        return ""
    }

    return $value
}

function Set-TemplateValue {
    param(
        [string]$Content,
        [string]$Token,
        [string]$Value
    )
    return $Content.Replace($Token, $Value.Replace("\", "\\").Replace('"', '\"'))
}

function Set-GeneratedDeploymentName {
    param(
        [string]$Path,
        [string]$Name
    )

    $content = Get-Content -Raw $Path
    $content = $content -replace "(?m)^name: .+$", "name: $Name"
    Set-Content -Path $Path -Value $content -Encoding utf8
}

Require-Command az

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$assetDir = Join-Path $repoRoot "services\workers\ai-data-worker\azureml\ootd-generation"
$generatedDir = Join-Path $assetDir ".generated"
New-Item -ItemType Directory -Force -Path $generatedDir | Out-Null

$endpointTemplate = Join-Path $assetDir "endpoint.template.yml"
$deploymentTemplate = Join-Path $assetDir "deployment.template.yml"
$endpointFile = Join-Path $generatedDir "endpoint.yml"
$deploymentFile = Join-Path $generatedDir "deployment.yml"

az extension add --name ml --upgrade --only-show-errors | Out-Null

$modelId = Get-KeyVaultSecretValue -VaultName $KeyVaultName -SecretName "staging-ootd-model-id"
$modelRevision = Get-KeyVaultSecretValue -VaultName $KeyVaultName -SecretName "staging-ootd-model-revision"
$hfToken = Get-KeyVaultSecretValue -VaultName $KeyVaultName -SecretName "staging-hf-token" -Required:($DryRun -eq "false")
$dockerfilePath = if ($DryRun -eq "true") { "Dockerfile.dryrun" } else { "Dockerfile" }

$endpointContent = Get-Content -Raw $endpointTemplate
$endpointContent = Set-TemplateValue $endpointContent "__ENDPOINT_NAME__" $EndpointName
Set-Content -Path $endpointFile -Value $endpointContent -Encoding utf8

$deploymentContent = Get-Content -Raw $deploymentTemplate
$deploymentContent = Set-TemplateValue $deploymentContent "__ENDPOINT_NAME__" $EndpointName
$deploymentContent = Set-TemplateValue $deploymentContent "__DEPLOYMENT_NAME__" $DeploymentName
$deploymentContent = Set-TemplateValue $deploymentContent "__INSTANCE_TYPE__" $InstanceType
$deploymentContent = Set-TemplateValue $deploymentContent "__ONMU_HF_TOKEN__" $hfToken
$deploymentContent = Set-TemplateValue $deploymentContent "__ONMU_OOTD_MODEL_ID__" $modelId
$deploymentContent = Set-TemplateValue $deploymentContent "__ONMU_OOTD_MODEL_REVISION__" $modelRevision
$deploymentContent = Set-TemplateValue $deploymentContent "__ONMU_OOTD_DRY_RUN__" $DryRun
$deploymentContent = Set-TemplateValue $deploymentContent "__DOCKERFILE_PATH__" $dockerfilePath
Set-Content -Path $deploymentFile -Value $deploymentContent -Encoding utf8

Write-Host "Generated Azure ML endpoint files under $generatedDir"
Write-Host "Endpoint: $EndpointName"
Write-Host "Deployment: $DeploymentName"
Write-Host "Instance type: $InstanceType"
Write-Host "Dry run: $DryRun"
Write-Host "Dockerfile: $dockerfilePath"

if (-not $Apply) {
    Write-Host "No Azure ML resource was changed. Re-run with -Apply to create/update the endpoint."
    exit 0
}

$endpointExists = $false
$previousErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = "Continue"
try {
    az ml online-endpoint show `
        --name $EndpointName `
        --resource-group $ResourceGroup `
        --workspace-name $WorkspaceName `
        --only-show-errors *> $null

    $endpointExists = ($LASTEXITCODE -eq 0)
}
finally {
    $ErrorActionPreference = $previousErrorActionPreference
}

if (-not $endpointExists) {
    Write-Host "Creating Azure ML online endpoint..."
    az ml online-endpoint create `
        --file $endpointFile `
        --resource-group $ResourceGroup `
        --workspace-name $WorkspaceName `
        --only-show-errors `
        -o none
    if ($LASTEXITCODE -ne 0) {
        throw "Azure ML online endpoint creation failed."
    }
}
else {
    Write-Host "Azure ML online endpoint already exists. Keeping endpoint."
}

$deploymentExists = $false
$deploymentProvisioningState = ""
$previousErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = "Continue"
try {
    $deploymentProvisioningState = az ml online-deployment show `
        --name $DeploymentName `
        --endpoint-name $EndpointName `
        --resource-group $ResourceGroup `
        --workspace-name $WorkspaceName `
        --query provisioning_state `
        -o tsv `
        --only-show-errors 2>$null

    $deploymentExists = ($LASTEXITCODE -eq 0)
}
finally {
    $ErrorActionPreference = $previousErrorActionPreference
}

if ($deploymentExists) {
    $deploymentNeedsRecreate = $RecreateDeployment -or ($deploymentProvisioningState -match "Failed|Canceled")
    if ($deploymentNeedsRecreate) {
        if (-not $RecreateDeployment) {
            Write-Host "Azure ML online deployment is '$deploymentProvisioningState'. Re-creating deployment automatically."
        }
        Write-Host "Deleting existing Azure ML online deployment before re-create..."
        $previousErrorActionPreference = $ErrorActionPreference
        $ErrorActionPreference = "Continue"
        try {
            $deleteResult = az ml online-deployment delete `
                --name $DeploymentName `
                --endpoint-name $EndpointName `
                --resource-group $ResourceGroup `
                --workspace-name $WorkspaceName `
                --yes `
                --only-show-errors 2>&1
            $deleteStatus = $LASTEXITCODE
        }
        finally {
            $ErrorActionPreference = $previousErrorActionPreference
        }

        if ($deleteStatus -ne 0) {
            $deleteMessage = $deleteResult -join "`n"
            if ($deleteMessage -match "ScopeLocked") {
                $previousDeploymentName = $DeploymentName
                $DeploymentName = "$DeploymentName-r$(Get-Date -Format 'MMddHHmm')"
                Set-GeneratedDeploymentName -Path $deploymentFile -Name $DeploymentName
                Write-Host "Delete is blocked by an Azure resource lock. Creating replacement deployment '$DeploymentName' instead of deleting '$previousDeploymentName'."
            }
            else {
                throw "Failed to delete existing Azure ML online deployment '$DeploymentName'."
            }
        }
        else {
            $deploymentExists = $false
        }
        if ($DeploymentName -ne $previousDeploymentName) {
            $deploymentExists = $false
        }
    }
    else {
        Write-Host "Azure ML online deployment already exists. Updating deployment..."
        az ml online-deployment update `
            --file $deploymentFile `
            --resource-group $ResourceGroup `
            --workspace-name $WorkspaceName `
            --only-show-errors `
            -o none
    }
}

if (-not $deploymentExists) {
    Write-Host "Creating Azure ML online deployment..."
    az ml online-deployment create `
        --file $deploymentFile `
        --resource-group $ResourceGroup `
        --workspace-name $WorkspaceName `
        --all-traffic `
        --only-show-errors `
        -o none
}

if ($LASTEXITCODE -ne 0) {
    throw "Azure ML online deployment create/update failed. If Azure reports the deployment is in an unrecoverable state, re-run this script with -RecreateDeployment."
}

az ml online-endpoint update `
    --name $EndpointName `
    --resource-group $ResourceGroup `
    --workspace-name $WorkspaceName `
    --traffic "$DeploymentName=100" `
    --only-show-errors `
    -o none
if ($LASTEXITCODE -ne 0) {
    throw "Failed to route Azure ML endpoint traffic to deployment '$DeploymentName'."
}

$scoringUri = az ml online-endpoint show `
    --name $EndpointName `
    --resource-group $ResourceGroup `
    --workspace-name $WorkspaceName `
    --query scoring_uri `
    -o tsv
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($scoringUri)) {
    throw "Failed to read Azure ML endpoint scoring URI."
}

$endpointKey = az ml online-endpoint get-credentials `
    --name $EndpointName `
    --resource-group $ResourceGroup `
    --workspace-name $WorkspaceName `
    --query primaryKey `
    -o tsv
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($endpointKey)) {
    throw "Failed to read Azure ML endpoint key."
}

if ($WriteEndpointSecrets) {
    az keyvault secret set `
        --vault-name $KeyVaultName `
        --name "staging-azureml-endpoint-url" `
        --value $scoringUri `
        --only-show-errors | Out-Null

    az keyvault secret set `
        --vault-name $KeyVaultName `
        --name "staging-azureml-endpoint-key" `
        --value $endpointKey `
        --only-show-errors | Out-Null

    Write-Host "Stored staging-azureml-endpoint-url and staging-azureml-endpoint-key in Key Vault."
}
else {
    Write-Host "Endpoint URL was created. Re-run with -WriteEndpointSecrets to store URL/key in Key Vault."
}

Write-Host "Azure ML OOTD endpoint deployment completed."
