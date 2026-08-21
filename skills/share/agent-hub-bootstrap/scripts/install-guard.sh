#!/usr/bin/env bash
set -euo pipefail

# Install destructive command guard hooks into the current project for all supported platforms.
#
# Usage:
#   bash "$AGENTS_HUB_ROOT/skills/share/agent-hub-bootstrap/scripts/install-guard.sh"
#   bash install-guard.sh --platforms cursor,claude,codex,gemini
#   bash install-guard.sh --dry-run

SCRIPT_NAME="guard-destructive-command.py"
AUTH_SCRIPT_NAME="write-authorization-guard.py"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCE_SCRIPT="$SCRIPT_DIR/$SCRIPT_NAME"
SOURCE_AUTH_SCRIPT="$SCRIPT_DIR/$AUTH_SCRIPT_NAME"
CWD="$(pwd)"
PLATFORMS=""
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --platforms) PLATFORMS="$2"; shift 2 ;;
        --dry-run) DRY_RUN=true; shift ;;
        *) echo "Unknown arg: $1"; exit 1 ;;
    esac
done

if [[ ! -f "$SOURCE_SCRIPT" ]]; then
    echo "ERROR: Guard script not found: $SOURCE_SCRIPT"
    exit 1
fi
if [[ ! -f "$SOURCE_AUTH_SCRIPT" ]]; then
    echo "ERROR: Authorization guard script not found: $SOURCE_AUTH_SCRIPT"
    exit 1
fi

# Auto-detect platforms if not specified
if [[ -z "$PLATFORMS" ]]; then
    PLATFORMS="cursor"
    [[ -d "$CWD/.claude" ]] && PLATFORMS+=",claude"
    [[ -d "$CWD/.codex" ]] && PLATFORMS+=",codex"
    [[ -d "$CWD/.gemini" ]] && PLATFORMS+=",gemini"
fi

INSTALLED=""
SKIPPED=""

install_cursor() {
    local hooks_dir="$CWD/.cursor/hooks"
    local hooks_json="$CWD/.cursor/hooks.json"
    local dest="$hooks_dir/$SCRIPT_NAME"

    if $DRY_RUN; then
        echo "[DRY-RUN] Would install to: $dest"
        echo "[DRY-RUN] Would update: $hooks_json"
        return
    fi

    mkdir -p "$hooks_dir"
    cp "$SOURCE_SCRIPT" "$dest"

    # Merge into hooks.json (preserve existing)
    python3 -c "
import json, sys
path = '$hooks_json'
try:
    with open(path) as f:
        config = json.load(f)
except FileNotFoundError:
    config = {'version': 1, 'hooks': {}}
if 'hooks' not in config:
    config['hooks'] = {}
entry = {'command': 'python \".cursor/hooks/$SCRIPT_NAME\"', 'failClosed': True, 'timeout': 10}
existing = config['hooks'].get('beforeShellExecution', [])
if any('guard-destructive-command' in str(e.get('command','')) for e in existing):
    print('SKIP')
    sys.exit(0)
existing.append(entry)
config['hooks']['beforeShellExecution'] = existing
with open(path, 'w') as f:
    json.dump(config, f, indent=2)
print('OK')
" && INSTALLED="$INSTALLED cursor" || SKIPPED="$SKIPPED cursor(already)"
}

install_claude() {
    local hooks_dir="$CWD/.claude/hooks"
    local settings="$CWD/.claude/settings.json"
    local dest="$hooks_dir/$SCRIPT_NAME"

    if $DRY_RUN; then
        echo "[DRY-RUN] Would install to: $dest"
        echo "[DRY-RUN] Would update: $settings"
        return
    fi

    mkdir -p "$hooks_dir"
    cp "$SOURCE_SCRIPT" "$dest"

    python3 -c "
import json, sys
path = '$settings'
try:
    with open(path) as f:
        config = json.load(f)
except FileNotFoundError:
    config = {'hooks': {}}
if 'hooks' not in config:
    config['hooks'] = {}
entry = {'matcher': 'Bash', 'hooks': [{'type': 'command', 'command': 'python \".claude/hooks/$SCRIPT_NAME\"', 'timeout': 10}]}
existing = config['hooks'].get('PreToolUse', [])
if any('guard-destructive-command' in str(e.get('hooks','')) for e in existing):
    print('SKIP')
    sys.exit(0)
existing.append(entry)
config['hooks']['PreToolUse'] = existing
with open(path, 'w') as f:
    json.dump(config, f, indent=2)
print('OK')
" && INSTALLED="$INSTALLED claude" || SKIPPED="$SKIPPED claude(already)"
}

