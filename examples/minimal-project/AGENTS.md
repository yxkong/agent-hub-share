# my-app — Agent rules (example)

This file illustrates **project overlay** content merged on top of hub common rules.

In a real workspace, `AGENTS.md` is **generated** by:

```powershell
pwsh -File "$env:AGENTS_HUB_ROOT\scripts\sync-agent-rules.ps1" -ProjectRoot . -ProjectKey my-app
```

See hub `rules/common/COMMON_AGENT_RULES.md` for global hard constraints and skill routing table.

Project-specific increments belong in hub `rules/projects/my-app/PROJECT_RULES.md` — see [PROJECT_RULES.md](PROJECT_RULES.md).
