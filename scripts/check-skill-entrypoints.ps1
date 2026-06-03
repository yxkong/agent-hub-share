[CmdletBinding()]
param(
    [string]$HubRoot = '',
    [switch]$OnlyShare
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'agent-hub-paths.ps1')

function Get-AgentRelativePath {
    param(
        [Parameter(Mandatory = $true)][string]$BasePath,
        [Parameter(Mandatory = $true)][string]$TargetPath
    )

    if ([System.IO.Path].GetMethods() | Where-Object { $_.Name -eq 'GetRelativePath' }) {
        return [System.IO.Path]::GetRelativePath($BasePath, $TargetPath)
    }

    $baseUri = New-Object System.Uri(($BasePath.TrimEnd('\', '/') + [System.IO.Path]::DirectorySeparatorChar))
    $targetUri = New-Object System.Uri($TargetPath)
    return [System.Uri]::UnescapeDataString($baseUri.MakeRelativeUri($targetUri).ToString()).Replace('/', [System.IO.Path]::DirectorySeparatorChar)
}

$agentsRoot = Resolve-AgentHubRoot -HubRoot $HubRoot -ScriptRoot $PSScriptRoot
$skillsRoot = Join-Path $agentsRoot 'skills'
$roots = @(
    [pscustomobject]@{ Path = (Join-Path $skillsRoot 'share'); LegalParts = 2 }
)
if (-not $OnlyShare) {
    $roots += [pscustomobject]@{ Path = (Join-Path $skillsRoot 'projects'); LegalParts = 3 }
    $roots += [pscustomobject]@{ Path = (Join-Path $skillsRoot 'media'); LegalParts = 2 }
}
$violations = New-Object System.Collections.Generic.List[object]

function Test-SkillFrontMatter {
    param([Parameter(Mandatory = $true)][string]$Path)

    $bytes = [System.IO.File]::ReadAllBytes($Path)
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 239 -and $bytes[1] -eq 187 -and $bytes[2] -eq 191) {
        return 'BOM detected before opening front matter delimiter'
    }

    # PowerShell 5.1 can mis-read UTF-8/LF frontmatter line boundaries when using
    # line-mode Get-Content. Read raw UTF-8 text and split explicitly.
    $text = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
    $lines = $text -split "`r?`n"
    if ($lines.Count -lt 3 -or $lines[0].Trim() -ne '---') {
        return 'Missing opening front matter delimiter'
    }
    $closingIndex = -1
    $maxInspect = [Math]::Min($lines.Count, 20)
    for ($i = 1; $i -lt $maxInspect; $i++) {
        if ($lines[$i].Trim() -eq '---') {
            $closingIndex = $i
            break
        }
    }
    if ($closingIndex -lt 0) {
        return 'Missing closing front matter delimiter'
    }
    $frontMatter = $lines[1..($closingIndex - 1)]
    if (-not ($frontMatter | Where-Object { $_ -match '^name:\s*\S+' })) {
        return 'Missing name in front matter'
    }
    if (-not ($frontMatter | Where-Object { $_ -match '^description:\s*\S+' })) {
        return 'Missing description in front matter'
    }
    return ''
}

foreach ($rootSpec in $roots) {
    $root = $rootSpec.Path
    if (-not (Test-Path -LiteralPath $root -PathType Container)) {
        continue
    }
    $rootItem = Get-Item -LiteralPath $root
    $entries = Get-ChildItem -LiteralPath $root -Filter 'SKILL.md' -File -Recurse
    foreach ($entry in $entries) {
        $relative = Get-AgentRelativePath -BasePath $rootItem.FullName -TargetPath $entry.FullName
        $parts = $relative -split '[\\/]'
        $isRootEntrypoint = $parts.Count -eq $rootSpec.LegalParts -and $parts[$parts.Count - 1] -eq 'SKILL.md'
        if ($isRootEntrypoint) {
            $frontMatterError = Test-SkillFrontMatter -Path $entry.FullName
            if ($frontMatterError) {
                $violations.Add([pscustomobject]@{
                    Root = $rootItem.FullName
                    Reason = $frontMatterError
                    Path = $entry.FullName
                }) | Out-Null
            }
            continue
        }
        $reason = if ($relative -match '(^|[\\/])bak([\\/]|$)') {
            'SKILL.md inside bak directory'
        }
        else {
            'Nested SKILL.md under skill directory'
        }
        $violations.Add([pscustomobject]@{
            Root = $rootItem.FullName
            Reason = $reason
            Path = $entry.FullName
        }) | Out-Null
    }

    $skillMdDirs = Get-ChildItem -LiteralPath $root -Directory -Recurse -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -eq 'SKILL.md' }

    foreach ($dirEntry in $skillMdDirs) {
        $relative = Get-AgentRelativePath -BasePath $rootItem.FullName -TargetPath $dirEntry.FullName
        $reason = if ($relative -match '(^|[\\/])bak([\\/]|$)') {
            'Directory named SKILL.md under bak path'
        }
        else {
            'Directory named SKILL.md (forbidden; rename per hub backup policy e.g. SKILL_md)'
        }
        $violations.Add([pscustomobject]@{
            Root = $rootItem.FullName
            Reason = $reason
            Path = $dirEntry.FullName
        }) | Out-Null
    }
}

if ($violations.Count -eq 0) {
    Write-Output 'SKILL_ENTRYPOINTS=ok'
    exit 0
}

$violations | Format-Table Root, Reason, Path -AutoSize
Write-Output ("SKILL_ENTRYPOINTS=fail count={0}" -f $violations.Count)
exit 1
