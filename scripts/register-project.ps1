# register-project.ps1
# One-shot: scaffold hub project structure, validate user-level links, then run init-project-agenting.
#
# Usage:
#   $env:AGENTS_HUB_ROOT = '<hub-root>'
#   & "$env:AGENTS_HUB_ROOT\scripts\register-project.ps1" `
#       -ProjectRoot '<project-repo-root>' `
#       -ProjectKey  'my-app'
#
# If run from inside the target project directory, -ProjectRoot can be omitted.
# -ProjectKey defaults to the folder name of -ProjectRoot.

[CmdletBinding()]
param(
    [string]$HubRoot       = '',
    [string]$ProjectRoot   = '',
    [string]$ProjectKey    = '',
    [switch]$SkipRules,
    [switch]$SkipSharedSkills,
    [switch]$SkipProjectSkills,
    [switch]$SkipUserTargets,
    [switch]$SkipPrompts,
    [switch]$LinkUserSkills,
    [switch]$LinkShareToWorkspace,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'agent-hub-paths.ps1')

# ---------------------------------------------------------------------------
# Resolve paths
# ---------------------------------------------------------------------------
$agentsRoot           = Resolve-AgentHubRoot -HubRoot $HubRoot -ScriptRoot $PSScriptRoot
$resolvedProjectRoot  = Resolve-AgentWorkspaceRoot -WorkspaceRoot $ProjectRoot -AllowCurrentLocation
$resolvedProjectKey   = Resolve-AgentProjectKey -ProjectKey $ProjectKey -WorkspaceRoot $resolvedProjectRoot

if (-not $resolvedProjectRoot) {
    throw 'register-project requires -ProjectRoot, AGENTS_DEFAULT_PROJECT_ROOT, or running from inside the target workspace.'
}
if (-not $resolvedProjectKey) {
    throw 'register-project requires -ProjectKey, AGENTS_DEFAULT_PROJECT_KEY, or a workspace root whose folder name can be used as the project key.'
}

Write-Host ""
Write-Host "=== register-project ===" -ForegroundColor Cyan
Write-Host "  Hub root      : $agentsRoot"
Write-Host "  Project root  : $resolvedProjectRoot"
Write-Host "  Project key   : $resolvedProjectKey"
if ($DryRun) { Write-Host "  [DRY-RUN - no files will be written]" -ForegroundColor Yellow }
Write-Host ""

# ---------------------------------------------------------------------------
# 1. Scaffold hub project structure
# ---------------------------------------------------------------------------
$hubProjectRulesDir   = Join-Path $agentsRoot "rules\projects\$resolvedProjectKey"
$hubProjectSkillsDir  = Join-Path $agentsRoot "skills\projects\$resolvedProjectKey"
$hubProjectPromptsDir = Join-Path $agentsRoot "prompts\projects\$resolvedProjectKey"
$promptsReadme        = Join-Path $hubProjectPromptsDir 'README.md'
$rulesFile            = Join-Path $hubProjectRulesDir 'PROJECT_RULES.md'

if (-not (Test-Path -LiteralPath $hubProjectRulesDir)) {
    Write-Host "[scaffold] Creating hub rules dir: $hubProjectRulesDir"
    if (-not $DryRun) { New-Item -ItemType Directory -Path $hubProjectRulesDir -Force | Out-Null }
}

# PROJECT_RULES.md is not auto-scaffolded; add it manually when the project has incremental rules.

if (-not (Test-Path -LiteralPath $hubProjectSkillsDir)) {
    Write-Host "[scaffold] Creating hub skills dir: $hubProjectSkillsDir"
    if (-not $DryRun) { New-Item -ItemType Directory -Path $hubProjectSkillsDir -Force | Out-Null }
}

if (-not (Test-Path -LiteralPath $hubProjectPromptsDir)) {
    Write-Host "[scaffold] Creating hub project prompts dir: $hubProjectPromptsDir"
    if ($DryRun) {
        Write-Host "[scaffold]   (dry-run) would create directory: $hubProjectPromptsDir"
    }
    else {
        New-Item -ItemType Directory -Path $hubProjectPromptsDir -Force | Out-Null
    }
}

