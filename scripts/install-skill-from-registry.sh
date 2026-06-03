#!/usr/bin/env bash
# install-skill-from-registry.sh — 从 skills.sh / GitHub 下载技能并安装到 hub
#
# Usage:
#   install-skill-from-registry.sh <owner/repo> [<skill-subpath>] [OPTIONS]
#
# 示例：
#   install-skill-from-registry.sh obra/superpowers systematic-debugging
#   install-skill-from-registry.sh anthropics/skills webapp-testing --scope share
#   install-skill-from-registry.sh vercel-labs/skills find-skills --dry-run
#
# OPTIONS:
#   --hub-root <path>     hub 根目录（默认 $AGENTS_HUB_ROOT 或脚本推导）
#   --scope share|project 安装到 skills/share 或 skills/projects/<key>（默认 share）
#   --project <key>       scope=project 时指定 project-key
#   --branch <branch>     GitHub 分支（默认尝试 main 再尝试 master）
#   --dry-run             仅下载到 vendors/ 并校验，不移入 skills/
#
# 流程：
#   1. 从 GitHub API 获取目录结构，找到 SKILL.md
#   2. 下载 SKILL.md + references/ 到 vendors/<safe-name>/
#   3. 运行 check-skill-structure / check-skill-size；vendor 阶段跳过 check-skill-links（面向工作区 symlink）；
#      对单个 SKILL.md 做与 check-skill-entrypoints 一致的前置校验
#   4. 全部通过且非 --dry-run：复制到 skills/<scope>/<skill-name>/
#   5. 打印结果摘要
#
# 外部技能行数：默认 --max 512（可通过环境变量 INSTALL_SKILL_REGISTRY_MAX_LINES 覆盖）

set -euo pipefail

OWNER_REPO=""
SKILL_SUBPATH=""
HUB_ROOT="${AGENTS_HUB_ROOT:-}"
SCOPE="share"
PROJECT_KEY=""
BRANCH=""
DRY_RUN=0
SIZE_MAX="${INSTALL_SKILL_REGISTRY_MAX_LINES:-512}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --hub-root)  HUB_ROOT="${2:-}";    shift 2 ;;
    --scope)     SCOPE="${2:-share}";  shift 2 ;;
    --project)   PROJECT_KEY="${2:-}"; shift 2 ;;
    --branch)    BRANCH="${2:-}";      shift 2 ;;
    --dry-run)   DRY_RUN=1;            shift ;;
    -*)          echo "unknown option: $1" >&2; exit 1 ;;
    *)
      if [ -z "$OWNER_REPO" ]; then
        OWNER_REPO="$1"
      elif [ -z "$SKILL_SUBPATH" ]; then
        SKILL_SUBPATH="$1"
      fi
      shift ;;
  esac
done

if [ -z "$OWNER_REPO" ]; then
  echo "Usage: $0 <owner/repo> [<skill-subpath>] [--scope share|project] [--project <key>] [--dry-run]" >&2
  exit 1
fi

# 推导 hub root
if [ -z "$HUB_ROOT" ]; then
  _SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
  HUB_ROOT="$(cd "$_SCRIPT_DIR/.." 2>/dev/null && pwd)"
fi

OWNER=$(echo "$OWNER_REPO" | cut -d/ -f1)
REPO=$(echo "$OWNER_REPO" | cut -d/ -f2)

# 确定技能名（取 SKILL_SUBPATH 最后一段，或 repo 名）
if [ -n "$SKILL_SUBPATH" ]; then
  SKILL_NAME=$(basename "$SKILL_SUBPATH")
else
  SKILL_NAME="$REPO"
fi

SAFE_NAME="${OWNER}--${REPO}--${SKILL_NAME}"
VENDOR_DIR="$HUB_ROOT/vendors/$SAFE_NAME"

# ── 步骤 1：从 GitHub API 获取文件列表 ──────────────────────────────────────
GH_API="https://api.github.com/repos/${OWNER}/${REPO}/contents"

fetch_json() {
  local url="$1"
  curl -fsSL --connect-timeout 10 \
    -H "Accept: application/vnd.github.v3+json" \
    "$url"
}

