[CmdletBinding()]
param(
    [string]$HubRoot = '',
    [switch]$DryRun,
    [switch]$ReplaceRealDirs
)

$ErrorActionPreference = 'Stop'

$skillScriptRoot = $PSScriptRoot
$fallbackHubRoot = Resolve-Path -LiteralPath (Join-Path $skillScriptRoot '..\..\..\..')
. (Join-Path $fallbackHubRoot 'scripts\agent-hub-paths.ps1')
. (Join-Path $skillScriptRoot 'gemini-skill-paths.ps1')

$agentsRoot = Resolve-AgentHubRoot -HubRoot $HubRoot -ScriptRoot (Join-Path $fallbackHubRoot 'scripts')
$geminiSkillsRoots = @(Get-GeminiUserSkillRoots)
$pythonBin = Resolve-AgentPython3Interpreter
$agentHubPy = Join-Path $fallbackHubRoot 'scripts\agent_hub.py'
$skillRelativePaths = @(& $pythonBin $agentHubPy list-skills --hub-root $agentsRoot --project-type generic --format paths | Where-Object { $_ })
$selectedSkillNames = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
foreach ($relativePath in $skillRelativePaths) { [void]$selectedSkillNames.Add((Split-Path $relativePath -Leaf)) }
$managedSkillsPrefix = [System.IO.Path]::GetFullPath((Join-Path $agentsRoot 'skills')).TrimEnd('\') + '\'

function Ensure-GeminiSkillJunction {
    param(
        [Parameter(Mandatory = $true)][string]$LinkPath,
        [Parameter(Mandatory = $true)][string]$TargetPath
    )

    if ($DryRun) {
        Write-Host ("  [DRY-RUN] Junction: {0} -> {1}" -f $LinkPath, $TargetPath)
        return
    }

    Ensure-AgentDirectory -Path (Split-Path -Parent $LinkPath)
    if (Test-Path -LiteralPath $LinkPath) {
        $existing = Get-Item -LiteralPath $LinkPath -Force
        $isReparse = ($existing.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0
        if ($isReparse) {
            $target = $existing.Target
            if ($target -contains $TargetPath) {
                Write-Host ("  [OK]  {0}" -f $LinkPath) -ForegroundColor Green
                return
            }
            [System.IO.Directory]::Delete($LinkPath)
        }
        elseif (Test-Path -LiteralPath (Join-Path $LinkPath 'SKILL.md')) {
            if ($ReplaceRealDirs) {
                Remove-Item -LiteralPath $LinkPath -Recurse -Force
            }
            else {
                throw "Refusing to replace real skill directory: $LinkPath"
            }
        }
        else {
            Remove-Item -LiteralPath $LinkPath -Recurse -Force
        }
    }

    New-Item -ItemType Junction -Path $LinkPath -Target $TargetPath | Out-Null
    Write-Host ("  [NEW] {0}" -f $LinkPath) -ForegroundColor DarkGreen
}

function Remove-StaleManagedGeminiSkillLinks {
    param([Parameter(Mandatory = $true)][string]$DestinationRoot)
    if (-not (Test-Path -LiteralPath $DestinationRoot)) { return }
    foreach ($item in @(Get-ChildItem -LiteralPath $DestinationRoot -Directory -Force)) {
        $isReparse = ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0
        if (-not $isReparse) { continue }
        $target = if ($item.Target -is [System.Array]) { [string]$item.Target[0] } else { [string]$item.Target }
        if (-not $target) { continue }
        $targetFull = [System.IO.Path]::GetFullPath($target)
        if (-not $targetFull.StartsWith($managedSkillsPrefix, [System.StringComparison]::OrdinalIgnoreCase)) { continue }
        if ($selectedSkillNames.Contains($item.Name)) { continue }
        if ($DryRun) {
            Write-Host ("  [DRY-RUN] Remove stale managed skill: {0} -> {1}" -f $item.FullName, $targetFull)
        }
        else {
            [System.IO.Directory]::Delete($item.FullName)
            Write-Host ("  [REMOVED] {0} -> {1}" -f $item.FullName, $targetFull) -ForegroundColor DarkYellow
        }
    }
}

Write-Host "=== sync-gemini-skills ===" -ForegroundColor Cyan
Write-Host "  Hub root      : $agentsRoot"
Write-Host "  Scope         : generic/global only"
Write-Host "  Gemini CLI     : $(Get-GeminiUserSkillRoot -Alias 'gemini-cli')"
Write-Host "  Antigravity    : $(Get-GeminiUserSkillRoot -Alias 'antigravity')"
if ($DryRun) { Write-Host "  [DRY-RUN - no files will be written]" -ForegroundColor Yellow }
Write-Host ""

$totalCount = 0
foreach ($destinationRoot in $geminiSkillsRoots) {
    if (-not $DryRun) { Ensure-AgentDirectory -Path $destinationRoot }
    Remove-StaleManagedGeminiSkillLinks -DestinationRoot $destinationRoot
    foreach ($relativePath in $skillRelativePaths) {
        $targetPath = Join-Path $agentsRoot ($relativePath -replace '/', '\')
        $name = Split-Path $relativePath -Leaf
        Ensure-GeminiSkillJunction -LinkPath (Join-Path $destinationRoot $name) -TargetPath $targetPath
        $totalCount++
    }
}

Write-Host ""
Write-Host "GEMINI_SKILLS_ROOTS=$($geminiSkillsRoots -join ';')"
Write-Host "GEMINI_SKILLS_SYNCED=$totalCount"
Write-Host "GEMINI_SKILL_PATHS=ok"