if (-not (Test-Path -LiteralPath $promptsReadme)) {
    Write-Host "[scaffold] Creating project prompts README skeleton"
    $readmeLines = @(
        "# $resolvedProjectKey project prompts",
        '',
        'Project-specific reusable prompts live here as `*.prompt.md`; front matter and sections follow the `prompt-engineering` skill.',
        '',
        '- Cross-project prompts: hub `prompts/share/`',
        '- Sync into workspace: `sync-prompts` (default after `init-project-agenting`; use `-SkipPrompts` to skip)',
        '',
        '## Suggested subfolders',
        '',
        'Optional: `api/`, `frontend/`, etc.',
        ''
    )
    $readmeBody = ($readmeLines -join "`n")
    if ($DryRun) {
        Write-Host "[scaffold]   (dry-run) would write: $promptsReadme"
    }
    else {
        Ensure-AgentDirectory -Path $hubProjectPromptsDir
        Write-AgentUtf8NoBomFile -Path $promptsReadme -Content $readmeBody
    }
    Write-Host "[scaffold]   -> $promptsReadme"
} else {
    Write-Host "[scaffold] project prompts README already exists, skipping scaffold."
}

$projectSkillsReadme = Join-Path $hubProjectSkillsDir 'README.md'
if (-not (Test-Path -LiteralPath $projectSkillsReadme)) {
    Write-Host "[scaffold] Creating project skills README skeleton"
    $psReadmeLines = @(
        "# $resolvedProjectKey 项目技能",
        '',
        "> **真源**：hub 内 skills/projects/$resolvedProjectKey/",
        '> **Agent 全局规则** → 各仓库 `AGENTS.md`',
        '',
        '## 领域技能',
        '',
        '| 技能 | 用途 |',
        '|------|------|',
        '| TODO | TODO |',
        '',
        '## 本仓库 docs 域索引（可选）',
        '',
        '<repo>/docs/guide/DOCS_GOVERNANCE.md',
        ''
    )
    $psReadmeBody = ($psReadmeLines -join "`n")
    if ($DryRun) {
        Write-Host "[scaffold]   (dry-run) would write: $projectSkillsReadme"
    }
    else {
        Ensure-AgentDirectory -Path $hubProjectSkillsDir
        Write-AgentUtf8NoBomFile -Path $projectSkillsReadme -Content $psReadmeBody
    }
    Write-Host "[scaffold]   -> $projectSkillsReadme"
} else {
    Write-Host "[scaffold] project skills README already exists, skipping scaffold."
}

Write-Host ""

# ---------------------------------------------------------------------------
# 2. Validate user-level agent targets
# ---------------------------------------------------------------------------
$userProfile = $env:USERPROFILE
$userTargets = @{
    'Claude CLAUDE.md'    = Join-Path $userProfile '.claude\CLAUDE.md'
    'Codex AGENTS.md'     = Join-Path $userProfile '.codex\AGENTS.md'
    'Claude skills/'      = Join-Path $userProfile '.claude\skills'
    'Cursor skills/'      = Join-Path $userProfile '.cursor\skills'
    'Codex skills/'       = Join-Path $userProfile '.codex\skills'
}

Write-Host "=== User-level target validation ===" -ForegroundColor Cyan
$anyMissing = $false
foreach ($label in $userTargets.Keys | Sort-Object) {
    $path   = $userTargets[$label]
    $exists = Test-Path -LiteralPath $path
    $icon   = if ($exists) { '[OK]' } else { '[MISSING]' }
    $color  = if ($exists) { 'Green' } else { 'Yellow' }
    Write-Host ("  {0,-22} {1}" -f $icon, $path) -ForegroundColor $color
    if (-not $exists) { $anyMissing = $true }
}

if ($anyMissing) {
    Write-Host ""
    Write-Host "  Tip: new machine should run hub install-hub first; register-project/sync-user targets refresh automatically for shared skills." -ForegroundColor Yellow
}
Write-Host ""

# ---------------------------------------------------------------------------
# 3. Validate project workspace targets
# ---------------------------------------------------------------------------
$projectTargets = @{
    'AGENTS.md'              = Join-Path $resolvedProjectRoot 'AGENTS.md'
    'CLAUDE.md'              = Join-Path $resolvedProjectRoot 'CLAUDE.md'
    '.cursorrules'           = Join-Path $resolvedProjectRoot '.cursorrules'
    '.cursor/rules/00-common.mdc' = Join-Path $resolvedProjectRoot '.cursor\rules\00-common.mdc'
    '.agents/skills/'        = Join-Path $resolvedProjectRoot '.agents\skills'
    '.cursor/skills/'        = Join-Path $resolvedProjectRoot '.cursor\skills'
}

