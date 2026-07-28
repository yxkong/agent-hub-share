#!/usr/bin/env sh
set -eu

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
. "$SCRIPT_DIR/agent-hub-paths.sh"

REPO_ROOT=''
HUB_ROOT=''
PROJECT_KEY=''
SKILL_NAME=''
SIMPLE=0

while [ $# -gt 0 ]; do
  case "$1" in
    --repo-root) REPO_ROOT=$2; shift 2 ;;
    --hub-root) HUB_ROOT=$2; shift 2 ;;
    --project-key) PROJECT_KEY=$2; shift 2 ;;
    --skill-name) SKILL_NAME=$2; shift 2 ;;
    --simple) SIMPLE=1; shift ;;
    *) agent_fail "Unknown argument: $1" ;;
  esac
done

show_simple_row() {
  path=$1
  name=$(basename -- "$path")
  link_type=$(agent_link_type "$path")
  real_path=$(agent_real_path "$path")
  exists='False'
  skill_md='False'
  if [ -n "$real_path" ] && [ -e "$real_path" ]; then exists='True'; fi
  if [ -n "$real_path" ] && [ -f "$real_path/SKILL.md" ]; then skill_md='True'; fi

  printf 'Name     : %s\n' "$name"
  printf 'Path     : %s\n' "$path"
  printf 'LinkType : %s\n' "$link_type"
  printf 'RealPath : %s\n' "$real_path"
  printf 'Exists   : %s\n' "$exists"
  printf 'SkillMd  : %s\n' "$skill_md"
}

