[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$SkillName,
    [ValidateSet('share', 'category', 'media')]
    [string]$Scope = 'category',
    [string]$HubRoot = '',
    [string]$Category = '',
    [string]$ProjectRoot = '',
    [switch]$LinkProject,
    [switch]$LinkUsers,
    [switch]$CreateIfMissing
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'agent-hub-paths.ps1')

$agentsRoot = Resolve-AgentHubRoot -HubRoot $HubRoot -ScriptRoot $PSScriptRoot
$skillsRoot = Join-Path $agentsRoot 'skills'
$userProfile = $env:USERPROFILE
$userClaudeSkillsRoot = Join-Path $userProfile '.claude\skills'
$userCursorSkillsRoot = Join-Path $userProfile '.cursor\skills'
$userCodexSkillsRoot = Join-Path $userProfile '.codex\skills'
$userAgentsSkillsRoot = Join-Path $userProfile '.agents\skills'

$resolvedProjectRoot = ''
if ($Scope -eq 'category' -or $LinkProject -or $ProjectRoot) {
    $resolvedProjectRoot = Resolve-AgentWorkspaceRoot -WorkspaceRoot $ProjectRoot -AllowCurrentLocation
}

$resolvedCategory = ''
if ($Scope -eq 'category') {
    $resolvedProjectKey = Resolve-AgentProjectKey -WorkspaceRoot $resolvedProjectRoot
    $resolvedCategory = if ($Category) { $Category.Trim() } else { Join-Path 'projects' $resolvedProjectKey }
    if (-not $resolvedCategory) {
        throw 'Category scope requires -Category, AGENTS_DEFAULT_PROJECT_KEY, or a workspace root whose folder name can be used as the project key. Default project skills are stored under skills\projects\<project-key>.'
    }
}

$projectClaudeSkillsRoot = ''
$projectCursorSkillsRoot = ''
$projectAgentsSkillsRoot = ''
$projectGeminiSkillsRoot = ''
if ($Scope -eq 'category' -or $LinkProject) {
    if (-not $resolvedProjectRoot) {
        throw 'Project links require -ProjectRoot, AGENTS_DEFAULT_PROJECT_ROOT, or running the script from the target workspace.'
    }
    $projectClaudeSkillsRoot = Join-Path $resolvedProjectRoot '.claude\skills'
    $projectCursorSkillsRoot = Join-Path $resolvedProjectRoot '.cursor\skills'
    $projectAgentsSkillsRoot = Join-Path $resolvedProjectRoot '.agents\skills'
    $projectGeminiSkillsRoot = Join-Path $resolvedProjectRoot '.gemini\skills'
}

function Ensure-Junction {
    param(
        [Parameter(Mandatory = $true)][string]$LinkPath,
        [Parameter(Mandatory = $true)][string]$TargetPath
    )

    Ensure-AgentDirectory -Path (Split-Path -Parent $LinkPath)
    if (Test-Path -LiteralPath $LinkPath) {
        $existing = Get-Item -LiteralPath $LinkPath -Force
        $isReparse = ($existing.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0
        if ($isReparse) {
            $target = (Get-Item -LiteralPath $LinkPath -Force).Target
            if ($target -contains $TargetPath) {
                return
            }
            [System.IO.Directory]::Delete($LinkPath)
        }
        elseif (Test-Path -LiteralPath (Join-Path $LinkPath 'SKILL.md')) {
            throw "Refusing to replace real skill directory: $LinkPath"
        }
        else {
            throw "Path exists and is not a junction: $LinkPath"
        }
    }

    New-Item -ItemType Junction -Path $LinkPath -Target $TargetPath | Out-Null
}

function Ensure-SkillSkeleton {
    param([Parameter(Mandatory = $true)][string]$Path)

    Ensure-AgentDirectory -Path $Path
    $skillFile = Join-Path $Path 'SKILL.md'
    if (-not (Test-Path -LiteralPath $skillFile)) {
        $content = @(
            '---',
            "name: $SkillName",
            'description: TODO',
            '---',
            '',
            "# $SkillName",
            '',
            'TODO'
        ) -join "
"
        Write-AgentUtf8NoBomFile -Path $skillFile -Content $content
    }
}

$scopeRoot = if ($Scope -eq 'share') {
    Join-Path $skillsRoot 'share'
}
elseif ($Scope -eq 'media') {
    Join-Path $skillsRoot 'media'
}
else {
    Join-Path $skillsRoot $resolvedCategory
}

$skillRoot = Join-Path $scopeRoot $SkillName
$skillFile = Join-Path $skillRoot 'SKILL.md'
if (-not (Test-Path -LiteralPath $skillFile)) {
    if (-not $CreateIfMissing) {
        throw "Skill source not found in hub (typo in -SkillName or wrong -Scope/-Category?): $skillFile. Create that directory and SKILL.md first, or pass -CreateIfMissing to generate a TODO placeholder only when you intentionally scaffold."
    }
    Ensure-SkillSkeleton -Path $skillRoot
}

if ($LinkProject -or $Scope -eq 'category') {
    Ensure-Junction -LinkPath (Join-Path $projectClaudeSkillsRoot $SkillName) -TargetPath $skillRoot
    Ensure-Junction -LinkPath (Join-Path $projectCursorSkillsRoot $SkillName) -TargetPath $skillRoot
    if ($Scope -eq 'category') {
        Ensure-Junction -LinkPath (Join-Path $projectAgentsSkillsRoot $SkillName) -TargetPath $skillRoot
        Ensure-Junction -LinkPath (Join-Path $projectGeminiSkillsRoot $SkillName) -TargetPath $skillRoot
    }
}

if ($LinkUsers -or $Scope -eq 'share' -or $Scope -eq 'media') {
    Ensure-Junction -LinkPath (Join-Path $userClaudeSkillsRoot $SkillName) -TargetPath $skillRoot
    Ensure-Junction -LinkPath (Join-Path $userCursorSkillsRoot $SkillName) -TargetPath $skillRoot
    Ensure-Junction -LinkPath (Join-Path $userCodexSkillsRoot $SkillName) -TargetPath $skillRoot
    Ensure-Junction -LinkPath (Join-Path $userAgentsSkillsRoot $SkillName) -TargetPath $skillRoot
}

Write-Host "Hub root: $agentsRoot"
Write-Host "Skill source: $skillRoot"
if ($resolvedProjectRoot) {
    Write-Host "Workspace root: $resolvedProjectRoot"
}