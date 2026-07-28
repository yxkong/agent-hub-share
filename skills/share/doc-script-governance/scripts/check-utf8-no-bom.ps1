[CmdletBinding()]
param(
    [switch]$StagedOnly,
    [Alias('WorkspaceRoot')]
    [string]$RepoRoot = ''
)

$ErrorActionPreference = 'Stop'
$__hubScripts = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\..\..\scripts'))
. (Join-Path $__hubScripts 'agent-hub-paths.ps1')

$resolvedRepoRoot = Resolve-AgentWorkspaceRoot -WorkspaceRoot $RepoRoot -AllowCurrentLocation
if (-not $resolvedRepoRoot) {
    throw 'A repository root is required. Pass -RepoRoot, set AGENTS_DEFAULT_PROJECT_ROOT, or run the script from the target repository.'
}

Push-Location $resolvedRepoRoot
try {
    if (-not (Test-Path -LiteralPath (Join-Path $resolvedRepoRoot '.git'))) {
        throw "Not a Git repository root (missing .git): $resolvedRepoRoot"
    }

    $extensions = @(
        '.java', '.xml', '.yml', '.yaml', '.properties', '.md', '.sql',
        '.js', '.ts', '.vue', '.json', '.css', '.scss', '.html', '.ps1', '.sh'
    )

    function Test-IsTextTarget([string]$path) {
        $ext = [System.IO.Path]::GetExtension($path)
        return $extensions -contains $ext.ToLowerInvariant()
    }

    function Get-TargetFiles {
        if ($StagedOnly) {
            $files = git -C $resolvedRepoRoot diff --cached --name-only --diff-filter=ACMR
        }
        else {
            $files = git -C $resolvedRepoRoot ls-files
        }

        return $files | Where-Object {
            $_ -and (Test-IsTextTarget $_) -and (Test-Path (Join-Path $resolvedRepoRoot $_))
        }
    }

    $invalidFiles = New-Object System.Collections.Generic.List[string]

    foreach ($file in Get-TargetFiles) {
        $fullPath = Join-Path $resolvedRepoRoot $file
        $bytes = [System.IO.File]::ReadAllBytes($fullPath)
        if ($bytes.Length -ge 3 -and $bytes[0] -eq 239 -and $bytes[1] -eq 187 -and $bytes[2] -eq 191) {
            $invalidFiles.Add($file)
        }
    }

    if ($invalidFiles.Count -gt 0) {
        Write-Host ''
        Write-Host 'The following files use UTF-8 BOM. Convert them to UTF-8 without BOM before commit:' -ForegroundColor Red
        $invalidFiles | ForEach-Object { Write-Host "  $_" -ForegroundColor Yellow }
        Write-Host ''
        Write-Host 'PowerShell fix for one file:' -ForegroundColor Cyan
        Write-Host '$p="relative/path"; $c=Get-Content $p -Raw; [System.IO.File]::WriteAllText($p,$c,(New-Object System.Text.UTF8Encoding($false)))'
        Write-Host ("UTF8_NO_BOM=fail count={0}" -f $invalidFiles.Count) -ForegroundColor Red
        exit 1
    }

    Write-Host 'UTF8_NO_BOM=ok' -ForegroundColor Green
}
finally {
    Pop-Location
}
