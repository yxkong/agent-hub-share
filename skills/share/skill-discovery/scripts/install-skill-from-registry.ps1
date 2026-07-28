<#
.SYNOPSIS
    从 skills.sh / GitHub 下载技能并安装到 hub

.DESCRIPTION
    从 GitHub 下载 SKILL.md + references/，存入 vendors/ 后运行验证，通过后复制到 skills/share 或 skills/projects/<key>。
    check-skill-structure / check-skill-size 使用与各脚本一致的参数；vendor 阶段跳过 check-skill-links（面向工作区 symlink）；
    对 SKILL.md 做与 check-skill-entrypoints 一致的前置校验。
    外部技能默认 nonempty 行上限 512，可用环境变量 INSTALL_SKILL_REGISTRY_MAX_LINES 覆盖。

.PARAMETER OwnerRepo
    必填。格式 <owner>/<repo>，例如 obra/superpowers

.PARAMETER SkillSubpath
    可选。技能在 repo 中的相对路径，例如 systematic-debugging

.PARAMETER HubRoot
    hub 根目录；默认从 $env:AGENTS_HUB_ROOT 或脚本路径推导

.PARAMETER Scope
    安装目标：share（默认）或 project

.PARAMETER Project
    Scope=project 时必填的 project-key

.PARAMETER Branch
    GitHub 分支；默认依次尝试 main、master

.PARAMETER DryRun
    仅下载到 vendors/ 并校验，不移入 skills/

.EXAMPLE
    .\install-skill-from-registry.ps1 obra/superpowers systematic-debugging
    .\install-skill-from-registry.ps1 anthropics/skills webapp-testing -Scope share
#>
param(
    [Parameter(Mandatory)][string]$OwnerRepo,
    [string]$SkillSubpath = '',
    [string]$HubRoot      = '',
    [ValidateSet('share','project')]
    [string]$Scope        = 'share',
    [string]$Project      = '',
    [string]$Branch       = '',
    [switch]$DryRun
)
$ErrorActionPreference = 'Stop'

$sizeMax = if ($env:INSTALL_SKILL_REGISTRY_MAX_LINES) { [int]$env:INSTALL_SKILL_REGISTRY_MAX_LINES } else { 512 }

if (-not $HubRoot) {
    $HubRoot = if ($env:AGENTS_HUB_ROOT) { $env:AGENTS_HUB_ROOT } `
               else { [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\..\..')) }
}

$parts    = $OwnerRepo -split '/'
$owner    = $parts[0]; $repo = $parts[1]
$skillName = if ($SkillSubpath) { Split-Path $SkillSubpath -Leaf } else { $repo }
$safeName  = "$owner--$repo--$skillName"
$vendorDir = Join-Path $HubRoot "vendors\$safeName"

$ghApi = "https://api.github.com/repos/$owner/$repo/contents"
$headers = @{ Accept = 'application/vnd.github.v3+json' }

function Fetch-JsonRaw([string]$url) {
    try {
        (Invoke-WebRequest -Uri $url -Headers $headers -UseBasicParsing -TimeoutSec 15).Content
    } catch {
        $null
    }
}

function Fetch-Json([string]$url) {
    $raw = Fetch-JsonRaw $url
    if (-not $raw) { return $null }
    $raw | ConvertFrom-Json
}

function Find-SkillMd([string]$tryBranch, [string]$subpathHint) {
    $candidates = @($subpathHint, "skills/$skillName", $skillName, '')
    foreach ($p in $candidates) {
        $url = if ($p) { "$ghApi/$p/SKILL.md?ref=$tryBranch" } else { "$ghApi/SKILL.md?ref=$tryBranch" }
        $r = Fetch-Json $url
        if ($r -and $r.PSObject.Properties['download_url'] -and $r.download_url) { return $p }
    }
    return $null
}

Write-Host "→ 从 GitHub 查找技能：$OwnerRepo"

if (-not $Branch) {
    foreach ($b in @('main','master')) {
        $found = Find-SkillMd $b $SkillSubpath
        if ($null -ne $found) { $Branch = $b; $SkillSubpath = $found; break }
    }
    if (-not $Branch) { Write-Error "✗ 未找到 SKILL.md。请检查 owner/repo 和 skill-subpath。"; exit 1 }
} else {
    $found = Find-SkillMd $Branch $SkillSubpath
    if ($null -eq $found) { Write-Error "✗ 在分支 $Branch 未找到 SKILL.md"; exit 1 }
    $SkillSubpath = $found
}

$apiBase = if ($SkillSubpath) { "$ghApi/$SkillSubpath" } else { $ghApi }
Write-Host "✓ 找到技能：branch=$Branch path=$(if ($SkillSubpath) { $SkillSubpath } else { '<root>' })"

New-Item -ItemType Directory -Path (Join-Path $vendorDir 'references') -Force | Out-Null

function Download-File([string]$url, [string]$dest) {
    $dir = Split-Path $dest -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    Invoke-WebRequest -Uri $url -OutFile $dest -UseBasicParsing -TimeoutSec 30
}

function Download-GhDir([string]$contentPrefix, [string]$destDir) {
    New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    $url = if ($contentPrefix) { "$ghApi/$contentPrefix`?ref=$Branch" } else { "$ghApi`?ref=$Branch" }
    $items = Fetch-Json $url
    if (-not $items) { return }
    if ($items -isnot [array]) { $items = @($items) }
    foreach ($item in $items) {
        if ($item.type -eq 'file') {
            Download-File $item.download_url (Join-Path $destDir $item.name)
        } elseif ($item.type -eq 'dir') {
            $nextPrefix = if ($contentPrefix) { "$contentPrefix/$($item.name)" } else { $item.name }
            Download-GhDir $nextPrefix (Join-Path $destDir $item.name)
        }
    }
}

Write-Host "→ 下载到 vendors/$safeName/ ..."
$skillMdMeta = Fetch-Json "$apiBase/SKILL.md?ref=$Branch"
if (-not $skillMdMeta.download_url) { Write-Error '无法解析 SKILL.md download_url'; exit 1 }
Download-File $skillMdMeta.download_url (Join-Path $vendorDir 'SKILL.md')
Write-Host "  ✓ SKILL.md"

$refPrefix = if ($SkillSubpath) { "$SkillSubpath/references" } else { 'references' }
$refRaw = Fetch-JsonRaw "$ghApi/$refPrefix`?ref=$Branch"
if ($refRaw) {
    try {
        $refItems = $refRaw | ConvertFrom-Json
        $list = if ($refItems -is [array]) { $refItems } else { @($refItems) }
        if ($list.Count -gt 0) {
            Download-GhDir $refPrefix (Join-Path $vendorDir 'references')
            Write-Host "  ✓ references/"
        }
    } catch { }
}
Write-Host "✓ 下载完成：$vendorDir"

function Test-VendorSkillEntrypoint([string]$file) {
    $lines = Get-Content -LiteralPath $file
    if (-not $lines -or $lines[0] -ne '---') { return $false }
    $closing = -1
    for ($i = 1; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -eq '---') { $closing = $i; break }
    }
    if ($closing -lt 0) { return $false }
    $fm = $lines[1..($closing - 1)] -join "`n"
    if ($fm -notmatch '(?m)^name:\s+\S') { return $false }
    if ($fm -notmatch '(?m)^description:\s+\S') { return $false }
    return $true
}

