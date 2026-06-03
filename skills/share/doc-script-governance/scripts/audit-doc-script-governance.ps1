param(
    [string]$HubRoot = ''
)
$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path ".").Path

# 解析 hub root：-HubRoot 参数 > AGENTS_HUB_ROOT 环境变量 > 脚本向上推导（scripts → …/skills/share/doc-script-governance → hub 根）
if (-not $HubRoot) {
    $HubRoot = if ($env:AGENTS_HUB_ROOT) { $env:AGENTS_HUB_ROOT } `
               else { Split-Path (Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent) -Parent }
}
$sharedSkillRoot = Join-Path $HubRoot 'skills'

$docScanRoots = @('docs', '.agents/skills', '.cursor/skills', '.claude/skills')
if (Test-Path $sharedSkillRoot) {
    $docScanRoots += $sharedSkillRoot
}

$textAuditExtensions = @('.md', '.sql', '.ps1', '.json', '.yml', '.yaml', '.mdc')
$excludePathPatterns = @('\\\.git\\', '\\node_modules\\', '\\target\\', '\\dist\\')
$namePattern = '(?i)(copy|_final|_v2|_backup|old)'
$usageGuideNamePattern = '(?i)(guide|manual|usage|howto|quickstart|使用说明|操作手册|接入指南|快速开始|运行指引)'
$linkPattern = '\[[^\]]+\]\(([^)]+)\)'
$historicalBackupNamePattern = '-\d{8}-\d{6}(\.[^.]+)$'

$namingViolations = New-Object System.Collections.Generic.List[string]
$historicalLinkViolations = New-Object System.Collections.Generic.List[string]
$placementWarnings = New-Object System.Collections.Generic.List[string]
$usageGuidePlacementViolations = New-Object System.Collections.Generic.List[string]
$forbiddenPathViolations = New-Object System.Collections.Generic.List[string]
$encodingViolations = New-Object System.Collections.Generic.List[string]
$lineEndingWarnings = New-Object System.Collections.Generic.List[string]
$backupPlacementViolations = New-Object System.Collections.Generic.List[string]

function Test-InExcludedPath([string]$path) {
    foreach ($pattern in $excludePathPatterns) {
        if ($path -match $pattern) {
            return $true
        }
    }

    return $false
}

function Test-InBakPath([string]$path) {
    return ($path -replace '/', '\\') -match '(^|\\)bak(\\|$)'
}

function Get-RepoFiles([string[]]$roots, [string[]]$exts) {
    $result = New-Object System.Collections.Generic.List[System.IO.FileInfo]
    foreach ($root in $roots | Select-Object -Unique) {
        if (-not (Test-Path $root)) {
            continue
        }

        Get-ChildItem -Path $root -Recurse -File | Where-Object {
            ($exts -contains $_.Extension.ToLowerInvariant()) -and -not (Test-InExcludedPath -path $_.FullName)
        } | ForEach-Object {
            $result.Add($_) | Out-Null
        }
    }

    return $result
}

function Get-ProjectFiles([string[]]$exts) {
    Get-ChildItem -Path $repoRoot -Recurse -File | Where-Object {
        ($exts -contains $_.Extension.ToLowerInvariant()) -and
        -not (Test-InExcludedPath -path $_.FullName) -and
        ($_.FullName -notlike "$sharedSkillRoot*")
    }
}

function Get-FileBytes([string]$path) {
    return [System.IO.File]::ReadAllBytes($path)
}

function Get-RelativePath([string]$basePath, [string]$targetPath) {
    $normalizedBase = [System.IO.Path]::GetFullPath($basePath).TrimEnd('\\') + '\\'
    $normalizedTarget = [System.IO.Path]::GetFullPath($targetPath)
    $comparison = [System.StringComparison]::OrdinalIgnoreCase

    if (-not $normalizedTarget.StartsWith($normalizedBase, $comparison)) {
        return $normalizedTarget
    }

    return $normalizedTarget.Substring($normalizedBase.Length)
}

function Test-Utf8NoBom([byte[]]$bytes) {
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
        return [pscustomobject]@{
            IsValid = $false
            Reason  = 'UTF-8 BOM'
        }
    }

    if ($bytes.Length -ge 2) {
        if (($bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE) -or ($bytes[0] -eq 0xFE -and $bytes[1] -eq 0xFF)) {
            return [pscustomobject]@{
                IsValid = $false
                Reason  = 'UTF-16 BOM'
            }
        }
    }

    try {
        $utf8 = New-Object System.Text.UTF8Encoding($false, $true)
        [void]$utf8.GetString($bytes)
        return [pscustomobject]@{
            IsValid = $true
            Reason  = 'UTF-8 (No BOM)'
        }
    } catch {
        return [pscustomobject]@{
            IsValid = $false
            Reason  = 'Not valid UTF-8'
        }
    }
}

function Get-LineEndingState([byte[]]$bytes) {
    $hasLF = $false
    $hasCRLF = $false
    $hasBareCR = $false

    for ($i = 0; $i -lt $bytes.Length; $i++) {
        if ($bytes[$i] -eq 0x0D) {
            if ($i + 1 -lt $bytes.Length -and $bytes[$i + 1] -eq 0x0A) {
                $hasCRLF = $true
                $i++
                continue
            }

            $hasBareCR = $true
            continue
        }

        if ($bytes[$i] -eq 0x0A) {
            $hasLF = $true
        }
    }

    if ($hasBareCR) {
        return [pscustomobject]@{ IsPreferred = $false; State = 'CR' }
    }

    if ($hasCRLF -and $hasLF) {
        return [pscustomobject]@{ IsPreferred = $false; State = 'Mixed' }
    }

    if ($hasCRLF) {
        return [pscustomobject]@{ IsPreferred = $false; State = 'CRLF' }
    }

    if ($hasLF) {
        return [pscustomobject]@{ IsPreferred = $true; State = 'LF' }
    }

    return [pscustomobject]@{ IsPreferred = $true; State = 'No newline' }
}

function Test-BackupPathRule([string]$fullPath) {
    $normalized = $fullPath -replace '/', '\\'
    if ($normalized -notmatch '(^|\\)bak(\\|$)') {
        return $true
    }

    $parts = $normalized -split '\\'
    $bakIndex = [Array]::IndexOf($parts, 'bak')
    if ($bakIndex -lt 0) {
        return $true
    }

    $remainingCount = $parts.Length - $bakIndex - 1
    if ($remainingCount -eq 1) {
        return $true
    }

    if ($remainingCount -eq 3 -and $parts[$bakIndex + 1] -match '^\d{6}$') {
        return $true
    }

    return $false
}

$docFiles = Get-RepoFiles -roots $docScanRoots -exts @('.md')
$projectTextFiles = Get-ProjectFiles -exts $textAuditExtensions
$textAuditFiles = Get-RepoFiles -roots $docScanRoots -exts $textAuditExtensions
$textAuditFiles += $projectTextFiles
$textAuditFiles = $textAuditFiles | Sort-Object FullName -Unique

foreach ($f in ($docFiles + $projectTextFiles | Sort-Object FullName -Unique)) {
    if (Test-InBakPath -path $f.FullName) {
        continue
    }

    if ($f.Name -match $namePattern) {
        $namingViolations.Add($f.FullName) | Out-Null
    }
}

foreach ($doc in $docFiles) {
    if (Test-InBakPath -path $doc.FullName) {
        continue
    }

    $content = Get-Content -Raw -Encoding UTF8 $doc.FullName
    $matches = [regex]::Matches($content, $linkPattern)
    foreach ($m in $matches) {
        $target = $m.Groups[1].Value
        if ($target -match $namePattern -or $target -match $historicalBackupNamePattern -or $target -match '(^|/)bak(/|$)' -or $target -match '(^|\\)bak(\\|$)') {
            $historicalLinkViolations.Add("$($doc.FullName) -> $target") | Out-Null
        }
    }
}

foreach ($file in $projectTextFiles) {
    $relativePath = Get-RelativePath -basePath $repoRoot -targetPath $file.FullName
    $normalized = $relativePath -replace '/', '\\'
    $isDocPath = $normalized -match '^docs\\'
    $isGuidePath = $normalized -match '^docs\\guide\\'
    $isSkillPath = $normalized -match '^\.agents\\skills\\' -or $normalized -match '^\.cursor\\skills\\'
    $isForbiddenModulePath = $normalized -match '(^|\\)src\\main\\resources(\\|$)'
    $isBakPath = Test-InBakPath -path $normalized
    $isGuideDocCandidate = ($file.Extension.ToLowerInvariant() -eq '.md') -and ($file.Name -match $usageGuideNamePattern)

    if ($isBakPath -and -not (Test-BackupPathRule -fullPath $normalized)) {
        $backupPlacementViolations.Add($file.FullName) | Out-Null
    }

    if ($isBakPath) {
        continue
    }

    if ($isGuideDocCandidate -and -not $isGuidePath) {
        $usageGuidePlacementViolations.Add($file.FullName) | Out-Null
    }

    if (-not ($isDocPath -or $isSkillPath)) {
        $placementWarnings.Add($file.FullName) | Out-Null
    }

    if ($isForbiddenModulePath) {
        $forbiddenPathViolations.Add($file.FullName) | Out-Null
    }
}

foreach ($file in $textAuditFiles) {
    # 历史备份目录只做软警告，不纳入 hard gate；旧快照无法要求重写
    if (Test-InBakPath -path $file.FullName) { continue }

    $bytes = Get-FileBytes -path $file.FullName
    $encodingState = Test-Utf8NoBom -bytes $bytes
    if (-not $encodingState.IsValid) {
        $encodingViolations.Add("$($file.FullName) [$($encodingState.Reason)]") | Out-Null
        continue
    }

    $lineEndingState = Get-LineEndingState -bytes $bytes
    if (-not $lineEndingState.IsPreferred) {
        $lineEndingWarnings.Add("$($file.FullName) [$($lineEndingState.State)]") | Out-Null
    }
}

Write-Host '== Doc/SQL Governance Audit ==' -ForegroundColor Cyan
Write-Host ''
Write-Host "[NamingViolations] $($namingViolations.Count)" -ForegroundColor Yellow
$namingViolations | ForEach-Object { Write-Host " - $_" }
Write-Host ''
Write-Host "[HistoricalLinkViolations] $($historicalLinkViolations.Count)" -ForegroundColor Yellow
$historicalLinkViolations | ForEach-Object { Write-Host " - $_" }
Write-Host ''
Write-Host "[EncodingViolations] $($encodingViolations.Count)" -ForegroundColor Yellow
$encodingViolations | ForEach-Object { Write-Host " - $_" }
Write-Host ''
Write-Host "[LineEndingWarnings] $($lineEndingWarnings.Count)" -ForegroundColor Yellow
$lineEndingWarnings | ForEach-Object { Write-Host " - $_" }
Write-Host ''
Write-Host "[PlacementWarnings] $($placementWarnings.Count)" -ForegroundColor Yellow
$placementWarnings | ForEach-Object { Write-Host " - $_" }
Write-Host ''
Write-Host "[UsageGuidePlacementViolations] $($usageGuidePlacementViolations.Count)" -ForegroundColor Yellow
$usageGuidePlacementViolations | ForEach-Object { Write-Host " - $_" }
Write-Host ''
Write-Host "[ForbiddenPathViolations] $($forbiddenPathViolations.Count)" -ForegroundColor Red
$forbiddenPathViolations | ForEach-Object { Write-Host " - $_" }
Write-Host ''
Write-Host "[BackupPlacementViolations] $($backupPlacementViolations.Count)" -ForegroundColor Yellow
$backupPlacementViolations | ForEach-Object { Write-Host " - $_" }
Write-Host ''

if ($namingViolations.Count -eq 0 -and $historicalLinkViolations.Count -eq 0 -and $encodingViolations.Count -eq 0 -and $forbiddenPathViolations.Count -eq 0 -and $backupPlacementViolations.Count -eq 0 -and $usageGuidePlacementViolations.Count -eq 0) {
    Write-Host 'Result: PASS (no hard violations found).' -ForegroundColor Green
    exit 0
} else {
    Write-Host 'Result: NEEDS_FIX (found hard violations).' -ForegroundColor Red
    exit 1
}
