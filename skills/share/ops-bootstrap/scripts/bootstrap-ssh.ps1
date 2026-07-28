#Requires -Version 5.1
<#
.SYNOPSIS
  Thin PowerShell wrapper for the cross-platform Python ECS ops bootstrap core.

.PARAMETER OpsRoot
  Project ops directory containing sync.config.json (and usually account.md).
#>
param(
    [Parameter(Mandatory = $false)]
    [string]$OpsRoot,
    [string]$IdentityFile = "",
    [switch]$SkipKeyDeploy,
    [switch]$Force,
    [switch]$SkipOpsCheck,
    [switch]$Help
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Python = Get-Command python -ErrorAction SilentlyContinue
if (-not $Python) {
    $Python = Get-Command python3 -ErrorAction SilentlyContinue
}
if (-not $Python) {
    Write-Host "python not found; install Python 3 and rerun" -ForegroundColor Red
    exit 1
}

$ArgsList = @(
    (Join-Path $ScriptDir "ecs_ops.py"),
    "bootstrap"
)
if ($Help) { $ArgsList += "--help" }
else {
    if (-not $OpsRoot) {
        Write-Host "missing required parameter: -OpsRoot" -ForegroundColor Red
        exit 1
    }
    $ArgsList += @("--ops-root", $OpsRoot)
}
if ($IdentityFile) { $ArgsList += @("--identity-file", $IdentityFile) }
if ($SkipKeyDeploy) { $ArgsList += "--skip-key-deploy" }
if ($Force) { $ArgsList += "--force" }
if ($SkipOpsCheck) { $ArgsList += "--skip-ops-check" }

& $Python.Source @ArgsList
exit $LASTEXITCODE
