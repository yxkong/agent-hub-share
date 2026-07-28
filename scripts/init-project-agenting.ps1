[CmdletBinding()]
param(
    [string]$HubRoot = '',
    [string]$ProjectRoot = '',
    [string]$ProjectKey = '',
    [ValidateSet('engineering', 'media', 'generic', 'mixed', 'hub')]
    [string]$ProjectType = '',
    [switch]$SkipRules,
    [switch]$SkipSharedSkills,
    [switch]$SkipProjectSkills,
    [switch]$SkipUserTargets,
    [switch]$SkipPrompts,
    [switch]$EnablePrompts,
    [switch]$SkipCommands,
    [switch]$LinkUserSkills,
    [switch]$LinkShareToWorkspace,
    [string[]]$ShareSkillNames,
    [string[]]$ProjectSkillNames
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'agent-hub-paths.ps1')

function Remove-AgentWorkspaceUnmanagedSkillLinks {
    param(
        [Parameter(Mandatory)][string]$ProjectRoot,
        [Parameter(Mandatory)][string]$HubAgentsRoot,
        [string[]]$KeepNames = @()
    )
    $keep = @{}
    foreach ($name in @($KeepNames)) {
        if (-not [string]::IsNullOrWhiteSpace($name)) { $keep[$name] = $true }
    }
    $layerRoots = @(
        ([System.IO.Path]::GetFullPath((Join-Path $HubAgentsRoot 'skills\share'))).TrimEnd('\'),
        ([System.IO.Path]::GetFullPath((Join-Path $HubAgentsRoot 'skills\media'))).TrimEnd('\'),
        ([System.IO.Path]::GetFullPath((Join-Path $HubAgentsRoot 'skills\tooling'))).TrimEnd('\'),
        ([System.IO.Path]::GetFullPath((Join-Path $HubAgentsRoot 'skills\research'))).TrimEnd('\')
    )
    foreach ($leaf in '.agents\skills', '.cursor\skills', '.claude\skills') {
        $dir = Join-Path $ProjectRoot $leaf
        if (-not (Test-Path -LiteralPath $dir)) { continue }
        $entries = @(Get-ChildItem -LiteralPath $dir -Directory -Force -ErrorAction SilentlyContinue)
        foreach ($entry in $entries) {
            try {
                $itemPath = $entry.FullName
                if ($keep.ContainsKey($entry.Name)) { continue }
                $item = Get-Item -LiteralPath $itemPath -Force -ErrorAction Stop
                if (($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -eq 0) { continue }
                $targets = @($item.Target)
                if ($targets.Count -eq 0 -or [string]::IsNullOrWhiteSpace([string]$targets[0])) { continue }
                $managed = $false
                $matchedTarget = ''
                foreach ($tgt in $targets) {
                    if ([string]::IsNullOrWhiteSpace($tgt)) { continue }
                    [string]$resolved = ''
                    try { $resolved = ([System.IO.Path]::GetFullPath($tgt)).TrimEnd('\') } catch { continue }
                    foreach ($root in $layerRoots) {
                        if ($resolved.Equals($root, [StringComparison]::OrdinalIgnoreCase) -or
                            $resolved.StartsWith($root + '\', [StringComparison]::OrdinalIgnoreCase)) {
                            $managed = $true
                            $matchedTarget = $resolved
                            break
                        }
                    }
                    if ($managed) { break }
                }
                if (-not $managed) { continue }
                cmd /c "rmdir `"$itemPath`"" | Out-Null
                if (Test-Path -LiteralPath $itemPath) {
                    [System.IO.Directory]::Delete($itemPath)
                }
                Write-Host ("  [cleanup] removed stale skill junction: {0} -> {1}" -f $itemPath, $matchedTarget)
            }
            catch {
                Write-Warning ("  [cleanup] failed: {0} err={1}" -f $entry.FullName, $_.Exception.Message)
            }
        }
    }
}

# Backward-compatible alias used by older call sites / mental model.
function Remove-AgentWorkspaceShareSkillLinks {
    param(
        [Parameter(Mandatory)][string]$ProjectRoot,
        [Parameter(Mandatory)][string]$HubAgentsRoot,
        [string[]]$KeepNames = @()
    )
    Remove-AgentWorkspaceUnmanagedSkillLinks -ProjectRoot $ProjectRoot -HubAgentsRoot $HubAgentsRoot -KeepNames $KeepNames
}

$agentsRoot = Resolve-AgentHubRoot -HubRoot $HubRoot -ScriptRoot $PSScriptRoot
$resolvedProjectRoot = Resolve-AgentWorkspaceRoot -WorkspaceRoot $ProjectRoot -AllowCurrentLocation
$resolvedProjectKey = Resolve-AgentProjectKey -ProjectKey $ProjectKey -WorkspaceRoot $resolvedProjectRoot

function Get-ProjectYamlValue {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Key
    )
    if (-not (Test-Path -LiteralPath $Path)) { return '' }
    foreach ($line in [System.IO.File]::ReadLines($Path, [System.Text.Encoding]::UTF8)) {
        if ($line -match ("^\s*{0}\s*:\s*(.*)\s*$" -f [regex]::Escape($Key))) {
            return ($Matches[1].Trim() -replace '^[\"'']', '' -replace '[\"'']$', '')
        }
    }
    return ''
}

function Resolve-ProjectTypeForInit {
    param(
        [string]$ExplicitType,
        [string]$YamlPath
    )
    if ($ExplicitType) { return $ExplicitType }
    $yamlType = Get-ProjectYamlValue -Path $YamlPath -Key 'project_type'
    if ($yamlType) {
        if (@('engineering', 'media', 'generic', 'mixed', 'hub') -notcontains $yamlType) {
            throw "Unsupported project_type: $yamlType (expected engineering, media, generic, mixed, or hub)"
        }
        return $yamlType
    }
    return 'generic'
}

function Resolve-PromptsEnabledForInit {
    param([string]$YamlPath)
    if ($SkipPrompts -and $EnablePrompts) { throw 'Use only one of -SkipPrompts or -EnablePrompts.' }
    if ($EnablePrompts) { return $true }
    if ($SkipPrompts) { return $false }
    $value = (Get-ProjectYamlValue -Path $YamlPath -Key 'prompts_enabled').ToLowerInvariant()
    if (-not $value) { return $true }
    if ($value -in @('true', '1', 'yes', 'on')) { return $true }
    if ($value -in @('false', '0', 'no', 'off')) { return $false }
    throw "Unsupported prompts_enabled value in project.yaml: $value"
}

function Get-AgentRegistrySkillNames {
    param(
        [Parameter(Mandatory)][string]$ProjectType,
        [Parameter(Mandatory)][string]$Layer
    )
    $pythonBin = Resolve-AgentPython3Interpreter
    $agentHubPy = Join-Path $PSScriptRoot 'agent_hub.py'
    $items = @(& $pythonBin $agentHubPy list-skills --hub-root $agentsRoot --project-type $ProjectType --layer $Layer | Where-Object { $_ })
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to resolve skill registry for project_type=$ProjectType layer=$Layer"
    }
    return $items
}

if (-not $resolvedProjectRoot) {
    throw 'Project init requires -ProjectRoot, AGENTS_DEFAULT_PROJECT_ROOT, or running the script from the target workspace.'
}
if (-not $resolvedProjectKey) {
    throw 'Project init requires -ProjectKey, AGENTS_DEFAULT_PROJECT_KEY, or a workspace root whose folder name can be used as the project key.'
}

$syncRulesScript = Join-Path $PSScriptRoot 'sync-agent-rules.ps1'
$syncSkillsScript = Join-Path $PSScriptRoot 'sync-shared-skills.ps1'
$projectCategory = Join-Path 'projects' $resolvedProjectKey
$projectYaml = Join-Path $agentsRoot ("rules\projects\{0}\project.yaml" -f $resolvedProjectKey)
$resolvedProjectType = Resolve-ProjectTypeForInit -ExplicitType $ProjectType -YamlPath $projectYaml
$promptsEnabled = Resolve-PromptsEnabledForInit -YamlPath $projectYaml

if (-not $SkipRules) {
    $ruleArgs = @{
        HubRoot = $agentsRoot
        ProjectRoot = $resolvedProjectRoot
        ProjectKey = $resolvedProjectKey
    }
    if ($ProjectType) {
        $ruleArgs.ProjectType = $ProjectType
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
    $resolvedShareSkillNames = if ($null -ne $ShareSkillNames -and @($ShareSkillNames).Count -gt 0) {
        $ShareSkillNames
    }
    else {
        Get-AgentRegistrySkillNames -ProjectType $resolvedProjectType -Layer 'share'
    }
    $resolvedMediaSkillNames = Get-AgentRegistrySkillNames -ProjectType $resolvedProjectType -Layer 'media'
    $resolvedToolingSkillNames = Get-AgentRegistrySkillNames -ProjectType $resolvedProjectType -Layer 'tooling'
    $resolvedResearchSkillNames = Get-AgentRegistrySkillNames -ProjectType $resolvedProjectType -Layer 'research'
    $shareArgs = @{
        HubRoot             = $agentsRoot
        RepoRoot            = $resolvedProjectRoot
        ProjectKey          = $resolvedProjectKey
        Categories          = @('share')
        LinkProjectSkills   = $true
        LinkUserSkills      = $true
    }
    if (-not $LinkUserSkills) {
        $shareArgs.Remove('LinkUserSkills')
    }
    if ($null -ne $resolvedShareSkillNames -and @($resolvedShareSkillNames).Count -gt 0) {
        $shareArgs.SkillNames = $resolvedShareSkillNames
        & $syncSkillsScript @shareArgs
    }

    if ($null -ne $resolvedMediaSkillNames -and @($resolvedMediaSkillNames).Count -gt 0) {
        $mediaArgs = @{
            HubRoot = $agentsRoot
            RepoRoot = $resolvedProjectRoot
            ProjectKey = $resolvedProjectKey
            Categories = @('media')
            LinkProjectSkills = $true
            SkillNames = $resolvedMediaSkillNames
        }
        if ($LinkUserSkills) {
            $mediaArgs.LinkUserSkills = $true
        }
        & $syncSkillsScript @mediaArgs
    }

    if ($null -ne $resolvedToolingSkillNames -and @($resolvedToolingSkillNames).Count -gt 0) {
        $toolingArgs = @{
            HubRoot = $agentsRoot
            RepoRoot = $resolvedProjectRoot
            ProjectKey = $resolvedProjectKey
            Categories = @('tooling')
            LinkProjectSkills = $true
            SkillNames = $resolvedToolingSkillNames
        }
        if ($LinkUserSkills) {
            $toolingArgs.LinkUserSkills = $true
        }
        & $syncSkillsScript @toolingArgs
    }

    if ($null -ne $resolvedResearchSkillNames -and @($resolvedResearchSkillNames).Count -gt 0) {
        $researchArgs = @{
            HubRoot = $agentsRoot
            RepoRoot = $resolvedProjectRoot
            ProjectKey = $resolvedProjectKey
            Categories = @('research')
            LinkProjectSkills = $true
            SkillNames = $resolvedResearchSkillNames
        }
        if ($LinkUserSkills) {
            $researchArgs.LinkUserSkills = $true
        }
        & $syncSkillsScript @researchArgs
    }
}

if (-not $SkipProjectSkills) {
    $projectArgs = @{
        HubRoot = $agentsRoot
        RepoRoot = $resolvedProjectRoot
        ProjectKey = $resolvedProjectKey
        LinkProjectSkills = $true
        Categories = @($projectCategory)
    }
    if ($null -ne $ProjectSkillNames -and @($ProjectSkillNames).Count -gt 0) {
        $projectArgs.SkillNames = $ProjectSkillNames
    }
    & $syncSkillsScript @projectArgs
}

 $syncPromptsScript = Join-Path $PSScriptRoot 'sync-prompts.ps1'
if ($promptsEnabled) {
    & $syncPromptsScript -HubRoot $agentsRoot -ProjectRoot $resolvedProjectRoot -ProjectKey $resolvedProjectKey
}
else {
    & $syncPromptsScript -HubRoot $agentsRoot -ProjectRoot $resolvedProjectRoot -ProjectKey $resolvedProjectKey -Disable
}

if (-not $SkipCommands) {
    $syncCommandsScript = Join-Path $PSScriptRoot 'sync-commands.ps1'
    $commandArgs = @{
        HubRoot = $agentsRoot
        ProjectRoot = $resolvedProjectRoot
        ProjectKey = $resolvedProjectKey
        ProjectType = $resolvedProjectType
    }
    if ($SkipUserTargets) {
        $commandArgs.SkipUserTargets = $true
    }
    & $syncCommandsScript @commandArgs
}

Write-Host "Initialized workspace: $resolvedProjectRoot"
Write-Host "Project key: $resolvedProjectKey"
Write-Host "Project type: $resolvedProjectType"
Write-Host "Prompts enabled: $promptsEnabled"
Write-Host "Hub root: $agentsRoot"
