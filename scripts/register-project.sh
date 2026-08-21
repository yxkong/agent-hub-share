#!/usr/bin/env sh
# register-project.sh
# One-shot: scaffold hub project structure, validate user-level links, then run init-project-agenting.
#
# Usage:
#   export AGENTS_HUB_ROOT="$HOME/agents"
#   sh "$AGENTS_HUB_ROOT/scripts/register-project.sh" \
#       --project-root /path/to/my-project \
#       --project-key  my-project
#
# If run from inside the target project directory, --project-root can be omitted.
# --project-key defaults to the folder name of --project-root.
set -eu

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
. "$SCRIPT_DIR/agent-hub-paths.sh"

HUB_ROOT=''
PROJECT_ROOT=''
PROJECT_KEY=''
PROJECT_TYPE=''
TOOLS='codex,claude,cursor'
CONTRACT_GROUPS=''
SKILL_GROUPS=''
PROJECT_SKILLS=''
SKIP_RULES=0
SKIP_SHARED_SKILLS=0
SKIP_PROJECT_SKILLS=0
SKIP_USER_TARGETS=0
SKIP_PROMPTS=0
ENABLE_PROMPTS=0
LINK_USER_SKILLS=0
LINK_SHARE_TO_WORKSPACE=0
DRY_RUN=0

while [ $# -gt 0 ]; do
  case "$1" in
    --hub-root)           HUB_ROOT=$2;       shift 2 ;;
    --project-root)       PROJECT_ROOT=$2;   shift 2 ;;
    --project-key)        PROJECT_KEY=$2;    shift 2 ;;
    --project-type)       PROJECT_TYPE=$2;   shift 2 ;;
    --tools|--hosts)      TOOLS=$2;          shift 2 ;;
    --contract-groups)    CONTRACT_GROUPS=$2; shift 2 ;;
    --skill-groups)       SKILL_GROUPS=$2;    shift 2 ;;
    --project-skills)     PROJECT_SKILLS=$2;  shift 2 ;;
    --skip-rules)         SKIP_RULES=1;      shift   ;;
    --skip-shared-skills) SKIP_SHARED_SKILLS=1; shift ;;
    --skip-project-skills) SKIP_PROJECT_SKILLS=1; shift ;;
    --skip-user-targets)  SKIP_USER_TARGETS=1; shift  ;;
    --skip-prompts)       SKIP_PROMPTS=1;     shift   ;;
    --enable-prompts)     ENABLE_PROMPTS=1;   shift   ;;
    --link-share-to-workspace) LINK_SHARE_TO_WORKSPACE=1; shift ;;
    --link-user-skills)   LINK_USER_SKILLS=1;  shift  ;;
    --dry-run)            DRY_RUN=1;         shift   ;;
    *) agent_fail "Unknown argument: $1" ;;
  esac
done

# ---------------------------------------------------------------------------
# Resolve paths
# ---------------------------------------------------------------------------
AGENTS_ROOT=$(agent_resolve_hub_root "$HUB_ROOT" "$SCRIPT_DIR")
RESOLVED_PROJECT_ROOT=$(agent_resolve_workspace_root "$PROJECT_ROOT" 1)
RESOLVED_PROJECT_KEY=$(agent_resolve_project_key "$PROJECT_KEY" "$RESOLVED_PROJECT_ROOT")

[ -n "$RESOLVED_PROJECT_ROOT" ] || \
  agent_fail 'register-project requires --project-root, AGENTS_DEFAULT_PROJECT_ROOT, or running from inside the target workspace.'
[ -n "$RESOLVED_PROJECT_KEY" ] || \
  agent_fail 'register-project requires --project-key, AGENTS_DEFAULT_PROJECT_KEY, or a workspace root whose folder name can be used as the project key.'

case "$PROJECT_TYPE" in
  engineering|media|generic|mixed|hub|'') ;;
  *) agent_fail "Unsupported project_type: $PROJECT_TYPE (expected engineering, media, generic, mixed, or hub)" ;;
esac

