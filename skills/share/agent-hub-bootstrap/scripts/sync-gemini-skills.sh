#!/usr/bin/env sh
set -eu

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
FALLBACK_HUB_ROOT=$(CDPATH='' cd -- "$SCRIPT_DIR/../../../.." && pwd -P)
. "$FALLBACK_HUB_ROOT/scripts/agent-hub-paths.sh"
. "$SCRIPT_DIR/gemini-skill-paths.sh"

HUB_ROOT=''
DRY_RUN=0
REPLACE_REAL_DIRS=0
SKIP_MEDIA=0

while [ $# -gt 0 ]; do
  case "$1" in
    --hub-root)
      HUB_ROOT=$2; shift 2 ;;
    --dry-run)
      DRY_RUN=1; shift ;;
    --replace-real-dirs)
      REPLACE_REAL_DIRS=1; shift ;;
    --skip-media)
      SKIP_MEDIA=1; shift ;;
    *)
      agent_fail "Unknown argument: $1" ;;
  esac
done

AGENTS_ROOT=$(agent_resolve_hub_root "$HUB_ROOT" "$FALLBACK_HUB_ROOT/scripts")
SHARE_ROOT="$AGENTS_ROOT/skills/share"
MEDIA_ROOT="$AGENTS_ROOT/skills/media"
GEMINI_SKILLS_ROOT=$(gemini_user_skill_root "${HOME:-${USERPROFILE:-}}" gemini)

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

SYNC_GEMINI_COUNT=0

sync_gemini_root() {
  source_root=$1
  SYNC_GEMINI_COUNT=0

  if [ ! -d "$source_root" ]; then
    return
  fi

  for skill_dir in "$source_root"/*; do
    [ -d "$skill_dir" ] || continue
    [ "$(basename -- "$skill_dir")" != 'bak' ] || continue
    [ -f "$skill_dir/SKILL.md" ] || continue
    name=$(basename -- "$skill_dir")
    SYNC_GEMINI_COUNT=$((SYNC_GEMINI_COUNT + 1))
    sync_gemini_link "$GEMINI_SKILLS_ROOT/$name" "$skill_dir"
  done
}

echo "=== sync-gemini-skills ==="
echo "  Hub root      : $AGENTS_ROOT"
echo "  Gemini skills : $GEMINI_SKILLS_ROOT"
[ "$DRY_RUN" = '1' ] && echo "  [DRY-RUN - no files will be written]"
echo ""

sync_gemini_root "$SHARE_ROOT"
SHARE_COUNT=$SYNC_GEMINI_COUNT
MEDIA_COUNT=0
if [ "$SKIP_MEDIA" != '1' ]; then
  sync_gemini_root "$MEDIA_ROOT"
  MEDIA_COUNT=$SYNC_GEMINI_COUNT
fi
TOTAL_COUNT=$((SHARE_COUNT + MEDIA_COUNT))

echo ""
echo "GEMINI_SKILLS_ROOT=$GEMINI_SKILLS_ROOT"
echo "GEMINI_SKILLS_SYNCED=$TOTAL_COUNT"
echo "GEMINI_SKILL_PATHS=ok"
