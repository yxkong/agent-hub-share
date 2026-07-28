[CmdletBinding()]
param(
    [string]$HubRoot = '',
    [string]$ReplayDir = '',
    [switch]$IncludeLegacy,
    [switch]$AllowExternalReplayDir
)

$ErrorActionPreference = 'Stop'
$__hubScripts = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\..\..\scripts'))
. (Join-Path $__hubScripts 'agent-hub-paths.ps1')

function Join-Chars {
    param([int[]]$Codes)
    $sb = New-Object System.Text.StringBuilder
    foreach ($code in $Codes) {
        [void]$sb.Append([char]$code)
    }
    return $sb.ToString()
}

$agentsRoot = Resolve-AgentHubRoot -HubRoot $HubRoot -ScriptRoot $__hubScripts
$dir = if ($ReplayDir) { Resolve-AgentAbsolutePath -Path $ReplayDir } else { Join-Path $agentsRoot 'docs\resource\replay' }
$canonicalDir = Join-Path $agentsRoot 'docs\resource\replay'

function Normalize-AgentPath {
    param([Parameter(Mandatory = $true)][string]$Path)
    return ([System.IO.Path]::GetFullPath($Path)).TrimEnd('\', '/')
}

$normalizedDir = Normalize-AgentPath -Path $dir
$normalizedCanonicalDir = Normalize-AgentPath -Path $canonicalDir

if (-not $AllowExternalReplayDir -and $normalizedDir -ne $normalizedCanonicalDir) {
    Write-Output "REPLAY_STRUCTURE=fail"
    Write-Output "REPLAY_VIOLATION: replay dir must be hub canonical dir: $normalizedCanonicalDir"
    Write-Output "REPLAY_VIOLATION: got replay dir: $normalizedDir"
    exit 1
}

if (-not (Test-Path -LiteralPath $dir)) {
    Write-Output 'REPLAY_STRUCTURE=skip (no replay dir)'
    exit 0
}

$hBoundary = '## ' + (Join-Chars @(0x4EFB, 0x52A1, 0x8FB9, 0x754C))
$hCoverage = '## ' + (Join-Chars @(0x8986, 0x76D6, 0x8303, 0x56F4, 0x6838, 0x9A8C))
$hTrajectory = '## ' + (Join-Chars @(0x4EA4, 0x4ED8, 0x8F68, 0x8FF9))
$hDecision = '## ' + (Join-Chars @(0x5173, 0x952E, 0x51B3, 0x7B56, 0x4E0E, 0x7EA0, 0x504F))
$hArtifact = '## ' + (Join-Chars @(0x4EA7, 0x7269, 0x4E0E, 0x7EC8, 0x6001))
$hEvidence = '## ' + (Join-Chars @(0x8BC1, 0x636E, 0x4E0E, 0x9A8C, 0x8BC1))
$hGap = '## ' + (Join-Chars @(0x7F3A, 0x53E3)) + ' / ' + (Join-Chars @(0x672A, 0x505A)) + ' / ' + (Join-Chars @(0x98CE, 0x9669))
$hReplayLite = '## Task Replay Lite'
$hRelease = '## Release Evidence'
$hFollow = '## ' + (Join-Chars @(0x540E, 0x7EED, 0x63A5, 0x7EED, 0x6E05, 0x5355))
$labelFeedback = Join-Chars @(0x5EFA, 0x8BAE, 0x56DE, 0x586B)

$required = @($hCoverage, $hBoundary, $hTrajectory, $hDecision, $hArtifact, $hEvidence, $hGap, $hReplayLite, $hRelease, $hFollow)

$violations = New-Object System.Collections.Generic.List[string]
$skipped = 0
$checked = 0
$files = Get-ChildItem -LiteralPath $dir -Filter "*.md" -File | Sort-Object Name

foreach ($f in $files) {
    $text = Get-Content -LiteralPath $f.FullName -Raw -Encoding UTF8
    $isV2 = $text -match '(?m)^replay_contract:\s*gate5-v2\s*$'
    if (-not $isV2 -and -not $IncludeLegacy) {
        $skipped++
        Write-Output "REPLAY_LEGACY_SKIPPED: $($f.Name)"
        continue
    }
    $checked++
    if ($text -notmatch '(?m)^task_id:\s*\S') {
        $violations.Add("$($f.Name): missing front matter task_id") | Out-Null
    }
    if (-not $isV2) {
        $violations.Add("$($f.Name): missing front matter replay_contract: gate5-v2") | Out-Null
    }
    if ($text -notmatch '(?m)^outcome:\s*\S') {
        $violations.Add("$($f.Name): missing front matter outcome") | Out-Null
    }
    $replayScope = if ($text -match '(?m)^replay_scope:\s*(\S+)') { $Matches[1] } else { '' }
    $coverageStatus = if ($text -match '(?m)^coverage_status:\s*(\S+)') { $Matches[1] } else { '' }
    if ([string]::IsNullOrEmpty($coverageStatus)) {
        $violations.Add("$($f.Name): missing front matter coverage_status") | Out-Null
    }
    elseif ($coverageStatus -notin @('full', 'partial', 'unknown')) {
        $violations.Add("$($f.Name): invalid coverage_status $coverageStatus") | Out-Null
    }
    if ($replayScope -eq 'session' -and $coverageStatus -ne 'full') {
        $violations.Add("$($f.Name): replay_scope session requires coverage_status full") | Out-Null
    }
    if ($replayScope -eq 'session' -and $text -match '(?i)R\d+\s*[\-–]\s*R\d+') {
        $violations.Add("$($f.Name): replay_scope session appears bounded to a stage range") | Out-Null
    }
    foreach ($h in $required) {
        if ($text -notmatch [regex]::Escape($h)) {
            $violations.Add("$($f.Name): missing heading $h") | Out-Null
        }
    }
    $hasPathGuardPass = $false
    foreach ($line in ($text -split '\r?\n')) {
        if ($line -match 'path_guard' -and $line -match '\bpass\b') {
            $hasPathGuardPass = $true
            break
        }
    }
    if (-not $hasPathGuardPass) {
        $violations.Add("$($f.Name): missing Path Guard pass") | Out-Null
    }
    if ($text -match '(?m)^-\s*target_path[：:]\s*(.+)$') {
        $targetPath = $Matches[1].Trim().Trim('`')
        if ($targetPath -and $targetPath -notmatch [regex]::Escape('$AGENTS_HUB_ROOT') -and $targetPath -notmatch [regex]::Escape($normalizedCanonicalDir)) {
            $violations.Add("$($f.Name): target_path is not hub replay dir") | Out-Null
        }
    }
    if ($text -notmatch '(?m)^\|.*static / contract / runtime / user-visible / release / limitation.*\|') {
        $violations.Add("$($f.Name): evidence table missing evidence level contract") | Out-Null
    }
    if ($text -notmatch ([regex]::Escape($labelFeedback))) {
        $violations.Add("$($f.Name): Task Replay Lite missing feedback row") | Out-Null
    }
}

if ($violations.Count -gt 0) {
    foreach ($v in $violations) { Write-Output "REPLAY_VIOLATION: $v" }
    Write-Output 'REPLAY_STRUCTURE=fail'
    exit 1
}

Write-Output "REPLAY_STRUCTURE=ok checked=$checked skipped_legacy=$skipped"
exit 0
