#!/usr/bin/env sh
set -eu

SKILL_SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
SELF_SKILL_ROOT=$(CDPATH='' cd -- "$SKILL_SCRIPT_DIR/.." && pwd -P)

HUB_ROOT=''
SKILL_NAMES=''
while [ $# -gt 0 ]; do
  case "$1" in
    --hub-root) HUB_ROOT=$2; shift 2 ;;
    --skill-name)
      SKILL_NAMES="${SKILL_NAMES}$2
"
      shift 2
      ;;
    *) printf 'check-behavior-audit: unknown argument: %s\n' "$1" >&2; exit 1 ;;
  esac
done

if [ -n "$HUB_ROOT" ]; then
  HUB_ROOT=$(CDPATH='' cd -- "$HUB_ROOT" && pwd -P)
fi
if [ -z "$SKILL_NAMES" ]; then
  if [ -n "$HUB_ROOT" ]; then
    SKILL_NAMES='delivery-workflow
ai-development-governance
skill-engineering
tdd-workflow
webapp-testing'
  else
    SKILL_NAMES='ai-development-governance'
  fi
fi

failed=0
checked=0
while IFS= read -r name || [ -n "$name" ]; do
  [ -n "$name" ] || continue
  audit_rel='references/behavior_audit.md'
  [ "$name" = 'ai-development-governance' ] &&
    audit_rel='references/governance/behavior_audit.md'
  if [ -n "$HUB_ROOT" ]; then
    skill_root="$HUB_ROOT/skills/share/$name"
  elif [ "$name" = 'ai-development-governance' ]; then
    skill_root=$SELF_SKILL_ROOT
  else
    printf 'BEHAVIOR_AUDIT_MISSING_CONTEXT=%s\n' "$name"
    failed=$((failed + 1))
    continue
  fi
  file="$skill_root/$audit_rel"
  checked=$((checked + 1))
  if [ ! -f "$file" ]; then
    printf 'BEHAVIOR_AUDIT_MISSING=%s\n' "$file"
    failed=$((failed + 1))
    continue
  fi
  file_failed=0
  for heading in '## 偏航信号' '## 反证问题' '## 闭环证据' '## 回灌动作'; do
    if ! grep -qF "$heading" "$file"; then
      printf 'BEHAVIOR_AUDIT_HEADING_MISSING=%s heading=%s\n' "$file" "$heading"
      failed=$((failed + 1))
      file_failed=1
    fi
  done
  [ "$file_failed" -ne 0 ] || printf 'ok -> %s\n' "$file"
done <<EOF
$SKILL_NAMES
EOF

if [ "$failed" -gt 0 ]; then
  printf 'BEHAVIOR_AUDIT_CHECK=fail failed=%s\n' "$failed"
  exit 1
fi
printf 'BEHAVIOR_AUDIT_CHECK=ok checked=%s\n' "$checked"
