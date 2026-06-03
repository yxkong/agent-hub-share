[CmdletBinding()]
param(
    [string]$RepoRoot = '',
    [string]$HubRoot = '',
    [string]$ProjectKey = '',
    [string]$SkillName = '',
    [switch]$Simple
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'agent-hub-paths.ps1')

function Get-LinkTargetText {
    param([Parameter(Mandatory = $true)]$Item)

    $target = $Item.Target
    if ($null -eq $target) {
        return ''
    }
    if ($target -is [System.Array]) {
        return [string]($target[0])
    }
    return [string]$target
}

function Get-SimpleRow {
    param([Parameter(Mandatory = $true)][string]$Path)

    $item = Get-Item -LiteralPath $Path -Force
    $isReparse = ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0
    $targetText = Get-LinkTargetText -Item $item
    $realPath = if ($targetText) { $targetText } else { $item.FullName }

    [pscustomobject]@{
        Name = $item.Name
        Path = $item.FullName
        LinkType = [string]$item.LinkType
        RealPath = $realPath
        Exists = (Test-Path -LiteralPath $realPath)
        SkillMd = (Test-Path -LiteralPath ([System.IO.Path]::Combine($realPath, 'SKILL.md')))
        IsLink = $isReparse
    }
}

function Show-SimpleRow {
    param([Parameter(Mandatory = $true)]$Row)

    $Row | Format-List Name, Path, LinkType, RealPath, Exists, SkillMd
}

function Invoke-SimpleMode {
    $current = (Get-Location).Path
    $currentItem = Get-Item -LiteralPath $current -Force
    $currentHasSkill = Test-Path -LiteralPath ([System.IO.Path]::Combine($current, 'SKILL.md'))
    $currentIsLink = ($currentItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0

    if ($currentIsLink -or $currentHasSkill) {
        Show-SimpleRow -Row (Get-SimpleRow -Path $current)
        return
    }

    $dirs = @(Get-ChildItem -LiteralPath $current -Directory -Force)
    if ($dirs.Count -eq 0) {
        Write-Host 'No subdirectories found in current directory.' -ForegroundColor Yellow
        return
    }

    $rows = foreach ($dir in $dirs) {
        Get-SimpleRow -Path $dir.FullName
    }
    @($rows | Sort-Object Name) | Format-Table Name, LinkType, RealPath, Exists, SkillMd -AutoSize
}

if ($Simple -or (-not $RepoRoot -and -not $ProjectKey -and -not $SkillName)) {
    Invoke-SimpleMode
    exit 0
}

$agentsRoot = [string](Resolve-AgentHubRoot -HubRoot $HubRoot -ScriptRoot $PSScriptRoot)
$resolvedRepoRoot = [string](Resolve-AgentWorkspaceRoot -WorkspaceRoot $RepoRoot -AllowCurrentLocation)
$resolvedProjectKey = [string](Resolve-AgentProjectKey -ProjectKey $ProjectKey -WorkspaceRoot $resolvedRepoRoot)
if (-not $resolvedRepoRoot) {
    throw 'check-skill-links.ps1 requires -RepoRoot, AGENTS_DEFAULT_PROJECT_ROOT, or running inside the target workspace.'
}
if (-not $resolvedProjectKey) {
    throw 'check-skill-links.ps1 requires -ProjectKey, AGENTS_DEFAULT_PROJECT_KEY, or a workspace root whose folder name can be used as the project key.'
}

$expectedProjectRoot = [System.IO.Path]::Combine($agentsRoot, 'skills', 'projects', $resolvedProjectKey)
$expectedShareRoot = [System.IO.Path]::Combine($agentsRoot, 'skills', 'share')
$skillRoots = @(
    [System.IO.Path]::Combine($resolvedRepoRoot, '.agents', 'skills'),
    [System.IO.Path]::Combine($resolvedRepoRoot, '.cursor', 'skills')
)

$rows = New-Object System.Collections.Generic.List[object]
foreach ($root in $skillRoots) {
    if (-not (Test-Path -LiteralPath $root)) {
        continue
    }

    Get-ChildItem -LiteralPath $root -Directory | ForEach-Object {
        if ($SkillName -and $_.Name -ne $SkillName) {
            return
        }

        $item = Get-Item -LiteralPath $_.FullName -Force
        $skill = [string]$_.Name
        $linkType = [string]$item.LinkType
        $targetText = Get-LinkTargetText -Item $item
        $targetExists = if ($targetText) { Test-Path -LiteralPath $targetText } else { $false }
        $isReparse = ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0

        $status = 'UNKNOWN'
        $expected = ''
        if (-not $isReparse) {
            $status = 'NOT_LINK'
        }
        elseif (-not $targetText) {
            $status = 'NO_TARGET'
        }
        elseif (-not $targetExists) {
            $status = 'BROKEN'
        }
        else {
            $expectedProject = [System.IO.Path]::Combine($expectedProjectRoot, $skill)
            $expectedShare = [System.IO.Path]::Combine($expectedShareRoot, $skill)
            if ([System.StringComparer]::OrdinalIgnoreCase.Equals($targetText, $expectedProject)) {
                $status = 'OK_PROJECT'
                $expected = $expectedProject
            }
            elseif ([System.StringComparer]::OrdinalIgnoreCase.Equals($targetText, $expectedShare)) {
                $status = 'OK_SHARE'
                $expected = $expectedShare
            }
            elseif ($targetText.StartsWith($expectedProjectRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
                $status = 'PROJECT_MISMATCH_NAME'
                $expected = $expectedProject
            }
            elseif ($targetText.StartsWith($expectedShareRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
                $status = 'SHARE_MISMATCH_NAME'
                $expected = $expectedShare
            }
            else {
                $status = 'OUTSIDE_HUB'
                $expected = "$expectedProject or $expectedShare"
            }
        }

        $rows.Add([pscustomobject]@{
            Root = $root
            Skill = $skill
            LinkType = $linkType
            Status = $status
            Target = $targetText
            Expected = $expected
            SkillMdExists = if ($targetText) { Test-Path -LiteralPath ([System.IO.Path]::Combine($targetText, 'SKILL.md')) } else { $false }
        }) | Out-Null
    }
}

if ($rows.Count -eq 0) {
    Write-Host 'No skill directories found to inspect.' -ForegroundColor Yellow
    exit 0
}

$sortedRows = @($rows | Sort-Object Root, Skill)
$sortedRows | Format-Table Root, Skill, LinkType, Status, SkillMdExists, Target -AutoSize
Write-Host ''
Write-Host ("Expected project root: {0}" -f $expectedProjectRoot)
Write-Host ("Expected share root:   {0}" -f $expectedShareRoot)
Write-Host ''

$bad = @($sortedRows | Where-Object { $_.Status -notin @('OK_PROJECT', 'OK_SHARE') })
$okCount = @($sortedRows | Where-Object { $_.Status -in @('OK_PROJECT', 'OK_SHARE') }).Count
$badCount = $bad.Count
Write-Host ("Summary: total={0}, ok={1}, bad={2}" -f $sortedRows.Count, $okCount, $badCount)

if ($badCount -eq 0) {
    Write-Host 'Result: PASS' -ForegroundColor Green
    exit 0
}

Write-Host 'Result: NEEDS_FIX' -ForegroundColor Red
$bad | Format-Table Root, Skill, Status, Expected, Target -AutoSize
exit 1
