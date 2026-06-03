[CmdletBinding()]
param(
    [string]$HubRoot = '',
    [string]$ProjectRoot = '',
    [string]$ProjectKey = '',
    [switch]$SkipRules,
    [switch]$SkipSharedSkills,
    [switch]$SkipProjectSkills,
    [switch]$SkipUserTargets,
    [switch]$SkipPrompts,
    [switch]$LinkUserSkills,
    [switch]$LinkShareToWorkspace,
    [string[]]$ShareSkillNames,
    [string[]]$ProjectSkillNames
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'agent-hub-paths.ps1')

function Remove-AgentWorkspaceShareSkillLinks {
    param(
        [Parameter(Mandatory)][string]$ProjectRoot,
        [Parameter(Mandatory)][string]$HubAgentsRoot
    )
    [string]$shareNorm = ([System.IO.Path]::GetFullPath((Join-Path $HubAgentsRoot 'skills\share'))).TrimEnd('\')
    foreach ($leaf in '.cursor\skills', '.claude\skills') {
        $dir = Join-Path $ProjectRoot $leaf
        if (-not (Test-Path -LiteralPath $dir)) { continue }
        Get-ChildItem -LiteralPath $dir -Directory -Force -ErrorAction SilentlyContinue | ForEach-Object {
            try {
                $itemPath = $_.FullName
                $item = Get-Item -LiteralPath $itemPath -Force -ErrorAction Stop
                if (($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -eq 0) { return }
                foreach ($tgt in @($item.Target)) {
                    if ([string]::IsNullOrWhiteSpace($tgt)) { continue }
                    [string]$resolved = ''
                    try {
                        $resolved = ([System.IO.Path]::GetFullPath($tgt)).TrimEnd('\')
                    }
                    catch { continue }

                    [bool]$shareTarget = $resolved.Equals($shareNorm, [StringComparison]::OrdinalIgnoreCase) -or
                        $resolved.StartsWith($shareNorm + '\', [StringComparison]::OrdinalIgnoreCase)

                    if ($shareTarget) {
                        [System.IO.Directory]::Delete($itemPath)
                        Write-Host ("  [cleanup] removed stale share junction: {0} -> {1}" -f $itemPath, $tgt)
                        break
                    }
                }
            }
            catch { }
        }
    }
}

$agentsRoot = Resolve-AgentHubRoot -HubRoot $HubRoot -ScriptRoot $PSScriptRoot
$resolvedProjectRoot = Resolve-AgentWorkspaceRoot -WorkspaceRoot $ProjectRoot -AllowCurrentLocation
$resolvedProjectKey = Resolve-AgentProjectKey -ProjectKey $ProjectKey -WorkspaceRoot $resolvedProjectRoot
if (-not $resolvedProjectRoot) {
    throw 'Project init requires -ProjectRoot, AGENTS_DEFAULT_PROJECT_ROOT, or running the script from the target workspace.'
}
if (-not $resolvedProjectKey) {
    throw 'Project init requires -ProjectKey, AGENTS_DEFAULT_PROJECT_KEY, or a workspace root whose folder name can be used as the project key.'
}

$syncRulesScript = Join-Path $PSScriptRoot 'sync-agent-rules.ps1'
$syncSkillsScript = Join-Path $PSScriptRoot 'sync-shared-skills.ps1'
$projectCategory = Join-Path 'projects' $resolvedProjectKey

if (-not $SkipRules) {
    $ruleArgs = @{
        HubRoot = $agentsRoot
        ProjectRoot = $resolvedProjectRoot
        ProjectKey = $resolvedProjectKey
    }
    if ($SkipUserTargets) {
        $ruleArgs.SkipUserTargets = $true
    }
    & $syncRulesScript @ruleArgs
}

if (-not $SkipSharedSkills) {
    if (-not $LinkShareToWorkspace) {
        Remove-AgentWorkspaceShareSkillLinks -ProjectRoot $resolvedProjectRoot -HubAgentsRoot $agentsRoot
    }
    $shareArgs = @{
        HubRoot             = $agentsRoot
        RepoRoot            = $resolvedProjectRoot
        ProjectKey          = $resolvedProjectKey
        Categories          = @('share')
        LinkProjectSkills   = [bool]$LinkShareToWorkspace
        LinkUserSkills      = $true
    }
    if ($ShareSkillNames -and $ShareSkillNames.Count -gt 0) {
        $shareArgs.SkillNames = $ShareSkillNames
    }
    & $syncSkillsScript @shareArgs
}

if (-not $SkipProjectSkills) {
    $projectArgs = @{
        HubRoot = $agentsRoot
        RepoRoot = $resolvedProjectRoot
        ProjectKey = $resolvedProjectKey
        LinkProjectSkills = $true
        Categories = @($projectCategory)
    }
    if ($ProjectSkillNames -and $ProjectSkillNames.Count -gt 0) {
        $projectArgs.SkillNames = $ProjectSkillNames
    }
    & $syncSkillsScript @projectArgs
}

if (-not $SkipPrompts) {
    $syncPromptsScript = Join-Path $PSScriptRoot 'sync-prompts.ps1'
    & $syncPromptsScript -HubRoot $agentsRoot -ProjectRoot $resolvedProjectRoot -ProjectKey $resolvedProjectKey
}

Write-Host "Initialized workspace: $resolvedProjectRoot"
Write-Host "Project key: $resolvedProjectKey"
Write-Host "Hub root: $agentsRoot"