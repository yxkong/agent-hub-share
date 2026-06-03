#!/usr/bin/env sh
set -eu

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
. "$SCRIPT_DIR/agent-hub-paths.sh"

HUB_ROOT=''
ONLY_SHARE=0
while [ $# -gt 0 ]; do
  case "$1" in
    --hub-root) HUB_ROOT=$2; shift 2 ;;
    --only-share) ONLY_SHARE=1; shift ;;
    *) agent_fail "Unknown argument: $1" ;;
  esac
done

AGENTS_ROOT=$(agent_resolve_hub_root "$HUB_ROOT" "$SCRIPT_DIR")
SKILLS_ROOT="$AGENTS_ROOT/skills"
COUNT=0

check_front_matter() {
  file=$1
  first_line=$(sed -n '1p' "$file")
  bom=$(LC_ALL=C od -An -t x1 -N 3 "$file" | tr -d ' \n')
  [ "$first_line" = '---' ] || {
    if [ "$bom" = 'efbbbf' ]; then
      printf 'SKILL_ENTRYPOINT_VIOLATION=%s reason=%s\n' "$file" 'BOM detected before opening front matter delimiter'
    else
      printf 'SKILL_ENTRYPOINT_VIOLATION=%s reason=%s\n' "$file" 'Missing opening front matter delimiter'
    fi
    COUNT=$((COUNT + 1))
    return
  }
  closing_line=$(awk 'NR > 1 && $0 == "---" { print NR; exit }' "$file")
  [ -n "$closing_line" ] || {
    printf 'SKILL_ENTRYPOINT_VIOLATION=%s reason=%s\n' "$file" 'Missing closing front matter delimiter'
    COUNT=$((COUNT + 1))
    return
  }
  sed -n "2,$((closing_line - 1))p" "$file" | grep -Eq '^name:[[:space:]]*[^[:space:]]+' || {
    printf 'SKILL_ENTRYPOINT_VIOLATION=%s reason=%s\n' "$file" 'Missing name in front matter'
    COUNT=$((COUNT + 1))
    return
  }
  sed -n "2,$((closing_line - 1))p" "$file" | grep -Eq '^description:[[:space:]]*[^[:space:]]+' || {
    printf 'SKILL_ENTRYPOINT_VIOLATION=%s reason=%s\n' "$file" 'Missing description in front matter'
    COUNT=$((COUNT + 1))
    return
  }
}

ROOT_SPECS="$SKILLS_ROOT/share:2"
[ "$ONLY_SHARE" -eq 0 ] && ROOT_SPECS="$ROOT_SPECS $SKILLS_ROOT/projects:3 $SKILLS_ROOT/media:2"

for ROOT_SPEC in $ROOT_SPECS; do
  ROOT=${ROOT_SPEC%:*}
  LEGAL_PARTS=${ROOT_SPEC##*:}
  [ -d "$ROOT" ] || continue
  while IFS= read -r FILE; do
    REL=${FILE#"$ROOT"/}
    PARTS=$(printf '%s' "$REL" | awk -F/ '{print NF}')
    if [ "$PARTS" -eq "$LEGAL_PARTS" ]; then
      check_front_matter "$FILE"
      continue
    fi
    case "$REL" in
      */bak/*|bak/*) REASON='SKILL.md inside bak directory' ;;
      *) REASON='Nested SKILL.md under skill directory' ;;
    esac
    printf 'SKILL_ENTRYPOINT_VIOLATION=%s reason=%s\n' "$FILE" "$REASON"
    COUNT=$((COUNT + 1))
  done <<EOF
$(find "$ROOT" -type f -name SKILL.md)
EOF
  while IFS= read -r DIR; do
    [ -n "$DIR" ] || continue
    [ -d "$DIR" ] || continue
    REL=${DIR#"$ROOT"/}
    case "$REL" in
      */bak/*|bak/*) REASON='Directory named SKILL.md under bak path' ;;
      *) REASON='Directory named SKILL.md (forbidden; rename per hub backup policy e.g. SKILL_md)' ;;
    esac
    printf 'SKILL_ENTRYPOINT_VIOLATION=%s reason=%s\n' "$DIR" "$REASON"
    COUNT=$((COUNT + 1))
  done <<EOF
$(find "$ROOT" -type d -name 'SKILL.md' 2>/dev/null || true)
EOF
done

if [ "$COUNT" -eq 0 ]; then
  printf '%s\n' 'SKILL_ENTRYPOINTS=ok'
  exit 0
fi

printf 'SKILL_ENTRYPOINTS=fail count=%s\n' "$COUNT"
exit 1
