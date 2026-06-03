#Requires -Version 5.1
# backup-file.ps1 — Windows 文档双份备份
# 改任何主文件前必须先调用本脚本
#
# Usage:
#   & backup-file.ps1 -FilePath <文件绝对路径>
#
# 输出：
#   1. <同级目录>\bak\_<原文件名>        — 即时备份（覆盖最近一次）
#   2. <同级目录>\bak\yyyyMM\<安全目录名>\<名>-yyyyMMdd-HHmmss.ext — 历史归档
#      安全目录名：原文件名中的 "." 换为 "_"（如 SKILL.md → SKILL_md），避免与技能入口冲突

param(
  [Parameter(Mandatory = $true)]
  [string]$FilePath
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $FilePath -PathType Leaf)) {
  Write-Error "File not found: $FilePath"
  exit 1
}

$dir       = Split-Path $FilePath -Parent
$filename  = Split-Path $FilePath -Leaf
$stem      = [System.IO.Path]::GetFileNameWithoutExtension($filename)
$ext       = [System.IO.Path]::GetExtension($filename)
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$month     = Get-Date -Format "yyyyMM"

# 历史归档子目录：将 "." 换为 "_"，避免目录名为 SKILL.md 等与技能入口冲突
$archiveSeg = ($filename -replace '\.', '_')

$bakDir  = Join-Path $dir 'bak'
$histDir = Join-Path (Join-Path $bakDir $month) $archiveSeg

# Step 1: 即时备份（直接覆盖）
New-Item -ItemType Directory -Force -Path $bakDir | Out-Null
Copy-Item $FilePath -Destination (Join-Path $bakDir "_$filename") -Force

# Step 2: 历史归档（追加）
New-Item -ItemType Directory -Force -Path $histDir | Out-Null
$archiveName = "$stem-$timestamp$ext"
Copy-Item $FilePath -Destination (Join-Path $histDir $archiveName) -Force

Write-Host "✓ 备份完成: $FilePath"
Write-Host "  即时备份: $(Join-Path $bakDir "_$filename")"
Write-Host "  历史归档: $(Join-Path $histDir $archiveName)"
