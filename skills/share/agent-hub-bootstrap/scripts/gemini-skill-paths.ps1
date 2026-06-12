Set-StrictMode -Version Latest

function Resolve-GeminiSkillAlias {
    [CmdletBinding()]
    param([string]$Alias = 'gemini')

    $normalized = ($Alias.Trim()).ToLowerInvariant()
    if (-not $normalized) {
        $normalized = 'gemini'
    }

    switch ($normalized) {
        'gemini' { return 'gemini' }
        'gemini-cli' { return 'gemini' }
        'antigravity' { return 'gemini' }
        'antigravity-cli' { return 'gemini' }
        'config' { return 'gemini' }
        '反重力' { return 'gemini' }
        default {
            throw "Unsupported Gemini skill alias: $Alias. Supported aliases resolve to ~/.gemini/skills."
        }
    }
}

function Get-GeminiUserSkillRoot {
    [CmdletBinding()]
    param(
        [string]$UserHome = $env:USERPROFILE,
        [string]$Alias = 'gemini'
    )

    Resolve-GeminiSkillAlias -Alias $Alias | Out-Null
    if (-not $UserHome) {
        throw 'Unable to resolve user home for Gemini skills.'
    }

    return (Join-Path $UserHome '.gemini\skills')
}

function Get-GeminiProjectSkillRoot {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    if (-not $ProjectRoot) {
        throw 'ProjectRoot is required for project-level Gemini skill links.'
    }

    return (Join-Path $ProjectRoot '.agents\skills')
}
