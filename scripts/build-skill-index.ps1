[CmdletBinding()]
param(
    [string]$HubRoot = ''
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'agent-hub-paths.ps1')

$agentsRoot = Resolve-AgentHubRoot -HubRoot $HubRoot -ScriptRoot $PSScriptRoot
$shareRoot = Join-Path $agentsRoot 'skills\share'
$mediaRoot = Join-Path $agentsRoot 'skills\media'

$py = Resolve-AgentPython3Interpreter
$hubPy = Join-Path $PSScriptRoot 'python/hub_build_indices.py'
if (-not (Test-Path -LiteralPath $hubPy -PathType Leaf)) {
    throw "missing indexer: $hubPy"
}

& $py $hubPy skills $shareRoot
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

if (Test-Path -LiteralPath $mediaRoot -PathType Container) {
    & $py $hubPy media-skills $mediaRoot
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}