find_skill_md() {
  local try_branch="$1"
  local try_path="${SKILL_SUBPATH:-}"

  local paths=("$try_path" "skills/$SKILL_NAME" "$SKILL_NAME" "")
  local p url resp dl
  for p in "${paths[@]}"; do
    if [ -n "$p" ]; then
      url="${GH_API}/${p}/SKILL.md?ref=${try_branch}"
    else
      url="${GH_API}/SKILL.md?ref=${try_branch}"
    fi
    resp=$(fetch_json "$url" 2>/dev/null) || continue
    dl=$(echo "$resp" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('download_url') or '')" 2>/dev/null) || continue
    case "$dl" in http*) echo "$p"; return 0 ;; esac
  done
  return 1
}

echo "→ 从 GitHub 查找技能：${OWNER}/${REPO}"

if [ -z "$BRANCH" ]; then
  found_path=""
  for try_branch in main master; do
    if found_path=$(find_skill_md "$try_branch" 2>/dev/null); then
      BRANCH="$try_branch"
      SKILL_SUBPATH="$found_path"
      break
    fi
  done
  if [ -z "${BRANCH:-}" ]; then
    echo "✗ 未找到 SKILL.md。请检查 owner/repo 和 skill-subpath。" >&2
    exit 1
  fi
else
  found_path=$(find_skill_md "$BRANCH") || {
    echo "✗ 在分支 $BRANCH 未找到 SKILL.md" >&2
    exit 1
  }
  SKILL_SUBPATH="$found_path"
fi

SKILL_API_BASE="${GH_API}"
if [ -n "$SKILL_SUBPATH" ]; then
  SKILL_API_BASE="${GH_API}/${SKILL_SUBPATH}"
fi

echo "✓ 找到技能：branch=$BRANCH path=${SKILL_SUBPATH:-<root>}"

# ── 步骤 2：下载到 vendors/ ──────────────────────────────────────────────────
mkdir -p "$VENDOR_DIR/references"

download_file() {
  local download_url="$1"
  local dest="$2"
  mkdir -p "$(dirname "$dest")"
  curl -fsSL --connect-timeout 15 "$download_url" -o "$dest"
}

# content_prefix: GitHub contents API 路径（repo 根起的相对路径，不含前导 /）
download_github_dir() {
  local content_prefix="$1"
  local dest_dir="$2"
  mkdir -p "$dest_dir"

  local url
  if [ -n "$content_prefix" ]; then
    url="${GH_API}/${content_prefix}?ref=${BRANCH}"
  else
    url="${GH_API}?ref=${BRANCH}"
  fi

  local listing
  listing=$(fetch_json "$url") || return 1

  local ftype fname fdownload_url
  while IFS=$'\t' read -r ftype fname fdownload_url; do
    [ -n "$ftype" ] || continue
    case "$ftype" in
      file) download_file "$fdownload_url" "$dest_dir/$fname" ;;
      dir)
        if [ -n "$content_prefix" ]; then
          download_github_dir "${content_prefix}/${fname}" "$dest_dir/$fname"
        else
          download_github_dir "${fname}" "$dest_dir/$fname"
        fi
        ;;
    esac
  done < <(echo "$listing" | python3 -c "
import json, sys
items = json.load(sys.stdin)
if isinstance(items, dict): items = [items]
for item in items:
    print(item.get('type',''), item.get('name',''), item.get('download_url') or '', sep='\t')
")
}

echo "→ 下载到 vendors/$SAFE_NAME/ ..."

SKILL_MD_URL="${GH_API}"
[ -n "$SKILL_SUBPATH" ] && SKILL_MD_URL="${GH_API}/${SKILL_SUBPATH}"
SKILL_MD_DOWNLOAD=$(fetch_json "${SKILL_MD_URL}/SKILL.md?ref=${BRANCH}" | python3 -c "import json,sys; print(json.load(sys.stdin)['download_url'])")
download_file "$SKILL_MD_DOWNLOAD" "$VENDOR_DIR/SKILL.md"
echo "  ✓ SKILL.md"

