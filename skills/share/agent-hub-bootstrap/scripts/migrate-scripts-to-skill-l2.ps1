#Requires -Version 5.1
<#
.SYNOPSIS
  Move skill-owned hub scripts to L2 skill scripts/ and leave thin hub forwarders.

.DESCRIPTION
  One-shot / repeatable migration for the fused plan:
  hub stable entry + skill implementation truth.
#>
[CmdletBinding()]
param(
    [string]$HubRoot = '',
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

$skillScriptRoot = $PSScriptRoot
$fallbackHubRoot = [System.IO.Path]::GetFullPath((Join-Path $skillScriptRoot '..\..\..\..'))
. (Join-Path $fallbackHubRoot 'scripts\agent-hub-paths.ps1')
$hub = Resolve-AgentHubRoot -HubRoot $HubRoot -ScriptRoot (Join-Path $fallbackHubRoot 'scripts')
$hubScripts = Join-Path $hub 'scripts'

$migrations = @(
    @{ Skill = 'doc-script-governance'; Files = @('check-backup-policy.ps1','check-backup-policy.sh','check-utf8-no-bom.ps1','check-utf8-no-bom.sh','normalize-utf8-lf.ps1') }
    @{ Skill = 'prompt-engineering'; Files = @('check-prompts.ps1','check-prompts.sh','build-prompt-index.ps1','build-prompt-index.sh','validate-prompt-body.awk') }
    @{ Skill = 'skill-engineering'; Files = @('check-skill-size.ps1','check-skill-size.sh','check-skill-structure.ps1','check-skill-structure.sh','check-share-skill-private-coupling.ps1','check-share-skill-private-coupling.sh','check-skill-entrypoints.ps1','check-skill-entrypoints.sh','fix-skill-entrypoints.ps1','fix-skill-entrypoints.sh') }
    @{ Skill = 'skill-discovery'; Files = @('find-skills.ps1','find-skills.sh','install-skill-from-registry.ps1','install-skill-from-registry.sh') }
    @{ Skill = 'project-insight-extractor'; Files = @('build-tech-insight-index.ps1','build-tech-insight-index.sh') }
    @{ Skill = 'ai-development-governance'; Files = @('check-spec-sdd-structure.ps1','check-spec-sdd-structure.sh','check-behavior-audit.ps1','check-behavior-audit.sh') }
    @{ Skill = 'delivery-workflow'; Files = @('check-replay-structure.ps1','check-replay-structure.sh') }
)

function Write-Utf8NoBom {
    param([string]$Path, [string]$Content)
    $enc = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Content, $enc)
}

function Patch-L2Ps1 {
    param([string]$Path)
    $text = [System.IO.File]::ReadAllText($Path)
    $orig = $text

    # Inject hub scripts bootstrap right after first agent-hub-paths dot-source, or before it.
    if ($text -match "\. \(Join-Path \$PSScriptRoot 'agent-hub-paths\.ps1'\)") {
        $inject = @'
$__hubScripts = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\..\..\scripts'))
. (Join-Path $__hubScripts 'agent-hub-paths.ps1')
'@
        $text = $text -replace "\. \(Join-Path \$PSScriptRoot 'agent-hub-paths\.ps1'\)", [System.Text.RegularExpressions.MatchEvaluator]{ param($m) $inject }
        $text = $text.Replace(
            'Resolve-AgentHubRoot -HubRoot $HubRoot -ScriptRoot $PSScriptRoot',
            'Resolve-AgentHubRoot -HubRoot $HubRoot -ScriptRoot $__hubScripts'
        )
        $text = $text.Replace(
            'Join-Path $PSScriptRoot ''python/hub_build_indices.py''',
            'Join-Path $__hubScripts ''python/hub_build_indices.py'''
        )
        $text = $text.Replace(
            'Join-Path $PSScriptRoot ''python\hub_build_indices.py''',
            'Join-Path $__hubScripts ''python\hub_build_indices.py'''
        )
    }

    # install-skill-from-registry style hub root fallback
    $text = $text.Replace(
        'else { Split-Path $PSScriptRoot -Parent }',
        'else { [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot ''..\..\..\..'')) }'
    )

    if ($text -ne $orig) {
        if (-not $DryRun) { Write-Utf8NoBom -Path $Path -Content $text }
        return $true
    }
    return $false
}

