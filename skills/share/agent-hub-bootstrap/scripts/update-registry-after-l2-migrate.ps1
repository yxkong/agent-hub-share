#Requires -Version 5.1
[CmdletBinding()]
param([string]$HubRoot = '')

$ErrorActionPreference = 'Stop'
$__hubScripts = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\..\..\scripts'))
. (Join-Path $__hubScripts 'agent-hub-paths.ps1')
$HubRoot = Resolve-AgentHubRoot -HubRoot $HubRoot -ScriptRoot $__hubScripts
$path = Join-Path $HubRoot 'scripts\registry.json'
$raw = [System.IO.File]::ReadAllText($path)
$j = $raw | ConvertFrom-Json

$updates = @{
    'check-backup-policy' = @{ skill = 'doc-script-governance'; files = @('check-backup-policy.ps1','check-backup-policy.sh') }
    'check-utf8-no-bom' = @{ skill = 'doc-script-governance'; files = @('check-utf8-no-bom.ps1','check-utf8-no-bom.sh') }
    'check-prompts' = @{ skill = 'prompt-engineering'; files = @('check-prompts.ps1','check-prompts.sh'); extra = @('skills/share/prompt-engineering/scripts/validate-prompt-body.awk') }
    'build-prompt-index' = @{ skill = 'prompt-engineering'; files = @('build-prompt-index.ps1','build-prompt-index.sh'); keepPy = $true }
    'check-skill-size' = @{ skill = 'skill-engineering'; files = @('check-skill-size.ps1','check-skill-size.sh') }
    'check-skill-structure' = @{ skill = 'skill-engineering'; files = @('check-skill-structure.ps1','check-skill-structure.sh') }
    'check-share-skill-private-coupling' = @{ skill = 'skill-engineering'; files = @('check-share-skill-private-coupling.ps1','check-share-skill-private-coupling.sh') }
    'check-skill-entrypoints' = @{ skill = 'skill-engineering'; files = @('check-skill-entrypoints.ps1','check-skill-entrypoints.sh') }
    'find-skills' = @{ skill = 'skill-discovery'; files = @('find-skills.ps1','find-skills.sh') }
    'install-skill-from-registry' = @{ skill = 'skill-discovery'; files = @('install-skill-from-registry.ps1','install-skill-from-registry.sh') }
    'build-tech-insight-index' = @{ skill = 'project-insight-extractor'; files = @('build-tech-insight-index.ps1','build-tech-insight-index.sh'); keepPy = $true }
    'check-spec-sdd-structure' = @{ skill = 'ai-development-governance'; files = @('check-spec-sdd-structure.ps1','check-spec-sdd-structure.sh') }
    'check-behavior-audit' = @{ skill = 'ai-development-governance'; files = @('check-behavior-audit.ps1','check-behavior-audit.sh') }
}

foreach ($name in $updates.Keys) {
    $u = $updates[$name]
    $tool = $j.tools.$name
    if (-not $tool) { Write-Host "MISSING $name"; continue }
    $paths = New-Object System.Collections.Generic.List[string]
    foreach ($f in $u.files) {
        $paths.Add("scripts/$f") | Out-Null
        $paths.Add("skills/share/$($u.skill)/scripts/$f") | Out-Null
    }
    if ($u.extra) { foreach ($e in $u.extra) { $paths.Add($e) | Out-Null } }
    if ($u.keepPy) { $paths.Add('scripts/python/hub_build_indices.py') | Out-Null }
    $tool.paths = @($paths)
    $tool.layer = 'l2-forwarder'
    Write-Host ("UPDATED {0} -> {1}" -f $name, $u.skill)
}

# Add new tools not previously registered
function Add-Tool($name, $skill, $files, $purpose, $group, $visibility = 'public') {
    if ($j.tools.PSObject.Properties.Name -contains $name) { return }
    $paths = @()
    foreach ($f in $files) {
        $paths += "scripts/$f"
        $paths += "skills/share/$skill/scripts/$f"
    }
    $obj = [pscustomobject]@{
        paths = $paths
        layer = 'l2-forwarder'
        group = $group
        visibility = $visibility
        purpose = $purpose
    }
    $j.tools | Add-Member -NotePropertyName $name -NotePropertyValue $obj -Force
    if ($j.groups.$group.tools -notcontains $name) {
        $j.groups.$group.tools += $name
    }
    Write-Host ("ADDED {0}" -f $name)
}

Add-Tool 'fix-skill-entrypoints' 'skill-engineering' @('fix-skill-entrypoints.ps1','fix-skill-entrypoints.sh') 'Fix nested or invalid SKILL.md entrypoints in skill trees.' 'hub-validation'
Add-Tool 'check-replay-structure' 'delivery-workflow' @('check-replay-structure.ps1','check-replay-structure.sh') 'Validate delivery-workflow Gate5 replay markdown structure.' 'hub-validation'
Add-Tool 'normalize-utf8-lf' 'doc-script-governance' @('normalize-utf8-lf.ps1') 'Normalize text files to UTF-8 without BOM and LF.' 'hub-validation'

# Move skill-discovery group ownership comment in description - optional
$json = $j | ConvertTo-Json -Depth 20
# PowerShell ConvertTo-Json may reorder; acceptable
$enc = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($path, $json + "`n", $enc)
Write-Host "WROTE $path"
