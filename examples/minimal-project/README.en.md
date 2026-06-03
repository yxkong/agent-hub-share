# minimal-project (example)

> **Language**：[简体中文](README.md) | [English](README.en.md)

Demo **private overlay** layout for a registered project (no real project keys).

## Layout after register-project

```text
my-app/                              # your git repo
  AGENTS.md
  .cursor/rules/00-common.mdc
  .agents/skills/                    # → hub skills/projects/my-app/*
  .agents/prompts/hub-share          # → private hub prompts/share (not in this public bundle)
  .agents/prompts/hub-project        # → private hub prompts/projects/my-app

<your-private-hub>/                  # private maintainer hub on your machine
  rules/projects/my-app/PROJECT_RULES.md
  skills/projects/my-app/<domain-skill>/
  prompts/share/ + prompts/projects/my-app/
```

## Register

```powershell
cd C:\path\to\my-app
pwsh -File "$env:AGENTS_HUB_ROOT\scripts\register-project.ps1" -ProjectKey my-app -SkipPrompts
```

When using **agent-hub-share** only, always pass **`-SkipPrompts`**.

## Files in this example

| File | Purpose |
|------|---------|
| [AGENTS.md](AGENTS.md) | Illustrative merged rules snippet |
| [PROJECT_RULES.md](PROJECT_RULES.md) | Domain skill name bindings |

Replace `my-app` with your project key.
