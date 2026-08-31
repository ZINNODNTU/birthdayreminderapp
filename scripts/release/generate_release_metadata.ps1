# Generate schema-v1 release metadata from a built APK.
param(
 [Parameter(Mandatory=$true)][ValidatePattern('^\d+\.\d+\.\d+$')][string]$Version,
 [Parameter(Mandatory=$true)][ValidateRange(1,[int]::MaxValue)][int]$BuildNumber,
 [Parameter(Mandatory=$true)][string]$ApkPath,
 [string]$OutputPath='release-metadata.json', [string]$MinimumSupportedVersion='',
 [string[]]$Changes=@(), [switch]$RequiresReinstall, [string]$MigrationMessage='',
 [string]$Channel='stable', [switch]$Mandatory
)
$ErrorActionPreference='Stop'
if(-not(Test-Path -LiteralPath $ApkPath -PathType Leaf)){throw "APK not found: $ApkPath"}
if($MinimumSupportedVersion -and $MinimumSupportedVersion -notmatch '^\d+\.\d+\.\d+$'){throw "Invalid minimum supported version: $MinimumSupportedVersion"}
if($RequiresReinstall -and [string]::IsNullOrWhiteSpace($MigrationMessage)){throw 'MigrationMessage is required when RequiresReinstall is true.'}
$apk=Get-Item -LiteralPath $ApkPath
$minimum=if($MinimumSupportedVersion){$MinimumSupportedVersion}else{$null}
$metadata=[ordered]@{
 schemaVersion=1; version=$Version; buildNumber=$BuildNumber; channel=$Channel
 minimumVersion=$minimum; minimumSupportedVersion=$minimum
 forceUpdate=[bool]$Mandatory; mandatory=[bool]$Mandatory; changes=@($Changes)
 requiresReinstall=[bool]$RequiresReinstall
 migrationMessage=if($MigrationMessage){$MigrationMessage}else{$null}
 apk=[ordered]@{name=$apk.Name;sha256=(Get-FileHash -Algorithm SHA256 -LiteralPath $apk.FullName).Hash.ToUpperInvariant();size=$apk.Length}
}
$parent=Split-Path -Parent $OutputPath;if($parent){New-Item -ItemType Directory -Force $parent|Out-Null}
$metadata|ConvertTo-Json -Depth 4|Set-Content -LiteralPath $OutputPath -Encoding utf8NoBOM
Write-Host "Generated $OutputPath"
