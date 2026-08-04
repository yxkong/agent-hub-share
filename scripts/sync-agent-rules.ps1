[CmdletBinding()]
param(
    [string]$HubRoot = '',
    [string]$ProjectRoot = '',
    [string]$ProjectKey = '',
    [ValidateSet('', 'engineering', 'media', 'generic', 'mixed', 'hub')]
    [string]$ProjectType = '',
    [ValidateSet('', 'posix', 'windows-pwsh', 'codex-desktop')]
    [string]$Environment = '',
    [string]$Hosts = '',
    [ValidateSet('', 'legacy', 'layered')]
    [string]$ProjectionMode = '',
    [ValidateSet('global', 'project', 'all')]
    [string]$Scope = 'all',
    [string]$Skills = '',
    [switch]$ApplyUserTargets,
    [switch]$DryRun,
    [switch]$SkipUserTargets,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Args
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'agent-hub-paths.ps1')
$scriptPath = Join-Path $PSScriptRoot 'agent_hub.py'

$cliArgs = @('sync-agent-rules')
if ($HubRoot) { $cliArgs += @('--hub-root', $HubRoot) }
if ($ProjectRoot) { $cliArgs += @('--project-root', $ProjectRoot) }
if ($ProjectKey) { $cliArgs += @('--project-key', $ProjectKey) }
if ($ProjectType) { $cliArgs += @('--project-type', $ProjectType) }
if ($Environment) { $cliArgs += @('--environment', $Environment) }
if ($Hosts) { $cliArgs += @('--hosts', $Hosts) }
if ($ProjectionMode) { $cliArgs += @('--projection-mode', $ProjectionMode) }
if ($Scope) { $cliArgs += @('--scope', $Scope) }
if ($Skills) { $cliArgs += @('--skills', $Skills) }
if ($ApplyUserTargets) { $cliArgs += '--apply-user-targets' }
if ($DryRun) { $cliArgs += '--dry-run' }
if ($SkipUserTargets) { $cliArgs += '--skip-user-targets' }
if ($Args) { $cliArgs += $Args }

$pythonBin = Resolve-AgentPython3Interpreter
& $pythonBin $scriptPath @cliArgs
exit $LASTEXITCODE
