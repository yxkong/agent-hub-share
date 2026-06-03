[CmdletBinding()]
param(
    [string]$HubRoot = '',
    [string[]]$SkillRoot = @()
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'agent-hub-paths.ps1')

function Test-SharePrivateCoupling {
    param([Parameter(Mandatory = $true)][string]$SkillRootPath)

    $violations = New-Object System.Collections.Generic.List[string]
    $files = New-Object System.Collections.Generic.List[string]

    foreach ($file in @(
            (Join-Path $SkillRootPath 'SKILL.md'),
            (Join-Path $SkillRootPath 'README.md')
        )) {
        if (Test-Path -LiteralPath $file -PathType Leaf) {
            $files.Add($file) | Out-Null
        }
    }

    $refDir = Join-Path $SkillRootPath 'references'
    if (Test-Path -LiteralPath $refDir -PathType Container) {
        Get-ChildItem -LiteralPath $refDir -Recurse -File -Filter '*.md' -Force -ErrorAction SilentlyContinue |
            Where-Object { $_.FullName -notmatch '[\\/]bak(\\|/|$)' } |
            ForEach-Object { $files.Add($_.FullName) | Out-Null }
    }

    $patterns = @(
        @{
            Regex  = 'platform-[a-z0-9][a-z0-9-]*'
            Reason = 'share skill must not hardcode real project/module prefix `platform-*`; replace with placeholders such as <project-key> / <runtime-module> / <domain-module>'
        },
        @{
            Regex  = 'platform-jdk17|platform-admin|platform-review|platform-backend-dev|platform-core'
            Reason = 'share skill must not hardcode private project or repository names; replace with generic placeholders or examples'
        },
        @{
            Regex  = 'admin-system-base(?:-frontend)?'
            Reason = 'share skill must not hardcode private module names; replace with generic placeholders such as <frontend-app> / <domain-module>'
        },
        @{
            Regex  = 'PLATFORM_DOCS_GOVERNANCE'
            Reason = 'replace legacy repo-specific docs governance filename with docs/guide/DOCS_GOVERNANCE.md or another generic project-local name'
        },
        @{
            Regex  = 'D:\\ai\\|D:/ai/'
            Reason = 'share skill must not include local absolute hub paths; use <hub-root> or repo-relative paths'
        },
        @{
            Regex  = 'ai-hub-private|yxkong/ai-hub-private'
            Reason = 'share skill must not refer to the private source repository; public-facing assets should use agent-hub-share or <hub-root>'
        },
        @{
            Regex  = 'wechat-article-writing|skills/media/'
            Reason = 'share skill must not expose non-export skill paths; use <private-media-skill> or maintainer hub docs'
        }
    )

    foreach ($file in ($files | Select-Object -Unique)) {
        foreach ($rule in $patterns) {
            $match = Select-String -LiteralPath $file -Pattern $rule.Regex -CaseSensitive:$false -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($null -ne $match) {
                $violations.Add(("SHARE_SKILL_PRIVATE_COUPLING_VIOLATION={0} reason={1} first_match={2}" -f $file, $rule.Reason, $match.Matches[0].Value)) | Out-Null
            }
        }
    }

    return $violations
}

$agentsRoot = Resolve-AgentHubRoot -HubRoot $HubRoot -ScriptRoot $PSScriptRoot
$shareRoot = Join-Path $agentsRoot 'skills\share'
$allViolations = New-Object System.Collections.Generic.List[string]

if ($SkillRoot.Count -gt 0) {
    foreach ($srRaw in $SkillRoot) {
        if ([string]::IsNullOrWhiteSpace($srRaw)) {
            continue
        }
        $sr = (Resolve-Path -LiteralPath $srRaw.Trim()).Path
        $skillMd = Join-Path $sr 'SKILL.md'
        if (-not (Test-Path -LiteralPath $skillMd -PathType Leaf)) {
            throw "check-share-skill-private-coupling: -SkillRoot must point to a directory containing SKILL.md: $sr"
        }
        if (-not $sr.StartsWith($shareRoot + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase)) {
            throw "check-share-skill-private-coupling: -SkillRoot must be under share root: $sr"
        }
        (Test-SharePrivateCoupling -SkillRootPath $sr) | ForEach-Object { $allViolations.Add($_) | Out-Null }
    }
}
elseif (Test-Path -LiteralPath $shareRoot -PathType Container) {
    $rootItem = Get-Item -LiteralPath $shareRoot
    Get-ChildItem -LiteralPath $shareRoot -Filter 'SKILL.md' -File -Recurse | ForEach-Object {
        $relative = [System.IO.Path]::GetRelativePath($rootItem.FullName, $_.FullName)
        $parts = $relative -split '[\\/]'
        if ($parts.Count -ne 2) {
            return
        }
        $oneSkillRoot = Split-Path -Parent $_.FullName
        (Test-SharePrivateCoupling -SkillRootPath $oneSkillRoot) | ForEach-Object { $allViolations.Add($_) | Out-Null }
    }
}

if ($allViolations.Count -eq 0) {
    Write-Output 'SHARE_SKILL_PRIVATE_COUPLING=ok'
    exit 0
}

$allViolations | ForEach-Object { Write-Output $_ }
Write-Output ("SHARE_SKILL_PRIVATE_COUPLING=fail count={0}" -f $allViolations.Count)
exit 1
