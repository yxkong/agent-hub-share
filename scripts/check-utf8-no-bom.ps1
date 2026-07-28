# L1 compatibility forwarder -> L2 skill script (doc-script-governance/check-utf8-no-bom.ps1)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'agent-hub-paths.ps1')
$hubRootArg = ''
for ($i = 0; $i -lt $args.Count; $i++) {
    if ($args[$i] -eq '-HubRoot' -and ($i + 1) -lt $args.Count) {
        $hubRootArg = [string]$args[$i + 1]
        break
    }
}
$agentsRoot = Resolve-AgentHubRoot -HubRoot $hubRootArg -ScriptRoot $PSScriptRoot
$target = Join-Path $agentsRoot "skills\share\doc-script-governance\scripts\check-utf8-no-bom.ps1"
if (-not (Test-Path -LiteralPath $target)) {
    throw "L2 script not found: $target"
}
& $target @args
if (Get-Variable -Name LASTEXITCODE -Scope Global -ErrorAction SilentlyContinue) {
    exit [int]$global:LASTEXITCODE
}
exit 0
