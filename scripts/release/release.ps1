[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^\d+\.\d+\.\d+$')]
    [string]$Version,
    [switch]$DryRun
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
function Invoke-Step([string]$Name, [scriptblock]$Action) {
    Write-Host "`n==> $Name" -ForegroundColor Cyan
    & $Action
    if ($LASTEXITCODE -ne 0) { throw "$Name failed (exit code $LASTEXITCODE)." }
}
function Parse-Version([string]$Value) {
    if ($Value -notmatch '^(\d+)\.(\d+)\.(\d+)$') { throw "Invalid semantic version: $Value" }
    [version]::new([int]$Matches[1], [int]$Matches[2], [int]$Matches[3])
}
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
Push-Location $repoRoot
try {
    Invoke-Step 'Verify Git repository' { git rev-parse --is-inside-work-tree | Out-Null }
    $branch = (git branch --show-current).Trim()
    if ($branch -ne 'main') { throw "Release must run from main; current branch: $branch" }
    if (-not $DryRun -and (git status --porcelain).Count -ne 0) { throw 'Working tree is not clean. Commit or stash changes first.' }
    git remote get-url origin *> $null
    if ($LASTEXITCODE -ne 0) { throw 'Git remote origin is not configured.' }
    git rev-parse "refs/tags/v$Version" *> $null
    if ($LASTEXITCODE -eq 0) { throw "Tag v$Version already exists locally." }
    git ls-remote --exit-code --tags origin "refs/tags/v$Version" *> $null
    if ($LASTEXITCODE -eq 0) { throw "Tag v$Version already exists on origin." }
    $global:LASTEXITCODE = 0
    $pubspec = Get-Content pubspec.yaml -Raw
    if ($pubspec -notmatch '(?m)^version:\s*(\d+\.\d+\.\d+)\+(\d+)\s*$') { throw 'pubspec.yaml version must use MAJOR.MINOR.PATCH+BUILD.' }
    $currentVersion = $Matches[1]
    $currentBuild = [int]$Matches[2]
    $targetVersion = Parse-Version $Version
    $currentSemVersion = Parse-Version $currentVersion
    if ($targetVersion -lt $currentSemVersion) {
        throw "Release version $Version cannot be lower than pubspec version $currentVersion."
    }
    $versionAlreadyPrepared = $targetVersion -eq $currentSemVersion
    $nextBuild = if ($versionAlreadyPrepared) { $currentBuild } else { $currentBuild + 1 }
    $nextFullVersion = "$Version+$nextBuild"
    if ($versionAlreadyPrepared) {
        Write-Host "Version already prepared: $nextFullVersion"
    } else {
        Write-Host "Version: $currentVersion+$currentBuild -> $nextFullVersion"
    }
    Invoke-Step 'Flutter clean' { flutter clean }
    Invoke-Step 'Flutter pub get' { flutter pub get }
    Invoke-Step 'Dart format check' { dart format --output=none --set-exit-if-changed lib test }
    Invoke-Step 'Flutter analyze' { flutter analyze }
    Invoke-Step 'Flutter test' { flutter test --no-pub }
    if ($DryRun) {
        Write-Host "`nDRY RUN PASSED. No file, commit, tag, or remote was changed." -ForegroundColor Green
        return
    }
    if (-not $versionAlreadyPrepared) {
        $updated = [regex]::Replace($pubspec, '(?m)^version:\s*\d+\.\d+\.\d+\+\d+\s*$', "version: $nextFullVersion")
        [IO.File]::WriteAllText((Join-Path $repoRoot 'pubspec.yaml'), $updated, [Text.UTF8Encoding]::new($false))
    }
    try {
        if (-not $versionAlreadyPrepared) {
            Invoke-Step 'Commit version' { git add -- pubspec.yaml; git commit -m "chore(release): v$Version" }
        }
        Invoke-Step 'Create annotated tag' { git tag -a "v$Version" -m "Birthday Reminder v$Version" }
        Invoke-Step 'Push release atomically' { git push --atomic origin main "v$Version" }
    } catch {
        Write-Error "Release publication failed. Local commit/tag may exist; inspect Git before retrying. $($_.Exception.Message)"
        throw
    }
    Write-Host "`nRelease v$Version triggered: https://github.com/ZINNODNTU/birthdayreminderapp/actions" -ForegroundColor Green
} finally { Pop-Location }
