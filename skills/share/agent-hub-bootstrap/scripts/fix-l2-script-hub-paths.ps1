#Requires -Version 5.1
# Fix L2 migrated scripts so they load hub scripts/agent-hub-paths.* correctly.
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

$psNeedle = '. (Join-Path $' + "PSScriptRoot 'agent-hub-paths.ps1')"
$psInject = @(
    '$__hubScripts = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot ''..\..\..\..\scripts''))'
    '. (Join-Path $__hubScripts ''agent-hub-paths.ps1'')'
) -join "`n"
# Fix inject quotes - want file to contain single quotes like original style
$psInject = @'
$__hubScripts = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\..\..\scripts'))
. (Join-Path $__hubScripts 'agent-hub-paths.ps1')
'@.TrimEnd()

$shLine1 = 'SCRIPT_DIR=$(CDPATH=' + "''" + ' cd -- "$(dirname -- "$0")" && pwd -P)'
$shLine2 = '. "$SCRIPT_DIR/agent-hub-paths.sh"'
$shInject = @'
SKILL_SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
HUB_SCRIPTS_DIR=$(CDPATH='' cd -- "$SKILL_SCRIPT_DIR/../../../../scripts" && pwd -P)
SCRIPT_DIR="$HUB_SCRIPTS_DIR"
. "$HUB_SCRIPTS_DIR/agent-hub-paths.sh"
'@.TrimEnd()

$skills = @(
    'doc-script-governance','prompt-engineering','skill-engineering',
    'skill-discovery','project-insight-extractor','ai-development-governance','delivery-workflow'
)

$fixed = 0
foreach ($skill in $skills) {
    $dir = Join-Path $HubRoot "skills\share\$skill\scripts"
    if (-not (Test-Path -LiteralPath $dir)) { continue }
    Get-ChildItem -LiteralPath $dir -File | ForEach-Object {
        $path = $_.FullName
        $text = [System.IO.File]::ReadAllText($path)
        $orig = $text

        if ($_.Extension -eq '.ps1') {
            if ($text.Contains($psNeedle) -and -not $text.Contains('$__hubScripts')) {
                $text = $text.Replace($psNeedle, $psInject)
                $text = $text.Replace(
                    'Resolve-AgentHubRoot -HubRoot $HubRoot -ScriptRoot $PSScriptRoot',
                    'Resolve-AgentHubRoot -HubRoot $HubRoot -ScriptRoot $__hubScripts'
                )
                $pyOld = 'Join-Path $' + "PSScriptRoot 'python/hub_build_indices.py'"
                $pyNew = 'Join-Path $' + "__hubScripts 'python/hub_build_indices.py'"
                $text = $text.Replace($pyOld, $pyNew)
            }
        }
        elseif ($_.Extension -eq '.sh') {
            if (-not $text.Contains('HUB_SCRIPTS_DIR=')) {
                $blockLf = $shLine1 + "`n" + $shLine2
                $blockCrlf = $shLine1 + "`r`n" + $shLine2
                if ($text.Contains($blockCrlf)) {
                    $text = $text.Replace($blockCrlf, $shInject)
                }
                elseif ($text.Contains($blockLf)) {
                    $text = $text.Replace($blockLf, $shInject)
                }
            }
            $oldHub = 'HUB_ROOT="$(cd "$_SCRIPT_DIR/.." 2>/dev/null && pwd)"'
            $newHub = 'HUB_ROOT="$(cd "$_SCRIPT_DIR/../../../.." 2>/dev/null && pwd)"'
            if ($text.Contains($oldHub)) { $text = $text.Replace($oldHub, $newHub) }

            if ($text.Contains('SKILL_SCRIPT_DIR=')) {
                $text = $text.Replace(
                    'VALIDATE_BODY_AWK="$SCRIPT_DIR/validate-prompt-body.awk"',
                    'VALIDATE_BODY_AWK="$SKILL_SCRIPT_DIR/validate-prompt-body.awk"'
                )
            }
        }

        if ($text -ne $orig) {
            Write-Utf8NoBom -Path $path -Content $text
            Write-Host ("FIXED {0}" -f $_.Name)
            $script:fixed++
        }
        else {
            if ($_.Extension -eq '.ps1' -and $text.Contains('agent-hub-paths.ps1') -and -not $text.Contains('$__hubScripts')) {
                Write-Host ("STILL_BROKEN_PS1 {0} needle={1}" -f $_.Name, $text.Contains($psNeedle))
            }
            if ($_.Extension -eq '.sh' -and $text.Contains('agent-hub-paths.sh') -and -not $text.Contains('HUB_SCRIPTS_DIR=') -and $text.Contains('SCRIPT_DIR=$(CDPATH')) {
                Write-Host ("STILL_BROKEN_SH {0}" -f $_.Name)
            }
        }
    }
}

Write-Host ("fixed_count={0}" -f $fixed)
