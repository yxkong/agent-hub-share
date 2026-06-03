[CmdletBinding()]
param(
    [switch]$PublishFromAgent,
    [switch]$PublishToShare,
    [switch]$PromoteToShare,
    [switch]$LinkProjectSkills,
    [switch]$LinkUserSkills,
    [string]$HubRoot = '',
    [string]$DefaultCategory = '',
    [string]$ProjectKey = '',
    [Alias('WorkspaceRoot')]
    [string]$RepoRoot = '',
    [string[]]$Categories,
    [string[]]$SkillNames
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'agent-hub-paths.ps1')

$agentsRoot = Resolve-AgentHubRoot -HubRoot $HubRoot -ScriptRoot $PSScriptRoot
$centralScript = Join-Path $PSScriptRoot 'publish-skill.ps1'
if (-not (Test-Path -LiteralPath $centralScript)) {
    throw "Central script not found: $centralScript"
}

$requiresWorkspace = $PublishFromAgent -or $LinkProjectSkills -or [bool]$RepoRoot
$resolvedRepoRoot = if ($requiresWorkspace) {
    Resolve-AgentWorkspaceRoot -WorkspaceRoot $RepoRoot -AllowCurrentLocation
}
else {
    Resolve-AgentWorkspaceRoot -WorkspaceRoot $RepoRoot
}

$resolvedProjectKey = Resolve-AgentProjectKey -ProjectKey $ProjectKey -WorkspaceRoot $resolvedRepoRoot
$resolvedDefaultCategory = if ($DefaultCategory) { $DefaultCategory.Trim() } elseif ($resolvedProjectKey) { Join-Path 'projects' $resolvedProjectKey } else { '' }

if (($PublishFromAgent -and -not $PublishToShare) -or $PromoteToShare -or $LinkProjectSkills) {
    if (-not $resolvedDefaultCategory) {
        throw 'Category operations require -DefaultCategory, -ProjectKey, AGENTS_DEFAULT_PROJECT_KEY, or a workspace root whose folder name can be used as the project key. Default project skills are stored under skills\projects\<project-key>.'
    }
}

if (($PublishFromAgent -or $LinkProjectSkills) -and -not $resolvedRepoRoot) {
    throw 'Workspace operations require -RepoRoot, AGENTS_DEFAULT_PROJECT_ROOT, or running the script from the target workspace.'
}

$projectAgentSkillsRoot = if ($resolvedRepoRoot) { Join-Path $resolvedRepoRoot '.agents\skills' } else { '' }
$skillsRoot = Join-Path $agentsRoot 'skills'
$shareRoot = Join-Path $skillsRoot 'share'
$mediaRoot = Join-Path $skillsRoot 'media'
$categoryRoot = if ($resolvedDefaultCategory) { Join-Path $skillsRoot $resolvedDefaultCategory } else { '' }

function Get-SkillNamesFromRoot {
    param([Parameter(Mandatory = $true)][string]$Root)
    if (-not (Test-Path -LiteralPath $Root)) {
        return @()
    }
    return Get-ChildItem -LiteralPath $Root -Directory | Where-Object {
        Test-Path -LiteralPath (Join-Path $_.FullName 'SKILL.md')
    } | Select-Object -ExpandProperty Name
}

function Resolve-Names {
    param(
        [string[]]$Preferred,
        [Parameter(Mandatory = $true)][string]$FallbackRoot
    )
    if ($Preferred -and $Preferred.Count -gt 0) {
        return $Preferred
    }
    return Get-SkillNamesFromRoot -Root $FallbackRoot
}

function Copy-SkillDirectory {
    param(
        [Parameter(Mandatory = $true)][string]$Source,
        [Parameter(Mandatory = $true)][string]$Destination
    )
    if (Test-Path -LiteralPath $Destination) {
        Remove-Item -LiteralPath $Destination -Recurse -Force
    }
    Copy-Item -LiteralPath $Source -Destination $Destination -Recurse -Force
}

