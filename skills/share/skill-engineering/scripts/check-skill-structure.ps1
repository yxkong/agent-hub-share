[CmdletBinding()]
param(
    [string]$HubRoot = '',
    [switch]$OnlyShare,
    [string[]]$SkillRoot = @()
)

$ErrorActionPreference = 'Stop'
$__hubScripts = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\..\..\scripts'))
. (Join-Path $__hubScripts 'agent-hub-paths.ps1')

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

function Get-CrossSubdirMdLinkViolations {
    param(
        [Parameter(Mandatory = $true)][string]$SkillRootPath,
        [Parameter(Mandatory = $true)][string]$RefDir,
        [string[]]$SemanticDirNames = @()
    )

    $violations = New-Object System.Collections.Generic.List[string]
    if ($SemanticDirNames.Count -eq 0) {
        return $violations
    }

    $mdFiles = Get-ChildItem -LiteralPath $RefDir -Recurse -File -Filter '*.md' -Force -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -notmatch '[\\/]bak(\\|/|$)' }

    foreach ($mdFile in $mdFiles) {
        $rel = Get-AgentRelativePath -BasePath $RefDir -TargetPath $mdFile.FullName
        $parts = $rel -split '[\\/]'
        if ($parts.Count -ne 2 -or ($parts[1] -notmatch '\.[mM][dD]$')) {
            continue
        }

        $currSem = $parts[0]
        if ($currSem -eq 'bak') {
            continue
        }

        foreach ($sib in $SemanticDirNames) {
            if ($sib -eq $currSem) {
                continue
            }
            $hit = $false
            foreach ($pat in @(
                    "](../$sib/",
                    "](./../$sib/",
                    "](../$sib.md)",
                    "](./../$sib.md)"
                )) {
                if (Select-String -LiteralPath $mdFile.FullName -Pattern $pat -SimpleMatch -Quiet -ErrorAction SilentlyContinue) {
                    $hit = $true
                    break
                }
            }
            if ($hit) {
                $message = "SKILL_STRUCTURE_VIOLATION={0} reason=references subdir '{1}' must not link to sibling '{2}' via relative Markdown path; route via root file or merge docs" -f $mdFile.FullName, $currSem, $sib
                $violations.Add($message) | Out-Null
            }
        }
    }

    return $violations
}

function Test-SkillReferencesTree {
    param([Parameter(Mandatory = $true)][string]$SkillRootParam)

    $refDir = Join-Path $SkillRootParam 'references'
    if (-not (Test-Path -LiteralPath $refDir -PathType Container)) {
        return @()
    }

    $violations = New-Object System.Collections.Generic.List[string]

    $topCount = (Get-ChildItem -LiteralPath $refDir -File -Filter '*.md' -Force -ErrorAction SilentlyContinue | Measure-Object).Count
    if ($topCount -gt 15) {
        $message = "SKILL_STRUCTURE_VIOLATION={0} reason=references top-level *.md exceeds limit (current {1}, max 15); merge, move into semantic subdirs, or archive to bak" -f $refDir, $topCount
        $violations.Add($message) | Out-Null
    }

    $semanticDirNames = New-Object System.Collections.Generic.List[string]
    Get-ChildItem -LiteralPath $refDir -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        if ($_.Name -eq 'bak') {
            return
        }
        $semanticDirNames.Add($_.Name) | Out-Null

        $nestedImmediate = Get-ChildItem -LiteralPath $_.FullName -Directory -Force -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -ne 'bak' } |
            Select-Object -First 1
        if ($null -ne $nestedImmediate) {
            $message = "SKILL_STRUCTURE_VIOLATION={0} reason=references semantic subdir must not contain nested directories" -f $_.FullName
            $violations.Add($message) | Out-Null
        }

        $subCount = (Get-ChildItem -LiteralPath $_.FullName -File -Filter '*.md' -Force -ErrorAction SilentlyContinue | Measure-Object).Count
        if ($subCount -gt 15) {
            $message = "SKILL_STRUCTURE_VIOLATION={0} reason=semantic subdir *.md exceeds limit (current {1}, max 15)" -f $_.FullName, $subCount
            $violations.Add($message) | Out-Null
        }
    }

    if ($semanticDirNames.Count -gt 0) {
        (Get-CrossSubdirMdLinkViolations -SkillRootPath $SkillRootParam -RefDir $refDir -SemanticDirNames ($semanticDirNames.ToArray())) |
            ForEach-Object { $violations.Add($_) | Out-Null }
    }

    return $violations
}

$agentsRoot = Resolve-AgentHubRoot -HubRoot $HubRoot -ScriptRoot $__hubScripts
$skillsRoot = Join-Path $agentsRoot 'skills'
$allViolations = New-Object System.Collections.Generic.List[string]

if ($SkillRoot.Count -gt 0) {
    foreach ($srRaw in $SkillRoot) {
        if ([string]::IsNullOrWhiteSpace($srRaw)) {
            continue
        }
        $sr = (Resolve-Path -LiteralPath $srRaw.Trim()).Path
        $skillMd = Join-Path $sr 'SKILL.md'
        if (-not (Test-Path -LiteralPath $skillMd -PathType Leaf)) {
            throw "check-skill-structure: -SkillRoot must point to a directory containing SKILL.md: $sr"
        }
        (Test-SkillReferencesTree -SkillRootParam $sr) | ForEach-Object { $allViolations.Add($_) | Out-Null }
    }
}
else {
    $pairs = @(
        [pscustomobject]@{ SubRoot = (Join-Path $skillsRoot 'share'); Depth = 2 }
        [pscustomobject]@{ SubRoot = (Join-Path $skillsRoot 'media'); Depth = 2 }
    )
    if (-not $OnlyShare) {
        $pairs += [pscustomobject]@{ SubRoot = (Join-Path $skillsRoot 'projects'); Depth = 3 }
    }

    foreach ($pair in $pairs) {
        if (-not (Test-Path -LiteralPath $pair.SubRoot -PathType Container)) {
            continue
        }
        $rootItem = Get-Item -LiteralPath $pair.SubRoot
        Get-ChildItem -LiteralPath $pair.SubRoot -Filter 'SKILL.md' -File -Recurse | ForEach-Object {
            $relative = Get-AgentRelativePath -BasePath $rootItem.FullName -TargetPath $_.FullName
            $parts = $relative -split '[\\/]'
            if ($parts.Count -ne $pair.Depth) {
                return
            }
            $oneSkillRoot = Split-Path -Parent $_.FullName
            (Test-SkillReferencesTree -SkillRootParam $oneSkillRoot) | ForEach-Object { $allViolations.Add($_) | Out-Null }
        }
    }
}

if ($allViolations.Count -eq 0) {
    Write-Output 'SKILL_REFERENCES_STRUCTURE=ok'
    exit 0
}

$allViolations | ForEach-Object { Write-Output $_ }
Write-Output ("SKILL_REFERENCES_STRUCTURE=fail count={0}" -f $allViolations.Count)
exit 1
