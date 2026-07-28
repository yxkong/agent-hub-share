#!/usr/bin/env sh
set -eu

gemini_resolve_skill_alias() {
  alias_name=${1:-gemini}
  normalized=$(printf '%s' "$alias_name" | tr '[:upper:]' '[:lower:]')

  case "$normalized" in
    ''|gemini|gemini-cli)
      printf '%s\n' 'gemini-cli'
      ;;
    antigravity|antigravity-ide|config|反重力)
      printf '%s\n' 'antigravity'
      ;;
    *)
      printf 'Unsupported Gemini skill alias: %s. Use gemini-cli or antigravity.\n' "$alias_name" >&2
      return 1
      ;;
  esac
}

gemini_user_skill_root() {
  user_home=${1:-${HOME:-${USERPROFILE:-}}}
  alias_name=${2:-gemini}

  resolved_alias=$(gemini_resolve_skill_alias "$alias_name")
  [ -n "$user_home" ] || {
    printf '%s\n' 'Unable to resolve user home for Gemini skills.' >&2
    return 1
  }

  if [ "$resolved_alias" = 'antigravity' ]; then
    printf '%s/.gemini/config/skills\n' "$user_home"
  else
    printf '%s/.gemini/skills\n' "$user_home"
  fi
}

gemini_user_skill_roots() {
  user_home=${1:-${HOME:-${USERPROFILE:-}}}
  gemini_user_skill_root "$user_home" gemini-cli
  gemini_user_skill_root "$user_home" antigravity
}

gemini_project_skill_root() {
  project_root=${1:-}
  [ -n "$project_root" ] || {
    printf '%s\n' 'project_root is required for project-level Gemini skill links.' >&2
    return 1
  }

  printf '%s/.agents/skills\n' "$project_root"
}
