#!/usr/bin/env sh
set -eu

SKILL_SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
HUB_SCRIPTS_DIR=$(CDPATH='' cd -- "$SKILL_SCRIPT_DIR/../../../../scripts" && pwd -P)
SCRIPT_DIR="$HUB_SCRIPTS_DIR"
. "$HUB_SCRIPTS_DIR/agent-hub-paths.sh"

HUB_ROOT=''
REPLAY_DIR=''
INCLUDE_LEGACY=0
ALLOW_EXTERNAL_REPLAY_DIR=0

while [ $# -gt 0 ]; do
  case "$1" in
    --hub-root) HUB_ROOT=$2; shift 2 ;;
    --replay-dir) REPLAY_DIR=$2; shift 2 ;;
    --include-legacy) INCLUDE_LEGACY=1; shift ;;
    --allow-external-replay-dir) ALLOW_EXTERNAL_REPLAY_DIR=1; shift ;;
    *) agent_fail "check-replay-structure: unknown argument: $1" ;;
  esac
done

AGENTS_ROOT=$(agent_resolve_hub_root "$HUB_ROOT" "$SCRIPT_DIR")
CANONICAL_DIR="$AGENTS_ROOT/docs/resource/replay"
if [ -n "$REPLAY_DIR" ]; then
  DIR=$(agent_resolve_absolute_path "$REPLAY_DIR")
else
  DIR=$CANONICAL_DIR
fi

if [ "$ALLOW_EXTERNAL_REPLAY_DIR" -eq 0 ] && [ "$DIR" != "$CANONICAL_DIR" ]; then
  printf 'REPLAY_STRUCTURE=fail\n'
  printf 'REPLAY_VIOLATION: replay dir must be hub canonical dir: %s\n' "$CANONICAL_DIR"
  printf 'REPLAY_VIOLATION: got replay dir: %s\n' "$DIR"
  exit 1
fi

if [ ! -d "$DIR" ]; then
  printf 'REPLAY_STRUCTURE=skip (no replay dir)\n'
  exit 0
fi

required_headings='## 覆盖范围核验
## 任务边界
## 交付轨迹
## 关键决策与纠偏
## 产物与终态
## 证据与验证
## 缺口 / 未做 / 风险
## Task Replay Lite
## Release Evidence
## 后续接续清单'

failed=0
checked=0
skipped=0
OUTPUT=$(mktemp)
trap 'rm -f "$OUTPUT"' EXIT

find "$DIR" -maxdepth 1 -type f -name '*.md' | sort | while IFS= read -r file; do
  name=$(basename -- "$file")
  if ! grep -q '^replay_contract:[[:space:]]*gate5-v2[[:space:]]*$' "$file"; then
    if [ "$INCLUDE_LEGACY" -eq 0 ]; then
      printf 'REPLAY_LEGACY_SKIPPED: %s\n' "$name"
      skipped=$((skipped + 1))
      continue
    fi
    printf 'REPLAY_VIOLATION: %s: missing front matter replay_contract: gate5-v2\n' "$name"
    failed=$((failed + 1))
  fi

  checked=$((checked + 1))
  grep -q '^task_id:[[:space:]]*[^[:space:]]' "$file" || { printf 'REPLAY_VIOLATION: %s: missing front matter task_id\n' "$name"; failed=$((failed + 1)); }
  grep -q '^outcome:[[:space:]]*[^[:space:]]' "$file" || { printf 'REPLAY_VIOLATION: %s: missing front matter outcome\n' "$name"; failed=$((failed + 1)); }
  coverage=$(sed -n 's/^coverage_status:[[:space:]]*//p' "$file" | head -n 1)
  scope=$(sed -n 's/^replay_scope:[[:space:]]*//p' "$file" | head -n 1)
  case "$coverage" in
    full|partial|unknown) ;;
    '') printf 'REPLAY_VIOLATION: %s: missing front matter coverage_status\n' "$name"; failed=$((failed + 1)) ;;
    *) printf 'REPLAY_VIOLATION: %s: invalid coverage_status %s\n' "$name" "$coverage"; failed=$((failed + 1)) ;;
  esac
  if [ "$scope" = "session" ] && [ "$coverage" != "full" ]; then
    printf 'REPLAY_VIOLATION: %s: replay_scope session requires coverage_status full\n' "$name"
    failed=$((failed + 1))
  fi

  while IFS= read -r heading || [ -n "$heading" ]; do
    [ -n "$heading" ] || continue
    grep -Fq "$heading" "$file" || { printf 'REPLAY_VIOLATION: %s: missing heading %s\n' "$name" "$heading"; failed=$((failed + 1)); }
  done <<EOF
$required_headings
EOF

  grep -q 'path_guard.*pass' "$file" || { printf 'REPLAY_VIOLATION: %s: missing Path Guard pass\n' "$name"; failed=$((failed + 1)); }
  grep -q 'static / contract / runtime / user-visible / release / limitation' "$file" || { printf 'REPLAY_VIOLATION: %s: evidence table missing evidence level contract\n' "$name"; failed=$((failed + 1)); }
  grep -q '建议回填' "$file" || { printf 'REPLAY_VIOLATION: %s: Task Replay Lite missing feedback row\n' "$name"; failed=$((failed + 1)); }
done > "$OUTPUT"

cat "$OUTPUT"
if grep -q '^REPLAY_VIOLATION:' "$OUTPUT"; then
  printf 'REPLAY_STRUCTURE=fail\n'
  exit 1
fi

total=$(find "$DIR" -maxdepth 1 -type f -name '*.md' | wc -l | tr -d ' ')
skipped=$(grep -c '^REPLAY_LEGACY_SKIPPED:' "$OUTPUT" || true)
checked=$((total - skipped))
printf 'REPLAY_STRUCTURE=ok checked=%s skipped_legacy=%s\n' "$checked" "$skipped"
