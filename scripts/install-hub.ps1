# install-hub.ps1
# One-shot hub installer: links shared skills to user-level directories.
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
#   2. Link registry generic/global skills -> host user roots, including ~/.gemini/skills/ and ~/.gemini/config/skills/
#   3. Persist AGENTS_HUB_ROOT in shell profile
#   4. Set AGENTS_HUB_ROOT in current PowerShell profile (optional, -SkipProfile to skip)
#   5. Print a summary
# Optional: -ReplaceRealDirs removes user-level real skill dirs (that contain SKILL.md) before linking (destructive).

[CmdletBinding()]
param(
    [switch]$DryRun,
    [switch]$SkipRules,
    [switch]$SkipProfile,
    [switch]$ReplaceRealDirs,
    [string]$Tools = 'codex,claude,cursor',
    [string[]]$Skills = @(),
    [switch]$ApplyUserRules
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'agent-hub-paths.ps1')

# Hub root auto-detected from script location (no env var needed)
$agentsRoot  = Resolve-AgentHubRoot -ScriptRoot $PSScriptRoot
$userProfile = $env:USERPROFILE
$pythonBin   = Resolve-AgentPython3Interpreter
$geminiSkillPathsScript = Join-Path $agentsRoot 'skills\share\agent-hub-bootstrap\scripts\gemini-skill-paths.ps1'
if (Test-Path -LiteralPath $geminiSkillPathsScript) {
    . $geminiSkillPathsScript
}
$userGeminiSkillRoots = if (Get-Command Get-GeminiUserSkillRoots -ErrorAction SilentlyContinue) {
    @(Get-GeminiUserSkillRoots -UserHome $userProfile)
}
else {
    @((Join-Path $userProfile '.gemini\skills'), (Join-Path $userProfile '.gemini\config\skills'))
}
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
) + $userGeminiSkillRoots

