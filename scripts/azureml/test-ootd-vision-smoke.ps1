param(
    [string]$KeyVaultName = "onmu-dev-kv-27db5e",
    [string]$EndpointUrlSecret = "staging-vision-endpoint-url",
    [string]$DeploymentNameSecret = "staging-vision-deployment-name",
    [string]$ApiKeySecret = "staging-vision-api-key",
    [string]$ApiVersionSecret = "staging-vision-api-version",
    [string]$ImagePath = "",
    [string]$ImageUrl = "",
    [string]$OutputJsonPath = "services\workers\ai-data-worker\azureml\ootd-generation\.generated\vision-descriptor-smoke.json"
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

function Convert-ImageFileToDataUrl {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "ImagePath does not exist: $Path"
    }

    $extension = [System.IO.Path]::GetExtension($Path).ToLowerInvariant()
    $mimeType = switch ($extension) {
        ".jpg" { "image/jpeg" }
        ".jpeg" { "image/jpeg" }
        ".png" { "image/png" }
        ".webp" { "image/webp" }
        default { throw "Unsupported image extension '$extension'. Use .jpg, .jpeg, .png, or .webp." }
    }

    $bytes = [System.IO.File]::ReadAllBytes((Resolve-Path -LiteralPath $Path))
    return "data:$mimeType;base64,$([Convert]::ToBase64String($bytes))"
}

function Get-MessageContent {
    param($Response)

    if ($null -eq $Response.choices -or $Response.choices.Count -lt 1) {
        throw "Vision response did not include choices."
    }
    $content = $Response.choices[0].message.content
    if ([string]::IsNullOrWhiteSpace($content)) {
        throw "Vision response did not include message content."
    }
    return $content.Trim()
}

function ConvertFrom-JsonFence {
    param([string]$Text)

    $value = $Text.Trim()
    if ($value.StartsWith('```')) {
        $lines = $value -split "`r?`n"
        if ($lines.Length -gt 1 -and $lines[0].Trim().StartsWith('```')) {
            $lines = $lines[1..($lines.Length - 1)]
        }
        if ($lines.Length -gt 1 -and $lines[$lines.Length - 1].Trim() -eq '```') {
            $lines = $lines[0..($lines.Length - 2)]
        }
        $value = ($lines -join "`n").Trim()
    }
    return $value
}

Require-Command az

if ([string]::IsNullOrWhiteSpace($ImagePath) -and [string]::IsNullOrWhiteSpace($ImageUrl)) {
    throw "Provide either -ImagePath or -ImageUrl for the Vision smoke test."
}
if (-not [string]::IsNullOrWhiteSpace($ImagePath) -and -not [string]::IsNullOrWhiteSpace($ImageUrl)) {
    throw "Provide only one of -ImagePath or -ImageUrl."
}

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$outputPath = Join-Path $repoRoot $OutputJsonPath
$outputDir = Split-Path -Parent $outputPath
New-Item -ItemType Directory -Force -Path $outputDir | Out-Null

$endpointUrl = (Get-KeyVaultSecretValue -VaultName $KeyVaultName -SecretName $EndpointUrlSecret).TrimEnd("/")
$deploymentName = Get-KeyVaultSecretValue -VaultName $KeyVaultName -SecretName $DeploymentNameSecret
$apiKey = Get-KeyVaultSecretValue -VaultName $KeyVaultName -SecretName $ApiKeySecret
$apiVersion = Get-KeyVaultSecretValue -VaultName $KeyVaultName -SecretName $ApiVersionSecret

$imageSource = if ([string]::IsNullOrWhiteSpace($ImagePath)) {
    $ImageUrl
}
else {
    Convert-ImageFileToDataUrl -Path $ImagePath
}

$systemPrompt = @"
You are a professional fashion analyst for ONMU OOTD avatar generation.
Analyze only wearable fashion items from the image.
Do not describe face, hairstyle, eyes, body shape, age, gender, pose, or background.
Return only a valid JSON object.
"@

$userPrompt = @"
Extract an extremely detailed outfit descriptor for pixel avatar outfit transfer.
Include visible clothing, shoes, accessories, colors, materials, silhouettes, logos, prints, embroidery, lettering, trims, pleats, buttons, lace, ribbons, bags, hats, glasses, jewelry, socks, and styling notes.

Required JSON keys:
style_name, overall_aesthetic, top, bottom, outerwear, dress, shoes, accessories, materials, colors, styling_notes

Use null for unavailable single objects and [] for unavailable arrays.
"@

$body = [ordered]@{
    messages = @(
        [ordered]@{
            role = "system"
            content = $systemPrompt
        },
        [ordered]@{
            role = "user"
            content = @(
                [ordered]@{
                    type = "text"
                    text = $userPrompt
                },
                [ordered]@{
                    type = "image_url"
                    image_url = [ordered]@{
                        url = $imageSource
                        detail = "high"
                    }
                }
            )
        }
    )
    max_tokens = 1800
    temperature = 0.1
    top_p = 0.2
    response_format = [ordered]@{
        type = "json_object"
    }
} | ConvertTo-Json -Depth 20

$headers = @{
    "api-key" = $apiKey
    "Content-Type" = "application/json"
}

$uri = "$endpointUrl/openai/deployments/$deploymentName/chat/completions?api-version=$apiVersion"

try {
    $response = Invoke-RestMethod `
        -Method Post `
        -Uri $uri `
        -Headers $headers `
        -Body $body `
        -TimeoutSec 180
}
catch {
    $message = $_.Exception.Message
    if (-not [string]::IsNullOrWhiteSpace($apiKey)) {
        $message = $message.Replace($apiKey, "<redacted>")
    }
    throw "Azure OpenAI Vision smoke request failed: $message"
}

$content = Get-MessageContent -Response $response
$jsonText = ConvertFrom-JsonFence -Text $content

try {
    $descriptor = $jsonText | ConvertFrom-Json
}
catch {
    throw "Azure OpenAI Vision smoke returned non-JSON content."
}

foreach ($requiredKey in @("style_name", "overall_aesthetic", "accessories", "materials", "colors", "styling_notes")) {
    if (-not ($descriptor.PSObject.Properties.Name -contains $requiredKey)) {
        throw "Vision descriptor is missing required key '$requiredKey'."
    }
}

$jsonText | Set-Content -Path $outputPath -Encoding utf8

Write-Host "Azure OpenAI Vision smoke test passed."
Write-Host "Deployment: $deploymentName"
Write-Host "API version: $apiVersion"
Write-Host "Descriptor JSON written: $outputPath"
