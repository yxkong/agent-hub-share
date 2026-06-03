#!/usr/bin/env bash
# audit-doc-script-governance.sh — macOS/Linux 文档治理审计
# 用于检查项目中文档、SQL、脚本的命名、放置和备份规范
#
# Usage:
#   cd <repo-root>
#   bash audit-doc-script-governance.sh [--hub-root <path>] [<repo-root>]
#   AGENTS_HUB_ROOT=<path> bash audit-doc-script-governance.sh [<repo-root>]
#
# 输出各类违规列表，0 个硬违规时退出码为 0，有硬违规时退出码为 1

set -euo pipefail

REPO_ROOT="."
HUB_ROOT="${AGENTS_HUB_ROOT:-}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --hub-root) HUB_ROOT="${2:-}"; shift 2 ;;
    *) REPO_ROOT="$1"; shift ;;
  esac
done

cd "$REPO_ROOT"

# 未提供 HUB_ROOT 时，从脚本路径反推（scripts → doc-script-governance → share → skills → hub）
if [ -z "$HUB_ROOT" ]; then
  _SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
  _CANDIDATE="$(cd "$_SCRIPT_DIR/../../../.." 2>/dev/null && pwd)"
  [ -d "$_CANDIDATE/skills" ] && HUB_ROOT="$_CANDIDATE"
fi

SHARED_SKILL_ROOT=""
if [ -n "$HUB_ROOT" ] && [ -d "$HUB_ROOT/skills" ]; then
  SHARED_SKILL_ROOT="$HUB_ROOT/skills"
fi

declare -a NAMING_VIOLATIONS=()
declare -a PLACEMENT_WARNINGS=()
declare -a FORBIDDEN_PATH_VIOLATIONS=()
declare -a BACKUP_PLACEMENT_VIOLATIONS=()
declare -a ENCODING_WARNINGS=()
declare -a HISTORICAL_LINK_VIOLATIONS=()
declare -a LINE_ENDING_WARNINGS=()

TEXT_EXTS="md|sql|ps1|sh|json|yml|yaml|mdc"
BAD_NAME_REGEX='\b(copy|_final|_v2|_backup|\.old)\b'
USAGE_GUIDE_REGEX='(guide|manual|usage|howto|quickstart|使用说明|操作手册|接入指南|快速开始|运行指引)'

# ── 1. 命名违规：主文件含 copy/_final/_v2/_backup/old ──────────────────────────
while IFS= read -r -d '' f; do
  base=$(basename "$f")
  dir=$(dirname "$f")
  # 跳过 bak/ 目录下的文件（备份本身不检查命名）
  if [[ "$dir" == *"/bak"* || "$dir" == *"/bak" ]]; then continue; fi
  if echo "$base" | grep -qiE '(copy|_final|_v\d+|_backup|\.old)'; then
    NAMING_VIOLATIONS+=("$f")
  fi
done < <(find . \( -path './.git' -o -path './node_modules' -o -path './target' -o -path './dist' \) -prune -o \
  -type f \( -name "*.md" -o -name "*.sql" -o -name "*.sh" -o -name "*.ps1" -o -name "*.json" -o -name "*.yml" -o -name "*.yaml" \) -print0)

# 同时扫描 hub skills（若 HUB_ROOT 已配置）
if [ -n "$SHARED_SKILL_ROOT" ]; then
  while IFS= read -r -d '' f; do
    base=$(basename "$f")
    dir=$(dirname "$f")
    if [[ "$dir" == *"/bak"* || "$dir" == *"/bak" ]]; then continue; fi
    if echo "$base" | grep -qiE '(copy|_final|_v[0-9]+|_backup|\.old)'; then
      NAMING_VIOLATIONS+=("$f")
    fi
  done < <(find "$SHARED_SKILL_ROOT" -type f \
    \( -name "*.md" -o -name "*.sql" -o -name "*.sh" -o -name "*.ps1" -o -name "*.json" -o -name "*.yml" -o -name "*.yaml" \) -print0)
fi

# ── 2. 禁止路径：文档型文件进入 src/main/resources（运行时 init/migrate 除外）──
while IFS= read -r -d '' f; do
  base=$(basename "$f")
  # 运行时 init/migrate 排除
  if echo "$base" | grep -qiE '^(init|migrate|schema|flyway)'; then continue; fi
  if [[ "$f" == *"/src/main/resources/"* ]]; then
    FORBIDDEN_PATH_VIOLATIONS+=("$f")
  fi
