#!/usr/bin/env sh
set -eu
# L1 compatibility forwarder -> L2 skill script (skill-discovery/install-skill-from-registry.sh)
SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
. "$SCRIPT_DIR/agent-hub-paths.sh"
HUB_ROOT=$(agent_resolve_hub_root "${AGENTS_HUB_ROOT:-}" "$SCRIPT_DIR")
SKILL_SCRIPT="$HUB_ROOT/skills/share/skill-discovery/scripts/install-skill-from-registry.sh"
[ -f "$SKILL_SCRIPT" ] || agent_fail "L2 script not found: $SKILL_SCRIPT"
exec sh "$SKILL_SCRIPT" "$@"