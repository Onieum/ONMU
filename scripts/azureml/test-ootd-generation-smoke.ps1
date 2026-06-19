param(
    [string]$KeyVaultName = "onmu-dev-kv-27db5e",
    [string]$EndpointUrlSecret = "staging-azureml-endpoint-url",
    [string]$EndpointKeySecret = "staging-azureml-endpoint-key",
    [ValidateSet("TEXT_PROMPT", "PHOTO_REFERENCE")]
    [string]$Mode = "TEXT_PROMPT",
    [string]$OutputImagePath = "services\workers\ai-data-worker\azureml\ootd-generation\.generated\smoke-result.png"
)

$ErrorActionPreference = "Stop"

function Require-Command {
    param([string]$Name)
    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "Required command '$Name' was not found."
    }
}

function Get-KeyVaultSecretValue {
    param(
        [string]$VaultName,
        [string]$SecretName
    )

    $value = az keyvault secret show `
        --vault-name $VaultName `
        --name $SecretName `
        --query value `
        -o tsv 2>$null

    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($value)) {
        throw "Key Vault secret '$SecretName' was not found in '$VaultName'."
    }

    return $value
}

Require-Command az

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$outputPath = Join-Path $repoRoot $OutputImagePath
$outputDir = Split-Path -Parent $outputPath
New-Item -ItemType Directory -Force -Path $outputDir | Out-Null

$endpointUrl = Get-KeyVaultSecretValue -VaultName $KeyVaultName -SecretName $EndpointUrlSecret
$endpointKey = Get-KeyVaultSecretValue -VaultName $KeyVaultName -SecretName $EndpointKeySecret

$characterImageBase64 = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/p9sAAAAASUVORK5CYII="

$payload = [ordered]@{
    requestId = "smoke_" + (Get-Date -Format "yyyyMMddHHmmss")
    mode = $Mode
    characterImageBase64 = $characterImageBase64
    seed = 1234
    numInferenceSteps = 4
    guidanceScale = 2.5
}

if ($Mode -eq "TEXT_PROMPT") {
    $payload.outfitDescription = "white short sleeve blouse, navy pleated skirt, white socks, white sneakers"
}
else {
    $payload.outfitDescriptor = [ordered]@{
        style_name = "dry-run school casual"
        overall_aesthetic = "clean casual navy and white outfit"
        top = "white short sleeve blouse with a small navy ribbon detail"
        bottom = "navy pleated mini skirt"
        shoes = "white low-top sneakers"
        accessories = @("small navy ribbon")
        styling_notes = "simple coordinated school-casual outfit"
    }
    $payload.visionMetadata = [ordered]@{
        provider = "smoke-test"
        deployment = "manual-descriptor"
        apiVersion = "none"
    }
}

$headers = @{
    Authorization = "Bearer $endpointKey"
    "Content-Type" = "application/json"
}

$body = $payload | ConvertTo-Json -Depth 12
$response = Invoke-RestMethod `
    -Method Post `
    -Uri $endpointUrl `
    -Headers $headers `
    -Body $body `
    -TimeoutSec 240

if ($response.status -ne "succeeded") {
    throw "Azure ML OOTD smoke test failed. status=$($response.status), errorCode=$($response.errorCode), message=$($response.message)"
}

if ([string]::IsNullOrWhiteSpace($response.imageBase64)) {
    throw "Azure ML OOTD smoke test succeeded but did not return imageBase64."
}

[System.IO.File]::WriteAllBytes($outputPath, [Convert]::FromBase64String($response.imageBase64))

Write-Host "Azure ML OOTD smoke test passed."
Write-Host "Mode: $($response.mode)"
Write-Host "Dry run: $($response.dryRun)"
Write-Host "Duration ms: $($response.durationMs)"
Write-Host "Image bytes written: $outputPath"
