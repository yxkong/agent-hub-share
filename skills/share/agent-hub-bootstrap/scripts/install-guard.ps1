#requires -Version 7.0
<#
  Install destructive command guard hooks into the current project for all supported platforms.

  Usage:
    pwsh -NoProfile -File "$AGENTS_HUB_ROOT/skills/share/agent-hub-bootstrap/scripts/install-guard.ps1"
    pwsh -NoProfile -File install-guard.ps1 -Platforms cursor,claude,codex,gemini

  Default: install for all detected platforms (cursor always; others if config dir exists).
#>
param(
    [string[]]$Platforms = @(),
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

# Resolve hub root
$hubRoot = $env:AGENTS_HUB_ROOT
if (-not $hubRoot) {
    $hubRoot = (Get-Item $PSScriptRoot).Parent.Parent.Parent.Parent.FullName
}

$scriptName = 'guard-destructive-command.py'
$authorizationScriptName = 'write-authorization-guard.py'
$sourceScript = Join-Path $PSScriptRoot $scriptName
$sourceAuthorizationScript = Join-Path $PSScriptRoot $authorizationScriptName

if (-not (Test-Path $sourceScript)) {
    Write-Error "Guard script not found: $sourceScript"
    exit 1
}
if (-not (Test-Path $sourceAuthorizationScript)) {
    Write-Error "Authorization guard script not found: $sourceAuthorizationScript"
    exit 1
}

$cwd = (Get-Location).Path
$installed = @()
$skipped = @()

function Install-ForCursor {
    $hooksDir = Join-Path $cwd '.cursor/hooks'
    $hooksJson = Join-Path $cwd '.cursor/hooks.json'
    $destScript = Join-Path $hooksDir $scriptName

    if ($DryRun) {
        Write-Host "[DRY-RUN] Would install to: $destScript"
        Write-Host "[DRY-RUN] Would update: $hooksJson"
        return
    }

    New-Item -ItemType Directory -Path $hooksDir -Force | Out-Null
    Copy-Item $sourceScript $destScript -Force

    # Merge into hooks.json
    $config = @{ version = 1; hooks = @{} }
    if (Test-Path $hooksJson) {
        $raw = Get-Content $hooksJson -Raw
        $config = $raw | ConvertFrom-Json -AsHashtable
        if (-not $config.ContainsKey('hooks')) {
            $config['hooks'] = @{}
        }
    }

    if (-not $config.hooks.ContainsKey('beforeShellExecution')) {
        $config.hooks['beforeShellExecution'] = @()
    }

    $existing = $config.hooks['beforeShellExecution'] | Where-Object {
        $_.command -match 'guard-destructive-command'
    }
    if ($existing) {
        $skipped += 'cursor (already configured)'
        return
    }

    $config.hooks['beforeShellExecution'] += @{
        command    = "python `".cursor/hooks/$scriptName`""
        failClosed = $true
        timeout    = 10
    }

    $config | ConvertTo-Json -Depth 10 | Set-Content $hooksJson -Encoding UTF8
    $installed += 'cursor'
}

function Install-ForClaude {
    $hooksDir = Join-Path $cwd '.claude/hooks'
    $settingsJson = Join-Path $cwd '.claude/settings.json'
    $destScript = Join-Path $hooksDir $scriptName

    if ($DryRun) {
        Write-Host "[DRY-RUN] Would install to: $destScript"
        Write-Host "[DRY-RUN] Would update: $settingsJson"
        return
    }

    New-Item -ItemType Directory -Path $hooksDir -Force | Out-Null
    Copy-Item $sourceScript $destScript -Force

    $config = @{ hooks = @{} }
    if (Test-Path $settingsJson) {
        $raw = Get-Content $settingsJson -Raw
        $config = $raw | ConvertFrom-Json -AsHashtable
        if (-not $config.ContainsKey('hooks')) {
            $config['hooks'] = @{}
        }
    }

    if (-not $config.hooks.ContainsKey('PreToolUse')) {
        $config.hooks['PreToolUse'] = @()
    }

    $existing = $config.hooks['PreToolUse'] | Where-Object {
        $_.hooks.command -match 'guard-destructive-command'
    }
    if ($existing) {
        $skipped += 'claude (already configured)'
        return
    }

    $config.hooks['PreToolUse'] += @{
        matcher = 'Bash'
        hooks   = @(
            @{
                type    = 'command'
                command = "python `".claude/hooks/$scriptName`""
                timeout = 10
            }
        )
    }

    $config | ConvertTo-Json -Depth 10 | Set-Content $settingsJson -Encoding UTF8
    $installed += 'claude'
}

