#!/usr/bin/env sh
set -eu

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
. "$SCRIPT_DIR/agent-hub-paths.sh"

agents_cleanup_workspace_unmanaged_skill_links() {
  project_root=$1
  hub_root=$2
  proj=$(agent_resolve_absolute_path "$project_root")
  hub=$(agent_resolve_absolute_path "$hub_root")
  share_norm=$(agent_resolve_absolute_path "$hub/skills/share")
  media_norm=$(agent_resolve_absolute_path "$hub/skills/media")
  tooling_norm=$(agent_resolve_absolute_path "$hub/skills/tooling")
  research_norm=$(agent_resolve_absolute_path "$hub/skills/research")

  for sd in "$proj/.agents/skills" "$proj/.cursor/skills" "$proj/.claude/skills"; do
    [ -d "$sd" ] || continue
    skills_abs=$(agent_resolve_absolute_path "$sd")

    for entry_path in "$skills_abs"/*; do
      [ "$entry_path" = "$skills_abs/*" ] && break
      case "$(agent_link_type "$entry_path")" in Symlink|Junction) ;; *) continue ;; esac
      resolved=$(agent_real_path "$entry_path")

      case "$resolved" in
      "$share_norm"|"$share_norm"/*|"$media_norm"|"$media_norm"/*|"$tooling_norm"|"$tooling_norm"/*|"$research_norm"|"$research_norm"/*)
        rm -f -- "$entry_path"
        printf '  [cleanup] removed stale skill symlink: %s -> %s\n' "$entry_path" "$resolved"
        ;;
      esac
    done
  done
}

# Backward-compatible alias.
agents_cleanup_workspace_share_skill_links() {
  agents_cleanup_workspace_unmanaged_skill_links "$@"
}

HUB_ROOT=''
PROJECT_ROOT=''
PROJECT_KEY=''
PROJECT_TYPE=''
SKIP_RULES=0
SKIP_SHARED_SKILLS=0
SKIP_PROJECT_SKILLS=0
SKIP_USER_TARGETS=0
SKIP_PROMPTS=0
ENABLE_PROMPTS=0
SKIP_COMMANDS=0
LINK_USER_SKILLS=0
LINK_SHARE_TO_WORKSPACE=0
SHARE_SKILL_NAMES=''
PROJECT_SKILL_NAMES=''

while [ $# -gt 0 ]; do
  case "$1" in
    --hub-root) HUB_ROOT=$2; shift 2 ;;
    --project-root) PROJECT_ROOT=$2; shift 2 ;;
    --project-key) PROJECT_KEY=$2; shift 2 ;;
    --project-type) PROJECT_TYPE=$2; shift 2 ;;
    --skip-rules) SKIP_RULES=1; shift ;;
    --skip-shared-skills) SKIP_SHARED_SKILLS=1; shift ;;
    --skip-project-skills) SKIP_PROJECT_SKILLS=1; shift ;;
    --skip-user-targets) SKIP_USER_TARGETS=1; shift ;;
    --skip-prompts) SKIP_PROMPTS=1; shift ;;
    --enable-prompts) ENABLE_PROMPTS=1; shift ;;
    --skip-commands) SKIP_COMMANDS=1; shift ;;
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
PROJECT_YAML="$AGENTS_ROOT/rules/projects/$RESOLVED_PROJECT_KEY/project.yaml"

read_project_yaml_value() {
  yaml_file=$1
  key=$2
  [ -f "$yaml_file" ] || return 0
  grep -E "^[[:space:]]*$key:" "$yaml_file" 2>/dev/null \
    | head -n 1 \
    | sed 's/^[^:]*:[[:space:]]*//' \
    | sed 's/[[:space:]]*$//' \
    | sed 's/^["'\'']//; s/["'\'']$//'
}

resolve_project_type() {
  if [ -n "$PROJECT_TYPE" ]; then
    value=$PROJECT_TYPE
  else
    value=$(read_project_yaml_value "$PROJECT_YAML" 'project_type')
  fi
  case "$value" in
    engineering|media|generic|mixed|hub) printf '%s\n' "$value" ;;
    '') printf '%s\n' 'generic' ;;
    *) agent_fail "Unsupported project_type: $value (expected engineering, media, generic, mixed, or hub)" ;;
  esac
}

RESOLVED_PROJECT_TYPE=$(resolve_project_type)

resolve_prompts_enabled() {
  if [ "$SKIP_PROMPTS" -eq 1 ] && [ "$ENABLE_PROMPTS" -eq 1 ]; then
    agent_fail 'Use only one of --skip-prompts or --enable-prompts.'
  fi
  if [ "$ENABLE_PROMPTS" -eq 1 ]; then printf '%s\n' 1; return; fi
  if [ "$SKIP_PROMPTS" -eq 1 ]; then printf '%s\n' 0; return; fi
  value=$(read_project_yaml_value "$PROJECT_YAML" prompts_enabled | tr '[:upper:]' '[:lower:]')
  case "$value" in
    ''|true|1|yes|on) printf '%s\n' 1 ;;
    false|0|no|off) printf '%s\n' 0 ;;
    *) agent_fail "Unsupported prompts_enabled value in project.yaml: $value" ;;
  esac
}

PROMPTS_ENABLED=$(resolve_prompts_enabled)
PYTHON_BIN=$(agent_resolve_python3)

