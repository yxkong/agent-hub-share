#!/usr/bin/env sh
set -eu

# Builds skills/share/index.json and skills/media/index.json from SKILL.md front matter.
#
# Usage: build-skill-index.sh [--hub-root DIR]

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
. "$SCRIPT_DIR/agent-hub-paths.sh"

HUB_ROOT=''
while [ $# -gt 0 ]; do
  case "$1" in
    --hub-root) HUB_ROOT=$2; shift 2 ;;
    *) agent_fail "build-skill-index: unknown arg: $1" ;;
  esac
done

AGENTS_ROOT=$(agent_resolve_hub_root "$HUB_ROOT" "$SCRIPT_DIR")
PY=$(agent_resolve_python3)
HUB_PY="$SCRIPT_DIR/python/hub_build_indices.py"
[ -f "$HUB_PY" ] || agent_fail "missing indexer: $HUB_PY"

SHARE_ROOT="$AGENTS_ROOT/skills/share"
MEDIA_ROOT="$AGENTS_ROOT/skills/media"

"$PY" "$HUB_PY" skills "$SHARE_ROOT" || exit $?
if [ -d "$MEDIA_ROOT" ]; then
  "$PY" "$HUB_PY" media-skills "$MEDIA_ROOT" || exit $?
fi
