# Windows 快速开始

> **语言**：[简体中文](WINDOWS.md) | [English](WINDOWS.en.md)

## 要求

- **PowerShell 7+**（`pwsh`）— `install-hub`、`check-skill-entrypoints` 等依赖 PS 7 API
- Git for Windows

验证版本：

```powershell
pwsh -NoProfile -Command '$PSVersionTable.PSVersion'
```

## 设置 AGENTS_HUB_ROOT

一次性（用户 profile）：

```powershell
# 编辑：Documents\PowerShell\Microsoft.PowerShell_profile.ps1
$env:AGENTS_HUB_ROOT = 'C:\path\to\agent-hub'
```

或当前会话：

```powershell
$env:AGENTS_HUB_ROOT = 'C:\path\to\agent-hub'
```

## 安装（先 DryRun）

```powershell
cd $env:AGENTS_HUB_ROOT\scripts
pwsh -File .\install-hub.ps1 -DryRun
pwsh -File .\install-hub.ps1
```

## Junction 与 symlink

Hub 在 Windows 上对技能目录使用 **目录 Junction**。资源管理器或 `dir /AL` 中看到 junction 是正常现象。

**不要**把项目工作区里的 `.cursor/skills/` 提交进 Git；加入 `.gitignore`。

## 验证

```powershell
pwsh -File "$env:AGENTS_HUB_ROOT\scripts\check-skill-entrypoints.ps1" -OnlyShare
pwsh -File "$env:AGENTS_HUB_ROOT\scripts\check-skill-structure.ps1" -OnlyShare
pwsh -File "$env:AGENTS_HUB_ROOT\scripts\build-skill-index.ps1"
```

## 注册项目

```powershell
cd C:\path\to\my-project
pwsh -File "$env:AGENTS_HUB_ROOT\scripts\register-project.ps1" -ProjectKey my-project -SkipPrompts
```

本 public 包无 `prompts/` 时请始终加 **`-SkipPrompts`**。

## 排障

| 现象 | 处理 |
|------|------|
| `GetRelativePath` 报错 | 使用 `pwsh`，不要用 `powershell.exe` 5.1 |
| 真实目录挡住安装 | 删除或重命名 `~\.cursor\skills\<name>`，或确认备份后使用 `-ReplaceRealDirs` |
| Junction 指向旧 hub | 重跑 `install-hub.ps1`；删除指向错误路径的 junction |

详见 [QUICKSTART.md](QUICKSTART.md)、[agent-hub-bootstrap](../../skills/share/agent-hub-bootstrap/SKILL.md)。
