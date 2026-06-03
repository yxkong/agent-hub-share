Set-StrictMode -Version Latest

function Resolve-AgentAbsolutePath {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][string]$Path)

    if (Test-Path -LiteralPath $Path) {
        return (Resolve-Path -LiteralPath $Path).Path
    }

    return [System.IO.Path]::GetFullPath($Path)
}

function Ensure-AgentDirectory {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

function Resolve-AgentHubRoot {
    [CmdletBinding()]
    param(
        [string]$HubRoot = '',
        [string]$ScriptRoot = ''
    )

    if ($HubRoot) {
        return Resolve-AgentAbsolutePath -Path $HubRoot
    }

    if ($env:AGENTS_HUB_ROOT) {
        return Resolve-AgentAbsolutePath -Path $env:AGENTS_HUB_ROOT
    }

    if ($ScriptRoot) {
        return Resolve-AgentAbsolutePath -Path (Join-Path $ScriptRoot '..')
    }

    throw 'Unable to resolve agent hub root. Pass -HubRoot, set AGENTS_HUB_ROOT, or run the script from inside the hub.'
}

function Resolve-AgentWorkspaceRoot {
    [CmdletBinding()]
    param(
        [string]$WorkspaceRoot = '',
        [switch]$AllowCurrentLocation
    )

    $candidate = ''
    if ($WorkspaceRoot) {
        $candidate = $WorkspaceRoot
    }
    elseif ($env:AGENTS_DEFAULT_PROJECT_ROOT) {
        $candidate = $env:AGENTS_DEFAULT_PROJECT_ROOT
    }
    elseif ($AllowCurrentLocation) {
        $candidate = (Get-Location).Path
    }

    if (-not $candidate) {
        return ''
    }

    return Resolve-AgentAbsolutePath -Path $candidate
}

function Resolve-AgentProjectKey {
    [CmdletBinding()]
    param(
        [string]$ProjectKey = '',
        [string]$WorkspaceRoot = ''
    )

    if ($ProjectKey) {
        return $ProjectKey.Trim()
    }

    if ($env:AGENTS_DEFAULT_PROJECT_KEY) {
        return $env:AGENTS_DEFAULT_PROJECT_KEY.Trim()
    }

    if ($WorkspaceRoot) {
        $normalized = [System.IO.Path]::GetFullPath($WorkspaceRoot).TrimEnd('\')
        return Split-Path -Leaf $normalized
    }

    return ''
}

function Normalize-AgentLf {
    [CmdletBinding()]
    param([AllowNull()][string]$Text)

    if ($null -eq $Text) {
        return ''
    }

    return ($Text -replace "`r`n", "`n" -replace "`r", "`n")
}

function Write-AgentUtf8NoBomFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [AllowNull()][string]$Content
    )

    Ensure-AgentDirectory -Path (Split-Path -Parent $Path)
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, (Normalize-AgentLf -Text $Content), $utf8NoBom)
}

function Resolve-AgentPython3Interpreter {
    [CmdletBinding()]
    param()

    foreach ($cmd in @('python3', 'python')) {
        $g = Get-Command $cmd -ErrorAction SilentlyContinue
        if (-not $g) {
            continue
        }
        try {
            $code = "import sys; sys.exit(0 if sys.version_info>=(3,6) else 1)"
            & $cmd -c $code 2>$null | Out-Null
            if ($LASTEXITCODE -eq 0) {
                return $cmd
            }
        }
        catch {
            continue
        }
    }

    $msg = @'
需要 Python 3.6+（用于执行 scripts/python/hub_build_indices.py 生成 JSON 索引）。安装示例：

  Windows:  https://www.python.org/downloads/windows/  （勾选 Add python.exe to PATH）
  或:       winget install --id Python.Python.3.12
  macOS:    brew install python3

完成后重新打开终端，运行:  & "$env:AGENTS_HUB_ROOT\scripts\ensure-hub-python.ps1"
'@
    throw $msg
}

function Test-AgentHubBackupPath {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][string]$RelativePath)

    $normalized = ($RelativePath -replace '\\', '/').TrimStart('./')
    return $normalized -match '(^|/)bak(/|$)|(^|/)bak[-_]|\.bak'
}

function Test-AgentSkillCanonicalEntrypointRel {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][string]$RelativePath)

    if (Test-AgentHubBackupPath -RelativePath $RelativePath) {
        return $false
    }
    $normalized = ($RelativePath -replace '\\', '/').TrimStart('./')
    if ($normalized -match '^skills/share/[^/]+/SKILL\.md$') { return $true }
    if ($normalized -match '^skills/projects/[^/]+/[^/]+/SKILL\.md$') { return $true }
    if ($normalized -match '^skills/media/[^/]+/SKILL\.md$') { return $true }
    return $false
}

function Get-AgentCanonicalSkillMdFiles {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$HubRoot,
        [string]$ProjectKey = ''
    )

    $hubRoot = Resolve-AgentAbsolutePath -Path $HubRoot
    $files = [System.Collections.Generic.List[string]]::new()

    $shareRoot = Join-Path $hubRoot 'skills\share'
    if (Test-Path -LiteralPath $shareRoot) {
        Get-ChildItem -LiteralPath $shareRoot -Directory | ForEach-Object {
            if ($_.Name -eq 'bak' -or $_.Name.StartsWith('.')) { return }
            $skillMd = Join-Path $_.FullName 'SKILL.md'
            if (Test-Path -LiteralPath $skillMd) {
                $rel = [System.IO.Path]::GetRelativePath($hubRoot, $skillMd) -replace '\\', '/'
                if (Test-AgentSkillCanonicalEntrypointRel -RelativePath $rel) {
                    $files.Add($skillMd) | Out-Null
                }
            }
        }
    }

    $mediaRoot = Join-Path $hubRoot 'skills\media'
    if (Test-Path -LiteralPath $mediaRoot) {
        Get-ChildItem -LiteralPath $mediaRoot -Directory | ForEach-Object {
            if ($_.Name -eq 'bak' -or $_.Name.StartsWith('.')) { return }
            $skillMd = Join-Path $_.FullName 'SKILL.md'
            if (Test-Path -LiteralPath $skillMd) {
                $rel = [System.IO.Path]::GetRelativePath($hubRoot, $skillMd) -replace '\\', '/'
                if (Test-AgentSkillCanonicalEntrypointRel -RelativePath $rel) {
                    $files.Add($skillMd) | Out-Null
                }
            }
        }
    }

    if ($ProjectKey) {
        $projectRoot = Join-Path $hubRoot "skills\projects\$ProjectKey"
        if (Test-Path -LiteralPath $projectRoot) {
            Get-ChildItem -LiteralPath $projectRoot -Directory | ForEach-Object {
                if ($_.Name -eq 'bak' -or $_.Name.StartsWith('.')) { return }
                $skillMd = Join-Path $_.FullName 'SKILL.md'
                if (Test-Path -LiteralPath $skillMd) {
                    $rel = [System.IO.Path]::GetRelativePath($hubRoot, $skillMd) -replace '\\', '/'
                    if (Test-AgentSkillCanonicalEntrypointRel -RelativePath $rel) {
                        $files.Add($skillMd) | Out-Null
                    }
                }
            }
        }
    }

    return $files
}
