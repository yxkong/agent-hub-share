[CmdletBinding()]
param(
    [string]$HubRoot = ''
)

$ErrorActionPreference = 'Stop'
$__hubScripts = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\..\..\scripts'))
. (Join-Path $__hubScripts 'agent-hub-paths.ps1')

$agentsRoot = Resolve-AgentHubRoot -HubRoot $HubRoot -ScriptRoot $__hubScripts
$promptsRoot = Join-Path $agentsRoot 'prompts'
$outDir = Join-Path $promptsRoot 'indexes'
New-Item -ItemType Directory -Path $outDir -Force | Out-Null

$py = Resolve-AgentPython3Interpreter
$hubPy = Join-Path $__hubScripts 'python/hub_build_indices.py'
if (-not (Test-Path -LiteralPath $hubPy -PathType Leaf)) {
    throw "missing indexer: $hubPy"
}

& $py $hubPy prompts $promptsRoot
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
