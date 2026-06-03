# Windows Quick Start

> **Language**：[简体中文](WINDOWS.md) | [English](WINDOWS.en.md)

## Requirements

- **PowerShell 7+** (`pwsh`) — required for `install-hub`, `check-skill-entrypoints`, and most hub scripts
- Git for Windows

Verify:

```powershell
pwsh -NoProfile -Command '$PSVersionTable.PSVersion'
```

## Set AGENTS_HUB_ROOT

One-time (user profile):

```powershell
# Edit: Documents\PowerShell\Microsoft.PowerShell_profile.ps1
$env:AGENTS_HUB_ROOT = 'C:\path\to\agent-hub'
```

Or per session:

```powershell
$env:AGENTS_HUB_ROOT = 'C:\path\to\agent-hub'
```

## Install (dry-run first)

```powershell
cd $env:AGENTS_HUB_ROOT\scripts
pwsh -File .\install-hub.ps1 -DryRun
pwsh -File .\install-hub.ps1
```

## Junction vs symlink

The hub uses **directory junctions** on Windows for skill mounts. Junctions in Explorer or `dir /AL` are expected—not failed symlinks.

Do **not** commit `.cursor/skills/` or `.agents/skills/` from project workspaces; add them to `.gitignore`.

## Verify

```powershell
pwsh -File "$env:AGENTS_HUB_ROOT\scripts\check-skill-entrypoints.ps1" -OnlyShare
pwsh -File "$env:AGENTS_HUB_ROOT\scripts\check-skill-structure.ps1" -OnlyShare
pwsh -File "$env:AGENTS_HUB_ROOT\scripts\build-skill-index.ps1"
```

## Register project

```powershell
cd C:\path\to\my-project
pwsh -File "$env:AGENTS_HUB_ROOT\scripts\register-project.ps1" -ProjectKey my-project -SkipPrompts
```

Always use **`-SkipPrompts`** when this public bundle has no `prompts/` tree.

## Troubleshooting

| Symptom | Action |
|---------|--------|
| `GetRelativePath` error | Use `pwsh`, not `powershell.exe` 5.1 |
| Real dir blocks install | Remove/rename `~\.cursor\skills\<name>`, or use `-ReplaceRealDirs` only after backup |
| Stale junction to old hub | Re-run `install-hub.ps1`; delete junctions pointing to wrong path |

See [QUICKSTART.md](QUICKSTART.md) and [agent-hub-bootstrap](../../skills/share/agent-hub-bootstrap/SKILL.md).
