[CmdletBinding()]
param(
    [string]$HubRoot = '',
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$__hubScripts = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\..\..\scripts'))
. (Join-Path $__hubScripts 'agent-hub-paths.ps1')

$agentsRoot = Resolve-AgentHubRoot -HubRoot $HubRoot -ScriptRoot $__hubScripts
$skillsRoot = Join-Path $agentsRoot 'skills'
$roots = @(
    [pscustomobject]@{ Path = (Join-Path $skillsRoot 'share'); LegalParts = 2 },
    [pscustomobject]@{ Path = (Join-Path $skillsRoot 'projects'); LegalParts = 3 }
)
$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$count = 0

foreach ($rootSpec in $roots) {
    $root = $rootSpec.Path
    if (-not (Test-Path -LiteralPath $root -PathType Container)) {
        continue
    }

    $rootItem = Get-Item -LiteralPath $root
    $entries = Get-ChildItem -LiteralPath $root -Filter 'SKILL.md' -File -Recurse
    foreach ($entry in $entries) {
        $relative = [System.IO.Path]::GetRelativePath($rootItem.FullName, $entry.FullName)
        $parts = $relative -split '[\\/]'
        $isRootEntrypoint = $parts.Count -eq $rootSpec.LegalParts -and $parts[$parts.Count - 1] -eq 'SKILL.md'
        if ($isRootEntrypoint) {
            continue
        }

        $dir = Split-Path -Parent $entry.FullName
        $target = Join-Path $dir '_SKILL.md'
        if (Test-Path -LiteralPath $target) {
            $target = Join-Path $dir ("SKILL.legacy-{0}.md" -f $timestamp)
        }
        if ($DryRun) {
            Write-Output ("DRY_RUN_RENAME={0} -> {1}" -f $entry.FullName, $target)
        }
        else {
            Move-Item -LiteralPath $entry.FullName -Destination $target -Force
            Write-Output ("RENAMED={0} -> {1}" -f $entry.FullName, $target)
        }
        $count++
    }

    $dirEntries = Get-ChildItem -LiteralPath $root -Directory -Recurse -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -eq 'SKILL.md' }

    foreach ($dirEntry in $dirEntries) {
        $parent = $dirEntry.Parent.FullName
        $targetDir = Join-Path $parent 'SKILL_md'

        if ($DryRun) {
            Write-Output ("DRY_RUN_MERGE_SKILL_MD_DIR={0} -> {1}" -f $dirEntry.FullName, $targetDir)
            $count++
            continue
        }

        if (-not (Test-Path -LiteralPath $targetDir -PathType Container)) {
            New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
        }

        if ((Get-ChildItem -LiteralPath $dirEntry.FullName -Directory -ErrorAction SilentlyContinue | Measure-Object).Count -gt 0) {
            throw "SKILL.md directory contains subdirectories (merge not supported): $($dirEntry.FullName)"
        }

        Get-ChildItem -LiteralPath $dirEntry.FullName -File | ForEach-Object {
            $dest = Join-Path $targetDir $_.Name
            if (Test-Path -LiteralPath $dest) {
                $stem = [System.IO.Path]::GetFileNameWithoutExtension($_.Name)
                $ext = [System.IO.Path]::GetExtension($_.Name)
                $dest = Join-Path $targetDir ("{0}.legacy-{1}{2}" -f $stem, $timestamp, $ext)
            }
            Move-Item -LiteralPath $_.FullName -Destination $dest -Force
            Write-Output ("MOVED={0} -> {1}" -f $_.FullName, $dest)
        }

        if ((Get-ChildItem -LiteralPath $dirEntry.FullName -Force -ErrorAction SilentlyContinue | Measure-Object).Count -gt 0) {
            throw "Cannot remove SKILL.md directory (not empty after file merge): $($dirEntry.FullName)"
        }

        Remove-Item -LiteralPath $dirEntry.FullName -Force -Recurse
        Write-Output ("REMOVED_DIR={0}" -f $dirEntry.FullName)
        $count++
    }
}

Write-Output ("SKILL_ENTRYPOINT_FIX=count={0}" -f $count)
