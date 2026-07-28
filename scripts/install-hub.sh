#!/usr/bin/env sh
# install-hub.sh
# One-shot hub installer: links shared skills to user-level directories.
# No parameters needed - hub root is auto-detected from the script's own location.
#
# Usage (from anywhere, no env var required):
#   sh ~/agents/scripts/install-hub.sh
#   # or:
#   cd ~/agents && sh scripts/install-hub.sh
#
# What it does:
#   1. Auto-detect hub root (script lives inside hub/scripts/)
#   2. Link registry generic/global skills -> host user roots, including ~/.gemini/skills/ and ~/.gemini/config/skills/
#   3. Persist AGENTS_HUB_ROOT in shell profile
#   4. Append AGENTS_HUB_ROOT to shell profile (skip with --skip-profile)
#   5. Print a summary
#
# Optional: --replace-real-dirs 删除用户级入口下已存在的「真实 skill 目录」（含 SKILL.md）再建链（破坏性，谨慎）。
set -eu

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
. "$SCRIPT_DIR/agent-hub-paths.sh"

DRY_RUN=0
SKIP_RULES=0
SKIP_PROFILE=0
REPLACE_REAL_DIRS=0
SKIP_SHARE_SKILLS=0

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run)      DRY_RUN=1;      shift ;;
    --skip-rules)   SKIP_RULES=1;   shift ;;
    --skip-profile) SKIP_PROFILE=1; shift ;;
    --replace-real-dirs) REPLACE_REAL_DIRS=1; shift ;;
    --skip-share-skills|--skip-share) SKIP_SHARE_SKILLS=1; shift ;;
    *) agent_fail "Unknown argument: $1" ;;
  esac
done

# Hub root auto-detected from script location (no env var needed)
AGENTS_ROOT=$(agent_resolve_hub_root '' "$SCRIPT_DIR")
USER_HOME="${HOME:-$USERPROFILE}"
SHARE_ROOT="$AGENTS_ROOT/skills/share"
MEDIA_ROOT="$AGENTS_ROOT/skills/media"
PYTHON_BIN=$(agent_resolve_python3)
GEMINI_SKILL_PATHS_SCRIPT="$AGENTS_ROOT/skills/share/agent-hub-bootstrap/scripts/gemini-skill-paths.sh"
if [ -f "$GEMINI_SKILL_PATHS_SCRIPT" ]; then
  . "$GEMINI_SKILL_PATHS_SCRIPT"
  USER_GEMINI_SKILL_ROOTS=$(gemini_user_skill_roots "$USER_HOME")
else
  USER_GEMINI_SKILL_ROOTS="$USER_HOME/.gemini/skills $USER_HOME/.gemini/config/skills"
fi
if [ -f "$SCRIPT_DIR/check-skill-entrypoints.sh" ]; then
  sh "$SCRIPT_DIR/check-skill-entrypoints.sh" --hub-root "$AGENTS_ROOT"
fi

echo ""
echo "=== install-hub ==="
echo "  Hub root  : $AGENTS_ROOT"
echo "  User home : $USER_HOME"
[ "$DRY_RUN" = '1' ] && echo "  [DRY-RUN - no files will be written]"
echo ""

# ---------------------------------------------------------------------------
# 1. Link shared skills to user-level directories
# ---------------------------------------------------------------------------
USER_SKILL_ROOTS="$USER_HOME/.claude/skills $USER_HOME/.cursor/skills $USER_HOME/.codex/skills $USER_HOME/.agents/skills $USER_GEMINI_SKILL_ROOTS"

if [ "$SKIP_SHARE_SKILLS" = '1' ]; then
  SHARE_SKILL_NAMES=""
else
  SHARE_SKILL_NAMES=$("$PYTHON_BIN" "$SCRIPT_DIR/agent_hub.py" list-skills --hub-root "$AGENTS_ROOT" --project-type generic --layer share)
fi
MEDIA_SKILL_NAMES=$("$PYTHON_BIN" "$SCRIPT_DIR/agent_hub.py" list-skills --hub-root "$AGENTS_ROOT" --project-type generic --layer media)
SELECTED_USER_SKILL_NAMES="$SHARE_SKILL_NAMES
$MEDIA_SKILL_NAMES"

selected_user_skill() {
  expected=$1
  printf '%s\n' "$SELECTED_USER_SKILL_NAMES" | awk -v expected="$expected" '$0 == expected {found=1} END {exit !found}'
}