install_codex() {
    local hooks_dir="$CWD/.codex/hooks"
    local hooks_json="$CWD/.codex/hooks.json"
    local state_dir="$CWD/.codex/state/write-authorization"
    local dest="$hooks_dir/$SCRIPT_NAME"
    local auth_dest="$hooks_dir/$AUTH_SCRIPT_NAME"

    if $DRY_RUN; then
        echo "[DRY-RUN] Would install to: $dest"
        echo "[DRY-RUN] Would install to: $auth_dest"
        echo "[DRY-RUN] Would update: $hooks_json"
        return
    fi

    mkdir -p "$hooks_dir"
    mkdir -p "$state_dir"
    if [[ ! -f "$state_dir/.gitignore" ]]; then
        printf '*\n!.gitignore\n' > "$state_dir/.gitignore"
    fi
    cp "$SOURCE_SCRIPT" "$dest"
    cp "$SOURCE_AUTH_SCRIPT" "$auth_dest"

    python3 -c "
import json, sys
path = '$hooks_json'
try:
    with open(path) as f:
        config = json.load(f)
except FileNotFoundError:
    config = {'hooks': {}}
if 'hooks' not in config:
    legacy = config
    config = {'hooks': {k: legacy[k] for k in ('SessionStart', 'UserPromptSubmit', 'PreToolUse') if k in legacy}}
hooks = config['hooks']
auth_command = 'python \".codex/hooks/$AUTH_SCRIPT_NAME\"'
for event in ('SessionStart', 'UserPromptSubmit', 'PreToolUse'):
    existing = hooks.setdefault(event, [])
    if not any('write-authorization-guard' in str(e.get('hooks','')) for e in existing):
        entry = {'hooks': [{'type': 'command', 'command': auth_command, 'timeout': 10}]}
        if event == 'PreToolUse':
            entry['matcher'] = '.*'
        existing.append(entry)
existing = hooks['PreToolUse']
if not any('guard-destructive-command' in str(e.get('hooks','')) for e in existing):
    existing.append({'matcher': '^Bash\$', 'hooks': [{'type': 'command', 'command': 'python \".codex/hooks/$SCRIPT_NAME\"', 'timeout': 10}]})
with open(path, 'w') as f:
    json.dump(config, f, indent=2)
print('OK')
" && INSTALLED="$INSTALLED codex" || SKIPPED="$SKIPPED codex(failed)"
}

install_gemini() {
    local hooks_dir="$CWD/.gemini/hooks"
    local settings="$CWD/.gemini/settings.json"
    local dest="$hooks_dir/$SCRIPT_NAME"

    if $DRY_RUN; then
        echo "[DRY-RUN] Would install to: $dest"
        echo "[DRY-RUN] Would update: $settings"
        return
    fi

    mkdir -p "$hooks_dir"
    cp "$SOURCE_SCRIPT" "$dest"

    python3 -c "
import json, sys
path = '$settings'
try:
    with open(path) as f:
        config = json.load(f)
except FileNotFoundError:
    config = {'hooks': {}}
if 'hooks' not in config:
    config['hooks'] = {}
entry = {'matcher': 'run_shell_command', 'hooks': [{'type': 'command', 'command': 'python \".gemini/hooks/$SCRIPT_NAME\"', 'timeout': 10000}]}
existing = config['hooks'].get('BeforeTool', [])
if any('guard-destructive-command' in str(e.get('hooks','')) for e in existing):
    print('SKIP')
    sys.exit(0)
existing.append(entry)
config['hooks']['BeforeTool'] = existing
with open(path, 'w') as f:
    json.dump(config, f, indent=2)
print('OK')
" && INSTALLED="$INSTALLED gemini" || SKIPPED="$SKIPPED gemini(already)"
}

IFS=',' read -ra PLAT_ARRAY <<< "$PLATFORMS"
for p in "${PLAT_ARRAY[@]}"; do
    p=$(echo "$p" | xargs)
    case "$p" in
        cursor) install_cursor ;;
        claude) install_claude ;;
        codex) install_codex ;;
        gemini) install_gemini ;;
        *) echo "Unknown platform: $p" ;;
    esac
done

echo ""
echo "=== Command + Write Authorization Guard Installation ==="
[[ -n "$INSTALLED" ]] && echo "Installed: $INSTALLED"
[[ -n "$SKIPPED" ]] && echo "Skipped: $SKIPPED"
echo ""
echo "Blocked: git restore/reset/clean/stash, git checkout --, rm -rf, del -force"
echo "Destructive filter allows normal commands; Codex write gate creates one goal authorization from an explicit implementation request."
echo "Codex write gate: GOAL_AUTHORIZED for the workspace; reconfirm only for high-risk or goal-boundary changes"