done < <(find . \( -path './.git' -o -path './node_modules' -o -path './target' \) -prune -o \
  -type f \( -name "*.md" -o -name "*.sql" \) -print0)

# ── 3. 使用说明放置检查：guide 类文档应在 docs/guide/ ──────────────────────────
while IFS= read -r -d '' f; do
  base=$(basename "$f")
  dir=$(dirname "$f")
  if [[ "$dir" == *"/bak"* ]]; then continue; fi
  if echo "$base" | grep -qiE "$USAGE_GUIDE_REGEX"; then
    if [[ "$dir" != *"/docs/guide"* ]]; then
      PLACEMENT_WARNINGS+=("$f → 应在 docs/guide/")
    fi
  fi
done < <(find . \( -path './.git' -o -path './node_modules' -o -path './target' \) -prune -o \
  -type f -name "*.md" -print0)

# ── 4. 备份文件放置：bak/ 之外不应有 *.bak、.bak-时间戳、_backup、_V2 类文件 ──
while IFS= read -r -d '' f; do
  dir=$(dirname "$f")
  if [[ "$dir" == *"/bak"* ]]; then continue; fi
  base=$(basename "$f")
  if echo "$base" | grep -qiE '(\.(bak|backup)$|\.bak-[0-9]{8}-[0-9]{6}$|_backup\.|_v[0-9]+\.)'; then
    BACKUP_PLACEMENT_VIOLATIONS+=("$f → 应移入同级 bak/ 目录")
  fi
done < <(find . \( -path './.git' -o -path './node_modules' -o -path './target' \) -prune -o \
  -type f -print0)

# ── 5. 编码检查（UTF-8 BOM 检测）──────────────────────────────────────────────
while IFS= read -r -d '' f; do
  # BOM 是 EF BB BF
  if LC_ALL=C head -c 3 "$f" | grep -q $'\xef\xbb\xbf'; then
    ENCODING_WARNINGS+=("$f → 含 UTF-8 BOM，应去除")
  fi
done < <(find . \( -path './.git' -o -path './node_modules' -o -path './target' \) -prune -o \
  -type f \( -name "*.md" -o -name "*.sql" -o -name "*.sh" -o -name "*.json" -o -name "*.yml" -o -name "*.yaml" \) -print0)

# hub skills 编码检查（bak/ 跳过；BOM 与项目文件同等对待，属 hard gate）
if [ -n "$SHARED_SKILL_ROOT" ]; then
  while IFS= read -r -d '' f; do
    if [[ "$f" == *"/bak/"* || "$f" == *"/bak" ]]; then continue; fi
    if LC_ALL=C head -c 3 "$f" | grep -q $'\xef\xbb\xbf'; then
      ENCODING_WARNINGS+=("$f → 含 UTF-8 BOM，应去除")
    fi
  done < <(find "$SHARED_SKILL_ROOT" -type f \
    \( -name "*.md" -o -name "*.sql" -o -name "*.sh" -o -name "*.json" -o -name "*.yml" -o -name "*.yaml" \) -print0)
fi

# ── 6. 历史链接检查：md 不应引用 bak/ 路径或历史快照文件名 ───────────────────
while IFS= read -r -d '' f; do
  dir=$(dirname "$f")
  if [[ "$dir" == *"/bak"* ]]; then continue; fi
  # 提取 markdown 链接目标 [text](url)
  while IFS= read -r target; do
    [ -z "$target" ] && continue
    if echo "$target" | grep -qiE '(/bak/|[/\\]bak[/\\]|(copy|_final|_v[0-9]+|_backup|\.old)(\.|$)|-[0-9]{8}-[0-9]{6}\.)'; then
      HISTORICAL_LINK_VIOLATIONS+=("$f → $target")
    fi
  done < <(grep -oE '\[[^]]*\]\([^)]+\)' "$f" 2>/dev/null | sed 's/.*(\(.*\))/\1/' || true)
done < <(find . \( -path './.git' -o -path './node_modules' -o -path './target' -o -path './dist' \) -prune -o \
  -type f -name "*.md" -print0)

