#!/usr/bin/env sh
set -eu

# Validates references/ layout per skill-engineering (top-level *.md count, semantic subdirs, bak exclusion,
# and Markdown links from one semantic subdir to another via ../sibling/).
#
# Usage:
#   check-skill-structure.sh [--hub-root DIR] [--only-share] [--skill-root PATH]...
#   --skill-root may repeat; each PATH is the skill directory that contains SKILL.md.
#   If any --skill-root is set, only those skills are checked (hub-wide scan skipped; --only-share ignored).

SKILL_SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
HUB_SCRIPTS_DIR=$(CDPATH='' cd -- "$SKILL_SCRIPT_DIR/../../../../scripts" && pwd -P)
SCRIPT_DIR="$HUB_SCRIPTS_DIR"
. "$HUB_SCRIPTS_DIR/agent-hub-paths.sh"

HUB_ROOT=''
ONLY_SHARE=0
SKILL_ROOT_LINES=''

while [ $# -gt 0 ]; do
  case "$1" in
    --hub-root) HUB_ROOT=$2; shift 2 ;;
    --only-share) ONLY_SHARE=1; shift ;;
    --skill-root)
      sr=$(agent_resolve_absolute_path "$2")
      [ -f "$sr/SKILL.md" ] || agent_fail "check-skill-structure: --skill-root must point to a directory containing SKILL.md: $sr"
      SKILL_ROOT_LINES="$SKILL_ROOT_LINES$sr
"
      shift 2
      ;;
    *) agent_fail "check-skill-structure: unknown argument: $1" ;;
  esac
done

AGENTS_ROOT=$(agent_resolve_hub_root "$HUB_ROOT" "$SCRIPT_DIR")
SKILLS_ROOT="$AGENTS_ROOT/skills"
COUNT=0

record_violation() {
  printf 'SKILL_STRUCTURE_VIOLATION=%s reason=%s\n' "$1" "$2"
  COUNT=$((COUNT + 1))
}

# From references/<curr_sem>/*.md, forbid linking to ../<sib>/ or ../<sib>.md where sib is another semantic subdir.
check_cross_subdir_relative_links() {
  skill_root=$1
  refdir="$skill_root/references"
  [ -d "$refdir" ] || return 0

  sem_list=''
  for sub in "$refdir"/*; do
    [ -d "$sub" ] || continue
    base=$(basename -- "$sub")
    case "$base" in bak) continue ;; esac
    if [ -z "$sem_list" ]; then
      sem_list=$base
    else
      sem_list="$sem_list $base"
    fi
  done
  [ -n "$sem_list" ] || return 0

  while IFS= read -r md || [ -n "$md" ]; do
    [ -n "$md" ] || continue
    rel=${md#"$refdir"/}
    case "$rel" in
      */bak/*|bak/*) continue ;;
    esac
    case "$rel" in
      */*/*) continue ;;
    esac
    case "$rel" in
      */*.md) ;;
      *) continue ;;
    esac

    curr_sem=${rel%%/*}
    case "$curr_sem" in
      bak) continue ;;
    esac

    for sib in $sem_list; do
      [ "$sib" = "$curr_sem" ] && continue
      if grep -qF "](../${sib}/" "$md" 2>/dev/null \
        || grep -qF "](./../${sib}/" "$md" 2>/dev/null \
        || grep -qF "](../${sib}.md)" "$md" 2>/dev/null \
        || grep -qF "](./../${sib}.md)" "$md" 2>/dev/null; then
        record_violation "$md" "references 子目录「${curr_sem}」内禁止用相对路径跨域链到「${sib}」（Markdown）；请改为主文件路由指针或合并文档（见 design_principles.md 2 级使用约束）"
      fi
    done
  done <<EOF
$(find "$refdir" -type f -name '*.md' ! -path "$refdir/bak/*" ! -path "$refdir/bak" 2>/dev/null || true)
EOF
}

check_references_tree() {
  skill_root=$1
  refdir="$skill_root/references"
  [ -d "$refdir" ] || return 0

  top=0
  for f in "$refdir"/*.md; do
    [ -f "$f" ] || continue
    top=$((top + 1))
  done
  if [ "$top" -gt 15 ]; then
    record_violation "$refdir" "references 顶层并列 *.md 超过上限（当前 ${top}，上限 15）；合并、下沉到语义子目录或移入 bak（见 skill-engineering references 规约）"
  fi

  for sub in "$refdir"/*; do
    [ -d "$sub" ] || continue
    base=$(basename -- "$sub")
    case "$base" in
      bak) continue ;;
    esac
    if find "$sub" -mindepth 1 -type d ! -path "$sub/bak" ! -path "$sub/bak/*" 2>/dev/null | head -n 1 | grep -q .; then
      record_violation "$sub" "references 语义子目录下不允许再嵌套目录（仅一层子目录 + 其下 *.md）"
    fi
    n=0
    for f in "$sub"/*.md; do
      [ -f "$f" ] || continue
      n=$((n + 1))
    done
    if [ "$n" -gt 15 ]; then
      record_violation "$sub" "语义子目录内并列 *.md 超过上限（当前 ${n}，上限 15）"
    fi
  done

  check_cross_subdir_relative_links "$skill_root"
}

if [ -n "$SKILL_ROOT_LINES" ]; then
  while IFS= read -r sr || [ -n "$sr" ]; do
    [ -z "$sr" ] && continue
    check_references_tree "$sr"
  done <<EOF
$SKILL_ROOT_LINES
EOF
else
  for layer in share media; do
    layer_root="$SKILLS_ROOT/$layer"
    [ -d "$layer_root" ] || continue
    while IFS= read -r f; do
      [ -n "$f" ] || continue
      rel=${f#"$layer_root/"}
      parts=$(printf '%s' "$rel" | awk -F/ '{print NF}')
      [ "$parts" -eq 2 ] || continue
      check_references_tree "$(dirname -- "$f")"
    done <<EOF
$(find "$layer_root" -type f -name SKILL.md)
EOF
  done

  if [ -d "$SKILLS_ROOT/projects" ] && [ "$ONLY_SHARE" -eq 0 ]; then
    while IFS= read -r f; do
      [ -n "$f" ] || continue
      rel=${f#"$SKILLS_ROOT/projects/"}
      parts=$(printf '%s' "$rel" | awk -F/ '{print NF}')
      [ "$parts" -eq 3 ] || continue
      check_references_tree "$(dirname -- "$f")"
    done <<EOF
$(find "$SKILLS_ROOT/projects" -type f -name SKILL.md)
EOF
  fi
fi

if [ "$COUNT" -eq 0 ]; then
  printf '%s\n' 'SKILL_REFERENCES_STRUCTURE=ok'
  exit 0
fi

printf 'SKILL_REFERENCES_STRUCTURE=fail count=%s\n' "$COUNT"
exit 1
