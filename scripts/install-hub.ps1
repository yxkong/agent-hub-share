# install-hub.ps1
# One-shot hub installer: links shared skills and global rules to user-level directories.
# No parameters needed - hub root is auto-detected from the script's own location.
#
# Usage (from anywhere, no env var required):
#   & "<hub-root>\scripts\install-hub.ps1"
#   # or cd into hub scripts/ and run:
#   cd <hub-root>\scripts
#   .\install-hub.ps1
#
# What it does:
#   1. Auto-detect hub root (script lives inside hub/scripts/)
#   2. Link all shared skills -> ~/.claude/skills/, ~/.cursor/skills/, ~/.codex/skills/, ~/.agents/skills/
#   3. Sync global rules    -> ~/.claude/CLAUDE.md, ~/.codex/AGENTS.md
#   4. Set AGENTS_HUB_ROOT in current PowerShell profile (optional, -SkipProfile to skip)
#   5. Print a summary
# Optional: -ReplaceRealDirs removes user-level real skill dirs (that contain SKILL.md) before linking (destructive).

[CmdletBinding()]
param(
    [switch]$DryRun,
    [switch]$SkipRules,
    [switch]$SkipProfile,
    [switch]$ReplaceRealDirs
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'agent-hub-paths.ps1')

# Hub root auto-detected from script location (no env var needed)
$agentsRoot  = Resolve-AgentHubRoot -ScriptRoot $PSScriptRoot
$userProfile = $env:USERPROFILE
$shareRoot   = Join-Path $agentsRoot 'skills\share'
$mediaRoot   = Join-Path $agentsRoot 'skills\media'
$entrypointCheckScript = Join-Path $PSScriptRoot 'check-skill-entrypoints.ps1'
if (Test-Path -LiteralPath $entrypointCheckScript) {
    & $entrypointCheckScript -HubRoot $agentsRoot
}

Write-Host ""
Write-Host "=== install-hub ===" -ForegroundColor Cyan
Write-Host "  Hub root    : $agentsRoot"
Write-Host "  User home   : $userProfile"
if ($DryRun) { Write-Host "  [DRY-RUN - no files will be written]" -ForegroundColor Yellow }
Write-Host ""

# ---------------------------------------------------------------------------
# 1. Link shared skills to user-level directories
# ---------------------------------------------------------------------------
$userSkillRoots = @(
    Join-Path $userProfile '.claude\skills'
    Join-Path $userProfile '.cursor\skills'
    Join-Path $userProfile '.codex\skills'
    Join-Path $userProfile '.agents\skills'
)

$shareSkillNames = [System.IO.Directory]::GetDirectories($shareRoot) | ForEach-Object {
    $name = Split-Path $_ -Leaf
    if (Test-Path (Join-Path $_ 'SKILL.md')) { $name }
}
$mediaSkillNames = @()
if (Test-Path -LiteralPath $mediaRoot) {
    $mediaSkillNames = [System.IO.Directory]::GetDirectories($mediaRoot) | ForEach-Object {
        $name = Split-Path $_ -Leaf
        if (Test-Path (Join-Path $_ 'SKILL.md')) { $name }
    }
}

