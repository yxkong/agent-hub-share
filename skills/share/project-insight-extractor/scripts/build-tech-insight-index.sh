#!/usr/bin/env sh
set -eu

# Builds TechInsightVault/indexes/assets.index.json.
# 只扫描 01_case_library/ 和 04_methodology/（canonical asset 目录）；排除 bak/、README.md。
#
# Usage: build-tech-insight-index.sh [--hub-root DIR] [--allow-missing]
# Requires: Python 3.6+（见 agent_resolve_python3）
# 索引逻辑：scripts/python/hub_build_indices.py tech-insight
#
# canonical_id：必须在文件中显式声明（YAML front matter 或旧 **canonical_id**: 格式）。
# 缺失时默认 exit 1（fail）；传入 --allow-missing 则仅 stderr 警告并 exit 0（审计/迁移模式）。
# 重复 canonical_id → 始终 exit 1。

SKILL_SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
HUB_SCRIPTS_DIR=$(CDPATH='' cd -- "$SKILL_SCRIPT_DIR/../../../../scripts" && pwd -P)
SCRIPT_DIR="$HUB_SCRIPTS_DIR"
. "$HUB_SCRIPTS_DIR/agent-hub-paths.sh"

HUB_ROOT=''
ALLOW_MISSING=''
while [ $# -gt 0 ]; do
  case "$1" in
    --hub-root) HUB_ROOT=$2; shift 2 ;;
    --allow-missing) ALLOW_MISSING='--allow-missing'; shift ;;
    *) agent_fail "build-tech-insight-index: unknown arg: $1" ;;
  esac
done

AGENTS_ROOT=$(agent_resolve_hub_root "$HUB_ROOT" "$SCRIPT_DIR")
PY=$(agent_resolve_python3)
HUB_PY="$SCRIPT_DIR/python/hub_build_indices.py"
[ -f "$HUB_PY" ] || agent_fail "missing indexer: $HUB_PY"

VAULT_ROOT="$AGENTS_ROOT/TechInsightVault"
OUT_DIR="$VAULT_ROOT/indexes"

[ -d "$VAULT_ROOT" ] || agent_fail "TechInsightVault not found: $VAULT_ROOT"
mkdir -p "$OUT_DIR"

# shellcheck disable=SC2086
exec "$PY" "$HUB_PY" tech-insight $ALLOW_MISSING "$VAULT_ROOT"