Write-Host "`n→ 运行验收检查 ..."
$allPass = $true

$structurePs1 = Join-Path $HubRoot 'scripts\check-skill-structure.ps1'
if (Test-Path $structurePs1) {
    try {
        & $structurePs1 -SkillRoot $vendorDir 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) { throw 'fail' }
        Write-Host '  ✓ structure'
    } catch {
        Write-Host '  ✗ structure'
        $allPass = $false
    }
} else {
    Write-Host '  ⚠ structure（脚本不存在，跳过）'
}

$sizePs1 = Join-Path $HubRoot 'scripts\check-skill-size.ps1'
if (Test-Path $sizePs1) {
    try {
        & $sizePs1 -File (Join-Path $vendorDir 'SKILL.md') -Max $sizeMax 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) { throw 'fail' }
        Write-Host '  ✓ size'
    } catch {
        Write-Host '  ✗ size'
        $allPass = $false
    }
} else {
    Write-Host '  ⚠ size（脚本不存在，跳过）'
}

Write-Host '  ⚠ links（vendor 阶段跳过：check-skill-links 校验工作区 symlink）'

$skillMdPath = Join-Path $vendorDir 'SKILL.md'
if (Test-VendorSkillEntrypoint $skillMdPath) {
    Write-Host '  ✓ entrypoints (SKILL.md front matter)'
} else {
    Write-Host '  ✗ entrypoints (SKILL.md front matter)'
    $allPass = $false
}

if (-not $allPass) {
    Write-Host "`n✗ 验收未通过。技能留在 $vendorDir，请手动修复后再移入 skills/。"
    exit 1
}
Write-Host '✓ 全部检查通过'

if ($DryRun) {
    Write-Host "`n✓ --dry-run 完成。技能在 $vendorDir，未移入 skills/。"
    exit 0
}

if ($Scope -eq 'project') {
    if (-not $Project) { Write-Error "-Scope project 需要 -Project <key>"; exit 1 }
    $dest = Join-Path $HubRoot "skills\projects\$Project\$skillName"
} else {
    $dest = Join-Path $HubRoot "skills\share\$skillName"
}

if (Test-Path $dest) { Write-Error "✗ 目标已存在：$dest。请先删除或重命名再重试。"; exit 1 }
$destParent = Split-Path $dest -Parent
if (-not (Test-Path $destParent)) { New-Item -ItemType Directory -Path $destParent -Force | Out-Null }
Copy-Item -Recurse $vendorDir $dest
$rel = $dest.Substring($HubRoot.Length).TrimStart('\','/')
Write-Host "`n✓ 已安装到：$rel"
Write-Host "`n下一步建议："
Write-Host "  1. 编辑 SKILL.md，把硬编码路径改为 `$AGENTS_HUB_ROOT 相对引用"
Write-Host "  2. 运行 hub 挂载脚本（agent-hub-bootstrap）将技能同步到客户端目录"
Write-Host "  3. 在 skill-discovery 的 find-skills 输出中确认可见"
