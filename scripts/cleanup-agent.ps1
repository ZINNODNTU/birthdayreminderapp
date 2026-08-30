param(
    [switch]$Deep
)

$ErrorActionPreference = "SilentlyContinue"

$root = Split-Path -Parent $PSScriptRoot

Write-Host "=== SAFE AGENT CLEANUP ==="

$rootPatterns = @(
    "analyze*.log",
    "build*.log",
    "test_*.log",
    "test*.log",
    "device*.log",
    "flutter_*.log",
    "firestore-debug.log",
    "*.exit"
)

foreach ($pattern in $rootPatterns) {
    Get-ChildItem `
        -Path $root `
        -File `
        -Filter $pattern `
        -ErrorAction SilentlyContinue |
    ForEach-Object {
        Write-Host "REMOVE TEMP $($_.Name)"
        Remove-Item $_.FullName -Force
    }
}

$tmp = Join-Path $root ".tmp"

if (Test-Path $tmp) {
    Write-Host "REMOVE .tmp"
    Remove-Item $tmp -Recurse -Force
}

if ($Deep) {
    Push-Location $root
    flutter clean
    Pop-Location
}

Write-Host "=== CLEANUP COMPLETE ==="