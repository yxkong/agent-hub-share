#!/usr/bin/env sh
set -eu

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
CORE="$SCRIPT_DIR/spec_compiler_check.py"

if [ ! -f "$CORE" ]; then
  printf 'Spec Compiler core not found: %s\n' "$CORE" >&2
  exit 1
fi

if command -v python3 >/dev/null 2>&1; then
  exec python3 "$CORE" "$@"
fi
if command -v python >/dev/null 2>&1; then
  exec python "$CORE" "$@"
fi
if command -v py >/dev/null 2>&1; then
  exec py -3 "$CORE" "$@"
fi

printf '%s\n' 'Spec Compiler requires python3, python, or py -3' >&2
exit 1
