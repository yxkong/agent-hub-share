# Quick Start

> **Language**：[简体中文](QUICKSTART.md) | [English](QUICKSTART.en.md)

Mount share skills and pass repository gates in about five minutes.

## Prerequisites

- Git
- Windows: **PowerShell 7+** (`pwsh`) — hub scripts are not guaranteed on Windows PowerShell 5.1
- macOS / Linux: Bash

## 1. Clone and set hub root

```bash
git clone git@github.com:yxkong/agent-hub-share.git agent-hub
cd agent-hub
export AGENTS_HUB_ROOT="$PWD"
```

Windows (persist in PowerShell profile):

```powershell
$env:AGENTS_HUB_ROOT = 'C:\path\to\agent-hub'
```

## 2. Dry-run install

```bash
bash scripts/install-hub.sh --dry-run
```

```powershell
pwsh -File "$env:AGENTS_HUB_ROOT\scripts\install-hub.ps1" -DryRun
```

## 3. Install share skills (user-level)

```bash
bash scripts/install-hub.sh
```

```powershell
pwsh -File "$env:AGENTS_HUB_ROOT\scripts\install-hub.ps1"
```

Links `skills/share/*` → `~/.cursor/skills/`, `~/.claude/skills/`, `~/.codex/skills/` and syncs global rules.

> **Safety**: read [agent-hub-bootstrap](../../skills/share/agent-hub-bootstrap/references/trigger_eval.md) before `-ReplaceRealDirs`.

## 4. Verify share skills (repo gates)

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

## 5. Register a project (optional)

From your **project repo root** (use `-SkipPrompts` when this bundle has no `prompts/`):

```bash
cd /path/to/my-app
bash "$AGENTS_HUB_ROOT/scripts/register-project.sh" --project-key my-app --skip-prompts
```

```powershell
cd C:\path\to\my-app
pwsh -File "$env:AGENTS_HUB_ROOT\scripts\register-project.ps1" -ProjectKey my-app -SkipPrompts
```

Demo layout: [examples/minimal-project/](../../examples/minimal-project/)

## Verify and platforms

- Client smoke tests: [VERIFY.md](VERIFY.md)
- Bundle scorecard: [SHARE_SKILL_SCORECARD.md](SHARE_SKILL_SCORECARD.md)
- [WINDOWS.md](WINDOWS.md) · [MACOS_LINUX.md](MACOS_LINUX.md)
- Doc index: [README.md](README.md)

## Next steps

| Goal | Read |
|------|------|
| Pick skills by task | [skills/share/index.json](../../skills/share/index.json) |
| Add a share skill | [CONTRIBUTING.md](../../CONTRIBUTING.md) |
| Mount troubleshooting | [agent-hub-bootstrap](../../skills/share/agent-hub-bootstrap/SKILL.md) |
