Set-StrictMode -Version Latest

function Resolve-GeminiSkillAlias {
    [CmdletBinding()]
    param([string]$Alias = 'gemini')

    $normalized = ($Alias.Trim()).ToLowerInvariant()
    if (-not $normalized) {
        $normalized = 'gemini'
    }

    switch ($normalized) {
        'gemini' { return 'gemini-cli' }
        'gemini-cli' { return 'gemini-cli' }
        'antigravity' { return 'antigravity' }
        'antigravity-ide' { return 'antigravity' }
        'config' { return 'antigravity' }
        "$([char]0x53cd)$([char]0x91cd)$([char]0x529b)" { return 'antigravity' }
        default {
            throw "Unsupported Gemini skill alias: $Alias. Use gemini-cli or antigravity."
        }
    }
}

function Get-GeminiUserSkillRoot {
    [CmdletBinding()]
    param(
        [string]$UserHome = $env:USERPROFILE,
        [string]$Alias = 'gemini'
    )

    $resolvedAlias = Resolve-GeminiSkillAlias -Alias $Alias
    if (-not $UserHome) {
        throw 'Unable to resolve user home for Gemini skills.'
    }

    if ($resolvedAlias -eq 'antigravity') { return (Join-Path $UserHome '.gemini\config\skills') }
    return (Join-Path $UserHome '.gemini\skills')
}

function Get-GeminiUserSkillRoots {
    [CmdletBinding()]
    param([string]$UserHome = $env:USERPROFILE)
    return @(
        (Get-GeminiUserSkillRoot -UserHome $UserHome -Alias 'gemini-cli'),
        (Get-GeminiUserSkillRoot -UserHome $UserHome -Alias 'antigravity')
    ) | Select-Object -Unique
}

function Get-GeminiProjectSkillRoot {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    if (-not $ProjectRoot) {
        throw 'ProjectRoot is required for project-level Gemini skill links.'
    }

    return (Join-Path $ProjectRoot '.agents\skills')
}
