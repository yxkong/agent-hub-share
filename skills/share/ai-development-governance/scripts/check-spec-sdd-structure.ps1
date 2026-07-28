[CmdletBinding()]
param(
    [string]$HubRoot = '',
    [string]$Brainstorm = '',
    [string]$Spec = '',
    [string]$Sdd = '',
    [string]$Adr = '',
    [string]$TaskContract = '',
    [ValidateSet('template', 'document', 'implementation-ready')]
    [string]$Mode = 'template',
    [string]$JsonOutput = ''
)

$ErrorActionPreference = 'Stop'
$core = Join-Path $PSScriptRoot 'spec_compiler_check.py'
if (-not (Test-Path -LiteralPath $core -PathType Leaf)) {
    throw "Spec Compiler core not found: $core"
}

$forward = @($core, '--mode', $Mode)
if ($HubRoot) { $forward += @('--hub-root', $HubRoot) }
if ($Brainstorm) { $forward += @('--brainstorm', $Brainstorm) }
if ($Spec) { $forward += @('--spec', $Spec) }
if ($Sdd) { $forward += @('--sdd', $Sdd) }
if ($Adr) { $forward += @('--adr', $Adr) }
if ($TaskContract) { $forward += @('--task-contract', $TaskContract) }
if ($JsonOutput) { $forward += @('--json-output', $JsonOutput) }

foreach ($candidate in @(
        [pscustomobject]@{ Name = 'python3'; Prefix = @() },
        [pscustomobject]@{ Name = 'python'; Prefix = @() },
        [pscustomobject]@{ Name = 'py'; Prefix = @('-3') }
    )) {
    $command = Get-Command $candidate.Name -ErrorAction SilentlyContinue
    if (-not $command) {
        continue
    }
    try {
        & $command.Source @($candidate.Prefix) --version *> $null
        if ($LASTEXITCODE -ne 0) {
            continue
        }
        & $command.Source @($candidate.Prefix) @forward
        exit $LASTEXITCODE
    }
    catch {
        continue
    }
}
throw 'Spec Compiler requires python3, python, or py -3'
