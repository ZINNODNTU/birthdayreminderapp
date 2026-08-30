# Calculate SHA256 of a file and write it to <file>.sha256.
#
# Usage:
#   pwsh -File scripts/release/calculate_sha256.ps1 -Path "BirthdayReminder-v1.0.1.apk"

param(
    [Parameter(Mandatory = $true)][string]$Path
)

if (-not (Test-Path $Path)) {
    Write-Error "File not found: $Path"
    exit 1
}

$hash = (Get-FileHash -Algorithm SHA256 $Path).Hash.ToUpper()
$out = "$Path.sha256"
$content = "$hash  $(Split-Path -Leaf $Path)"
Set-Content -Path $out -Value $content -Encoding UTF8
Write-Host "$out"
Get-Content $out
