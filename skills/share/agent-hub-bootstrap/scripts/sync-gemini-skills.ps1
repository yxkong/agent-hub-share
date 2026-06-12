[CmdletBinding()]
param(
    [string]$HubRoot = '',
    [switch]$DryRun,
    [switch]$ReplaceRealDirs,
    [switch]$SkipMedia
)

$ErrorActionPreference = 'Stop'

$skillScriptRoot = $PSScriptRoot
$fallbackHubRoot = Resolve-Path -LiteralPath (Join-Path $skillScriptRoot '..\..\..\..')
. (Join-Path $fallbackHubRoot 'scripts\agent-hub-paths.ps1')
. (Join-Path $skillScriptRoot 'gemini-skill-paths.ps1')

$agentsRoot = Resolve-AgentHubRoot -HubRoot $HubRoot -ScriptRoot (Join-Path $fallbackHubRoot 'scripts')
$shareRoot = Join-Path $agentsRoot 'skills\share'
$mediaRoot = Join-Path $agentsRoot 'skills\media'
$geminiSkillsRoot = Get-GeminiUserSkillRoot -Alias 'gemini'

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

function Sync-GeminiSkillRoot {
    param([Parameter(Mandatory = $true)][string]$SourceRoot)

    if (-not (Test-Path -LiteralPath $SourceRoot)) {
        return 0
    }

    $count = 0
    Get-ChildItem -LiteralPath $SourceRoot -Directory | Where-Object {
        $_.Name -ne 'bak' -and -not $_.Name.StartsWith('.') -and (Test-Path -LiteralPath (Join-Path $_.FullName 'SKILL.md'))
    } | ForEach-Object {
        $count++
        Ensure-GeminiSkillJunction -LinkPath (Join-Path $geminiSkillsRoot $_.Name) -TargetPath $_.FullName
    }

    return $count
}

Write-Host "=== sync-gemini-skills ===" -ForegroundColor Cyan
Write-Host "  Hub root      : $agentsRoot"
Write-Host "  Gemini skills : $geminiSkillsRoot"
if ($DryRun) { Write-Host "  [DRY-RUN - no files will be written]" -ForegroundColor Yellow }
Write-Host ""

$shareCount = Sync-GeminiSkillRoot -SourceRoot $shareRoot
$mediaCount = 0
if (-not $SkipMedia) {
    $mediaCount = Sync-GeminiSkillRoot -SourceRoot $mediaRoot
}

Write-Host ""
Write-Host "GEMINI_SKILLS_ROOT=$geminiSkillsRoot"
Write-Host "GEMINI_SKILLS_SYNCED=$($shareCount + $mediaCount)"
Write-Host "GEMINI_SKILL_PATHS=ok"
