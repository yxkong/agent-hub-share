# minimal-project（示例）

> **语言**：[简体中文](README.md) | [English](README.en.md)

演示**项目 private overlay** 的目录布局（无真实项目 key）。

## register-project 之后的布局

```text
my-app/                              # 你的 Git 仓库
  AGENTS.md
  .cursor/rules/00-common.mdc
  .agents/skills/                    # → hub skills/projects/my-app/*
  .agents/prompts/hub-share          # → private hub prompts/share（本 public 包不含）
  .agents/prompts/hub-project        # → private hub prompts/projects/my-app

<your-private-hub>/                  # 维护者机器上的 private hub
  rules/projects/my-app/PROJECT_RULES.md
  skills/projects/my-app/<domain-skill>/
  prompts/share/ + prompts/projects/my-app/
```

## 注册

```powershell
cd C:\path\to\my-app
pwsh -File "$env:AGENTS_HUB_ROOT\scripts\register-project.ps1" -ProjectKey my-app -SkipPrompts
```

仅 clone **agent-hub-share** 时请加 **`-SkipPrompts`**。

## 本示例文件

| 文件 | 用途 |
|------|------|
| [AGENTS.md](AGENTS.md) | 合并规则片段示例 |
| [PROJECT_RULES.md](PROJECT_RULES.md) | 领域技能名绑定示例 |

将 `my-app` 替换为你的 project key。
