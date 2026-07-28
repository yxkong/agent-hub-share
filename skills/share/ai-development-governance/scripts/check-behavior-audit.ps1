[CmdletBinding()]
param(
    [string]$HubRoot = '',
    [string[]]$SkillNames = @()
)

$ErrorActionPreference = 'Stop'
$selfSkillRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$resolvedHub = if ($HubRoot) {
    [System.IO.Path]::GetFullPath($HubRoot)
}
else {
    ''
}
$names = if ($SkillNames.Count -gt 0) {
    @($SkillNames)
}
elseif ($resolvedHub) {
    @(
        'delivery-workflow',
        'ai-development-governance',
        'skill-engineering',
        'tdd-workflow',
        'webapp-testing'
    )
}
else {
    @('ai-development-governance')
}

$failed = 0
$checked = 0
$required = @('## 偏航信号', '## 反证问题', '## 闭环证据', '## 回灌动作')
$auditPaths = @{
    'ai-development-governance' = 'references\governance\behavior_audit.md'
}

foreach ($name in $names) {
    $auditRel = if ($auditPaths.ContainsKey($name)) {
        $auditPaths[$name]
    }
    else {
        'references\behavior_audit.md'
    }
    if ($resolvedHub) {
        $skillRoot = Join-Path $resolvedHub "skills\share\$name"
    }
    elseif ($name -eq 'ai-development-governance') {
        $skillRoot = $selfSkillRoot
    }
    else {
        Write-Output ("BEHAVIOR_AUDIT_MISSING_CONTEXT={0}" -f $name)
        $failed++
        continue
    }
    $file = Join-Path $skillRoot $auditRel
    $checked++
    if (-not (Test-Path -LiteralPath $file -PathType Leaf)) {
        Write-Output ("BEHAVIOR_AUDIT_MISSING={0}" -f $file)
        $failed++
        continue
    }
    $text = [System.IO.File]::ReadAllText($file)
    $fileFailed = $false
    foreach ($heading in $required) {
        if ($text -notmatch [regex]::Escape($heading)) {
            Write-Output ("BEHAVIOR_AUDIT_HEADING_MISSING={0} heading={1}" -f $file, $heading)
            $failed++
            $fileFailed = $true
        }
    }
    if (-not $fileFailed) {
        Write-Output ("ok -> {0}" -f $file)
    }
}

if ($failed -gt 0) {
    Write-Output ("BEHAVIOR_AUDIT_CHECK=fail failed={0}" -f $failed)
    exit 1
}

Write-Output ("BEHAVIOR_AUDIT_CHECK=ok checked={0}" -f $checked)
