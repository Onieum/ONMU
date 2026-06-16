$script:OnmuUtf8NoBomEncoding = [System.Text.UTF8Encoding]::new($false)

function Set-OnmuUtf8Console {
  [CmdletBinding()]
  param()

  [Console]::InputEncoding = $script:OnmuUtf8NoBomEncoding
  [Console]::OutputEncoding = $script:OnmuUtf8NoBomEncoding
  $global:OutputEncoding = $script:OnmuUtf8NoBomEncoding
}

function Write-Utf8NoBom {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [string]$Path,

    [Parameter(Mandatory = $true)]
    [AllowEmptyString()]
    [string]$Content
  )

  $directory = Split-Path -Parent $Path
  if (-not [string]::IsNullOrWhiteSpace($directory) -and -not (Test-Path -LiteralPath $directory)) {
    New-Item -ItemType Directory -Force -Path $directory | Out-Null
  }

  [System.IO.File]::WriteAllText($Path, $Content, $script:OnmuUtf8NoBomEncoding)
}

function Read-Utf8 {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [string]$Path
  )

  return [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)
}