function Install-ForCodex {
    $hooksDir = Join-Path $cwd '.codex/hooks'
    $hooksJson = Join-Path $cwd '.codex/hooks.json'
    $stateDir = Join-Path $cwd '.codex/state/write-authorization'
    $stateIgnore = Join-Path $stateDir '.gitignore'
    $destScript = Join-Path $hooksDir $scriptName
    $destAuthorizationScript = Join-Path $hooksDir $authorizationScriptName

    if ($DryRun) {
        Write-Host "[DRY-RUN] Would install to: $destScript"
        Write-Host "[DRY-RUN] Would install to: $destAuthorizationScript"
        Write-Host "[DRY-RUN] Would update: $hooksJson"
        return
    }

    New-Item -ItemType Directory -Path $hooksDir -Force | Out-Null
    New-Item -ItemType Directory -Path $stateDir -Force | Out-Null
    if (-not (Test-Path -LiteralPath $stateIgnore)) {
        "*`n!.gitignore`n" | Set-Content -LiteralPath $stateIgnore -Encoding utf8NoBOM -NoNewline
    }
    Copy-Item $sourceScript $destScript -Force
    Copy-Item $sourceAuthorizationScript $destAuthorizationScript -Force

    $config = @{ hooks = @{} }
    if (Test-Path $hooksJson) {
        $raw = Get-Content $hooksJson -Raw
        $config = $raw | ConvertFrom-Json -AsHashtable
    }

    if (-not $config.ContainsKey('hooks')) {
        $legacy = $config
        $config = @{ hooks = @{} }
        foreach ($eventName in @('SessionStart', 'UserPromptSubmit', 'PreToolUse')) {
            if ($legacy.ContainsKey($eventName)) {
                $config.hooks[$eventName] = $legacy[$eventName]
            }
        }
    }

    foreach ($eventName in @('SessionStart', 'UserPromptSubmit', 'PreToolUse')) {
        if (-not $config.hooks.ContainsKey($eventName)) {
            $config.hooks[$eventName] = @()
        }
    }

    $authorizationCommand = "python `".codex/hooks/$authorizationScriptName`""
    foreach ($eventName in @('SessionStart', 'UserPromptSubmit', 'PreToolUse')) {
        $existingAuthorization = $config.hooks[$eventName] | Where-Object {
            $_.hooks.command -match 'write-authorization-guard'
        }
        if (-not $existingAuthorization) {
            $entry = @{
                hooks = @(
                    @{
                        type    = 'command'
                        command = $authorizationCommand
                        timeout = 10
                    }
                )
            }
            if ($eventName -eq 'PreToolUse') {
                $entry.matcher = '.*'
            }
            $config.hooks[$eventName] += $entry
        }
    }

    $existingDestructive = $config.hooks.PreToolUse | Where-Object {
        $_.hooks.command -match 'guard-destructive-command'
    }
    if (-not $existingDestructive) {
        $config.hooks.PreToolUse += @{
            matcher = '^Bash$'
            hooks   = @(
                @{
                    type    = 'command'
                    command = "python `".codex/hooks/$scriptName`""
                    timeout = 10
                }
            )
        }
    }

    $config | ConvertTo-Json -Depth 10 | Set-Content $hooksJson -Encoding UTF8
    $script:installed += 'codex'
}

function Install-ForGemini {
    $hooksDir = Join-Path $cwd '.gemini/hooks'
    $settingsJson = Join-Path $cwd '.gemini/settings.json'
    $destScript = Join-Path $hooksDir $scriptName

    if ($DryRun) {
        Write-Host "[DRY-RUN] Would install to: $destScript"
        Write-Host "[DRY-RUN] Would update: $settingsJson"
        return
    }

    New-Item -ItemType Directory -Path $hooksDir -Force | Out-Null
    Copy-Item $sourceScript $destScript -Force

    $config = @{ hooks = @{} }
    if (Test-Path $settingsJson) {
        $raw = Get-Content $settingsJson -Raw
        $config = $raw | ConvertFrom-Json -AsHashtable
        if (-not $config.ContainsKey('hooks')) {
            $config['hooks'] = @{}
        }
    }

    if (-not $config.hooks.ContainsKey('BeforeTool')) {
        $config.hooks['BeforeTool'] = @()
    }

    $existing = $config.hooks['BeforeTool'] | Where-Object {
        $_.hooks.command -match 'guard-destructive-command'
    }
    if ($existing) {
        $skipped += 'gemini (already configured)'
        return
    }

    $config.hooks['BeforeTool'] += @{
        matcher = 'run_shell_command'
        hooks   = @(
            @{
                type    = 'command'
                command = "python `".gemini/hooks/$scriptName`""
                timeout = 10000
            }
        )
    }

    $config | ConvertTo-Json -Depth 10 | Set-Content $settingsJson -Encoding UTF8
    $installed += 'gemini'
}

# --- Determine platforms ---
if ($Platforms.Count -eq 0) {
    # Auto-detect: always cursor; others if their config dirs exist
    $Platforms = @('cursor')
    if (Test-Path (Join-Path $cwd '.claude')) { $Platforms += 'claude' }
    if (Test-Path (Join-Path $cwd '.codex')) { $Platforms += 'codex' }
    if (Test-Path (Join-Path $cwd '.gemini')) { $Platforms += 'gemini' }
}

foreach ($p in $Platforms) {
    switch ($p) {
        'cursor' { Install-ForCursor }
        'claude' { Install-ForClaude }
        'codex' { Install-ForCodex }
        'gemini' { Install-ForGemini }
        default { Write-Warning "Unknown platform: $p" }
    }
}

Write-Host ""
Write-Host "=== Command + Write Authorization Guard Installation ==="
if ($installed.Count -gt 0) {
    Write-Host "Installed: $($installed -join ', ')"
}
if ($skipped.Count -gt 0) {
    Write-Host "Skipped: $($skipped -join ', ')"
}
Write-Host ""
Write-Host "Blocked commands: git restore/reset/clean/stash, git checkout --, rm -rf, del -force"
Write-Host "Destructive filter allows normal commands; Codex write gate creates one goal authorization from an explicit implementation request."
Write-Host "Codex write gate: GOAL_AUTHORIZED for the workspace; reconfirm only for high-risk or goal-boundary changes"
Write-Host ""
Write-Host "Verify:"
Write-Host '  python .codex/hooks/write-authorization-guard.py status'
Write-Host '  pwsh -NoProfile -File scripts/check-hooks.ps1 -ProjectRoot . -RequireCodex'