function Patch-L2Sh {
    param([string]$Path)
    $text = [System.IO.File]::ReadAllText($Path)
    $orig = $text

    # Standard SCRIPT_DIR + agent-hub-paths.sh pattern
    if ($text -match 'SCRIPT_DIR=\$\(CDPATH') {
        $replacement = @'
SKILL_SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
HUB_SCRIPTS_DIR=$(CDPATH='' cd -- "$SKILL_SCRIPT_DIR/../../../../scripts" && pwd -P)
SCRIPT_DIR="$HUB_SCRIPTS_DIR"
. "$HUB_SCRIPTS_DIR/agent-hub-paths.sh"
'@
        $text = [regex]::Replace(
            $text,
            'SCRIPT_DIR=\$\(CDPATH='' cd -- "\$\(dirname -- "\$0"\)" && pwd -P\)\r?\n\. "\$SCRIPT_DIR/agent-hub-paths\.sh"',
            $replacement,
            1
        )
        # awk lives beside L2 script
        $text = $text -replace 'VALIDATE_BODY_AWK="\$SCRIPT_DIR/validate-prompt-body\.awk"', 'VALIDATE_BODY_AWK="$SKILL_SCRIPT_DIR/validate-prompt-body.awk"'
    }

    # find-skills.sh hub root from script parent -> four levels up from skill scripts
    $text = $text -replace 'HUB_ROOT="\$\(cd "\$_SCRIPT_DIR/\.\." 2>/dev/null && pwd\)"', 'HUB_ROOT="$(cd "$_SCRIPT_DIR/../../../.." 2>/dev/null && pwd)"'

    if ($text -ne $orig) {
        if (-not $DryRun) { Write-Utf8NoBom -Path $Path -Content $text }
        return $true
    }
    return $false
}

function New-Ps1Forwarder {
    param([string]$HubFile, [string]$Skill, [string]$FileName)
    $rel = "skills\share\$Skill\scripts\$FileName"
    $content = @"
# L1 compatibility forwarder -> L2 skill script ($Skill/$FileName)
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
exit `$LASTEXITCODE
"@
    if (-not $DryRun) { Write-Utf8NoBom -Path $HubFile -Content ($content.TrimStart() + "`n") }
}

function New-ShForwarder {
    param([string]$HubFile, [string]$Skill, [string]$FileName)
    $rel = "skills/share/$Skill/scripts/$FileName"
    $content = @"
#!/usr/bin/env sh
set -eu
# L1 compatibility forwarder -> L2 skill script ($Skill/$FileName)
SCRIPT_DIR=`$(CDPATH='' cd -- "`$(dirname -- "`$0")" && pwd -P)
. "`$SCRIPT_DIR/agent-hub-paths.sh"
HUB_ROOT=`$(agent_resolve_hub_root "`${AGENTS_HUB_ROOT:-}" "`$SCRIPT_DIR")
SKILL_SCRIPT="`$HUB_ROOT/$rel"
[ -f "`$SKILL_SCRIPT" ] || agent_fail "L2 script not found: `$SKILL_SCRIPT"
exec sh "`$SKILL_SCRIPT" "`$@"
"@
    if (-not $DryRun) {
        Write-Utf8NoBom -Path $HubFile -Content $content
    }
}

$moved = 0
$skipped = 0
foreach ($m in $migrations) {
    $destDir = Join-Path $hub "skills\share\$($m.Skill)\scripts"
    if (-not (Test-Path -LiteralPath $destDir)) {
        Write-Host ("[mkdir] {0}" -f $destDir)
        if (-not $DryRun) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }
    }

    foreach ($file in $m.Files) {
        $src = Join-Path $hubScripts $file
        $dst = Join-Path $destDir $file
        if (-not (Test-Path -LiteralPath $src)) {
            Write-Host ("[skip-missing] {0}" -f $src) -ForegroundColor Yellow
            $skipped++
            continue
        }

        # Already a forwarder?
        $head = Get-Content -LiteralPath $src -TotalCount 3 -ErrorAction SilentlyContinue
        if ($head -match 'L1 compatibility forwarder') {
            Write-Host ("[skip-forwarder] {0}" -f $file)
            $skipped++
            continue
        }

        Write-Host ("[move] {0} -> {1}/{2}" -f $file, $m.Skill, $file)
        if (-not $DryRun) {
            if (Test-Path -LiteralPath $dst) {
                Remove-Item -LiteralPath $dst -Force
            }
            Copy-Item -LiteralPath $src -Destination $dst -Force

            if ($file -like '*.ps1') {
                [void](Patch-L2Ps1 -Path $dst)
                New-Ps1Forwarder -HubFile $src -Skill $m.Skill -FileName $file
            }
            elseif ($file -like '*.sh') {
                [void](Patch-L2Sh -Path $dst)
                New-ShForwarder -HubFile $src -Skill $m.Skill -FileName $file
            }
            else {
                # awk etc: move only, hub copy removed and optional note forwarder N/A
                Remove-Item -LiteralPath $src -Force
            }
        }
        $moved++
    }
}

Write-Host ""
Write-Host ("DONE hub={0} moved={1} skipped={2} dryRun={3}" -f $hub, $moved, $skipped, [bool]$DryRun)
