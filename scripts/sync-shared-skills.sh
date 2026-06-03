#!/usr/bin/env sh
set -eu

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
. "$SCRIPT_DIR/agent-hub-paths.sh"

PUBLISH_FROM_AGENT=0
PUBLISH_TO_SHARE=0
PROMOTE_TO_SHARE=0
LINK_PROJECT_SKILLS=0
LINK_USER_SKILLS=0
HUB_ROOT=''
DEFAULT_CATEGORY=''
PROJECT_KEY=''
REPO_ROOT=''
CATEGORIES=''
SKILL_NAMES=''

while [ $# -gt 0 ]; do
  case "$1" in
    --publish-from-agent) PUBLISH_FROM_AGENT=1; shift ;;
    --publish-to-share) PUBLISH_TO_SHARE=1; shift ;;
    --promote-to-share) PROMOTE_TO_SHARE=1; shift ;;
    --link-project-skills) LINK_PROJECT_SKILLS=1; shift ;;
    --link-user-skills) LINK_USER_SKILLS=1; shift ;;
    --hub-root) HUB_ROOT=$2; shift 2 ;;
    --default-category) DEFAULT_CATEGORY=$2; shift 2 ;;
    --project-key) PROJECT_KEY=$2; shift 2 ;;
    --repo-root|--workspace-root) REPO_ROOT=$2; shift 2 ;;
    --categories) CATEGORIES=$2; shift 2 ;;
    --skill-names) SKILL_NAMES=$2; shift 2 ;;
    *) agent_fail "Unknown argument: $1" ;;
  esac
done

AGENTS_ROOT=$(agent_resolve_hub_root "$HUB_ROOT" "$SCRIPT_DIR")
CENTRAL_SCRIPT="$SCRIPT_DIR/publish-skill.sh"
[ -f "$CENTRAL_SCRIPT" ] || agent_fail "Central script not found: $CENTRAL_SCRIPT"

REQUIRES_WORKSPACE=0
if [ "$PUBLISH_FROM_AGENT" = '1' ] || [ "$LINK_PROJECT_SKILLS" = '1' ] || [ -n "$REPO_ROOT" ]; then
  REQUIRES_WORKSPACE=1
fi
if [ "$REQUIRES_WORKSPACE" = '1' ]; then
  RESOLVED_REPO_ROOT=$(agent_resolve_workspace_root "$REPO_ROOT" 1)
else
  RESOLVED_REPO_ROOT=$(agent_resolve_workspace_root "$REPO_ROOT" 0)
fi
RESOLVED_PROJECT_KEY=$(agent_resolve_project_key "$PROJECT_KEY" "$RESOLVED_REPO_ROOT")
if [ -n "$DEFAULT_CATEGORY" ]; then
  RESOLVED_DEFAULT_CATEGORY=$DEFAULT_CATEGORY
elif [ -n "$RESOLVED_PROJECT_KEY" ]; then
  RESOLVED_DEFAULT_CATEGORY="projects/$RESOLVED_PROJECT_KEY"
else
  RESOLVED_DEFAULT_CATEGORY=''
fi

if { [ "$PUBLISH_FROM_AGENT" = '1' ] && [ "$PUBLISH_TO_SHARE" != '1' ]; } || [ "$PROMOTE_TO_SHARE" = '1' ] || [ "$LINK_PROJECT_SKILLS" = '1' ]; then
  [ -n "$RESOLVED_DEFAULT_CATEGORY" ] || agent_fail 'Category operations require --default-category, --project-key, AGENTS_DEFAULT_PROJECT_KEY, or a workspace root whose folder name can be used as the project key.'
fi

if { [ "$PUBLISH_FROM_AGENT" = '1' ] || [ "$LINK_PROJECT_SKILLS" = '1' ]; } && [ -z "$RESOLVED_REPO_ROOT" ]; then
  agent_fail 'Workspace operations require --repo-root, AGENTS_DEFAULT_PROJECT_ROOT, or running the script from the target workspace.'
fi

PROJECT_AGENT_SKILLS_ROOT=''
if [ -n "$RESOLVED_REPO_ROOT" ]; then
  PROJECT_AGENT_SKILLS_ROOT="$RESOLVED_REPO_ROOT/.agents/skills"
fi
SKILLS_ROOT="$AGENTS_ROOT/skills"
SHARE_ROOT="$SKILLS_ROOT/share"
MEDIA_ROOT="$SKILLS_ROOT/media"
CATEGORY_ROOT=''
if [ -n "$RESOLVED_DEFAULT_CATEGORY" ]; then
  CATEGORY_ROOT="$SKILLS_ROOT/$RESOLVED_DEFAULT_CATEGORY"
fi

resolve_names() {
  preferred=$1
  fallback_root=$2
  if [ -n "$preferred" ]; then
    printf '%s\n' "$preferred" | tr ',' '\n' | sed '/^$/d'
    return
  fi
  agent_skill_names_from_root "$fallback_root"
}

copy_skill_directory() {
  source=$1
  destination=$2
  rm -rf -- "$destination"
  mkdir -p -- "$(dirname -- "$destination")"
  cp -R "$source" "$destination"
}