remove_stale_managed_user_skill_links() {
  skill_root=$1
  [ -d "$skill_root" ] || return 0
  for link_path in "$skill_root"/*; do
    [ -L "$link_path" ] || continue
    name=$(basename -- "$link_path")
    raw_target=$(readlink "$link_path")
    case "$raw_target" in
      /*) target_path=$raw_target ;;
      *) target_path=$(agent_resolve_absolute_path "$(dirname -- "$link_path")/$raw_target") ;;
    esac
    case "$target_path" in "$AGENTS_ROOT/skills"/*) ;; *) continue ;; esac
    if selected_user_skill "$name"; then continue; fi
    if [ "$DRY_RUN" = '1' ]; then
      printf '  [DRY-RUN] Remove stale managed skill: %s -> %s\n' "$link_path" "$target_path"
    else
      rm -f -- "$link_path"
      printf '  [REMOVED] %s -> %s\n' "$link_path" "$target_path"
    fi
  done
}

echo "=== Linking global skills ==="
INSTALL_HUB_BLOCKED=0
for skill_root in $USER_SKILL_ROOTS; do
  [ "$DRY_RUN" = '0' ] && agent_ensure_dir "$skill_root"
  remove_stale_managed_user_skill_links "$skill_root"
  for name in $SHARE_SKILL_NAMES; do
    link_path="$skill_root/$name"
    target_path="$SHARE_ROOT/$name"
    if [ "$DRY_RUN" = '1' ]; then
      printf '  [DRY-RUN] symlink: %s -> %s\n' "$link_path" "$target_path"
      continue
    fi
    target_resolved=$(agent_resolve_absolute_path "$target_path")
    if [ -e "$link_path" ] || [ -L "$link_path" ]; then
      if [ -L "$link_path" ]; then
        existing=$(agent_real_path "$link_path")
        if [ "$existing" = "$target_resolved" ]; then
          printf '  [OK] %s\n' "$link_path"
          continue
        fi
        rm -f -- "$link_path"
      elif [ -f "$link_path/SKILL.md" ]; then
        if [ "$REPLACE_REAL_DIRS" = '1' ]; then
          rm -rf -- "$link_path"
        else
          printf '  [SKIP] Real dir exists, wont overwrite: %s\n' "$link_path" >&2
          INSTALL_HUB_BLOCKED=$((INSTALL_HUB_BLOCKED + 1))
          continue
        fi
      else
        agent_fail "Path exists and is not a symlink: $link_path"
      fi
    fi
    ln -s "$target_path" "$link_path"
    printf '  [NEW] %s\n' "$link_path"
  done

  for name in $MEDIA_SKILL_NAMES; do
    link_path="$skill_root/$name"
    target_path="$MEDIA_ROOT/$name"
    if [ "$DRY_RUN" = '1' ]; then
      printf '  [DRY-RUN] symlink: %s -> %s\n' "$link_path" "$target_path"
      continue
    fi
    target_resolved=$(agent_resolve_absolute_path "$target_path")
    if [ -e "$link_path" ] || [ -L "$link_path" ]; then
      if [ -L "$link_path" ]; then
        existing=$(agent_real_path "$link_path")
        if [ "$existing" = "$target_resolved" ]; then
          printf '  [OK] %s\n' "$link_path"
          continue
        fi
        rm -f -- "$link_path"
      elif [ -f "$link_path/SKILL.md" ]; then
        if [ "$REPLACE_REAL_DIRS" = '1' ]; then
          rm -rf -- "$link_path"
        else
          printf '  [SKIP] Real dir exists, wont overwrite: %s\n' "$link_path" >&2
          INSTALL_HUB_BLOCKED=$((INSTALL_HUB_BLOCKED + 1))
          continue
        fi
      else
        agent_fail "Path exists and is not a symlink: $link_path"
      fi
    fi
    ln -s "$target_path" "$link_path"
    printf '  [NEW] %s\n' "$link_path"
  done
done
agent_count_names() {
  names=$1
  if [ -z "$names" ]; then
    printf '%s' 0
    return
  fi
  # shellcheck disable=SC2086
  set -- $names
  printf '%s' "$#"
}

SHARE_SKILL_COUNT=$(agent_count_names "$SHARE_SKILL_NAMES")
MEDIA_SKILL_COUNT=$(agent_count_names "$MEDIA_SKILL_NAMES")
echo ""

if [ "$INSTALL_HUB_BLOCKED" -gt 0 ] && [ "$DRY_RUN" = '0' ]; then
  echo "=== install-hub FAILED: $INSTALL_HUB_BLOCKED skill link(s) blocked (real directories at user skill paths). Remove, rename, or re-run with --replace-real-dirs (destructive: deletes that directory)." >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# 2. User-level rules are intentionally not synced
# ---------------------------------------------------------------------------
if [ "$SKIP_RULES" != '1' ]; then
  echo "=== User-level rules ==="
  echo "  Skipped: user-level AGENTS.md / CLAUDE.md are deprecated; project rules are synced per workspace."
  echo ""
fi

# ---------------------------------------------------------------------------
# 3. Optionally persist AGENTS_HUB_ROOT in shell profile
# ---------------------------------------------------------------------------
if [ "$SKIP_PROFILE" != '1' ] && [ "$DRY_RUN" = '0' ]; then
  # Detect shell profile: prefer .zshrc > .bash_profile > .profile
  if [ -n "${ZSH_VERSION:-}" ] || [ -f "$USER_HOME/.zshrc" ]; then
    PROFILE_FILE="$USER_HOME/.zshrc"
  elif [ -f "$USER_HOME/.bash_profile" ]; then
    PROFILE_FILE="$USER_HOME/.bash_profile"
  else
    PROFILE_FILE="$USER_HOME/.profile"
  fi

  ENV_LINE="export AGENTS_HUB_ROOT=\"$AGENTS_ROOT\""
  echo "=== Profile ==="
  if grep -q 'AGENTS_HUB_ROOT' "$PROFILE_FILE" 2>/dev/null; then
    echo "  AGENTS_HUB_ROOT already in profile: $PROFILE_FILE"
  else
    printf '\n%s\n' "$ENV_LINE" >> "$PROFILE_FILE"
    echo "  Added AGENTS_HUB_ROOT to: $PROFILE_FILE"
  fi
  export AGENTS_HUB_ROOT="$AGENTS_ROOT"
  echo ""
fi

# ---------------------------------------------------------------------------
# 4. Summary
# ---------------------------------------------------------------------------
echo "=== Summary ==="
echo "  Hub           : $AGENTS_ROOT"
echo "  Global share skills : $SHARE_SKILL_COUNT -> user roots including Gemini CLI ~/.gemini/skills and Antigravity ~/.gemini/config/skills"
echo "  Global media skills : $MEDIA_SKILL_COUNT -> user roots including Gemini CLI ~/.gemini/skills and Antigravity ~/.gemini/config/skills"
echo "  Next step     : cd <your-project> && sh \"$AGENTS_ROOT/scripts/register-project.sh\""
echo ""
echo "=== Done ==="
