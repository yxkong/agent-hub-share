#!/usr/bin/env sh
set -eu

# Builds prompts/indexes/prompts.index.json from *.prompt.md under prompts/share and prompts/projects.
#
# Usage: build-prompt-index.sh [--hub-root DIR]
# Requires: Python 3.6+（见 agent_resolve_python3；可运行 ensure-hub-python.sh 自检）
# 索引逻辑：scripts/python/hub_build_indices.py prompts

SKILL_SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
HUB_SCRIPTS_DIR=$(CDPATH='' cd -- "$SKILL_SCRIPT_DIR/../../../../scripts" && pwd -P)
SCRIPT_DIR="$HUB_SCRIPTS_DIR"
. "$HUB_SCRIPTS_DIR/agent-hub-paths.sh"

HUB_ROOT=''
while [ $# -gt 0 ]; do
  case "$1" in
    --hub-root) HUB_ROOT=$2; shift 2 ;;
    *) agent_fail "build-prompt-index: unknown arg: $1" ;;
  esac
done

AGENTS_ROOT=$(agent_resolve_hub_root "$HUB_ROOT" "$SCRIPT_DIR")
PY=$(agent_resolve_python3)
HUB_PY="$SCRIPT_DIR/python/hub_build_indices.py"
[ -f "$HUB_PY" ] || agent_fail "missing indexer: $HUB_PY"

PROMPTS_ROOT="$AGENTS_ROOT/prompts"
OUT_DIR="$PROMPTS_ROOT/indexes"
mkdir -p "$OUT_DIR"

exec "$PY" "$HUB_PY" prompts "$PROMPTS_ROOT"