Write-Host "=== Linking shared skills ===" -ForegroundColor Cyan
$installHubBlocked = 0
foreach ($skillRoot in $userSkillRoots) {
    if (-not $DryRun) { Ensure-AgentDirectory -Path $skillRoot }

    foreach ($name in $shareSkillNames) {
        $linkPath   = Join-Path $skillRoot $name
        $targetPath = Join-Path $shareRoot $name

        if ($DryRun) {
            Write-Host ("  [DRY-RUN] Junction: {0} -> {1}" -f $linkPath, $targetPath)
            continue
        }

        if (Test-Path -LiteralPath $linkPath) {
            $existing = Get-Item -LiteralPath $linkPath -Force
            $isReparse = ($existing.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0
            if ($isReparse) {
                $currentTarget = $existing.Target
                if ($currentTarget -contains $targetPath) {
                    Write-Host ("  [OK]  {0}" -f $linkPath) -ForegroundColor Green
                    continue
                }
                [System.IO.Directory]::Delete($linkPath)
            } elseif (Test-Path -LiteralPath (Join-Path $linkPath 'SKILL.md')) {
                if ($ReplaceRealDirs) {
                    Remove-Item -LiteralPath $linkPath -Recurse -Force
                }
                else {
                    Write-Host ("  [SKIP] Real dir exists, won't overwrite: {0}" -f $linkPath) -ForegroundColor Yellow
                    $installHubBlocked++
                    continue
                }
            } else {
                Remove-Item -LiteralPath $linkPath -Recurse -Force
            }
        }
        New-Item -ItemType Junction -Path $linkPath -Target $targetPath | Out-Null
        Write-Host ("  [NEW] {0}" -f $linkPath) -ForegroundColor DarkGreen
    }

    foreach ($name in $mediaSkillNames) {
        $linkPath   = Join-Path $skillRoot $name
        $targetPath = Join-Path $mediaRoot $name

        if ($DryRun) {
            Write-Host ("  [DRY-RUN] Junction: {0} -> {1}" -f $linkPath, $targetPath)
            continue
        }

        if (Test-Path -LiteralPath $linkPath) {
            $existing = Get-Item -LiteralPath $linkPath -Force
            $isReparse = ($existing.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0
            if ($isReparse) {
                $currentTarget = $existing.Target
                if ($currentTarget -contains $targetPath) {
                    Write-Host ("  [OK]  {0}" -f $linkPath) -ForegroundColor Green
                    continue
                }
                [System.IO.Directory]::Delete($linkPath)
            } elseif (Test-Path -LiteralPath (Join-Path $linkPath 'SKILL.md')) {
                if ($ReplaceRealDirs) {
                    Remove-Item -LiteralPath $linkPath -Recurse -Force
                }
                else {
                    Write-Host ("  [SKIP] Real dir exists, won't overwrite: {0}" -f $linkPath) -ForegroundColor Yellow
                    $installHubBlocked++
                    continue
                }
            } else {
                Remove-Item -LiteralPath $linkPath -Recurse -Force
            }
        }
        New-Item -ItemType Junction -Path $linkPath -Target $targetPath | Out-Null
        Write-Host ("  [NEW] {0}" -f $linkPath) -ForegroundColor DarkGreen
    }
}
Write-Host ""

if ($installHubBlocked -gt 0 -and -not $DryRun) {
    Write-Host ("=== install-hub FAILED: {0} skill link(s) blocked (real directories at user skill paths). Remove, rename, or re-run with -ReplaceRealDirs (destructive: deletes that directory)." -f $installHubBlocked) -ForegroundColor Red
    exit 1
}

# ---------------------------------------------------------------------------
# 2. Sync global rules to user-level files
# ---------------------------------------------------------------------------
if (-not $SkipRules) {
    Write-Host "=== Syncing global rules ===" -ForegroundColor Cyan
    if (-not $DryRun) {
        $syncRulesScript = Join-Path $PSScriptRoot 'sync-agent-rules.ps1'
        & $syncRulesScript -HubRoot $agentsRoot -SkipUserTargets:$false
    } else {
        Write-Host "  [DRY-RUN] Would run sync-agent-rules.ps1 -SkipUserTargets:`$false"
    }
    Write-Host ""
}

# ---------------------------------------------------------------------------
# 3. Optionally persist AGENTS_HUB_ROOT in PowerShell profile
# ---------------------------------------------------------------------------
if (-not $SkipProfile -and -not $DryRun) {
    $profilePath = $PROFILE.CurrentUserAllHosts
    $envLine     = "`$env:AGENTS_HUB_ROOT = '$agentsRoot'"

    if (-not (Test-Path $profilePath)) {
        Ensure-AgentDirectory -Path (Split-Path $profilePath)
        Write-AgentUtf8NoBomFile -Path $profilePath -Content ($envLine + "`n")
        Write-Host "=== Profile ===" -ForegroundColor Cyan
        Write-Host "  Created profile and added AGENTS_HUB_ROOT: $profilePath" -ForegroundColor DarkGreen
    } elseif (-not (Select-String -LiteralPath $profilePath -Pattern 'AGENTS_HUB_ROOT' -Quiet)) {
        Add-Content -LiteralPath $profilePath -Value "`n$envLine"
        Write-Host "=== Profile ===" -ForegroundColor Cyan
        Write-Host "  Added AGENTS_HUB_ROOT to existing profile: $profilePath" -ForegroundColor DarkGreen
    } else {
        Write-Host "=== Profile ===" -ForegroundColor Cyan
        Write-Host "  AGENTS_HUB_ROOT already in profile: $profilePath" -ForegroundColor Green
    }
    $env:AGENTS_HUB_ROOT = $agentsRoot
    Write-Host ""
}

# ---------------------------------------------------------------------------
# 4. Summary
# ---------------------------------------------------------------------------
Write-Host "=== Summary ===" -ForegroundColor Cyan
Write-Host "  Hub            : $agentsRoot"
Write-Host "  Share skills   : $($shareSkillNames.Count) -> ~/.claude/skills, ~/.cursor/skills, ~/.codex/skills, ~/.agents/skills"
Write-Host "  Media skills   : $($mediaSkillNames.Count) -> ~/.claude/skills, ~/.cursor/skills, ~/.codex/skills, ~/.agents/skills"
Write-Host "  Next step      : cd <your-project> && & `"$agentsRoot\scripts\register-project.ps1`""
Write-Host ""
Write-Host "=== Done ===" -ForegroundColor Green
