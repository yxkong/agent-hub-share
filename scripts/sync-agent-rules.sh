#!/usr/bin/env sh
set -eu

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
. "$SCRIPT_DIR/agent-hub-paths.sh"

HUB_ROOT=''
PROJECT_ROOT=''
PROJECT_KEY=''
SKIP_USER_TARGETS=0

while [ $# -gt 0 ]; do
  case "$1" in
    --hub-root)
      HUB_ROOT=$2; shift 2 ;;
    --project-root)
      PROJECT_ROOT=$2; shift 2 ;;
    --project-key)
      PROJECT_KEY=$2; shift 2 ;;
    --skip-user-targets)
      SKIP_USER_TARGETS=1; shift ;;
    *)
      agent_fail "Unknown argument: $1" ;;
  esac
done

AGENTS_ROOT=$(agent_resolve_hub_root "$HUB_ROOT" "$SCRIPT_DIR")
RESOLVED_PROJECT_ROOT=$(agent_resolve_workspace_root "$PROJECT_ROOT" 1)
RESOLVED_PROJECT_KEY=$(agent_resolve_project_key "$PROJECT_KEY" "$RESOLVED_PROJECT_ROOT")
[ -n "$RESOLVED_PROJECT_KEY" ] || agent_fail 'Project rules sync requires --project-key, AGENTS_DEFAULT_PROJECT_KEY, or a workspace root whose folder name can be used as the project key.'
[ -n "$RESOLVED_PROJECT_ROOT" ] || agent_fail 'Project rules sync requires --project-root, AGENTS_DEFAULT_PROJECT_ROOT, or running the script from the target workspace.'

COMMON_PATH="$AGENTS_ROOT/rules/common/COMMON_AGENT_RULES.md"
PROJECT_PATH="$AGENTS_ROOT/rules/projects/$RESOLVED_PROJECT_KEY/PROJECT_RULES.md"
GENERATED_GLOBAL="$AGENTS_ROOT/rules/generated/global"
GENERATED_PROJECT="$AGENTS_ROOT/rules/generated/projects/$RESOLVED_PROJECT_KEY"
USER_HOME=${HOME:-}

[ -f "$COMMON_PATH" ] || agent_fail "Common rules not found: $COMMON_PATH"
agent_ensure_dir "$GENERATED_GLOBAL"
agent_ensure_dir "$GENERATED_PROJECT"

COMMON=$(cat "$COMMON_PATH" | agent_normalize_lf_stream)
PROJECT=''
if [ -f "$PROJECT_PATH" ]; then
  PROJECT=$(cat "$PROJECT_PATH" | agent_normalize_lf_stream)
else
  echo "Warning: Project rules missing: $PROJECT_PATH (using COMMON_AGENT_RULES only for project targets)." >&2
fi

COMMON=$(printf '%s' "$COMMON" | perl -0pe 's/\n+\z//')
PROJECT=$(printf '%s' "$PROJECT" | perl -0pe 's/\n+\z//')

GLOBAL_CODEX="$COMMON
"
GLOBAL_CLAUDE="$COMMON
"
GLOBAL_CURSOR="$COMMON
"
if [ -n "$PROJECT" ]; then
  PROJECT_COMBINED="$COMMON

$PROJECT
"
  MDC_DESCRIPTION="Shared + project rules synced from $AGENTS_ROOT"
else
  PROJECT_COMBINED="$COMMON
"
  MDC_DESCRIPTION="Shared rules only (no PROJECT_RULES.md) from $AGENTS_ROOT"
fi

PROJECT_CURSOR_MDC=$(cat <<EOF
---
description: $MDC_DESCRIPTION
alwaysApply: true
---

$(printf '%s' "$PROJECT_COMBINED" | perl -0pe 's/\n+\z//')
EOF
)

write_target() {
  target=$1
  content=$2
  agent_write_utf8_no_bom_file "$target" "$content"
  echo "Synced -> $target"
}

write_target "$GENERATED_GLOBAL/CODEX_AGENTS.md" "$GLOBAL_CODEX"
write_target "$GENERATED_GLOBAL/CLAUDE.md" "$GLOBAL_CLAUDE"
write_target "$GENERATED_GLOBAL/CURSOR_USER_RULES.md" "$GLOBAL_CURSOR"
write_target "$GENERATED_PROJECT/AGENTS.md" "$PROJECT_COMBINED"
write_target "$GENERATED_PROJECT/CLAUDE.md" "$PROJECT_COMBINED"
write_target "$GENERATED_PROJECT/.cursorrules" "$PROJECT_COMBINED"
write_target "$GENERATED_PROJECT/.cursor/rules/00-common.mdc" "$PROJECT_CURSOR_MDC"
write_target "$RESOLVED_PROJECT_ROOT/AGENTS.md" "$PROJECT_COMBINED"
write_target "$RESOLVED_PROJECT_ROOT/CLAUDE.md" "$PROJECT_COMBINED"
write_target "$RESOLVED_PROJECT_ROOT/.cursorrules" "$PROJECT_COMBINED"
write_target "$RESOLVED_PROJECT_ROOT/.cursor/rules/00-common.mdc" "$PROJECT_CURSOR_MDC"

if [ "$SKIP_USER_TARGETS" != '1' ] && [ -n "$USER_HOME" ]; then
  write_target "$USER_HOME/.codex/AGENTS.md" "$GLOBAL_CODEX"
  write_target "$USER_HOME/.claude/CLAUDE.md" "$GLOBAL_CLAUDE"
fi