echo ""
echo "=== register-project ==="
echo "  Hub root      : $AGENTS_ROOT"
echo "  Project root  : $RESOLVED_PROJECT_ROOT"
echo "  Project key   : $RESOLVED_PROJECT_KEY"
[ -n "$PROJECT_TYPE" ] && echo "  Project type  : $PROJECT_TYPE"
[ "$DRY_RUN" = '1' ] && echo "  [DRY-RUN - no files will be written]"
echo ""

# ---------------------------------------------------------------------------
# 1. Scaffold hub project structure
# ---------------------------------------------------------------------------
HUB_PROJECT_RULES_DIR="$AGENTS_ROOT/rules/projects/$RESOLVED_PROJECT_KEY"
HUB_PROJECT_SKILLS_DIR="$AGENTS_ROOT/skills/projects/$RESOLVED_PROJECT_KEY"
HUB_PROJECT_PROMPTS_DIR="$AGENTS_ROOT/prompts/projects/$RESOLVED_PROJECT_KEY"
PROMPTS_README="$HUB_PROJECT_PROMPTS_DIR/README.md"
RULES_FILE="$HUB_PROJECT_RULES_DIR/PROJECT_RULES.md"
PROJECT_YAML="$HUB_PROJECT_RULES_DIR/project.yaml"

if [ ! -d "$HUB_PROJECT_RULES_DIR" ]; then
  echo "[scaffold] Creating hub rules dir: $HUB_PROJECT_RULES_DIR"
  [ "$DRY_RUN" = '0' ] && mkdir -p "$HUB_PROJECT_RULES_DIR"
fi

# PROJECT_RULES.md is not auto-scaffolded; add it manually when the project has incremental rules.

if [ -n "$PROJECT_TYPE" ]; then
  if [ ! -f "$PROJECT_YAML" ]; then
    echo "[scaffold] Creating project type metadata: $PROJECT_YAML"
    if [ "$DRY_RUN" = '1' ]; then
      echo "[scaffold]   (dry-run) would write project_type: $PROJECT_TYPE"
    else
      case "$PROJECT_TYPE" in
        engineering) DEFAULT_WORKFLOW='delivery-workflow' ;;
        hub) DEFAULT_WORKFLOW='agent-hub-bootstrap' ;;
        *) DEFAULT_WORKFLOW='none' ;;
      esac
      cat > "$PROJECT_YAML" <<SKELETON
project_key: $RESOLVED_PROJECT_KEY
project_type: $PROJECT_TYPE
hosts: $TOOLS
projection_mode: layered
contract_groups: $CONTRACT_GROUPS
skill_groups: $SKILL_GROUPS
project_skills: $PROJECT_SKILLS
default_workflow: $DEFAULT_WORKFLOW
prompts_enabled: $(if [ "$PROJECT_TYPE" = 'media' ]; then printf false; else printf true; fi)
SKELETON
    fi
  else
    echo "[scaffold] project.yaml already exists, skipping scaffold."
  fi
else
  echo "[scaffold] project_type not provided; project.yaml will not be created. Missing type falls back to generic."
fi

if [ "$SKIP_PROMPTS" = '1' ] && [ "$ENABLE_PROMPTS" = '1' ]; then
  agent_fail 'Use only one of --skip-prompts or --enable-prompts.'
fi
if [ "$ENABLE_PROMPTS" = '1' ]; then
  PROMPTS_ENABLED=1
elif [ "$SKIP_PROMPTS" = '1' ]; then
  PROMPTS_ENABLED=0
elif [ -f "$PROJECT_YAML" ]; then
  PROMPTS_VALUE=$(awk '/^[[:space:]]*prompts_enabled[[:space:]]*:/ {sub("^[^:]*:[[:space:]]*", ""); print; exit}' "$PROJECT_YAML" | tr '[:upper:]' '[:lower:]')
  case "$PROMPTS_VALUE" in false|0|no|off) PROMPTS_ENABLED=0 ;; *) PROMPTS_ENABLED=1 ;; esac
elif [ "$PROJECT_TYPE" = 'media' ]; then
  PROMPTS_ENABLED=0
else
  PROMPTS_ENABLED=1
fi

if [ ! -d "$HUB_PROJECT_SKILLS_DIR" ]; then
  echo "[scaffold] Creating hub skills dir: $HUB_PROJECT_SKILLS_DIR"
  [ "$DRY_RUN" = '0' ] && mkdir -p "$HUB_PROJECT_SKILLS_DIR"
