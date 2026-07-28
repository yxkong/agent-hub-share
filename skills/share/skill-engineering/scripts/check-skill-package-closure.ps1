[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$SkillsRoot,
    [string]$SkillRoot = '',
    [switch]$AllManifests,
    [switch]$RunSmoke,
    [string]$ExportDir = '',
    [string]$JsonOutput = ''
)

$ErrorActionPreference = 'Stop'
$core = Join-Path $PSScriptRoot 'skill_package_closure.py'
if (-not (Test-Path -LiteralPath $core -PathType Leaf)) {
    throw "Skill package closure core not found: $core"
}

$forward = @($core, '--skills-root', $SkillsRoot)
if ($SkillRoot) { $forward += @('--skill-root', $SkillRoot) }
if ($AllManifests) { $forward += '--all-manifests' }
if ($RunSmoke) { $forward += '--run-smoke' }
if ($ExportDir) { $forward += @('--export-dir', $ExportDir) }
if ($JsonOutput) { $forward += @('--json-output', $JsonOutput) }

foreach ($candidate in @(
        [pscustomobject]@{ Name = 'python3'; Prefix = @() },
        [pscustomobject]@{ Name = 'python'; Prefix = @() },
        [pscustomobject]@{ Name = 'py'; Prefix = @('-3') }
    )) {
    $command = Get-Command $candidate.Name -ErrorAction SilentlyContinue
    if (-not $command) { continue }
    try {
        & $command.Source @($candidate.Prefix) --version *> $null
        if ($LASTEXITCODE -ne 0) { continue }
        & $command.Source @($candidate.Prefix) @forward
        exit $LASTEXITCODE
    }
    catch {
        continue
    }
}
throw 'Skill package closure requires python3, python, or py -3'
