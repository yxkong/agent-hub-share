[CmdletBinding()]
param(
    [string]$HubRoot = ''
)

$ErrorActionPreference = 'Stop'
$__hubScripts = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\..\..\scripts'))
. (Join-Path $__hubScripts 'agent-hub-paths.ps1')

$agentsRoot = Resolve-AgentHubRoot -HubRoot $HubRoot -ScriptRoot $__hubScripts
$promptsRoot = Join-Path $agentsRoot 'prompts'
$count = 0

function Get-PromptMarkdownBodyViolations {
    param([Parameter(Mandatory = $true)][string]$FilePath)

    function Join-Chars {
        param([int[]]$Codes)
        $sbChars = New-Object System.Text.StringBuilder
        foreach ($code in $Codes) {
            [void]$sbChars.Append([char]$code)
        }
        return $sbChars.ToString()
    }

    $out = New-Object System.Collections.Generic.List[string]
    $text = Get-Content -LiteralPath $FilePath -Raw -Encoding UTF8 -ErrorAction Stop
    $body = $text
    if ($text -match '(?ms)^---\s*\r?\n.*?\r?\n---\s*\r?\n') {
        $body = $text.Substring($Matches[0].Length)
    }
    $lines = $body -split '\r?\n'
    $headingContext = '## ' + (Join-Chars @(0x9002, 0x7528, 0x573A, 0x666F))
    $headingInput = '## ' + (Join-Chars @(0x8F93, 0x5165, 0x8981, 0x6C42))
    $headingPrompt = '## Prompt ' + (Join-Chars @(0x6B63, 0x6587))
    $headingAcceptance = '## ' + (Join-Chars @(0x9A8C, 0x6536, 0x6807, 0x51C6))
    $required = @($headingContext, $headingInput, $headingPrompt, $headingAcceptance)
    $last = -1
    foreach ($h in $required) {
        $positions = New-Object System.Collections.Generic.List[int]
        for ($j = 0; $j -lt $lines.Count; $j++) {
            if ($lines[$j].Trim() -eq $h) {
                $positions.Add($j) | Out-Null
            }
        }
        if ($positions.Count -eq 0) {
            $out.Add("missing heading: $h") | Out-Null
        }
        elseif ($positions.Count -ne 1) {
            $out.Add("heading must appear exactly once: $h") | Out-Null
        }
        else {
            $pos = $positions[0]
            if ($pos -le $last) {
                $out.Add('headings out of order: required sequence is context, input, prompt body, acceptance') | Out-Null
            }
            $last = $pos
        }
    }

    $pp = -1
    $aa = -1
    for ($j = 0; $j -lt $lines.Count; $j++) {
        $t = $lines[$j].Trim()
        if ($t -eq $headingPrompt) {
            $pp = $j
        }
        if ($t -eq $headingAcceptance) {
            $aa = $j
        }
    }
    if ($pp -ge 0) {
        $sb = New-Object System.Text.StringBuilder
        for ($j = $pp + 1; $j -lt $lines.Count; $j++) {
            $raw = $lines[$j]
            $trim = $raw.Trim()
            if ($trim.StartsWith('## ')) {
                break
            }
            [void]$sb.AppendLine($raw)
        }
        $pb = $sb.ToString().Trim()
        if ($pb.Length -eq 0) {
            $out.Add('prompt body section must not be empty') | Out-Null
        }
    }
    if ($aa -ge 0) {
        $sb2 = New-Object System.Text.StringBuilder
        for ($j = $aa + 1; $j -lt $lines.Count; $j++) {
            $raw = $lines[$j]
            $trim = $raw.Trim()
            if ($trim.StartsWith('## ')) {
                break
            }
            [void]$sb2.AppendLine($raw)
        }
        $ac = $sb2.ToString().Trim()
        if ($ac.Length -eq 0) {
            $out.Add('acceptance section must not be empty') | Out-Null
        }
    }
    return $out
}

function Add-PromptViolation {
    param([string]$Path, [string]$Reason)
    Write-Output ("PROMPT_CHECK_VIOLATION={0} reason={1}" -f $Path, $Reason)
    $script:count++
}

function Get-FmValueFromFile {
    param([string]$FilePath, [string]$Key)
    $text = Get-Content -LiteralPath $FilePath -Raw -Encoding UTF8 -ErrorAction Stop
    if ($text -notmatch '(?ms)^---\s*\r?\n(.*?)\r?\n---') {
        return ''
    }
    $block = $Matches[1]
    foreach ($line in $block -split '\r?\n') {
        if ($line -match ('^' + [regex]::Escape($Key) + ':\s*(.*)$')) {
            $v = $Matches[1].Trim().Trim('"').Trim("'")
            if ($v -eq '' -or $v -eq "''") {
                return ''
            }
            return $v
        }
    }
    return ''
}

$ids = New-Object System.Collections.Generic.List[string]
$deprecatedRbPairs = New-Object System.Collections.Generic.List[object]

