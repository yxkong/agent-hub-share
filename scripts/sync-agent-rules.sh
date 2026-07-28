#!/usr/bin/env sh
set -eu

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)

if command -v python3 >/dev/null 2>&1; then
  PYTHON_BIN=python3
elif command -v python >/dev/null 2>&1; then
  PYTHON_BIN=python
else
  echo 'sync-agent-rules: Python 3 is required. Install python3 or provide python on PATH.' >&2
  exit 1
fi

exec "$PYTHON_BIN" "$SCRIPT_DIR/agent_hub.py" sync-agent-rules "$@"
