[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$File,
    [int]$Max = 0,
    [string]$Type = ''
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'agent-hub-paths.ps1')

if ($Max -gt 0 -and -not [string]::IsNullOrEmpty($Type)) {
    throw 'check-skill-size: use only one of -Max and -Type'
}

$resolved = Resolve-AgentAbsolutePath -Path $File
if (-not (Test-Path -LiteralPath $resolved -PathType Leaf)) {
    throw "check-skill-size: file not found: $File"
}

function Get-NonemptyLineCount {
    param([Parameter(Mandatory = $true)][string]$Path)
    $n = 0
    Get-Content -LiteralPath $Path | ForEach-Object {
        if ($_.Trim().Length -gt 0) {
            $n++
        }
    }
    return $n
}

$n = Get-NonemptyLineCount -Path $resolved

if ($Max -le 0 -and [string]::IsNullOrEmpty($Type)) {
    Write-Output ("SKILL_NONEMPTY_LINES={0} file={1}" -f $n, $resolved)
    exit 0
}

$limit = $Max
if (-not [string]::IsNullOrEmpty($Type)) {
    $limit = switch ($Type) {
        'pure-router' { 80 }
        'router-hard' { 130 }
        'multi-domain' { 150 }
        'meta' { 160 }
        Default {
            throw 'check-skill-size: -Type must be pure-router|router-hard|multi-domain|meta'
        }
    }
}

if ($limit -le 0) {
    throw 'check-skill-size: set -Max or -Type'
}

if ($n -le $limit) {
    Write-Output ("SKILL_SIZE_OK nonempty={0} max={1} file={2}" -f $n, $limit, $resolved)
    exit 0
}

Write-Output ("SKILL_SIZE_FAIL nonempty={0} max={1} file={2}" -f $n, $limit, $resolved)
exit 1
