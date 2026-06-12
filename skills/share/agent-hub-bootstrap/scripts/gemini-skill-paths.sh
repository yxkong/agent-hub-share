#!/usr/bin/env sh
set -eu

gemini_resolve_skill_alias() {
  alias_name=${1:-gemini}
  normalized=$(printf '%s' "$alias_name" | tr '[:upper:]' '[:lower:]')

  case "$normalized" in
    ''|gemini|gemini-cli|antigravity|antigravity-cli|config|反重力)
      printf '%s\n' 'gemini'
      ;;
    *)
      printf 'Unsupported Gemini skill alias: %s. Supported aliases resolve to ~/.gemini/skills.\n' "$alias_name" >&2
      return 1
      ;;
  esac
}

gemini_user_skill_root() {
  user_home=${1:-${HOME:-${USERPROFILE:-}}}
  alias_name=${2:-gemini}

  gemini_resolve_skill_alias "$alias_name" >/dev/null
  [ -n "$user_home" ] || {
    printf '%s\n' 'Unable to resolve user home for Gemini skills.' >&2
    return 1
  }

  printf '%s/.gemini/skills\n' "$user_home"
}

gemini_project_skill_root() {
  project_root=${1:-}
  [ -n "$project_root" ] || {
    printf '%s\n' 'project_root is required for project-level Gemini skill links.' >&2
    return 1
  }

  printf '%s/.agents/skills\n' "$project_root"
}
