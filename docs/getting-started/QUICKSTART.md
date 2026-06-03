# 快速开始

> **语言**：[简体中文](QUICKSTART.md) | [English](QUICKSTART.en.md)

约 5 分钟完成 share 技能挂载与仓库门禁验证。

## 前置条件

- Git
- Windows：**PowerShell 7+**（`pwsh`）；hub 脚本不保证兼容 Windows PowerShell 5.1
- macOS / Linux：Bash

## 1. 克隆并设置 hub 根

```bash
git clone git@github.com:yxkong/agent-hub-share.git agent-hub
cd agent-hub
export AGENTS_HUB_ROOT="$PWD"
```

Windows（可写入 PowerShell profile）：

```powershell
$env:AGENTS_HUB_ROOT = 'C:\path\to\agent-hub'
```

## 2. 预演安装（不写盘）

```bash
bash scripts/install-hub.sh --dry-run
```

```powershell
pwsh -File "$env:AGENTS_HUB_ROOT\scripts\install-hub.ps1" -DryRun
```

## 3. 安装 share 技能（用户级）

```bash
bash scripts/install-hub.sh
```

```powershell
pwsh -File "$env:AGENTS_HUB_ROOT\scripts\install-hub.ps1"
```

将把 `skills/share/*` 链接到 `~/.cursor/skills/`、`~/.claude/skills/`、`~/.codex/skills/`，并同步全局规则。

> **安全**：使用 `-ReplaceRealDirs` 前请先读 [agent-hub-bootstrap](../../skills/share/agent-hub-bootstrap/references/trigger_eval.md)。

## 4. 验证 share 技能（仓库门禁）

```bash
bash scripts/check-utf8-no-bom.sh --repo-root "$AGENTS_HUB_ROOT"
bash scripts/check-skill-entrypoints.sh --hub-root "$AGENTS_HUB_ROOT" --only-share
bash scripts/check-skill-structure.sh --hub-root "$AGENTS_HUB_ROOT" --only-share
bash scripts/check-share-skill-private-coupling.sh --hub-root "$AGENTS_HUB_ROOT"
bash scripts/build-skill-index.sh --hub-root "$AGENTS_HUB_ROOT"
```

```powershell
pwsh -File "$env:AGENTS_HUB_ROOT\scripts\check-utf8-no-bom.ps1" -RepoRoot $env:AGENTS_HUB_ROOT
pwsh -File "$env:AGENTS_HUB_ROOT\scripts\check-skill-entrypoints.ps1" -OnlyShare
pwsh -File "$env:AGENTS_HUB_ROOT\scripts\check-skill-structure.ps1" -OnlyShare
pwsh -File "$env:AGENTS_HUB_ROOT\scripts\check-share-skill-private-coupling.ps1"
pwsh -File "$env:AGENTS_HUB_ROOT\scripts\build-skill-index.ps1"
```

## 5. 注册项目（可选）

在**项目仓库根**执行（本仓无 `prompts/` 时请加 `-SkipPrompts`）：

```bash
cd /path/to/my-app
bash "$AGENTS_HUB_ROOT/scripts/register-project.sh" --project-key my-app --skip-prompts
```

```powershell
cd C:\path\to\my-app
pwsh -File "$env:AGENTS_HUB_ROOT\scripts\register-project.ps1" -ProjectKey my-app -SkipPrompts
```

示例布局：[examples/minimal-project/](../../examples/minimal-project/)

## 验证与平台

- 客户端触发烟测：[VERIFY.md](VERIFY.md)
- 公共包评分：[SHARE_SKILL_SCORECARD.md](SHARE_SKILL_SCORECARD.md)
- [WINDOWS.md](WINDOWS.md) · [MACOS_LINUX.md](MACOS_LINUX.md)
- 文档索引：[README.md](README.md)

## 下一步

| 目标 | 阅读 |
|------|------|
| 按任务选技能 | [skills/share/index.json](../../skills/share/index.json) |
| 新增 share 技能 | [CONTRIBUTING.md](../../CONTRIBUTING.md) |
| 挂载排障 | [agent-hub-bootstrap](../../skills/share/agent-hub-bootstrap/SKILL.md) |
