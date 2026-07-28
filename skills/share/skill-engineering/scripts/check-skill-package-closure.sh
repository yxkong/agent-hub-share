#!/usr/bin/env sh
set -eu

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
CORE="$SCRIPT_DIR/skill_package_closure.py"

[ -f "$CORE" ] || {
  printf 'Skill package closure core not found: %s\n' "$CORE" >&2
  exit 1
}

if command -v python3 >/dev/null 2>&1; then
  exec python3 "$CORE" "$@"
fi
if command -v python >/dev/null 2>&1; then
  exec python "$CORE" "$@"
fi
if command -v py >/dev/null 2>&1; then
  exec py -3 "$CORE" "$@"
fi

printf '%s\n' 'Skill package closure requires python3, python, or py -3' >&2
exit 1
