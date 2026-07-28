[CmdletBinding()]
param(
    [string[]]$FilePath,
    [switch]$StagedOnly,
    [switch]$AllTracked,
    [switch]$WorkingTree,
    [switch]$AllowBatch,
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

$selectedModeCount = 0
if ($FilePath -and $FilePath.Count -gt 0) { $selectedModeCount++ }
if ($StagedOnly) { $selectedModeCount++ }
if ($AllTracked) { $selectedModeCount++ }
if ($WorkingTree) { $selectedModeCount++ }

if ($selectedModeCount -ne 1) {
    throw 'Choose exactly one mode: -FilePath <relative-path>, -StagedOnly, -AllTracked, or -WorkingTree.'
}

if ($FilePath -and $FilePath.Count -ne 1) {
    throw 'For safety, -FilePath accepts exactly one file per run. Validate one file first, then run batch mode explicitly if needed.'
}

if (($StagedOnly -or $AllTracked -or $WorkingTree) -and -not $AllowBatch) {
    throw 'Batch normalization is blocked by default. After validating one file, rerun with -AllowBatch plus -StagedOnly, -AllTracked, or -WorkingTree.'
}

Push-Location $resolvedRepoRoot
try {
    if (-not (Test-Path -LiteralPath (Join-Path $resolvedRepoRoot '.git'))) {
        throw "Not a Git repository root (missing .git): $resolvedRepoRoot"
    }

    $extensions = @(
        '.java', '.xml', '.yml', '.yaml', '.properties', '.md', '.mdc', '.sql',
        '.js', '.jsx', '.ts', '.tsx', '.vue', '.json', '.css', '.scss', '.html',
        '.ps1', '.psm1', '.py', '.sh', '.txt', '.ini', '.editorconfig', '.gitattributes', '.gitignore'
    )

    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    $updatedFiles = New-Object System.Collections.Generic.List[string]

    function Test-IsTextTarget([string]$path) {
        $fileName = [System.IO.Path]::GetFileName($path)
        if ($fileName -in @('.gitignore', '.gitattributes', '.editorconfig', 'AGENTS.md')) {
            return $true
        }

        $ext = [System.IO.Path]::GetExtension($path)
        return $extensions -contains $ext.ToLowerInvariant()
    }

    function Get-TargetFiles {
        if ($FilePath) {
            $candidate = $FilePath[0]
            if (-not (Test-Path -LiteralPath $candidate)) {
                throw "File not found: $candidate"
            }
            if (-not (Test-IsTextTarget $candidate)) {
                throw "Unsupported file type for normalization: $candidate"
            }
            return @($candidate)
        }

        if ($StagedOnly) {
            $files = git diff --cached --name-only --diff-filter=ACMR
        }
        elseif ($AllTracked) {
            $files = git ls-files
        }
        else {
            $files = git ls-files --cached --others --exclude-standard
        }

        return $files | Where-Object {
            $_ -and (Test-IsTextTarget $_) -and (Test-Path -LiteralPath $_)
        } | Select-Object -Unique
    }

    foreach ($file in Get-TargetFiles) {
        $reader = [System.IO.StreamReader]::new($file, $true)
        try {
            $content = $reader.ReadToEnd()
        }
        finally {
            $reader.Dispose()
        }

        $normalized = $content.Replace("`r`n", "`n").Replace("`r", "`n")
        $existingBytes = [System.IO.File]::ReadAllBytes($file)
        $targetBytes = $utf8NoBom.GetBytes($normalized)

        if (-not [System.Linq.Enumerable]::SequenceEqual($existingBytes, $targetBytes)) {
            [System.IO.File]::WriteAllBytes($file, $targetBytes)
            $updatedFiles.Add($file)
        }
    }

    Write-Host ("Normalized files: {0}" -f $updatedFiles.Count) -ForegroundColor Green
    $updatedFiles | Sort-Object | ForEach-Object { Write-Host "  $_" }
}
finally {
    Pop-Location
}