<#
.SYNOPSIS
    Builds TechInsightVault/indexes/assets.index.json.
.DESCRIPTION
    只扫描 01_case_library/ 和 04_methodology/（canonical asset 目录）；排除 bak/、README.md。
    canonical_id 必须显式声明（YAML front matter 或旧 **canonical_id**: 格式）。
    缺失时默认 exit 1（fail）；-AllowMissing 仅 stderr 警告并 exit 0（审计/迁移模式）。
    重复 canonical_id 始终 exit 1。
#>
[CmdletBinding()]
param(
    [string]$HubRoot = '',
    [switch]$AllowMissing
)

$ErrorActionPreference = 'Stop'
$__hubScripts = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\..\..\scripts'))
. (Join-Path $__hubScripts 'agent-hub-paths.ps1')

$agentsRoot = Resolve-AgentHubRoot -HubRoot $HubRoot -ScriptRoot $__hubScripts
$vaultRoot = Join-Path $agentsRoot 'TechInsightVault'
if (-not (Test-Path -LiteralPath $vaultRoot -PathType Container)) {
    throw "TechInsightVault not found: $vaultRoot"
}

$indexesDir = Join-Path $vaultRoot 'indexes'
New-Item -ItemType Directory -Path $indexesDir -Force | Out-Null

$py = Resolve-AgentPython3Interpreter
$hubPy = Join-Path $__hubScripts 'python/hub_build_indices.py'
if (-not (Test-Path -LiteralPath $hubPy -PathType Leaf)) {
    throw "missing indexer: $hubPy"
}

$pyArgs = @('tech-insight')
if ($AllowMissing) { $pyArgs += '--allow-missing' }
$pyArgs += $vaultRoot

& $py $hubPy @pyArgs
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
