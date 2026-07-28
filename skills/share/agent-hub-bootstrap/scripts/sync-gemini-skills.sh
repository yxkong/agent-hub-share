#!/usr/bin/env sh
set -eu

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
FALLBACK_HUB_ROOT=$(CDPATH='' cd -- "$SCRIPT_DIR/../../../.." && pwd -P)
. "$FALLBACK_HUB_ROOT/scripts/agent-hub-paths.sh"
. "$SCRIPT_DIR/gemini-skill-paths.sh"

HUB_ROOT=''
DRY_RUN=0
REPLACE_REAL_DIRS=0

while [ $# -gt 0 ]; do
  case "$1" in
    --hub-root)
      HUB_ROOT=$2; shift 2 ;;
    --dry-run)
      DRY_RUN=1; shift ;;
    --replace-real-dirs)
      REPLACE_REAL_DIRS=1; shift ;;
    *)
      agent_fail "Unknown argument: $1" ;;
  esac
done

AGENTS_ROOT=$(agent_resolve_hub_root "$HUB_ROOT" "$FALLBACK_HUB_ROOT/scripts")
GEMINI_SKILLS_ROOTS=$(gemini_user_skill_roots "${HOME:-${USERPROFILE:-}}")
PYTHON_BIN=$(agent_resolve_python3)
SKILL_RELATIVE_PATHS=$("$PYTHON_BIN" "$FALLBACK_HUB_ROOT/scripts/agent_hub.py" list-skills --hub-root "$AGENTS_ROOT" --project-type generic --format paths)
SELECTED_SKILL_NAMES=$(printf '%s\n' "$SKILL_RELATIVE_PATHS" | awk -F/ 'NF {print $NF}')

sync_gemini_link() {
  link_path=$1
  target_path=$2

  if [ "$DRY_RUN" = '1' ]; then
    printf '  [DRY-RUN] symlink: %s -> %s\n' "$link_path" "$target_path"
    return
  fi

  agent_ensure_dir "$(dirname -- "$link_path")"
  target_resolved=$(agent_resolve_absolute_path "$target_path")
  if [ -e "$link_path" ] || [ -L "$link_path" ]; then
    if [ -L "$link_path" ]; then
      existing=$(agent_real_path "$link_path")
      if [ "$existing" = "$target_resolved" ]; then
        printf '  [OK] %s\n' "$link_path"
        return
      fi
      rm -f -- "$link_path"
    elif [ -f "$link_path/SKILL.md" ]; then
      if [ "$REPLACE_REAL_DIRS" = '1' ]; then
        rm -rf -- "$link_path"
      else
        agent_fail "Refusing to replace real skill directory: $link_path"
      fi
    else
      agent_fail "Path exists and is not a symlink: $link_path"
    fi
  fi

  ln -s "$target_path" "$link_path"
  printf '  [NEW] %s\n' "$link_path"
}

selected_skill_name() {
  expected=$1
  printf '%s\n' "$SELECTED_SKILL_NAMES" | awk -v expected="$expected" '$0 == expected {found=1} END {exit !found}'
}

remove_stale_managed_gemini_links() {
  destination_root=$1
  [ -d "$destination_root" ] || return 0
  for link_path in "$destination_root"/*; do
    [ -L "$link_path" ] || continue
    name=$(basename -- "$link_path")
    raw_target=$(readlink "$link_path")
    case "$raw_target" in
      /*) target_path=$raw_target ;;
      *) target_path=$(agent_resolve_absolute_path "$(dirname -- "$link_path")/$raw_target") ;;
    esac
    case "$target_path" in "$AGENTS_ROOT/skills"/*) ;; *) continue ;; esac
    if selected_skill_name "$name"; then continue; fi
    if [ "$DRY_RUN" = '1' ]; then
      printf '  [DRY-RUN] Remove stale managed skill: %s -> %s\n' "$link_path" "$target_path"
    else
      rm -f -- "$link_path"
      printf '  [REMOVED] %s -> %s\n' "$link_path" "$target_path"
    fi
  done
}

echo "=== sync-gemini-skills ==="
echo "  Hub root      : $AGENTS_ROOT"
echo "  Scope         : generic/global only"
printf '  Gemini roots  : %s\n' "$(printf '%s' "$GEMINI_SKILLS_ROOTS" | tr '\n' ' ')"
[ "$DRY_RUN" = '1' ] && echo "  [DRY-RUN - no files will be written]"
echo ""

TOTAL_COUNT=0
for DESTINATION_ROOT in $GEMINI_SKILLS_ROOTS; do
  [ "$DRY_RUN" = '1' ] || agent_ensure_dir "$DESTINATION_ROOT"
  remove_stale_managed_gemini_links "$DESTINATION_ROOT"
  while IFS= read -r relative_path || [ -n "$relative_path" ]; do
    [ -n "$relative_path" ] || continue
    name=$(basename -- "$relative_path")
    sync_gemini_link "$DESTINATION_ROOT/$name" "$AGENTS_ROOT/$relative_path"
    TOTAL_COUNT=$((TOTAL_COUNT + 1))
  done <<EOF
$SKILL_RELATIVE_PATHS
EOF
done

echo ""
printf 'GEMINI_SKILLS_ROOTS=%s\n' "$(printf '%s' "$GEMINI_SKILLS_ROOTS" | tr '\n' ';')"
echo "GEMINI_SKILLS_SYNCED=$TOTAL_COUNT"
echo "GEMINI_SKILL_PATHS=ok"
