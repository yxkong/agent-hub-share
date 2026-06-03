#!/usr/bin/env sh
set -eu

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
. "$SCRIPT_DIR/agent-hub-paths.sh"

SKILL_NAME=''
SCOPE='category'
HUB_ROOT=''
CATEGORY=''
PROJECT_ROOT=''
LINK_PROJECT=0
LINK_USERS=0
CREATE_IF_MISSING=0

while [ $# -gt 0 ]; do
  case "$1" in
    --skill-name)
      SKILL_NAME=$2; shift 2 ;;
    --scope)
      SCOPE=$2; shift 2 ;;
    --hub-root)
      HUB_ROOT=$2; shift 2 ;;
    --category)
      CATEGORY=$2; shift 2 ;;
    --project-root)
      PROJECT_ROOT=$2; shift 2 ;;
    --link-project)
      LINK_PROJECT=1; shift ;;
    --link-users)
      LINK_USERS=1; shift ;;
    --create-if-missing)
      CREATE_IF_MISSING=1; shift ;;
    *)
      agent_fail "Unknown argument: $1" ;;
  esac
done

[ -n "$SKILL_NAME" ] || agent_fail '--skill-name is required'
[ "$SCOPE" = 'share' ] || [ "$SCOPE" = 'category' ] || [ "$SCOPE" = 'media' ] || agent_fail '--scope must be share, category, or media'

AGENTS_ROOT=$(agent_resolve_hub_root "$HUB_ROOT" "$SCRIPT_DIR")
SKILLS_ROOT="$AGENTS_ROOT/skills"
USER_HOME=${HOME:-}
USER_CLAUDE_SKILLS_ROOT="$USER_HOME/.claude/skills"
USER_CURSOR_SKILLS_ROOT="$USER_HOME/.cursor/skills"
USER_CODEX_SKILLS_ROOT="$USER_HOME/.codex/skills"

RESOLVED_PROJECT_ROOT=''
if [ "$SCOPE" = 'category' ] || [ "$LINK_PROJECT" = '1' ] || [ -n "$PROJECT_ROOT" ]; then
  RESOLVED_PROJECT_ROOT=$(agent_resolve_workspace_root "$PROJECT_ROOT" 1)
fi

RESOLVED_CATEGORY=''
if [ "$SCOPE" = 'category' ]; then
  RESOLVED_PROJECT_KEY=$(agent_resolve_project_key '' "$RESOLVED_PROJECT_ROOT")
  if [ -n "$CATEGORY" ]; then
    RESOLVED_CATEGORY=$CATEGORY
  elif [ -n "$RESOLVED_PROJECT_KEY" ]; then
    RESOLVED_CATEGORY="projects/$RESOLVED_PROJECT_KEY"
  fi
  [ -n "$RESOLVED_CATEGORY" ] || agent_fail 'Category scope requires --category, AGENTS_DEFAULT_PROJECT_KEY, or a workspace root whose folder name can be used as the project key.'
fi

PROJECT_AGENT_SKILLS_ROOT=''
PROJECT_CURSOR_SKILLS_ROOT=''
if [ "$SCOPE" = 'category' ] || [ "$LINK_PROJECT" = '1' ]; then
  [ -n "$RESOLVED_PROJECT_ROOT" ] || agent_fail 'Project links require --project-root, AGENTS_DEFAULT_PROJECT_ROOT, or running the script from the target workspace.'
  PROJECT_AGENT_SKILLS_ROOT="$RESOLVED_PROJECT_ROOT/.agents/skills"
  PROJECT_CURSOR_SKILLS_ROOT="$RESOLVED_PROJECT_ROOT/.cursor/skills"
fi

ensure_skill_skeleton() {
  path=$1
  agent_ensure_dir "$path"
  skill_file="$path/SKILL.md"
  if [ ! -f "$skill_file" ]; then
    content=$(cat <<EOF
---
name: $SKILL_NAME
description: TODO
---

# $SKILL_NAME

TODO
EOF
)
    agent_write_utf8_no_bom_file "$skill_file" "$content"
  fi
}

if [ "$SCOPE" = 'share' ]; then
  SCOPE_ROOT="$SKILLS_ROOT/share"
elif [ "$SCOPE" = 'media' ]; then
  SCOPE_ROOT="$SKILLS_ROOT/media"
else
  SCOPE_ROOT="$SKILLS_ROOT/$RESOLVED_CATEGORY"
fi

SKILL_ROOT="$SCOPE_ROOT/$SKILL_NAME"
SKILL_FILE="$SKILL_ROOT/SKILL.md"
if [ ! -f "$SKILL_FILE" ]; then
  if [ "$CREATE_IF_MISSING" != '1' ]; then
    agent_fail "Skill source not found in hub (typo in --skill-name or wrong --scope/--category?): $SKILL_FILE. Create that directory and SKILL.md first, or pass --create-if-missing to generate a TODO placeholder only when you intentionally scaffold."
  fi
  ensure_skill_skeleton "$SKILL_ROOT"
fi

if [ "$LINK_PROJECT" = '1' ] || [ "$SCOPE" = 'category' ]; then
  agent_ensure_symlink "$PROJECT_AGENT_SKILLS_ROOT/$SKILL_NAME" "$SKILL_ROOT"
  agent_ensure_symlink "$PROJECT_CURSOR_SKILLS_ROOT/$SKILL_NAME" "$SKILL_ROOT"
fi

if [ "$LINK_USERS" = '1' ] || [ "$SCOPE" = 'share' ] || [ "$SCOPE" = 'media' ]; then
  [ -n "$USER_HOME" ] || agent_fail 'HOME is required for user skill links'
  agent_ensure_symlink "$USER_CLAUDE_SKILLS_ROOT/$SKILL_NAME" "$SKILL_ROOT"
  agent_ensure_symlink "$USER_CURSOR_SKILLS_ROOT/$SKILL_NAME" "$SKILL_ROOT"
  agent_ensure_symlink "$USER_CODEX_SKILLS_ROOT/$SKILL_NAME" "$SKILL_ROOT"
fi

echo "Hub root: $AGENTS_ROOT"
echo "Skill source: $SKILL_ROOT"
if [ -n "$RESOLVED_PROJECT_ROOT" ]; then
  echo "Workspace root: $RESOLVED_PROJECT_ROOT"
fi