invoke_simple_mode() {
  current=$(pwd -P)
  logical=${PWD:-$current}

  if [ -L "$logical" ] || [ -f "$current/SKILL.md" ]; then
    show_simple_row "$logical"
    return
  fi

  printf '%-30s %-10s %-70s %-6s %-7s\n' 'Name' 'LinkType' 'RealPath' 'Exists' 'SkillMd'
  found=0
  for dir in "$current"/*; do
    [ -e "$dir" ] || continue
    [ -d "$dir" ] || [ -L "$dir" ] || continue
    found=1
    name=$(basename -- "$dir")
    link_type=$(agent_link_type "$dir")
    real_path=$(agent_real_path "$dir")
    exists='False'
    skill_md='False'
    if [ -n "$real_path" ] && [ -e "$real_path" ]; then exists='True'; fi
    if [ -n "$real_path" ] && [ -f "$real_path/SKILL.md" ]; then skill_md='True'; fi
    printf '%-30s %-10s %-70s %-6s %-7s\n' "$name" "$link_type" "$real_path" "$exists" "$skill_md"
  done
  if [ "$found" = '0' ]; then
    echo 'No subdirectories found in current directory.'
  fi
}

if [ "$SIMPLE" = '1' ] || { [ -z "$REPO_ROOT" ] && [ -z "$PROJECT_KEY" ] && [ -z "$SKILL_NAME" ]; }; then
  invoke_simple_mode
  exit 0
fi

AGENTS_ROOT=$(agent_resolve_hub_root "$HUB_ROOT" "$SCRIPT_DIR")
RESOLVED_REPO_ROOT=$(agent_resolve_workspace_root "$REPO_ROOT" 1)
RESOLVED_PROJECT_KEY=$(agent_resolve_project_key "$PROJECT_KEY" "$RESOLVED_REPO_ROOT")
[ -n "$RESOLVED_REPO_ROOT" ] || agent_fail 'check-skill-links.sh requires --repo-root, AGENTS_DEFAULT_PROJECT_ROOT, or running inside the target workspace.'
[ -n "$RESOLVED_PROJECT_KEY" ] || agent_fail 'check-skill-links.sh requires --project-key, AGENTS_DEFAULT_PROJECT_KEY, or a workspace root whose folder name can be used as the project key.'

EXPECTED_PROJECT_ROOT="$AGENTS_ROOT/skills/projects/$RESOLVED_PROJECT_KEY"
EXPECTED_SHARE_ROOT="$AGENTS_ROOT/skills/share"
EXPECTED_MEDIA_ROOT="$AGENTS_ROOT/skills/media"
EXPECTED_TOOLING_ROOT="$AGENTS_ROOT/skills/tooling"
EXPECTED_RESEARCH_ROOT="$AGENTS_ROOT/skills/research"
BAD_COUNT=0
TOTAL=0
OK=0
TMP_FILE=$(mktemp)
trap 'rm -f "$TMP_FILE"' EXIT HUP INT TERM

printf '%-50s %-30s %-10s %-24s %-12s %s\n' 'Root' 'Skill' 'LinkType' 'Status' 'SkillMdExists' 'Target'
for root in "$RESOLVED_REPO_ROOT/.agents/skills" "$RESOLVED_REPO_ROOT/.cursor/skills"; do
  [ -d "$root" ] || continue
  for dir in "$root"/*; do
    [ -e "$dir" ] || continue
    [ -d "$dir" ] || [ -L "$dir" ] || continue
    skill=$(basename -- "$dir")
    case "$skill" in source-command-*) continue ;; esac
    if [ -f "$dir/SKILL.md" ] && grep -F 'GENERATED_BY_SYNC_COMMANDS' "$dir/SKILL.md" >/dev/null 2>&1; then
      continue
    fi
    if [ -n "$SKILL_NAME" ] && [ "$skill" != "$SKILL_NAME" ]; then
      continue
    fi
    link_type=$(agent_link_type "$dir")
    target=$(agent_real_path "$dir")
    status='UNKNOWN'
    skill_md='False'
    if [ -n "$target" ] && [ -f "$target/SKILL.md" ]; then skill_md='True'; fi
    if [ ! -L "$dir" ]; then
      status='NOT_LINK'
    elif [ -z "$target" ]; then
      status='NO_TARGET'
    elif [ ! -e "$target" ]; then
      status='BROKEN'
    else
      expected_project="$EXPECTED_PROJECT_ROOT/$skill"
      expected_share="$EXPECTED_SHARE_ROOT/$skill"
      expected_media="$EXPECTED_MEDIA_ROOT/$skill"
      expected_tooling="$EXPECTED_TOOLING_ROOT/$skill"
      expected_research="$EXPECTED_RESEARCH_ROOT/$skill"
      if [ "$target" = "$expected_project" ]; then
        status='OK_PROJECT'
      elif [ "$target" = "$expected_share" ]; then
        status='OK_SHARE'
      elif [ "$target" = "$expected_media" ]; then
        status='OK_MEDIA'
      elif [ "$target" = "$expected_tooling" ]; then
        status='OK_TOOLING'
      elif [ "$target" = "$expected_research" ]; then
        status='OK_RESEARCH'
      else
        case "$target" in
          "$EXPECTED_PROJECT_ROOT"/*) status='PROJECT_MISMATCH_NAME' ;;
          "$EXPECTED_SHARE_ROOT"/*) status='SHARE_MISMATCH_NAME' ;;
          "$EXPECTED_MEDIA_ROOT"/*) status='MEDIA_MISMATCH_NAME' ;;
          "$EXPECTED_TOOLING_ROOT"/*) status='TOOLING_MISMATCH_NAME' ;;
          "$EXPECTED_RESEARCH_ROOT"/*) status='RESEARCH_MISMATCH_NAME' ;;
          *) status='OUTSIDE_HUB' ;;
        esac
      fi
    fi
    printf '%-50s %-30s %-10s %-24s %-12s %s\n' "$root" "$skill" "$link_type" "$status" "$skill_md" "$target"
    printf '%s\n' "$status" >> "$TMP_FILE"
  done
 done

while IFS= read -r status; do
  TOTAL=$((TOTAL+1))
  case "$status" in
    OK_PROJECT|OK_SHARE|OK_MEDIA|OK_TOOLING|OK_RESEARCH) OK=$((OK+1)) ;;
    *) BAD_COUNT=$((BAD_COUNT+1)) ;;
  esac
done < "$TMP_FILE"

printf '\nExpected project root: %s\n' "$EXPECTED_PROJECT_ROOT"
printf 'Expected share root:   %s\n' "$EXPECTED_SHARE_ROOT"
printf 'Expected media root:   %s\n' "$EXPECTED_MEDIA_ROOT"
printf 'Expected tooling root: %s\n' "$EXPECTED_TOOLING_ROOT"
printf 'Expected research root: %s\n\n' "$EXPECTED_RESEARCH_ROOT"
printf 'Summary: total=%s, ok=%s, bad=%s\n' "$TOTAL" "$OK" "$BAD_COUNT"
if [ "$BAD_COUNT" -eq 0 ]; then
  echo 'Result: PASS'
else
  echo 'Result: NEEDS_FIX'
  exit 1
fi
