#!/usr/bin/env sh
set -eu

agent_script_dir() {
  CDPATH='' cd -- "$(dirname -- "$1")" && pwd -P
}

agent_fail() {
  echo "$*" >&2
  exit 1
}

agent_ensure_dir() {
  [ -n "$1" ] || agent_fail 'agent_ensure_dir requires a path'
  mkdir -p -- "$1"
}

agent_normalize_lf_stream() {
  perl -0pe 's/\r\n?/\n/g'
}

agent_write_utf8_no_bom_file() {
  path=$1
  content=${2-}
  agent_ensure_dir "$(dirname -- "$path")"
  printf '%s' "$content" | agent_normalize_lf_stream > "$path"
}

agent_resolve_absolute_path() {
  path=$1
  if [ -e "$path" ]; then
    perl -MCwd=abs_path -e 'print abs_path(shift)' "$path"
    return
  fi

  dir=$(dirname -- "$path")
  base=$(basename -- "$path")
  if [ "$dir" = "." ]; then
    printf '%s/%s' "$(pwd -P)" "$base"
    return
  fi

  if [ -d "$dir" ]; then
    printf '%s/%s' "$(CDPATH='' cd -- "$dir" && pwd -P)" "$base"
    return
  fi

  parent=$(dirname -- "$dir")
  leaf=$(basename -- "$dir")
  if [ -d "$parent" ]; then
    printf '%s/%s/%s' "$(CDPATH='' cd -- "$parent" && pwd -P)" "$leaf" "$base"
    return
  fi

  agent_fail "Unable to resolve path: $path"
}

agent_resolve_hub_root() {
  hub_root=${1-}
  script_root=${2-}

  if [ -n "$hub_root" ]; then
    agent_resolve_absolute_path "$hub_root"
    return
  fi

  if [ -n "${AGENTS_HUB_ROOT:-}" ]; then
    agent_resolve_absolute_path "$AGENTS_HUB_ROOT"
    return
  fi

  if [ -n "$script_root" ]; then
    agent_resolve_absolute_path "$script_root/.."
    return
  fi

  agent_fail 'Unable to resolve agent hub root. Pass --hub-root, set AGENTS_HUB_ROOT, or run the script from inside the hub.'
}

agent_resolve_workspace_root() {
  workspace_root=${1-}
  allow_current=${2-0}
  candidate=''

  if [ -n "$workspace_root" ]; then
    candidate=$workspace_root
  elif [ -n "${AGENTS_DEFAULT_PROJECT_ROOT:-}" ]; then
    candidate=$AGENTS_DEFAULT_PROJECT_ROOT
  elif [ "$allow_current" = '1' ]; then
    candidate=$(pwd -P)
  fi

  if [ -z "$candidate" ]; then
    return 0
  fi

  agent_resolve_absolute_path "$candidate"
}

agent_resolve_project_key() {
  project_key=${1-}
  workspace_root=${2-}

  if [ -n "$project_key" ]; then
    printf '%s' "$project_key"
    return
  fi

  if [ -n "${AGENTS_DEFAULT_PROJECT_KEY:-}" ]; then
    printf '%s' "$AGENTS_DEFAULT_PROJECT_KEY"
    return
  fi

  if [ -n "$workspace_root" ]; then
    basename -- "$workspace_root"
    return
  fi
}

agent_link_type() {
  path=$1
  if [ -L "$path" ]; then
    printf 'Symlink'
  elif [ -d "$path" ]; then
    printf 'Directory'
  elif [ -e "$path" ]; then
    printf 'File'
  else
    printf 'Missing'
  fi
}

agent_real_path() {
  path=$1
  if [ -L "$path" ]; then
    target=$(readlink "$path")
    case "$target" in
      /*) printf '%s' "$target" ;;
      *) agent_resolve_absolute_path "$(dirname -- "$path")/$target" ;;
    esac
    return
  fi

  if [ -e "$path" ]; then
    agent_resolve_absolute_path "$path"
    return
  fi

  printf ''
}

agent_ensure_symlink() {
  link_path=$1
  target_path=$2

  agent_ensure_dir "$(dirname -- "$link_path")"
  if [ -e "$link_path" ] || [ -L "$link_path" ]; then
    if [ -L "$link_path" ]; then
      existing=$(agent_real_path "$link_path")
      if [ "$existing" = "$target_path" ]; then
        return
      fi
      rm -f -- "$link_path"
    elif [ -f "$link_path/SKILL.md" ]; then
      agent_fail "Refusing to replace real skill directory: $link_path"
    else
      agent_fail "Path exists and is not a symlink: $link_path"
    fi
  fi

  ln -s "$target_path" "$link_path"
}

agent_hub_backup_path() {
  rel=${1-}
  rel=$(printf '%s' "$rel" | tr '\\' '/')
  rel=${rel#./}
  case "$rel" in
    bak/*|*/bak/*|*/bak|bak|*bak-*|*.bak*) return 0 ;;
    *) return 1 ;;
  esac
}

