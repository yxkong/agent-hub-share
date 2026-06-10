#!/usr/bin/env sh
# install-hub.sh
# One-shot hub installer: links shared skills and global rules to user-level directories.
# No parameters needed - hub root is auto-detected from the script's own location.
#
# Usage (from anywhere, no env var required):
#   sh ~/agents/scripts/install-hub.sh
#   # or:
#   cd ~/agents && sh scripts/install-hub.sh
#
# What it does:
#   1. Auto-detect hub root (script lives inside hub/scripts/)
#   2. Link all shared skills -> ~/.claude/skills/, ~/.cursor/skills/, ~/.codex/skills/, ~/.agents/skills/
#   3. Sync global rules    -> ~/.claude/CLAUDE.md, ~/.codex/AGENTS.md
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

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run)      DRY_RUN=1;      shift ;;
    --skip-rules)   SKIP_RULES=1;   shift ;;
    --skip-profile) SKIP_PROFILE=1; shift ;;
    --replace-real-dirs) REPLACE_REAL_DIRS=1; shift ;;
    *) agent_fail "Unknown argument: $1" ;;
  esac
done

# Hub root auto-detected from script location (no env var needed)
AGENTS_ROOT=$(agent_resolve_hub_root '' "$SCRIPT_DIR")
USER_HOME="${HOME:-$USERPROFILE}"
SHARE_ROOT="$AGENTS_ROOT/skills/share"
MEDIA_ROOT="$AGENTS_ROOT/skills/media"
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
USER_SKILL_ROOTS="$USER_HOME/.claude/skills $USER_HOME/.cursor/skills $USER_HOME/.codex/skills $USER_HOME/.agents/skills $USER_HOME/.gemini/antigravity/skills $USER_HOME/.gemini/config/skills $USER_HOME/.antigravity/skills"

SHARE_SKILL_NAMES=$(agent_skill_names_from_root "$SHARE_ROOT")
MEDIA_SKILL_NAMES=$(agent_skill_names_from_root "$MEDIA_ROOT")

echo "=== Linking shared + media skills ==="
INSTALL_HUB_BLOCKED=0
for skill_root in $USER_SKILL_ROOTS; do
  [ "$DRY_RUN" = '0' ] && agent_ensure_dir "$skill_root"
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
SHARE_SKILL_COUNT=$(printf '%s\n' $SHARE_SKILL_NAMES | wc -l | tr -d ' ')
MEDIA_SKILL_COUNT=$(printf '%s\n' $MEDIA_SKILL_NAMES | wc -l | tr -d ' ')
echo ""

if [ "$INSTALL_HUB_BLOCKED" -gt 0 ] && [ "$DRY_RUN" = '0' ]; then
  echo "=== install-hub FAILED: $INSTALL_HUB_BLOCKED skill link(s) blocked (real directories at user skill paths). Remove, rename, or re-run with --replace-real-dirs (destructive: deletes that directory)." >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# 2. Sync global rules to user-level files
# ---------------------------------------------------------------------------
if [ "$SKIP_RULES" != '1' ]; then
  echo "=== Syncing global rules ==="
  if [ "$DRY_RUN" = '0' ]; then
    sh "$SCRIPT_DIR/sync-agent-rules.sh" --hub-root "$AGENTS_ROOT"
  else
    echo "  [DRY-RUN] Would run sync-agent-rules.sh --hub-root $AGENTS_ROOT"
  fi
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
echo "  Share skills  : $SHARE_SKILL_COUNT -> ~/.claude/skills, ~/.cursor/skills, ~/.codex/skills, ~/.agents/skills, ~/.gemini/config/skills, ~/.antigravity/skills"
echo "  Media skills  : $MEDIA_SKILL_COUNT -> ~/.claude/skills, ~/.cursor/skills, ~/.codex/skills, ~/.agents/skills, ~/.gemini/config/skills, ~/.antigravity/skills"
echo "  Next step     : cd <your-project> && sh \"$AGENTS_ROOT/scripts/register-project.sh\""
echo ""
echo "=== Done ==="
