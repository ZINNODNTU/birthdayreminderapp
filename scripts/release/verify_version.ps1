# Verify that the git tag version matches the pubspec.yaml version.
#
# Usage:
#   pwsh -File scripts/release/verify_version.ps1 -Tag "v1.0.1"
#
# Exit codes:
#   0 - tag and pubspec match
#   1 - any validation failure
#
# Rules:
#   - Tag must start with 'v'.
#   - Tag body must be X.Y.Z (three integers separated by dots).
#   - Pubspec version must be X.Y.Z+N (semantic + build number).

param(
    [Parameter(Mandatory = $true)][string]$Tag
)

if ($Tag -notmatch '^v\d+\.\d+\.\d+$') {
    Write-Error "Tag '$Tag' is malformed. Expected format: vX.Y.Z (e.g. v1.0.1)."
    exit 1
}

$TagSem = $Tag -replace '^v', ''

if (-not (Test-Path "pubspec.yaml")) {
    Write-Error "pubspec.yaml not found"
    exit 1
}

$pubLine = Select-String -Path "pubspec.yaml" -Pattern '^version:\s*(.+)$' | ForEach-Object { $_.Matches[0].Groups[1].Value.Trim() }
if (-not $pubLine) {
    Write-Error "pubspec version not found"
    exit 1
}

if ($pubLine -notmatch '^\d+\.\d+\.\d+\+\d+$') {
    Write-Error "pubspec version '$pubLine' is malformed. Expected X.Y.Z+N (e.g. 1.0.1+2)."
    exit 1
}

$PubSem = ($pubLine -split '\+')[0]

if ($TagSem -ne $PubSem) {
    Write-Error "Tag ($TagSem) does not match pubspec ($PubSem)"
    exit 1
}

Write-Host "OK: Tag $TagSem matches pubspec $PubSem"
exit 0