agent_skill_canonical_entrypoint_rel() {
  rel=${1-}
  rel=$(printf '%s' "$rel" | tr '\\' '/')
  rel=${rel#./}
  if agent_hub_backup_path "$rel"; then
    return 1
  fi
  case "$rel" in
    skills/share/*/SKILL.md) return 0 ;;
    skills/projects/*/*/SKILL.md) return 0 ;;
    skills/media/*/SKILL.md) return 0 ;;
    *) return 1 ;;
  esac
}

agent_skill_names_from_root() {
  root=$1
  if [ ! -d "$root" ]; then
    return 0
  fi

  find "$root" -mindepth 1 -maxdepth 1 -type d ! -name 'bak' ! -name '.*' | while IFS= read -r dir; do
    if [ -f "$dir/SKILL.md" ]; then
      basename -- "$dir"
    fi
  done | sort
}

agent_canonical_skill_md_files() {
  hub_root=$1
  project_key=${2-}

  if [ -d "$hub_root/skills/share" ]; then
    find "$hub_root/skills/share" -mindepth 1 -maxdepth 1 -type d ! -name 'bak' ! -name '.*' 2>/dev/null | while IFS= read -r dir; do
      if [ -f "$dir/SKILL.md" ]; then
        rel="${dir#$hub_root/}/SKILL.md"
        if agent_skill_canonical_entrypoint_rel "$rel"; then
          printf '%s\n' "$dir/SKILL.md"
        fi
      fi
    done
  fi

  if [ -d "$hub_root/skills/media" ]; then
    find "$hub_root/skills/media" -mindepth 1 -maxdepth 1 -type d ! -name 'bak' ! -name '.*' 2>/dev/null | while IFS= read -r dir; do
      if [ -f "$dir/SKILL.md" ]; then
        rel="${dir#$hub_root/}/SKILL.md"
        if agent_skill_canonical_entrypoint_rel "$rel"; then
          printf '%s\n' "$dir/SKILL.md"
        fi
      fi
    done
  fi

  if [ -n "$project_key" ] && [ -d "$hub_root/skills/projects/$project_key" ]; then
    find "$hub_root/skills/projects/$project_key" -mindepth 1 -maxdepth 1 -type d ! -name 'bak' ! -name '.*' 2>/dev/null | while IFS= read -r dir; do
      if [ -f "$dir/SKILL.md" ]; then
        rel="${dir#$hub_root/}/SKILL.md"
        if agent_skill_canonical_entrypoint_rel "$rel"; then
          printf '%s\n' "$dir/SKILL.md"
        fi
      fi
    done
  fi
}

# True if cmd is Python 3.6+.
_agent_python3_version_ok() {
  cmd=$1
  command -v "$cmd" >/dev/null 2>&1 || return 1
  "$cmd" -c 'import sys; sys.exit(0 if sys.version_info>=(3,6) else 1)' >/dev/null 2>&1
}

# Print python3 or python launcher name to stdout, or print install hint to stderr and exit 1.
agent_resolve_python3() {
  if _agent_python3_version_ok python3; then
    printf '%s\n' python3
    return 0
  fi
  if _agent_python3_version_ok python; then
    printf '%s\n' python
    return 0
  fi
  agent_python_install_hint >&2
  exit 1
}

agent_python_install_hint() {
  printf '%s\n' \
    '需要 Python 3.6+ 才能运行本脚本（用于执行 scripts/python/hub_build_indices.py 生成 JSON 索引）。' \
    '  macOS:    brew install python3' \
    '  Windows:  若主要用 .ps1 可无 Python；若跑 .sh 请安装 https://www.python.org/downloads/windows/ 并勾选 Add python.exe to PATH' \
    '            或  winget install --id Python.Python.3.12' \
    '  自检:     sh \"$AGENTS_HUB_ROOT/scripts/ensure-hub-python.sh\"  （PowerShell: ensure-hub-python.ps1）'
}
