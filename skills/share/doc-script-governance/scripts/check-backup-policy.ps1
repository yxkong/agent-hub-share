[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\..\..'))
$runId = Get-Date -Format 'yyyyMMdd-HHmmss'
$workDir = Join-Path (Join-Path $repoRoot '.tmp') "backup-policy-check-$runId"
$sampleFile = Join-Path $workDir 'sample.name.md'

New-Item -ItemType Directory -Path $workDir -Force | Out-Null
[System.IO.File]::WriteAllText(
    $sampleFile,
    'backup policy check',
    (New-Object System.Text.UTF8Encoding($false))
)

$output = & (Join-Path $PSScriptRoot 'backup-file.ps1') -FilePath $sampleFile
$archiveLine = $output | Where-Object { $_ -like 'ARCHIVE_BACKUP=*' } | Select-Object -First 1
if (-not $archiveLine) {
    throw 'backup-file.ps1 did not output ARCHIVE_BACKUP.'
}

$archivePath = $archiveLine.Substring('ARCHIVE_BACKUP='.Length)
$monthBucket = Get-Date -Format 'yyyyMM'
$expectedFragment = Join-Path (Join-Path 'bak' $monthBucket) 'sample_name_md'

if ($archivePath -notlike "*$expectedFragment*") {
    throw "Archive path does not follow policy. Expected fragment: $expectedFragment Actual: $archivePath"
}

if (-not (Test-Path -LiteralPath $archivePath -PathType Leaf)) {
    throw "Archive backup was not created: $archivePath"
}

Write-Output 'BACKUP_POLICY=ok'
Write-Output ("ARCHIVE_BACKUP={0}" -f $archivePath)