registry_skill_names_csv() {
  layer=$1
  "$PYTHON_BIN" "$SCRIPT_DIR/agent_hub.py" list-skills \
    --hub-root "$AGENTS_ROOT" \
    --project-type "$RESOLVED_PROJECT_TYPE" \
    --layer "$layer" \
    | awk 'NF { if (out) out = out "," $0; else out = $0 } END { print out }'
}

if [ "$SKIP_RULES" != '1' ]; then
  rule_args="--hub-root $AGENTS_ROOT --project-root $RESOLVED_PROJECT_ROOT --project-key $RESOLVED_PROJECT_KEY"
  if [ -n "$PROJECT_TYPE" ]; then
    rule_args="$rule_args --project-type $PROJECT_TYPE"
  fi
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
  if [ -z "$SHARE_SKILL_NAMES" ]; then
    SHARE_SKILL_NAMES=$(registry_skill_names_csv share)
  fi
  MEDIA_SKILL_NAMES=$(registry_skill_names_csv media)
  TOOLING_SKILL_NAMES=$(registry_skill_names_csv tooling)
  RESEARCH_SKILL_NAMES=$(registry_skill_names_csv research)
  share_args="--hub-root $AGENTS_ROOT --repo-root $RESOLVED_PROJECT_ROOT --project-key $RESOLVED_PROJECT_KEY --categories share"
  share_args="$share_args --link-project-skills"
  if [ "$LINK_USER_SKILLS" = '1' ]; then
    share_args="$share_args --link-user-skills"
  fi

  if [ -n "$SHARE_SKILL_NAMES" ]; then
    share_args="$share_args --skill-names $SHARE_SKILL_NAMES"
    # shellcheck disable=SC2086
    sh "$SYNC_SKILLS_SCRIPT" $share_args
  fi

  if [ -n "$MEDIA_SKILL_NAMES" ]; then
    media_args="--hub-root $AGENTS_ROOT --repo-root $RESOLVED_PROJECT_ROOT --project-key $RESOLVED_PROJECT_KEY --categories media --link-project-skills"
    if [ "$LINK_USER_SKILLS" = '1' ]; then
      media_args="$media_args --link-user-skills"
    fi
    media_args="$media_args --skill-names $MEDIA_SKILL_NAMES"
    # shellcheck disable=SC2086
    sh "$SYNC_SKILLS_SCRIPT" $media_args
  fi

  if [ -n "$TOOLING_SKILL_NAMES" ]; then
    tooling_args="--hub-root $AGENTS_ROOT --repo-root $RESOLVED_PROJECT_ROOT --project-key $RESOLVED_PROJECT_KEY --categories tooling --link-project-skills"
    if [ "$LINK_USER_SKILLS" = '1' ]; then
      tooling_args="$tooling_args --link-user-skills"
    fi
    tooling_args="$tooling_args --skill-names $TOOLING_SKILL_NAMES"
    # shellcheck disable=SC2086
    sh "$SYNC_SKILLS_SCRIPT" $tooling_args
  fi

  if [ -n "$RESEARCH_SKILL_NAMES" ]; then
    research_args="--hub-root $AGENTS_ROOT --repo-root $RESOLVED_PROJECT_ROOT --project-key $RESOLVED_PROJECT_KEY --categories research --link-project-skills"
    if [ "$LINK_USER_SKILLS" = '1' ]; then
      research_args="$research_args --link-user-skills"
    fi
    research_args="$research_args --skill-names $RESEARCH_SKILL_NAMES"
    # shellcheck disable=SC2086
    sh "$SYNC_SKILLS_SCRIPT" $research_args
  fi
fi

if [ "$SKIP_PROJECT_SKILLS" != '1' ]; then
  project_args="--hub-root $AGENTS_ROOT --repo-root $RESOLVED_PROJECT_ROOT --project-key $RESOLVED_PROJECT_KEY --link-project-skills --categories $PROJECT_CATEGORY"
  if [ -n "$PROJECT_SKILL_NAMES" ]; then
    project_args="$project_args --skill-names $PROJECT_SKILL_NAMES"
  fi
  # shellcheck disable=SC2086
  sh "$SYNC_SKILLS_SCRIPT" $project_args
fi

if [ "$PROMPTS_ENABLED" = '1' ]; then
  prompt_args="--hub-root $AGENTS_ROOT --project-root $RESOLVED_PROJECT_ROOT --project-key $RESOLVED_PROJECT_KEY"
  # shellcheck disable=SC2086
  sh "$SCRIPT_DIR/sync-prompts.sh" $prompt_args
else
  sh "$SCRIPT_DIR/sync-prompts.sh" --hub-root "$AGENTS_ROOT" --project-root "$RESOLVED_PROJECT_ROOT" --project-key "$RESOLVED_PROJECT_KEY" --disable
fi

if [ "$SKIP_COMMANDS" != '1' ]; then
  command_args="--hub-root $AGENTS_ROOT --project-root $RESOLVED_PROJECT_ROOT --project-key $RESOLVED_PROJECT_KEY --project-type $RESOLVED_PROJECT_TYPE"
  if [ "$SKIP_USER_TARGETS" = '1' ]; then
    command_args="$command_args --skip-user-targets"
  fi
  # shellcheck disable=SC2086
  sh "$SCRIPT_DIR/sync-commands.sh" $command_args
fi

echo "Initialized workspace: $RESOLVED_PROJECT_ROOT"
echo "Project key: $RESOLVED_PROJECT_KEY"
echo "Project type: $RESOLVED_PROJECT_TYPE"
echo "Prompts enabled: $PROMPTS_ENABLED"
echo "Hub root: $AGENTS_ROOT"