REF_PREFIX="references"
[ -n "$SKILL_SUBPATH" ] && REF_PREFIX="${SKILL_SUBPATH}/references"
if ref_listing=$(fetch_json "${GH_API}/${REF_PREFIX}?ref=${BRANCH}" 2>/dev/null); then
  if echo "$ref_listing" | python3 -c "import json,sys; j=json.load(sys.stdin); sys.exit(0 if isinstance(j,list) else 1)" 2>/dev/null; then
    download_github_dir "$REF_PREFIX" "$VENDOR_DIR/references"
    echo "  ✓ references/"
  fi
fi

echo "✓ 下载完成：$VENDOR_DIR"

# ── 步骤 3：验证 ─────────────────────────────────────────────────────────────
SCRIPTS_DIR="$HUB_ROOT/scripts"
PASS=1

run_check_exit() {
  local label="$1"
  shift
  if "$@"; then
    echo "  ✓ $label"
  else
    echo "  ✗ $label"
    PASS=0
  fi
}

# 与 check-skill-entrypoints 对齐：仅校验本目录 SKILL.md 前置元数据
check_vendor_skill_entrypoint() {
  local file="$VENDOR_DIR/SKILL.md"
  local first closing_line
  first=$(sed -n '1p' "$file")
  [ "$first" = '---' ] || return 1
  closing_line=$(awk 'NR > 1 && $0 == "---" { print NR; exit }' "$file")
  [ -n "$closing_line" ] || return 1
  sed -n "2,$((closing_line - 1))p" "$file" | grep -Eq '^name:[[:space:]]*[^[:space:]]+' || return 1
  sed -n "2,$((closing_line - 1))p" "$file" | grep -Eq '^description:[[:space:]]*[^[:space:]]+' || return 1
  return 0
}

echo ""
echo "→ 运行验收检查 ..."
if [ -f "$SCRIPTS_DIR/check-skill-structure.sh" ]; then
  run_check_exit "structure" bash "$SCRIPTS_DIR/check-skill-structure.sh" --skill-root "$VENDOR_DIR"
else
  echo "  ⚠ structure（脚本不存在，跳过）"
fi

if [ -f "$SCRIPTS_DIR/check-skill-size.sh" ]; then
  run_check_exit "size" bash "$SCRIPTS_DIR/check-skill-size.sh" --file "$VENDOR_DIR/SKILL.md" --max "$SIZE_MAX"
else
  echo "  ⚠ size（脚本不存在，跳过）"
fi

echo "  ⚠ links（vendor 阶段跳过：check-skill-links 校验工作区 .cursor/.agents symlink；安装后可对项目运行）"

if check_vendor_skill_entrypoint; then
  echo "  ✓ entrypoints (SKILL.md front matter)"
else
  echo "  ✗ entrypoints (SKILL.md front matter)"
  PASS=0
fi

if [ $PASS -eq 0 ]; then
  echo ""
  echo "✗ 验收未通过。技能留在 ${VENDOR_DIR}，请手动修复后再移入 skills/。"
  exit 1
fi

echo "✓ 全部检查通过"

# ── 步骤 4：移入 skills/ ──────────────────────────────────────────────────────
if [ $DRY_RUN -eq 1 ]; then
  echo ""
  echo "✓ --dry-run 完成。技能在 ${VENDOR_DIR}，未移入 skills/。"
  exit 0
fi

if [ "$SCOPE" = "project" ]; then
  if [ -z "$PROJECT_KEY" ]; then
    echo "✗ --scope project 需要 --project <key>" >&2
    exit 1
  fi
  DEST="$HUB_ROOT/skills/projects/$PROJECT_KEY/$SKILL_NAME"
else
  DEST="$HUB_ROOT/skills/share/$SKILL_NAME"
fi

if [ -d "$DEST" ]; then
  echo "✗ 目标已存在：$DEST。请先删除或重命名再重试。" >&2
  exit 1
fi

mkdir -p "$(dirname "$DEST")"
cp -R "$VENDOR_DIR" "$DEST"
echo ""
echo "✓ 已安装到：${DEST#$HUB_ROOT/}"
echo ""
echo "下一步建议："
echo "  1. 编辑 $DEST/SKILL.md，把硬编码路径改为 \$AGENTS_HUB_ROOT 相对引用"
echo "  2. 运行 hub 挂载脚本（agent-hub-bootstrap）将技能同步到客户端目录"
echo "  3. 在 skill-discovery 的 find-skills 输出中确认可见"