foreach ($subName in @('share', 'projects')) {
    $sub = Join-Path $promptsRoot $subName
    if (-not (Test-Path -LiteralPath $sub -PathType Container)) {
        continue
    }
    Get-ChildItem -LiteralPath $sub -Recurse -File -Filter '*.prompt.md' -ErrorAction SilentlyContinue | ForEach-Object {
        if ($_.FullName -match '[\\/]bak[\\/]') {
            return
        }
        $f = $_.FullName
        $id = Get-FmValueFromFile -FilePath $f -Key 'id'
        $sc = Get-FmValueFromFile -FilePath $f -Key 'scope'
        $pj = Get-FmValueFromFile -FilePath $f -Key 'project'
        $ty = Get-FmValueFromFile -FilePath $f -Key 'type'
        $ow = Get-FmValueFromFile -FilePath $f -Key 'owner_skill'
        $st = Get-FmValueFromFile -FilePath $f -Key 'status'
        $rb = Get-FmValueFromFile -FilePath $f -Key 'replaced_by'

        if (-not $id) {
            Add-PromptViolation -Path $f -Reason 'front matter missing id'
        }
        if (-not $sc) {
            Add-PromptViolation -Path $f -Reason 'front matter missing scope'
        }
        elseif ($sc -ne 'share' -and $sc -ne 'project') {
            Add-PromptViolation -Path $f -Reason ("invalid scope: {0}; expected share|project" -f $sc)
        }

        if (-not $ty) {
            Add-PromptViolation -Path $f -Reason 'front matter missing type'
        }
        if (-not $ow) {
            Add-PromptViolation -Path $f -Reason 'front matter missing owner_skill'
        }
        if (-not $st) {
            Add-PromptViolation -Path $f -Reason 'front matter missing status'
        }
        elseif ($st -ne 'active' -and $st -ne 'deprecated') {
            Add-PromptViolation -Path $f -Reason ("invalid status: {0}; expected active|deprecated" -f $st)
        }

        if ($sc -eq 'project' -and -not $pj) {
            Add-PromptViolation -Path $f -Reason 'scope=project requires project'
        }
        if ($sc -eq 'share' -and $pj) {
            Add-PromptViolation -Path $f -Reason 'scope=share requires empty project'
        }

        if ($st -eq 'active' -and $rb) {
            Add-PromptViolation -Path $f -Reason 'status=active must not set replaced_by'
        }
        if ($st -eq 'deprecated' -and -not $rb) {
            Add-PromptViolation -Path $f -Reason 'status=deprecated requires replaced_by'
        }
        if ($st -eq 'deprecated' -and $rb -and $id -and ($rb -eq $id)) {
            Add-PromptViolation -Path $f -Reason 'replaced_by must not equal current id'
        }

        $fullText = Get-Content -LiteralPath $f -Raw -Encoding UTF8
        if ($fullText -match '\bTODO\b') {
            Add-PromptViolation -Path $f -Reason 'content contains TODO'
        }
        if ($fullText -match '(?i)(api_key|apikey|client_secret|secret_key|password\s*=\s*\S+|Bearer\s+[A-Za-z0-9_-]{24,})') {
            Add-PromptViolation -Path $f -Reason 'possible secret token pattern'
        }

        foreach ($reason in Get-PromptMarkdownBodyViolations -FilePath $f) {
            Add-PromptViolation -Path $f -Reason $reason
        }

        if ($id) {
            $ids.Add(("{0}`t{1}`t{2}" -f $id, $f, $st)) | Out-Null
        }
        if ($st -eq 'deprecated' -and $rb) {
            $deprecatedRbPairs.Add(@($f, $rb)) | Out-Null
        }
    }
}

if ($ids.Count -gt 0) {
    $dupIds = $ids | ForEach-Object { ($_ -split "`t", 2)[0] } | Group-Object | Where-Object { $_.Count -gt 1 }
    foreach ($g in $dupIds) {
        $paths = ($ids | Where-Object { ($_ -split "`t", 2)[0] -eq $g.Name } | ForEach-Object { ($_ -split "`t", 2)[1] }) -join ' '
        Add-PromptViolation -Path ("id={0}" -f $g.Name) -Reason ("duplicate id: {0}" -f $paths)
    }
}

$idSet = @{}  # id -> status
foreach ($line in $ids) {
    $parts = $line -split "`t", 3
    $onlyId = $parts[0]
    $idStatus = if ($parts.Count -ge 3) { $parts[2] } else { '' }
    $idSet[$onlyId] = $idStatus
}
foreach ($pair in $deprecatedRbPairs) {
    $fp = $pair[0]
    $target = $pair[1]
    if (-not $idSet.ContainsKey($target)) {
        Add-PromptViolation -Path $fp -Reason ("replaced_by target id does not exist: {0}" -f $target)
    } elseif ($idSet[$target] -ne 'active') {
        Add-PromptViolation -Path $fp -Reason ("replaced_by target status is not active: {0}; target={1}" -f $idSet[$target], $target)
    }
}

if ($count -eq 0) {
    Write-Output 'PROMPTS_CHECK=ok'
    exit 0
}

Write-Output ("PROMPTS_CHECK=fail count={0}" -f $count)
exit 1
