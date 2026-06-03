#!/usr/bin/env sh
set -eu

# Renames illegal nested SKILL.md *files* to _SKILL.md / SKILL.legacy-*.
# Merges illegal directories named SKILL.md into sibling SKILL_md/ (check-skill-entrypoints rejects dirs).
#
# Usage: fix-skill-entrypoints.sh [--hub-root DIR] [--dry-run]

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
. "$SCRIPT_DIR/agent-hub-paths.sh"

HUB_ROOT=''
DRY_RUN=0
while [ $# -gt 0 ]; do
  case "$1" in
    --hub-root) HUB_ROOT=$2; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    *) agent_fail "Unknown argument: $1" ;;
  esac
done

AGENTS_ROOT=$(agent_resolve_hub_root "$HUB_ROOT" "$SCRIPT_DIR")
SKILLS_ROOT="$AGENTS_ROOT/skills"
TIMESTAMP=$(date '+%Y%m%d-%H%M%S')
COUNT=0

merge_skill_md_directory() {
  dir=$1
  parent=$(dirname -- "$dir")
  target="$parent/SKILL_md"
  if [ "$DRY_RUN" -eq 1 ]; then
    printf 'DRY_RUN_MERGE_SKILL_MD_DIR=%s -> %s\n' "$dir" "$target"
    COUNT=$((COUNT + 1))
    return
  fi
  agent_ensure_dir "$target"
  if find "$dir" -mindepth 1 -type d 2>/dev/null | head -n 1 | grep -q .; then
    agent_fail "SKILL.md directory contains nested directories (not supported): $dir"
  fi
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    base=$(basename -- "$f")
    dest="$target/$base"
    if [ -e "$dest" ]; then
      stem=${base%.*}
      ext=${base##*.}
      if [ "$stem" = "$ext" ]; then ext=''; fi
      [ -n "$ext" ] && ext=".$ext" || ext=''
      dest="$target/${stem}.legacy-${TIMESTAMP}${ext}"
    fi
    mv -- "$f" "$dest"
    printf 'MOVED=%s -> %s\n' "$f" "$dest"
  done <<EOF
$(find "$dir" -mindepth 1 -maxdepth 1 -type f)
EOF
  rmdir -- "$dir" 2>/dev/null || agent_fail "Cannot remove directory after merge (not empty?): $dir"
  printf 'REMOVED_DIR=%s\n' "$dir"
  COUNT=$((COUNT + 1))
}

for ROOT_SPEC in "$SKILLS_ROOT/share:2" "$SKILLS_ROOT/projects:3"; do
  ROOT=${ROOT_SPEC%:*}
  LEGAL_PARTS=${ROOT_SPEC##*:}
  [ -d "$ROOT" ] || continue
  while IFS= read -r FILE; do
    REL=${FILE#"$ROOT"/}
    PARTS=$(printf '%s' "$REL" | awk -F/ '{print NF}')
    [ "$PARTS" -eq "$LEGAL_PARTS" ] && continue
    DIR=$(dirname -- "$FILE")
    TARGET="$DIR/_SKILL.md"
    if [ -e "$TARGET" ]; then
      TARGET="$DIR/SKILL.legacy-$TIMESTAMP.md"
    fi
    if [ "$DRY_RUN" -eq 1 ]; then
      printf 'DRY_RUN_RENAME=%s -> %s\n' "$FILE" "$TARGET"
    else
      mv "$FILE" "$TARGET"
      printf 'RENAMED=%s -> %s\n' "$FILE" "$TARGET"
    fi
    COUNT=$((COUNT + 1))
  done <<EOF
$(find "$ROOT" -type f -name SKILL.md)
EOF

  while IFS= read -r DIRDUP; do
    [ -n "$DIRDUP" ] || continue
    [ -d "$DIRDUP" ] || continue
    merge_skill_md_directory "$DIRDUP"
  done <<EOF
$(find "$ROOT" -type d -name 'SKILL.md' 2>/dev/null || true)
EOF
done

printf 'SKILL_ENTRYPOINT_FIX=count=%s\n' "$COUNT"