$agentHubPy = Join-Path $PSScriptRoot 'agent_hub.py'
$includeSkills = ($Skills | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }) -join ','
$globalSkillRecords = @()
foreach ($layer in 'share', 'media', 'tooling', 'research') {
    $listArgs = @('list-skills', '--hub-root', $agentsRoot, '--project-type', 'generic', '--layer', $layer)
    if ($includeSkills) { $listArgs += @('--include', $includeSkills) }
    foreach ($name in @(& $pythonBin $agentHubPy @listArgs | Where-Object { $_ })) {
        $globalSkillRecords += [pscustomobject]@{
            Name = $name
            Target = Join-Path $agentsRoot ("skills\{0}\{1}" -f $layer, $name)
        }
    }
}
$selectedUserSkillNames = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
foreach ($item in $globalSkillRecords) { [void]$selectedUserSkillNames.Add($item.Name) }
$managedSkillsPrefix = [System.IO.Path]::GetFullPath((Join-Path $agentsRoot 'skills')).TrimEnd('\') + '\'

function Remove-StaleManagedUserSkillLinks {
    param([Parameter(Mandatory = $true)][string]$SkillRoot)
    if (-not (Test-Path -LiteralPath $SkillRoot)) { return }
    foreach ($item in @(Get-ChildItem -LiteralPath $SkillRoot -Directory -Force)) {
        $isReparse = ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0
        if (-not $isReparse) { continue }
        $target = if ($item.Target -is [System.Array]) { [string]$item.Target[0] } else { [string]$item.Target }
        if (-not $target) { continue }
        $targetFull = [System.IO.Path]::GetFullPath($target)
        if (-not $targetFull.StartsWith($managedSkillsPrefix, [System.StringComparison]::OrdinalIgnoreCase)) { continue }
        if ($selectedUserSkillNames.Contains($item.Name)) { continue }
        if ($DryRun) {
            Write-Host ("  [DRY-RUN] Remove stale managed skill: {0} -> {1}" -f $item.FullName, $targetFull)
        }
        else {
            [System.IO.Directory]::Delete($item.FullName)
            Write-Host ("  [REMOVED] {0} -> {1}" -f $item.FullName, $targetFull) -ForegroundColor DarkYellow
        }
    }
}

Write-Host "=== Linking global skills ===" -ForegroundColor Cyan
$installHubBlocked = 0
function Sync-AgentUserSkillLink {
    param(
        [Parameter(Mandatory)][string]$SkillRoot,
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$TargetPath
    )
    $linkPath = Join-Path $SkillRoot $Name
    if ($DryRun) {
        Write-Host ("  [DRY-RUN] Junction: {0} -> {1}" -f $linkPath, $TargetPath)
        return
    }
    if (Test-Path -LiteralPath $linkPath) {
        $existing = Get-Item -LiteralPath $linkPath -Force
        $isReparse = ($existing.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0
        if ($isReparse) {
            $currentTarget = @($existing.Target)
            if ($currentTarget -contains $TargetPath) {
                Write-Host ("  [OK]  {0}" -f $linkPath) -ForegroundColor Green
                return
            }
            [System.IO.Directory]::Delete($linkPath)
        }
        elseif (Test-Path -LiteralPath (Join-Path $linkPath 'SKILL.md')) {
            if ($ReplaceRealDirs) { Remove-Item -LiteralPath $linkPath -Recurse -Force }
            else {
                Write-Host ("  [SKIP] Real dir exists, won't overwrite: {0}" -f $linkPath) -ForegroundColor Yellow
                $script:installHubBlocked++
                return
            }
        }
        else { Remove-Item -LiteralPath $linkPath -Recurse -Force }
    }
    New-Item -ItemType Junction -Path $linkPath -Target $TargetPath | Out-Null
    Write-Host ("  [NEW] {0}" -f $linkPath) -ForegroundColor DarkGreen
}
foreach ($skillRoot in $userSkillRoots) {
    if (-not $DryRun) { Ensure-AgentDirectory -Path $skillRoot }
    Remove-StaleManagedUserSkillLinks -SkillRoot $skillRoot
    foreach ($item in $globalSkillRecords) {
        Sync-AgentUserSkillLink -SkillRoot $skillRoot -Name $item.Name -TargetPath $item.Target
    }
}
Write-Host ""

if ($installHubBlocked -gt 0 -and -not $DryRun) {
    Write-Host ("=== install-hub FAILED: {0} skill link(s) blocked (real directories at user skill paths). Remove, rename, or re-run with -ReplaceRealDirs (destructive: deletes that directory)." -f $installHubBlocked) -ForegroundColor Red
    exit 1
}

# ---------------------------------------------------------------------------
# 2. Generate global rules and optionally apply managed user targets
# ---------------------------------------------------------------------------
if (-not $SkipRules) {
    Write-Host "=== User-level rules ===" -ForegroundColor Cyan
    $ruleArgs = @(
        'sync-agent-rules', '--hub-root', $agentsRoot, '--project-root', $agentsRoot,
        '--project-key', 'agents', '--projection-mode', 'layered', '--scope', 'global', '--hosts', $Tools
    )
    if ($includeSkills) { $ruleArgs += @('--skills', $includeSkills) }
    if ($ApplyUserRules) { $ruleArgs += '--apply-user-targets' }
    if ($DryRun) { $ruleArgs += '--dry-run' }
    & $pythonBin $agentHubPy @ruleArgs
    if ($LASTEXITCODE -ne 0) { throw 'Global rule initialization failed.' }
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
Write-Host "  Global skills  : $($globalSkillRecords.Count) -> user roots including Gemini CLI ~/.gemini/skills and Antigravity ~/.gemini/config/skills"
Write-Host "  Global rules   : hosts=$Tools apply_user_targets=$ApplyUserRules"
Write-Host "  Next step      : cd <your-project> && & `"$agentsRoot\scripts\register-project.ps1`""
Write-Host ""
Write-Host "=== Done ===" -ForegroundColor Green