Write-Host "=== Project workspace target validation ===" -ForegroundColor Cyan
foreach ($label in $projectTargets.Keys | Sort-Object) {
    $path   = $projectTargets[$label]
    $exists = Test-Path -LiteralPath $path
    $icon   = if ($exists) { '[OK]' } else { '[WILL CREATE]' }
    $color  = if ($exists) { 'Green' } else { 'DarkYellow' }
    Write-Host ("  {0,-22} {1}" -f $icon, $path) -ForegroundColor $color
}
Write-Host ""

# ---------------------------------------------------------------------------
# 4. Run init-project-agenting
# ---------------------------------------------------------------------------
if (-not $DryRun) {
    Write-Host "=== Running init-project-agenting ===" -ForegroundColor Cyan
    $initScript = Join-Path $PSScriptRoot 'init-project-agenting.ps1'
    $initArgs = @{
        HubRoot    = $agentsRoot
        ProjectRoot = $resolvedProjectRoot
        ProjectKey  = $resolvedProjectKey
    }
    if ($SkipRules)         { $initArgs.SkipRules         = $true }
    if ($SkipSharedSkills)  { $initArgs.SkipSharedSkills  = $true }
    if ($SkipProjectSkills) { $initArgs.SkipProjectSkills = $true }
    if ($SkipUserTargets)   { $initArgs.SkipUserTargets   = $true }
    if ($SkipPrompts)       { $initArgs.SkipPrompts       = $true }
    if ($LinkUserSkills)    { $initArgs.LinkUserSkills     = $true }
    if ($LinkShareToWorkspace) { $initArgs.LinkShareToWorkspace = $true }

    & $initScript @initArgs
    Write-Host ""
}

# ---------------------------------------------------------------------------
# 5. Hub prompts gate (full hub scan + index refresh)
# ---------------------------------------------------------------------------
if (-not $DryRun -and -not $SkipPrompts) {
    Write-Host "=== Running check-prompts ===" -ForegroundColor Cyan
    $checkPromptsScript = Join-Path $PSScriptRoot 'check-prompts.ps1'
    & $checkPromptsScript -HubRoot $agentsRoot
    Write-Host "=== Running build-prompt-index ===" -ForegroundColor Cyan
    $buildIndexScript = Join-Path $PSScriptRoot 'build-prompt-index.ps1'
    & $buildIndexScript -HubRoot $agentsRoot
    $idx = Join-Path $agentsRoot 'prompts\indexes\prompts.index.json'
    Write-Host ("  PROMPTS_CHECK=ok index={0}" -f $idx) -ForegroundColor Green
    Write-Host ""
}

# ---------------------------------------------------------------------------
# 6. Skill links
# ---------------------------------------------------------------------------
Write-Host "=== Running check-skill-links ===" -ForegroundColor Cyan
$checkScript = Join-Path $PSScriptRoot 'check-skill-links.ps1'
if (-not $DryRun) {
    & $checkScript -RepoRoot $resolvedProjectRoot -HubRoot $agentsRoot -ProjectKey $resolvedProjectKey
} else {
    Write-Host "  [DRY-RUN] Skipped check-skill-links."
}

Write-Host ""
Write-Host "=== Done ===" -ForegroundColor Green
Write-Host "  Hub PROJECT_RULES : $rulesFile"
if (-not $SkipPrompts) {
    Write-Host "  Hub prompts       : $hubProjectPromptsDir"
    Write-Host "  Prompt index      : $(Join-Path $agentsRoot 'prompts\indexes\prompts.index.json')"
    if (-not $DryRun) {
        $wAgents = Join-Path $resolvedProjectRoot '.agents\prompts\hub-project'
        $wCursor = Join-Path $resolvedProjectRoot '.cursor\prompts\hub-project'
        Write-Host "  WS .agents link   : $wAgents -> $hubProjectPromptsDir"
        Write-Host "  WS .cursor link   : $wCursor -> $hubProjectPromptsDir"
    }
}
Write-Host "  Next step         : edit PROJECT_RULES.md + skills/projects/$resolvedProjectKey/README.md; optional <repo>/docs/guide/DOCS_GOVERNANCE.md; then sync-agent-rules.ps1"