fi

if [ "$PROMPTS_ENABLED" = '1' ] && [ ! -d "$HUB_PROJECT_PROMPTS_DIR" ]; then
  echo "[scaffold] Creating hub project prompts dir: $HUB_PROJECT_PROMPTS_DIR"
  if [ "$DRY_RUN" = '1' ]; then
    echo "[scaffold]   (dry-run) would mkdir -p $HUB_PROJECT_PROMPTS_DIR"
  else
    mkdir -p "$HUB_PROJECT_PROMPTS_DIR"
  fi
fi

if [ "$PROMPTS_ENABLED" = '1' ] && [ ! -f "$PROMPTS_README" ]; then
  echo "[scaffold] Creating project prompts README skeleton"
  if [ "$DRY_RUN" = '1' ]; then
    echo "[scaffold]   (dry-run) would write $PROMPTS_README"
  else
    cat > "$PROMPTS_README" <<SKELETON
# $RESOLVED_PROJECT_KEY project prompts

项目专属可复用提示词放在本目录，使用文件名后缀 \`.prompt.md\`，元数据见 \`prompt-engineering\` 技能。

- 跨项目通用：hub \`prompts/share/\`
- 同步到工作区：\`sync-prompts\`（由 \`init-project-agenting\` 默认调用，可用 \`--skip-prompts\` 跳过）

## 子目录建议

可按领域分子目录（例如 \`api/\`、\`frontend/\`），不做强制要求。
SKELETON
  fi
  echo "[scaffold]   -> $PROMPTS_README"
elif [ "$PROMPTS_ENABLED" = '1' ]; then
  echo "[scaffold] project prompts README already exists, skipping scaffold."
fi

PROJECT_SKILLS_README="$HUB_PROJECT_SKILLS_DIR/README.md"
if [ ! -f "$PROJECT_SKILLS_README" ]; then
  echo "[scaffold] Creating project skills README skeleton"
  if [ "$DRY_RUN" = '1' ]; then
    echo "[scaffold]   (dry-run) would write $PROJECT_SKILLS_README"
  else
    cat > "$PROJECT_SKILLS_README" <<SKELETON
# $RESOLVED_PROJECT_KEY 项目技能

> **真源**：hub 内 skills/projects/$RESOLVED_PROJECT_KEY/
> **Agent 全局规则** → 各仓库 AGENTS.md

## 领域技能

| 技能 | 用途 |
|------|------|
| TODO | TODO |

## 本仓库 docs 域索引（可选）

<repo>/docs/guide/DOCS_GOVERNANCE.md
SKELETON
  fi
  echo "[scaffold]   -> $PROJECT_SKILLS_README"
else
  echo "[scaffold] project skills README already exists, skipping scaffold."
fi

echo ""

# ---------------------------------------------------------------------------
# 2. Validate user-level agent targets
# ---------------------------------------------------------------------------
USER_HOME="${HOME:-$USERPROFILE}"
echo "=== User-level target validation ==="
_check_path() {
  label=$1; path=$2
  if [ -e "$path" ]; then
    printf '  [OK]      %-24s %s\n' "$label" "$path"
  else
    printf '  [MISSING] %-24s %s\n' "$label" "$path"
  fi
}
_check_path "Claude skills/"     "$USER_HOME/.claude/skills"
_check_path "Cursor skills/"     "$USER_HOME/.cursor/skills"
_check_path "Codex skills/"      "$USER_HOME/.codex/skills"
echo ""

# ---------------------------------------------------------------------------
# 3. Validate project workspace targets
# ---------------------------------------------------------------------------
echo "=== Project workspace target validation ==="
_check_path "AGENTS.md"               "$RESOLVED_PROJECT_ROOT/AGENTS.md"
_check_path "CLAUDE.md"               "$RESOLVED_PROJECT_ROOT/CLAUDE.md"
_check_path ".cursorrules"            "$RESOLVED_PROJECT_ROOT/.cursorrules"
_check_path ".cursor/rules/00-common" "$RESOLVED_PROJECT_ROOT/.cursor/rules/00-common.mdc"
_check_path ".agents/skills/"         "$RESOLVED_PROJECT_ROOT/.agents/skills"
_check_path ".cursor/skills/"         "$RESOLVED_PROJECT_ROOT/.cursor/skills"
echo ""

# ---------------------------------------------------------------------------
# 4. Run init-project-agenting
# ---------------------------------------------------------------------------
if [ "$DRY_RUN" = '0' ]; then
  echo "=== Running init-project-agenting ==="
  init_args="--hub-root $AGENTS_ROOT --project-root $RESOLVED_PROJECT_ROOT --project-key $RESOLVED_PROJECT_KEY"
  [ -n "$PROJECT_TYPE" ] && init_args="$init_args --project-type $PROJECT_TYPE"
  [ -n "$TOOLS" ] && init_args="$init_args --hosts $TOOLS"
  [ "$SKIP_RULES"          = '1' ] && init_args="$init_args --skip-rules"
  [ "$SKIP_SHARED_SKILLS"  = '1' ] && init_args="$init_args --skip-shared-skills"
  [ "$SKIP_PROJECT_SKILLS" = '1' ] && init_args="$init_args --skip-project-skills"
  [ "$SKIP_USER_TARGETS"   = '1' ] && init_args="$init_args --skip-user-targets"
  [ "$SKIP_PROMPTS"        = '1' ] && init_args="$init_args --skip-prompts"
  [ "$ENABLE_PROMPTS"      = '1' ] && init_args="$init_args --enable-prompts"
  [ "$LINK_SHARE_TO_WORKSPACE" = '1' ] && init_args="$init_args --link-share-to-workspace"
  [ "$LINK_USER_SKILLS"    = '1' ] && init_args="$init_args --link-user-skills"
  # shellcheck disable=SC2086
  sh "$SCRIPT_DIR/init-project-agenting.sh" $init_args
  echo ""
fi

# ---------------------------------------------------------------------------
# 5. Hub prompts gate (full hub scan + index refresh)
# ---------------------------------------------------------------------------
if [ "$DRY_RUN" = '0' ] && [ "$PROMPTS_ENABLED" = '1' ]; then
  echo "=== Running check-prompts ==="
  sh "$SCRIPT_DIR/check-prompts.sh" --hub-root "$AGENTS_ROOT"
  echo "=== Running build-prompt-index ==="
  sh "$SCRIPT_DIR/build-prompt-index.sh" --hub-root "$AGENTS_ROOT"
  idx="$AGENTS_ROOT/prompts/indexes/prompts.index.json"
  printf '  PROMPTS_CHECK=ok index=%s\n' "$idx"
  echo ""
fi

# ---------------------------------------------------------------------------
# 6. Skill links
# ---------------------------------------------------------------------------
echo "=== Running check-skill-links ==="
if [ "$DRY_RUN" = '0' ]; then
  sh "$SCRIPT_DIR/check-skill-links.sh" \
    --repo-root "$RESOLVED_PROJECT_ROOT" \
    --hub-root  "$AGENTS_ROOT" \
    --project-key "$RESOLVED_PROJECT_KEY"
else
  echo "  [DRY-RUN] Skipped check-skill-links."
fi

echo ""
echo "=== Done ==="
echo "  Hub PROJECT_RULES : $RULES_FILE"
[ -n "$PROJECT_TYPE" ] && echo "  Hub project.yaml  : $PROJECT_YAML"
if [ "$SKIP_PROMPTS" != '1' ]; then
  echo "  Hub prompts       : $HUB_PROJECT_PROMPTS_DIR"
  echo "  Prompt index      : $AGENTS_ROOT/prompts/indexes/prompts.index.json"
  if [ "$DRY_RUN" = '0' ]; then
    echo "  WS .agents link   : $RESOLVED_PROJECT_ROOT/.agents/prompts/hub-project -> $HUB_PROJECT_PROMPTS_DIR"
    echo "  WS .cursor link   : $RESOLVED_PROJECT_ROOT/.cursor/prompts/hub-project -> $HUB_PROJECT_PROMPTS_DIR"
  fi
fi
echo "  Next step         : edit project.yaml / PROJECT_RULES.md + skills/projects/$RESOLVED_PROJECT_KEY/README.md; optional <repo>/docs/guide/DOCS_GOVERNANCE.md; then sync-agent-rules.sh"