if ($PublishFromAgent) {
    $scope = if ($PublishToShare) { 'share' } else { 'category' }
    $sourceRoot = $projectAgentSkillsRoot
    $names = Resolve-Names -Preferred $SkillNames -FallbackRoot $sourceRoot
    foreach ($name in $names) {
        $linkUsers = $PublishToShare -and $LinkUserSkills
        & $centralScript 
            -SkillName $name 
            -HubRoot $agentsRoot 
            -Scope $scope 
            -Category $resolvedDefaultCategory 
            -ProjectRoot $resolvedRepoRoot 
            -LinkProject:$LinkProjectSkills 
            -LinkUsers:$linkUsers

        $targetRoot = if ($PublishToShare) { $shareRoot } else { $categoryRoot }
        Ensure-AgentDirectory -Path $targetRoot
        $sourcePath = Join-Path $sourceRoot $name
        if (Test-Path -LiteralPath $sourcePath) {
            Copy-SkillDirectory -Source $sourcePath -Destination (Join-Path $targetRoot $name)
            Write-Host "Published $name -> $(Join-Path $targetRoot $name)"
        }
    }
}

if ($PromoteToShare) {
    $names = Resolve-Names -Preferred $SkillNames -FallbackRoot $categoryRoot
    foreach ($name in $names) {
        $sourcePath = Join-Path $categoryRoot $name
        if (-not (Test-Path -LiteralPath $sourcePath)) {
            continue
        }
        Ensure-AgentDirectory -Path $shareRoot
        Copy-SkillDirectory -Source $sourcePath -Destination (Join-Path $shareRoot $name)
        & $centralScript -SkillName $name -HubRoot $agentsRoot -Scope share -Category $resolvedDefaultCategory -ProjectRoot $resolvedRepoRoot -LinkUsers:$LinkUserSkills
        Write-Host "Promoted $name -> $(Join-Path $shareRoot $name)"
    }
}

if ($LinkProjectSkills) {
    $activeCategories = if ($Categories -and $Categories.Count -gt 0) { $Categories } else { @($resolvedDefaultCategory) }
    foreach ($category in $activeCategories) {
        $categoryPath = if ($category -eq 'share') { $shareRoot } else { Join-Path $skillsRoot $category }
        $names = Resolve-Names -Preferred $SkillNames -FallbackRoot $categoryPath
        foreach ($name in $names) {
            $scope = if ($category -eq 'share') { 'share' } else { 'category' }
            & $centralScript -SkillName $name -HubRoot $agentsRoot -Scope $scope -Category $category -ProjectRoot $resolvedRepoRoot -LinkProject
        }
    }
}

if ($LinkUserSkills) {
    $shareNamesAll = Resolve-Names -Preferred $SkillNames -FallbackRoot $shareRoot
    $mediaNamesAll = Resolve-Names -Preferred $SkillNames -FallbackRoot $mediaRoot

    $shareNames = $shareNamesAll | Where-Object { Test-Path -LiteralPath (Join-Path $shareRoot $_ 'SKILL.md') }
    $mediaNames = $mediaNamesAll | Where-Object { Test-Path -LiteralPath (Join-Path $mediaRoot $_ 'SKILL.md') }

    foreach ($name in $shareNames) {
        & $centralScript -SkillName $name -HubRoot $agentsRoot -Scope share -Category $resolvedDefaultCategory -ProjectRoot $resolvedRepoRoot -LinkUsers
    }

    foreach ($name in $mediaNames) {
        & $centralScript -SkillName $name -HubRoot $agentsRoot -Scope media -Category $resolvedDefaultCategory -ProjectRoot $resolvedRepoRoot -LinkUsers
    }
}

if (-not $PublishFromAgent -and -not $PromoteToShare -and -not $LinkProjectSkills -and -not $LinkUserSkills) {
    Write-Host ("No action selected. Use -PublishFromAgent, -PromoteToShare, -LinkProjectSkills, and/or -LinkUserSkills. See {0}." -f (Join-Path $PSScriptRoot 'README.md'))
}