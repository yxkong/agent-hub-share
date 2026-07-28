#Requires -Version 5.1
# Regenerate hub L1 forwarders and fix check-backup-policy hub-root derivation.
[CmdletBinding()]
param([string]$HubRoot = '')

$ErrorActionPreference = 'Stop'
$__hubScripts = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\..\..\scripts'))
. (Join-Path $__hubScripts 'agent-hub-paths.ps1')
$HubRoot = Resolve-AgentHubRoot -HubRoot $HubRoot -ScriptRoot $__hubScripts

function Write-Utf8NoBom([string]$Path, [string]$Content) {
    $enc = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Content, $enc)
}

$map = @{
    'check-backup-policy.ps1' = 'doc-script-governance'
    'check-backup-policy.sh' = 'doc-script-governance'
    'check-utf8-no-bom.ps1' = 'doc-script-governance'
    'check-utf8-no-bom.sh' = 'doc-script-governance'
    'normalize-utf8-lf.ps1' = 'doc-script-governance'
    'check-prompts.ps1' = 'prompt-engineering'
    'check-prompts.sh' = 'prompt-engineering'
    'build-prompt-index.ps1' = 'prompt-engineering'
    'build-prompt-index.sh' = 'prompt-engineering'
    'check-skill-size.ps1' = 'skill-engineering'
    'check-skill-size.sh' = 'skill-engineering'
    'check-skill-structure.ps1' = 'skill-engineering'
    'check-skill-structure.sh' = 'skill-engineering'
    'check-share-skill-private-coupling.ps1' = 'skill-engineering'
    'check-share-skill-private-coupling.sh' = 'skill-engineering'
    'check-skill-entrypoints.ps1' = 'skill-engineering'
    'check-skill-entrypoints.sh' = 'skill-engineering'
    'fix-skill-entrypoints.ps1' = 'skill-engineering'
    'fix-skill-entrypoints.sh' = 'skill-engineering'
    'find-skills.ps1' = 'skill-discovery'
    'find-skills.sh' = 'skill-discovery'
    'install-skill-from-registry.ps1' = 'skill-discovery'
    'install-skill-from-registry.sh' = 'skill-discovery'
    'build-tech-insight-index.ps1' = 'project-insight-extractor'
    'build-tech-insight-index.sh' = 'project-insight-extractor'
    'check-spec-sdd-structure.ps1' = 'ai-development-governance'
    'check-spec-sdd-structure.sh' = 'ai-development-governance'
    'check-behavior-audit.ps1' = 'ai-development-governance'
    'check-behavior-audit.sh' = 'ai-development-governance'
    'check-replay-structure.ps1' = 'delivery-workflow'
    'check-replay-structure.sh' = 'delivery-workflow'
}

foreach ($file in $map.Keys) {
    $skill = $map[$file]
    $hubFile = Join-Path $HubRoot "scripts\$file"
    if ($file -like '*.ps1') {
        $rel = "skills\share\$skill\scripts\$file"
        $content = @"
# L1 compatibility forwarder -> L2 skill script ($skill/$file)
`$ErrorActionPreference = 'Stop'
. (Join-Path `$PSScriptRoot 'agent-hub-paths.ps1')
`$hubRootArg = ''
for (`$i = 0; `$i -lt `$args.Count; `$i++) {
    if (`$args[`$i] -eq '-HubRoot' -and (`$i + 1) -lt `$args.Count) {
        `$hubRootArg = [string]`$args[`$i + 1]
        break
    }
}
`$agentsRoot = Resolve-AgentHubRoot -HubRoot `$hubRootArg -ScriptRoot `$PSScriptRoot
`$target = Join-Path `$agentsRoot "$rel"
if (-not (Test-Path -LiteralPath `$target)) {
    throw "L2 script not found: `$target"
}
& `$target @args
if (Get-Variable -Name LASTEXITCODE -Scope Global -ErrorAction SilentlyContinue) {
    exit [int]`$global:LASTEXITCODE
}
exit 0
"@
        Write-Utf8NoBom $hubFile ($content.TrimStart() + "`n")
    }
    else {
        $rel = "skills/share/$skill/scripts/$file"
        $content = @"
#!/usr/bin/env sh
set -eu
# L1 compatibility forwarder -> L2 skill script ($skill/$file)
SCRIPT_DIR=`$(CDPATH='' cd -- "`$(dirname -- "`$0")" && pwd -P)
. "`$SCRIPT_DIR/agent-hub-paths.sh"
HUB_ROOT=`$(agent_resolve_hub_root "`${AGENTS_HUB_ROOT:-}" "`$SCRIPT_DIR")
SKILL_SCRIPT="`$HUB_ROOT/$rel"
[ -f "`$SKILL_SCRIPT" ] || agent_fail "L2 script not found: `$SKILL_SCRIPT"
exec sh "`$SKILL_SCRIPT" "`$@"
"@
        Write-Utf8NoBom $hubFile $content
    }
    Write-Host ("FORWARDER {0}" -f $file)
}

# Fix check-backup-policy.ps1 repo root
$bp = Join-Path $HubRoot 'skills\share\doc-script-governance\scripts\check-backup-policy.ps1'
$t = [System.IO.File]::ReadAllText($bp)
$old = '$repoRoot = Split-Path -Parent $PSScriptRoot'
$new = '$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot ''..\..\..\..''))'
# actual desired file content uses single quotes in Join-Path
$new = '$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot ''..\..\..\..''))'
$newLiteral = @'
$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\..\..'))
'@.Trim()
if ($t.Contains($old)) {
    $t2 = $t.Replace($old, $newLiteral)
    Write-Utf8NoBom $bp $t2
    Write-Host 'FIXED check-backup-policy.ps1 repoRoot'
}

Write-Host 'done'
