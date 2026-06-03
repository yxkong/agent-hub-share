<#
.SYNOPSIS
    枚举 hub 中的技能，输出结构化候选表

.DESCRIPTION
    扫描 $AGENTS_HUB_ROOT/skills/share、skills/media 和 skills/projects/<project-key>（可选），
    解析 SKILL.md front matter 中的 name/description，支持关键词过滤。

.PARAMETER HubRoot
    Hub 根目录；默认从 $env:AGENTS_HUB_ROOT 或脚本路径推导。

.PARAMETER Query
    过滤关键词；匹配 name 或 description（不区分大小写）。

.PARAMETER Project
    project-key；指定后同时扫描 skills/projects/<key>。

.PARAMETER Output
    输出格式：table（默认）| json

.EXAMPLE
    .\find-skills.ps1 -Query delivery -Project my-app
#>
param(
    [string]$HubRoot  = '',
    [string]$Query    = '',
    [string]$Project  = '',
    [ValidateSet('table','json')]
    [string]$Output   = 'table'
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'agent-hub-paths.ps1')

# 推导 hub root
if (-not $HubRoot) {
    $HubRoot = if ($env:AGENTS_HUB_ROOT) { $env:AGENTS_HUB_ROOT } `
               else { Split-Path $PSScriptRoot -Parent }
}

$skillsShare = Join-Path $HubRoot 'skills\share'

if (-not (Test-Path $skillsShare)) {
    Write-Error "find-skills: skills/share not found under $HubRoot"
    exit 1
}

function Parse-SkillMd([string]$file, [string]$scope, [string]$project) {
    $name = ''; $desc = ''
    $inFm = $false; $fmDone = $false
    foreach ($line in [System.IO.File]::ReadLines($file)) {
        if ($fmDone) { break }
        if ($line -eq '---') {
            if (-not $inFm) { $inFm = $true; continue }
            else             { $fmDone = $true; break }
        }
        if ($inFm) {
            if ($line -match '^name:\s*(.+)$')        { $name = $Matches[1].Trim() }
            if ($line -match '^description:\s*(.+)$') { $desc = $Matches[1].Trim().Substring(0, [Math]::Min(80, $Matches[1].Trim().Length)) }
        }
    }
    if ($Query -and -not ("$name $desc" -match [regex]::Escape($Query))) { return $null }

    $relPath = $file.Replace("$HubRoot\", '').Replace("$HubRoot/", '')
    return [pscustomobject]@{
        skill               = $name
        scope               = $scope
        project             = $project
        path                = $relPath
        description_snippet = $desc
    }
}

$results = [System.Collections.Generic.List[pscustomobject]]::new()

foreach ($skillMd in (Get-AgentCanonicalSkillMdFiles -HubRoot $HubRoot -ProjectKey $Project)) {
    $relPath = $skillMd.Replace("$HubRoot\", '').Replace("$HubRoot/", '') -replace '\\', '/'
    $scope = if ($relPath -like 'skills/share/*') { 'share' } elseif ($relPath -like 'skills/media/*') { 'media' } else { 'project' }
    $project = if ($scope -eq 'project') {
        ($relPath -split '/')[2]
    } else { '-' }
    $r = Parse-SkillMd $skillMd $scope $project
    if ($r) { $results.Add($r) }
}

if ($Output -eq 'json') {
    $results | ConvertTo-Json -Depth 3
} else {
    $results | Format-Table skill, scope, project, path -AutoSize
    Write-Host "Total: $($results.Count) skill(s)"
}
