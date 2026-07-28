#Requires -Version 5.1
<#
.SYNOPSIS
  Thin PowerShell wrapper for the cross-platform Python ops-check core.
#>
param(
    [Parameter(Mandatory = $false)]
    [string]$OpsRoot,
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

if ($Help) {
    & $Python.Source (Join-Path $ScriptDir "ecs_ops.py") "ops-check" "--help"
} else {
    if (-not $OpsRoot) {
        Write-Host "missing required parameter: -OpsRoot" -ForegroundColor Red
        exit 1
    }
    & $Python.Source (Join-Path $ScriptDir "ecs_ops.py") "ops-check" "--ops-root" $OpsRoot
}
exit $LASTEXITCODE
