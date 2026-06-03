# macOS / Linux 快速开始

> **语言**：[简体中文](MACOS_LINUX.md) | [English](MACOS_LINUX.en.md)

## 要求

- Bash
- Python 3.6+（`build-skill-index` 等）
- Git

## 设置 AGENTS_HUB_ROOT

```bash
export AGENTS_HUB_ROOT="$HOME/code/agent-hub"
# 持久化写入 ~/.zshrc 或 ~/.bashrc
```

## 安装（先 dry-run）

```bash
cd "$AGENTS_HUB_ROOT/scripts"
sh ./install-hub.sh --dry-run
sh ./install-hub.sh
```

Share 技能以 **symlink** 挂到 `~/.cursor/skills/`、`~/.claude/skills/`、`~/.codex/skills/`。

## 验证

```bash
sh "$AGENTS_HUB_ROOT/scripts/check-skill-entrypoints.sh" --hub-root "$AGENTS_HUB_ROOT" --only-share
sh "$AGENTS_HUB_ROOT/scripts/check-skill-structure.sh" --hub-root "$AGENTS_HUB_ROOT" --only-share
sh "$AGENTS_HUB_ROOT/scripts/build-skill-index.sh" --hub-root "$AGENTS_HUB_ROOT"
```

## 注册项目

```bash
cd ~/code/my-project
sh "$AGENTS_HUB_ROOT/scripts/register-project.sh" --project-key my-project --skip-prompts
```

## 排障

| 现象 | 处理 |
|------|------|
| symlink 权限错误 | 确认 `$AGENTS_HUB_ROOT/skills/share/` 下存在目标技能目录 |
| 脚本不可执行 | 用 `sh script.sh` 调用，勿依赖缺失的可执行位 |
| 缺 Python | 安装 Python 3.6+（完整 private hub 可用 `ensure-hub-python.sh`） |

详见 [QUICKSTART.md](QUICKSTART.md)。
