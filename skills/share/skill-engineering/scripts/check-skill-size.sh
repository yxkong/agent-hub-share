#!/usr/bin/env sh
set -eu

# Counts nonempty lines in a SKILL.md (trim leading/trailing whitespace per line; blank lines excluded).
# Same semantics as skill-engineering: references/SKILL.md §主文件行数
#
# Usage:
#   check-skill-size.sh --file path/to/SKILL.md [--max N | --type TYPE]
#   TYPE: pure-router (80) | router-hard (130) | multi-domain (150) | meta (160)
# If neither --max nor --type: print SKILL_NONEMPTY_LINES=n and exit 0.

SKILL_SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
HUB_SCRIPTS_DIR=$(CDPATH='' cd -- "$SKILL_SCRIPT_DIR/../../../../scripts" && pwd -P)
SCRIPT_DIR="$HUB_SCRIPTS_DIR"
. "$HUB_SCRIPTS_DIR/agent-hub-paths.sh"

FILE=''
MAX=''
TYPE=''

while [ $# -gt 0 ]; do
  case "$1" in
    --file) FILE=$2; shift 2 ;;
    --max) MAX=$2; shift 2 ;;
    --type) TYPE=$2; shift 2 ;;
    *) agent_fail "check-skill-size: unknown argument: $1" ;;
  esac
done

[ -n "$MAX" ] && [ -n "$TYPE" ] && agent_fail 'check-skill-size: use only one of --max and --type'

[ -n "$FILE" ] || agent_fail 'check-skill-size: --file is required'
[ -f "$FILE" ] || agent_fail "check-skill-size: file not found: $FILE"

FILE=$(agent_resolve_absolute_path "$FILE")

count_nonempty() {
  awk '{s=$0; gsub(/^[ \t]+|[ \t]+$/,"",s); if(length(s)>0)c++}END{print c+0}' "$1"
}

N=$(count_nonempty "$FILE")

if [ -z "$MAX" ] && [ -z "$TYPE" ]; then
  printf 'SKILL_NONEMPTY_LINES=%s file=%s\n' "$N" "$FILE"
  exit 0
fi

LIMIT=$MAX
if [ -n "$TYPE" ]; then
  case "$TYPE" in
    pure-router) LIMIT=80 ;;
    router-hard) LIMIT=130 ;;
    multi-domain) LIMIT=150 ;;
    meta) LIMIT=160 ;;
    *) agent_fail 'check-skill-size: --type must be pure-router|router-hard|multi-domain|meta' ;;
  esac
fi

[ -n "$LIMIT" ] || agent_fail 'check-skill-size: set --max or --type'

if [ "$N" -le "$LIMIT" ]; then
  printf 'SKILL_SIZE_OK nonempty=%s max=%s file=%s\n' "$N" "$LIMIT" "$FILE"
  exit 0
fi

printf 'SKILL_SIZE_FAIL nonempty=%s max=%s file=%s\n' "$N" "$LIMIT" "$FILE"
exit 1
