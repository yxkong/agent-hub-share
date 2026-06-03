# macOS / Linux Quick Start

> **Language**：[简体中文](MACOS_LINUX.md) | [English](MACOS_LINUX.en.md)

## Requirements

- Bash
- Python 3.6+ (for `build-skill-index` and similar)
- Git

## Set AGENTS_HUB_ROOT

```bash
export AGENTS_HUB_ROOT="$HOME/code/agent-hub"
# persist in ~/.zshrc or ~/.bashrc
```

## Install (dry-run first)

```bash
cd "$AGENTS_HUB_ROOT/scripts"
sh ./install-hub.sh --dry-run
sh ./install-hub.sh
```

Share skills link to `~/.cursor/skills/`, `~/.claude/skills/`, `~/.codex/skills/` as **symlinks**.

## Verify

```bash
sh "$AGENTS_HUB_ROOT/scripts/check-skill-entrypoints.sh" --hub-root "$AGENTS_HUB_ROOT" --only-share
sh "$AGENTS_HUB_ROOT/scripts/check-skill-structure.sh" --hub-root "$AGENTS_HUB_ROOT" --only-share
sh "$AGENTS_HUB_ROOT/scripts/build-skill-index.sh" --hub-root "$AGENTS_HUB_ROOT"
```

## Register project

```bash
cd ~/code/my-project
sh "$AGENTS_HUB_ROOT/scripts/register-project.sh" --project-key my-project --skip-prompts
```

## Troubleshooting

| Symptom | Action |
|---------|--------|
| Permission denied on symlink | Ensure the skill dir exists under `$AGENTS_HUB_ROOT/skills/share/` |
| Script not executable | Run with `sh script.sh` instead of `./script.sh` if mode bit is missing |
| Python missing | Install Python 3.6+ (full private hub may use `ensure-hub-python.sh`) |

See [QUICKSTART.md](QUICKSTART.md).