# hub skills 历史链接检查
if [ -n "$SHARED_SKILL_ROOT" ]; then
  while IFS= read -r -d '' f; do
    dir=$(dirname "$f")
    if [[ "$dir" == *"/bak"* ]]; then continue; fi
    while IFS= read -r target; do
      [ -z "$target" ] && continue
      if echo "$target" | grep -qiE '(/bak/|[/\\]bak[/\\]|(copy|_final|_v[0-9]+|_backup|\.old)(\.|$)|-[0-9]{8}-[0-9]{6}\.)'; then
        HISTORICAL_LINK_VIOLATIONS+=("$f → $target")
      fi
    done < <(grep -oE '\[[^]]*\]\([^)]+\)' "$f" 2>/dev/null | sed 's/.*(\(.*\))/\1/' || true)
  done < <(find "$SHARED_SKILL_ROOT" -type f -name "*.md" -print0)
fi

# ── 7. 行尾检查：检测 CRLF（警告，不影响 exit 码）──────────────────────────
while IFS= read -r -d '' f; do
  if LC_ALL=C grep -q $'\r' "$f" 2>/dev/null; then
    LINE_ENDING_WARNINGS+=("$f → 含 CRLF，建议统一为 LF")
  fi
done < <(find . \( -path './.git' -o -path './node_modules' -o -path './target' -o -path './dist' \) -prune -o \
  -type f \( -name "*.md" -o -name "*.sql" -o -name "*.sh" -o -name "*.json" -o -name "*.yml" -o -name "*.yaml" \) -print0)

# ── 报告 ───────────────────────────────────────────────────────────────────────
HARD_TOTAL=0
WARN_TOTAL=0

print_hard() {
  local title="$1"; shift
  local items=("$@")
  if [[ ${#items[@]} -gt 0 ]]; then
    echo ""
    echo "[$title] — ${#items[@]} 个"
    for item in "${items[@]}"; do
      echo "  ✗ $item"
    done
    HARD_TOTAL=$((HARD_TOTAL + ${#items[@]}))
  fi
}

print_warn() {
  local title="$1"; shift
  local items=("$@")
  if [[ ${#items[@]} -gt 0 ]]; then
    echo ""
    echo "[$title] — ${#items[@]} 个 (警告)"
    for item in "${items[@]}"; do
      echo "  ⚠ $item"
    done
    WARN_TOTAL=$((WARN_TOTAL + ${#items[@]}))
  fi
}

echo "=== doc-script-governance 审计报告 ==="
echo "扫描目录: $(pwd)"
if [ -n "$SHARED_SKILL_ROOT" ]; then
  echo "hub 技能目录: $SHARED_SKILL_ROOT"
else
  echo "hub 技能目录: 未配置（仅审计项目目录）"
fi
echo "时间: $(date)"

print_hard "NamingViolations（命名违规）"              "${NAMING_VIOLATIONS[@]+"${NAMING_VIOLATIONS[@]}"}"
print_hard "HistoricalLinkViolations（历史链接引用）"  "${HISTORICAL_LINK_VIOLATIONS[@]+"${HISTORICAL_LINK_VIOLATIONS[@]}"}"
print_hard "ForbiddenPathViolations（禁止路径）"       "${FORBIDDEN_PATH_VIOLATIONS[@]+"${FORBIDDEN_PATH_VIOLATIONS[@]}"}"
print_warn "UsageGuidePlacementViolations（使用说明放置）" "${PLACEMENT_WARNINGS[@]+"${PLACEMENT_WARNINGS[@]}"}"
print_hard "EncodingViolations（编码违规）"            "${ENCODING_WARNINGS[@]+"${ENCODING_WARNINGS[@]}"}"
print_hard "BackupPlacementViolations（备份放置违规）" "${BACKUP_PLACEMENT_VIOLATIONS[@]+"${BACKUP_PLACEMENT_VIOLATIONS[@]}"}"
print_warn "LineEndingWarnings（行尾建议）"            "${LINE_ENDING_WARNINGS[@]+"${LINE_ENDING_WARNINGS[@]}"}"

echo ""
if [[ $HARD_TOTAL -eq 0 ]]; then
  echo "Result: PASS (no hard violations found)."
  exit 0
else
  echo "Result: NEEDS_FIX (found $HARD_TOTAL hard violation(s))."
  exit 1
fi