if [ "$PUBLISH_FROM_AGENT" = '1' ]; then
  if [ "$PUBLISH_TO_SHARE" = '1' ]; then SCOPE='share'; else SCOPE='category'; fi
  for name in $(resolve_names "$SKILL_NAMES" "$PROJECT_AGENT_SKILLS_ROOT"); do
    publish_args="--skill-name $name --hub-root $AGENTS_ROOT --scope $SCOPE"
    if [ -n "$RESOLVED_DEFAULT_CATEGORY" ]; then
      publish_args="$publish_args --category $RESOLVED_DEFAULT_CATEGORY"
    fi
    if [ -n "$RESOLVED_REPO_ROOT" ]; then
      publish_args="$publish_args --project-root $RESOLVED_REPO_ROOT"
    fi
    if [ "$LINK_PROJECT_SKILLS" = '1' ]; then
      publish_args="$publish_args --link-project"
    fi
    if [ "$PUBLISH_TO_SHARE" = '1' ] && [ "$LINK_USER_SKILLS" = '1' ]; then
      publish_args="$publish_args --link-users"
    fi
    # shellcheck disable=SC2086
    sh "$CENTRAL_SCRIPT" $publish_args
    if [ "$PUBLISH_TO_SHARE" = '1' ]; then TARGET_ROOT="$SHARE_ROOT"; else TARGET_ROOT="$CATEGORY_ROOT"; fi
    agent_ensure_dir "$TARGET_ROOT"
    SOURCE_PATH="$PROJECT_AGENT_SKILLS_ROOT/$name"
    if [ -d "$SOURCE_PATH" ]; then
      copy_skill_directory "$SOURCE_PATH" "$TARGET_ROOT/$name"
      echo "Published $name -> $TARGET_ROOT/$name"
    fi
  done
fi

if [ "$PROMOTE_TO_SHARE" = '1' ]; then
  for name in $(resolve_names "$SKILL_NAMES" "$CATEGORY_ROOT"); do
    SOURCE_PATH="$CATEGORY_ROOT/$name"
    [ -d "$SOURCE_PATH" ] || continue
    agent_ensure_dir "$SHARE_ROOT"
    copy_skill_directory "$SOURCE_PATH" "$SHARE_ROOT/$name"
    promote_args="--skill-name $name --hub-root $AGENTS_ROOT --scope share"
    if [ -n "$RESOLVED_DEFAULT_CATEGORY" ]; then
      promote_args="$promote_args --category $RESOLVED_DEFAULT_CATEGORY"
    fi
    if [ -n "$RESOLVED_REPO_ROOT" ]; then
      promote_args="$promote_args --project-root $RESOLVED_REPO_ROOT"
    fi
    if [ "$LINK_USER_SKILLS" = '1' ]; then
      promote_args="$promote_args --link-users"
    fi
    # shellcheck disable=SC2086
    sh "$CENTRAL_SCRIPT" $promote_args
    echo "Promoted $name -> $SHARE_ROOT/$name"
  done
fi

if [ "$LINK_PROJECT_SKILLS" = '1' ]; then
  if [ -n "$CATEGORIES" ]; then
    ACTIVE_CATEGORIES=$(printf '%s\n' "$CATEGORIES" | tr ',' '\n' | sed '/^$/d')
  else
    ACTIVE_CATEGORIES=$RESOLVED_DEFAULT_CATEGORY
  fi
  printf '%s\n' "$ACTIVE_CATEGORIES" | sed '/^$/d' | while IFS= read -r category; do
    if [ "$category" = 'share' ]; then CATEGORY_PATH="$SHARE_ROOT"; else CATEGORY_PATH="$SKILLS_ROOT/$category"; fi
    for name in $(resolve_names "$SKILL_NAMES" "$CATEGORY_PATH"); do
      if [ "$category" = 'share' ]; then SCOPE='share'; else SCOPE='category'; fi
      link_args="--skill-name $name --hub-root $AGENTS_ROOT --scope $SCOPE --category $category --project-root $RESOLVED_REPO_ROOT --link-project"
      # shellcheck disable=SC2086
      sh "$CENTRAL_SCRIPT" $link_args
    done
  done
fi

if [ "$LINK_USER_SKILLS" = '1' ]; then
  for name in $(resolve_names "$SKILL_NAMES" "$SHARE_ROOT"); do
    link_user_args="--skill-name $name --hub-root $AGENTS_ROOT --scope share --link-users"
    if [ -n "$RESOLVED_DEFAULT_CATEGORY" ]; then
      link_user_args="$link_user_args --category $RESOLVED_DEFAULT_CATEGORY"
    fi
    if [ -n "$RESOLVED_REPO_ROOT" ]; then
      link_user_args="$link_user_args --project-root $RESOLVED_REPO_ROOT"
    fi
    # shellcheck disable=SC2086
    sh "$CENTRAL_SCRIPT" $link_user_args
  done

  for name in $(resolve_names "$SKILL_NAMES" "$MEDIA_ROOT"); do
    link_user_args="--skill-name $name --hub-root $AGENTS_ROOT --scope media --link-users"
    if [ -n "$RESOLVED_DEFAULT_CATEGORY" ]; then
      link_user_args="$link_user_args --category $RESOLVED_DEFAULT_CATEGORY"
    fi
    if [ -n "$RESOLVED_REPO_ROOT" ]; then
      link_user_args="$link_user_args --project-root $RESOLVED_REPO_ROOT"
    fi
    # shellcheck disable=SC2086
    sh "$CENTRAL_SCRIPT" $link_user_args
  done
fi

if [ "$PUBLISH_FROM_AGENT" != '1' ] && [ "$PROMOTE_TO_SHARE" != '1' ] && [ "$LINK_PROJECT_SKILLS" != '1' ] && [ "$LINK_USER_SKILLS" != '1' ]; then
  echo "No action selected. Use --publish-from-agent, --promote-to-share, --link-project-skills, and/or --link-user-skills. See $SCRIPT_DIR/README.md."
fi
