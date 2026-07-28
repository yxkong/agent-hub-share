#!/usr/bin/env sh
set -eu

# Validates that share skills do not hardcode known private project/module prefixes in active docs.
#
# Usage:
#   check-share-skill-private-coupling.sh [--hub-root DIR] [--skill-root PATH]...
#   --skill-root may repeat; each PATH must be a share skill directory that contains SKILL.md.

SKILL_SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
HUB_SCRIPTS_DIR=$(CDPATH='' cd -- "$SKILL_SCRIPT_DIR/../../../../scripts" && pwd -P)
SCRIPT_DIR="$HUB_SCRIPTS_DIR"
. "$HUB_SCRIPTS_DIR/agent-hub-paths.sh"

HUB_ROOT=''
SKILL_ROOT_LINES=''
COUNT=0

while [ $# -gt 0 ]; do
  case "$1" in
    --hub-root) HUB_ROOT=$2; shift 2 ;;
    --skill-root)
      sr=$(agent_resolve_absolute_path "$2")
      [ -f "$sr/SKILL.md" ] || agent_fail "check-share-skill-private-coupling: --skill-root must point to a directory containing SKILL.md: $sr"
      SKILL_ROOT_LINES="$SKILL_ROOT_LINES$sr
"
      shift 2
      ;;
    *) agent_fail "check-share-skill-private-coupling: unknown argument: $1" ;;
  esac
done

AGENTS_ROOT=$(agent_resolve_hub_root "$HUB_ROOT" "$SCRIPT_DIR")
SHARE_ROOT="$AGENTS_ROOT/skills/share"
bs='\\'
ai_segment='ai'
private_suffix='private'
admin_segment='admin'
review_segment='review'
core_segment='core'
frontend_module="admin-system""-base"
legacy_docs_re="PLATFORM_DOCS""_GOVERNANCE"
wechat_skill="wechat-article""-workflow"
media_path_re="skills/""media/"
LOCAL_HUB_PATH_RE="D:${bs}${bs}${ai_segment}${bs}${bs}|D:/${ai_segment}/"
PRIVATE_HUB_RE="ai-hub-${private_suffix}|yxkong/ai-hub-${private_suffix}"
PRIVATE_PROJECT_RE="platform-jdk""17|platform-${admin_segment}|platform-${review_segment}|platform-backend""-dev|platform-${core_segment}"
PRIVATE_MODULE_RE="${frontend_module}(-frontend)?"
PRIVATE_MEDIA_RE="${wechat_skill}|${media_path_re}"

record_violation() {
  printf 'SHARE_SKILL_PRIVATE_COUPLING_VIOLATION=%s reason=%s\n' "$1" "$2"
  COUNT=$((COUNT + 1))
}

check_one_skill() {
  skill_root=$1
  case "$skill_root" in
    "$SHARE_ROOT"/*) ;;
    *) agent_fail "check-share-skill-private-coupling: --skill-root must be under share root: $skill_root" ;;
  esac

  files=''
  for f in "$skill_root/SKILL.md" "$skill_root/README.md"; do
    [ -f "$f" ] || continue
    files="$files$f
"
  done
  if [ -d "$skill_root/references" ]; then
    files="$files$(find "$skill_root/references" -type f -name '*.md' ! -path '*/bak/*' ! -path '*/bak' 2>/dev/null || true)
"
  fi

  while IFS= read -r f || [ -n "$f" ]; do
    [ -n "$f" ] || continue
    if grep -Eiq 'platform-[a-z0-9][a-z0-9-]*' "$f" 2>/dev/null; then
      first_match=$(grep -Eio 'platform-[a-z0-9][a-z0-9-]*' "$f" 2>/dev/null | head -n 1)
      record_violation "$f" "share skill 不得硬编码真实项目/模块前缀 \`platform-*\`；请改为 <project-key> / <runtime-module> / <domain-module> 等占位符 first_match=${first_match}"
    fi
    if grep -Eiq "$PRIVATE_PROJECT_RE" "$f" 2>/dev/null; then
      first_match=$(grep -Eio "$PRIVATE_PROJECT_RE" "$f" 2>/dev/null | head -n 1)
      record_violation "$f" "share skill 不得硬编码 private 项目或仓库名；请改为通用占位符或示例 first_match=${first_match}"
    fi
    if grep -Eiq "$PRIVATE_MODULE_RE" "$f" 2>/dev/null; then
      first_match=$(grep -Eio "$PRIVATE_MODULE_RE" "$f" 2>/dev/null | head -n 1)
      record_violation "$f" "share skill 不得硬编码 private 模块名；请改为 <frontend-app> / <domain-module> 等占位符 first_match=${first_match}"
    fi
    if grep -Eiq "$legacy_docs_re" "$f" 2>/dev/null; then
      record_violation "$f" '请将旧项目文档治理文件名改为 docs/guide/DOCS_GOVERNANCE.md 或其他通用项目内命名'
    fi
    if grep -Eiq "$LOCAL_HUB_PATH_RE" "$f" 2>/dev/null; then
      first_match=$(grep -Eio "$LOCAL_HUB_PATH_RE" "$f" 2>/dev/null | head -n 1)
      record_violation "$f" "share skill 不得包含本机绝对路径；请改为 <hub-root> 或仓库相对路径 first_match=${first_match}"
    fi
    if grep -Eiq "$PRIVATE_HUB_RE" "$f" 2>/dev/null; then
      first_match=$(grep -Eio "$PRIVATE_HUB_RE" "$f" 2>/dev/null | head -n 1)
      record_violation "$f" "share skill 不得引用 private 源仓；public 语境请改为 agent-hub-share 或 <hub-root> first_match=${first_match}"
    fi
    if grep -Eiq "$PRIVATE_MEDIA_RE" "$f" 2>/dev/null; then
      first_match=$(grep -Eio "$PRIVATE_MEDIA_RE" "$f" 2>/dev/null | head -n 1)
      record_violation "$f" "share skill 不得暴露 maintainer hub 未 export 的技能路径；请改为 <private-media-skill> 或 maintainer hub 文档 first_match=${first_match}"
    fi
  done <<EOF
$files
EOF
}

if [ -n "$SKILL_ROOT_LINES" ]; then
  while IFS= read -r sr || [ -n "$sr" ]; do
    [ -n "$sr" ] || continue
    check_one_skill "$sr"
  done <<EOF
$SKILL_ROOT_LINES
EOF
elif [ -d "$SHARE_ROOT" ]; then
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    rel=${f#"$SHARE_ROOT"/}
    parts=$(printf '%s' "$rel" | awk -F/ '{print NF}')
    [ "$parts" -eq 2 ] || continue
    check_one_skill "$(dirname -- "$f")"
  done <<EOF
$(find "$SHARE_ROOT" -type f -name SKILL.md)
EOF
fi

if [ "$COUNT" -eq 0 ]; then
  printf '%s\n' 'SHARE_SKILL_PRIVATE_COUPLING=ok'
  exit 0
fi

printf 'SHARE_SKILL_PRIVATE_COUPLING=fail count=%s\n' "$COUNT"
exit 1
