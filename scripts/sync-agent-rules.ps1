[CmdletBinding()]
param(
    [string]$HubRoot = '',
    [string]$ProjectRoot = '',
    [string]$ProjectKey = '',
    [switch]$SkipUserTargets
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'agent-hub-paths.ps1')

$agentsRoot = Resolve-AgentHubRoot -HubRoot $HubRoot -ScriptRoot $PSScriptRoot
$resolvedProjectRoot = Resolve-AgentWorkspaceRoot -WorkspaceRoot $ProjectRoot -AllowCurrentLocation
$resolvedProjectKey = Resolve-AgentProjectKey -ProjectKey $ProjectKey -WorkspaceRoot $resolvedProjectRoot
if (-not $resolvedProjectKey) {
    throw 'Project rules sync requires -ProjectKey, AGENTS_DEFAULT_PROJECT_KEY, or a workspace root whose folder name can be used as the project key.'
}

$commonPath = Join-Path $agentsRoot 'rules\common\COMMON_AGENT_RULES.md'
$projectPath = Join-Path $agentsRoot ("rules\projects\{0}\PROJECT_RULES.md" -f $resolvedProjectKey)
$generatedGlobal = Join-Path $agentsRoot 'rules\generated\global'
$generatedProject = Join-Path $agentsRoot ("rules\generated\projects\{0}" -f $resolvedProjectKey)
$userProfile = $env:USERPROFILE
$lf = "`n"

if (-not (Test-Path -LiteralPath $commonPath)) {
    throw "Common rules not found: $commonPath"
}
if (-not $resolvedProjectRoot) {
    throw 'Project rules sync requires -ProjectRoot, AGENTS_DEFAULT_PROJECT_ROOT, or running the script from the target workspace.'
}

foreach ($dir in @($generatedGlobal, $generatedProject)) {
    Ensure-AgentDirectory -Path $dir
}

$common = Normalize-AgentLf(([System.IO.File]::ReadAllText($commonPath, [System.Text.Encoding]::UTF8)).Trim())
if (Test-Path -LiteralPath $projectPath) {
    $project = Normalize-AgentLf(([System.IO.File]::ReadAllText($projectPath, [System.Text.Encoding]::UTF8)).Trim())
}
else {
    $project = ''
    Write-Warning "Project rules missing: $projectPath (using COMMON_AGENT_RULES only for project targets)."
}

$globalCodex = $common + $lf
$globalClaude = $common + $lf
$globalCursor = $common + $lf
if ($project) {
    $projectCombined = $common + $lf + $lf + $project + $lf
}
else {
    $projectCombined = $common + $lf
}
$mdcDescription = if ($project) {
    ('Shared + project rules synced from {0}' -f $agentsRoot)
}
else {
    ('Shared rules only (no PROJECT_RULES.md) from {0}' -f $agentsRoot)
}
$projectCursorMdc = @(
    '---',
    ('description: {0}' -f $mdcDescription),
    'alwaysApply: true',
    '---',
    '',
    $projectCombined.TrimEnd()
) -join $lf

$targets = @{}
$targets[(Join-Path $generatedGlobal 'CODEX_AGENTS.md')] = $globalCodex
$targets[(Join-Path $generatedGlobal 'CLAUDE.md')] = $globalClaude
$targets[(Join-Path $generatedGlobal 'CURSOR_USER_RULES.md')] = $globalCursor
$targets[(Join-Path $generatedProject 'AGENTS.md')] = $projectCombined
$targets[(Join-Path $generatedProject 'CLAUDE.md')] = $projectCombined
$targets[(Join-Path $generatedProject '.cursorrules')] = $projectCombined
$targets[(Join-Path $generatedProject '.cursor\rules\00-common.mdc')] = $projectCursorMdc
$targets[(Join-Path $resolvedProjectRoot 'AGENTS.md')] = $projectCombined
$targets[(Join-Path $resolvedProjectRoot 'CLAUDE.md')] = $projectCombined
$targets[(Join-Path $resolvedProjectRoot '.cursorrules')] = $projectCombined
$targets[(Join-Path $resolvedProjectRoot '.cursor\rules\00-common.mdc')] = $projectCursorMdc
if (-not $SkipUserTargets) {
    $targets[(Join-Path $userProfile '.codex\AGENTS.md')] = $globalCodex
    $targets[(Join-Path $userProfile '.claude\CLAUDE.md')] = $globalClaude
}

foreach ($target in $targets.Keys) {
    Write-AgentUtf8NoBomFile -Path $target -Content $targets[$target]
    Write-Host "Synced -> $target"
}