#Requires -Version 5.1
<#
.SYNOPSIS
  Thin PowerShell wrapper: free a local TCP port (ops-bootstrap helper).

.EXAMPLE
  pwsh -File .\free-local-port.ps1 -Port 9100
  pwsh -File .\free-local-port.ps1 -Port 9100 -DryRun
#>
param(
    [int]$Port = 9100,
    [string]$Match = "uvicorn|main:app",
    [switch]$DryRun,
    [switch]$Probe,
    [int]$Retries = 3,
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
    & $Python.Source (Join-Path $ScriptDir "ecs_ops.py") "local" "free-port" "--help"
    exit $LASTEXITCODE
}

$argv = @(
    (Join-Path $ScriptDir "ecs_ops.py"),
    "local",
    "free-port",
    "--port", "$Port",
    "--retries", "$Retries"
)
if ($Match) {
    $argv += @("--match", $Match)
}
if ($DryRun) {
    $argv += "--dry-run"
}
if ($Probe) {
    $argv += "--probe"
}

& $Python.Source @argv
exit $LASTEXITCODE
