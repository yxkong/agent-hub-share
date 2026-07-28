#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PYTHON_BIN="${PYTHON:-python3}"
PORT="${PORT:-9100}"
MATCH="${MATCH:-uvicorn|main:app}"
RETRIES="${RETRIES:-3}"
DRY_RUN=0
PROBE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --port) PORT="$2"; shift 2 ;;
    --match) MATCH="$2"; shift 2 ;;
    --retries) RETRIES="$2"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    --probe) PROBE=1; shift ;;
    -h|--help)
      exec "$PYTHON_BIN" "$SCRIPT_DIR/ecs_ops.py" local free-port --help
      ;;
    *)
      echo "unknown arg: $1" >&2
      exit 2
      ;;
  esac
done

args=(local free-port --port "$PORT" --retries "$RETRIES")
if [[ -n "$MATCH" ]]; then
  args+=(--match "$MATCH")
fi
if [[ "$DRY_RUN" -eq 1 ]]; then
  args+=(--dry-run)
fi
if [[ "$PROBE" -eq 1 ]]; then
  args+=(--probe)
fi

exec "$PYTHON_BIN" "$SCRIPT_DIR/ecs_ops.py" "${args[@]}"
