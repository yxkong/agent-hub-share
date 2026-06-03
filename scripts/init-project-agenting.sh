#!/usr/bin/env sh
set -eu

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
. "$SCRIPT_DIR/agent-hub-paths.sh"

agents_cleanup_workspace_share_skill_links() {
  project_root=$1
  hub_root=$2
  proj=$(agent_resolve_absolute_path "$project_root")
  hub=$(agent_resolve_absolute_path "$hub_root")
  share_norm=$(agent_resolve_absolute_path "$hub/skills/share")

  for sd in "$proj/.cursor/skills" "$proj/.claude/skills"; do
    [ -d "$sd" ] || continue
    skills_abs=$(agent_resolve_absolute_path "$sd")

    for entry_path in "$skills_abs"/*; do
      [ "$entry_path" = "$skills_abs/*" ] && break
      case "$(agent_link_type "$entry_path")" in Symlink) ;; *) continue ;; esac
      resolved=$(agent_real_path "$entry_path")

      case "$resolved" in
      "$share_norm"|"$share_norm"/*)
        rm -f -- "$entry_path"
        printf '  [cleanup] removed stale share symlink: %s -> %s\n' "$entry_path" "$resolved"
        ;;
      esac
    done
  done
}

HUB_ROOT=''
PROJECT_ROOT=''
PROJECT_KEY=''
SKIP_RULES=0
SKIP_SHARED_SKILLS=0
SKIP_PROJECT_SKILLS=0
SKIP_USER_TARGETS=0
SKIP_PROMPTS=0
LINK_USER_SKILLS=0
LINK_SHARE_TO_WORKSPACE=0
SHARE_SKILL_NAMES=''
PROJECT_SKILL_NAMES=''

while [ $# -gt 0 ]; do
  case "$1" in
    --hub-root) HUB_ROOT=$2; shift 2 ;;
    --project-root) PROJECT_ROOT=$2; shift 2 ;;
    --project-key) PROJECT_KEY=$2; shift 2 ;;
    --skip-rules) SKIP_RULES=1; shift ;;
    --skip-shared-skills) SKIP_SHARED_SKILLS=1; shift ;;
    --skip-project-skills) SKIP_PROJECT_SKILLS=1; shift ;;
    --skip-user-targets) SKIP_USER_TARGETS=1; shift ;;
    --skip-prompts) SKIP_PROMPTS=1; shift ;;
    --link-share-to-workspace) LINK_SHARE_TO_WORKSPACE=1; shift ;;
    --link-user-skills) LINK_USER_SKILLS=1; shift ;;
    --share-skill-names) SHARE_SKILL_NAMES=$2; shift 2 ;;
    --project-skill-names) PROJECT_SKILL_NAMES=$2; shift 2 ;;
    *) agent_fail "Unknown argument: $1" ;;
  esac
done

AGENTS_ROOT=$(agent_resolve_hub_root "$HUB_ROOT" "$SCRIPT_DIR")
RESOLVED_PROJECT_ROOT=$(agent_resolve_workspace_root "$PROJECT_ROOT" 1)
RESOLVED_PROJECT_KEY=$(agent_resolve_project_key "$PROJECT_KEY" "$RESOLVED_PROJECT_ROOT")
[ -n "$RESOLVED_PROJECT_ROOT" ] || agent_fail 'Project init requires --project-root, AGENTS_DEFAULT_PROJECT_ROOT, or running the script from the target workspace.'
[ -n "$RESOLVED_PROJECT_KEY" ] || agent_fail 'Project init requires --project-key, AGENTS_DEFAULT_PROJECT_KEY, or a workspace root whose folder name can be used as the project key.'

SYNC_RULES_SCRIPT="$SCRIPT_DIR/sync-agent-rules.sh"
SYNC_SKILLS_SCRIPT="$SCRIPT_DIR/sync-shared-skills.sh"
PROJECT_CATEGORY="projects/$RESOLVED_PROJECT_KEY"

if [ "$SKIP_RULES" != '1' ]; then
  rule_args="--hub-root $AGENTS_ROOT --project-root $RESOLVED_PROJECT_ROOT --project-key $RESOLVED_PROJECT_KEY"
  if [ "$SKIP_USER_TARGETS" = '1' ]; then
    rule_args="$rule_args --skip-user-targets"
  fi
  # shellcheck disable=SC2086
  sh "$SYNC_RULES_SCRIPT" $rule_args
fi

if [ "$SKIP_SHARED_SKILLS" != '1' ]; then
  if [ "$LINK_SHARE_TO_WORKSPACE" != '1' ]; then
    agents_cleanup_workspace_share_skill_links "$RESOLVED_PROJECT_ROOT" "$AGENTS_ROOT"
  fi
  share_args="--hub-root $AGENTS_ROOT --repo-root $RESOLVED_PROJECT_ROOT --project-key $RESOLVED_PROJECT_KEY --categories share --link-user-skills"
  if [ "$LINK_SHARE_TO_WORKSPACE" = '1' ]; then
    share_args="$share_args --link-project-skills"
  fi

  if [ -n "$SHARE_SKILL_NAMES" ]; then
    share_args="$share_args --skill-names $SHARE_SKILL_NAMES"
  fi
  # shellcheck disable=SC2086
  sh "$SYNC_SKILLS_SCRIPT" $share_args
fi

if [ "$SKIP_PROJECT_SKILLS" != '1' ]; then
  project_args="--hub-root $AGENTS_ROOT --repo-root $RESOLVED_PROJECT_ROOT --project-key $RESOLVED_PROJECT_KEY --link-project-skills --categories $PROJECT_CATEGORY"
  if [ -n "$PROJECT_SKILL_NAMES" ]; then
    project_args="$project_args --skill-names $PROJECT_SKILL_NAMES"
  fi
  # shellcheck disable=SC2086
  sh "$SYNC_SKILLS_SCRIPT" $project_args
fi

if [ "$SKIP_PROMPTS" != '1' ]; then
  prompt_args="--hub-root $AGENTS_ROOT --project-root $RESOLVED_PROJECT_ROOT --project-key $RESOLVED_PROJECT_KEY"
  # shellcheck disable=SC2086
  sh "$SCRIPT_DIR/sync-prompts.sh" $prompt_args
fi

echo "Initialized workspace: $RESOLVED_PROJECT_ROOT"
echo "Project key: $RESOLVED_PROJECT_KEY"
echo "Hub root: $AGENTS_ROOT"