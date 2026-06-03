# Hub Scripts (Public Export)

> **Language**：[简体中文](README.md) | [English](README.en.md)

> **Public `agent-hub-share` ships only L1 scripts required by share skills** (paired `.ps1` / `.sh`).  
> Full L1/L2 index and private-only tools live in the **private maintainer hub** `scripts/README.md`.

## Boundary

| Layer | public export | Notes |
|-------|---------------|-------|
| **L1 hub `scripts/`** | This page | install, register, mount, verify, index |
| **L2 `skills/share/<skill>/scripts/`** | Exported with skills | e.g. `doc-script-governance/scripts/backup-file.*` |
| **prompt / export / git-hooks** | Not exported | private hub only |

When there is no `prompts/` tree, use **`-SkipPrompts`** on `register-project` / `init-project-agenting`.

## Public L1 list

| Function | PowerShell | Shell |
|----------|------------|-------|
| Path resolution | `agent-hub-paths.ps1` | `agent-hub-paths.sh` |
| Fresh machine install | `install-hub.ps1` | `install-hub.sh` |
| Register project | `register-project.ps1` | `register-project.sh` |
| Full project init | `init-project-agenting.ps1` | `init-project-agenting.sh` |
| Sync rules | `sync-agent-rules.ps1` | `sync-agent-rules.sh` |
| Sync share skills | `sync-shared-skills.ps1` | `sync-shared-skills.sh` |
| Publish / remount skill | `publish-skill.ps1` | `publish-skill.sh` |
| Check skill links | `check-skill-links.ps1` | `check-skill-links.sh` |
| Fix duplicate SKILL entry | `fix-skill-entrypoints.ps1` | `fix-skill-entrypoints.sh` |
| Check SKILL entrypoints | `check-skill-entrypoints.ps1` | `check-skill-entrypoints.sh` |
| Check references topology | `check-skill-structure.ps1` | `check-skill-structure.sh` |
| Check main file size | `check-skill-size.ps1` | `check-skill-size.sh` |
| Share de-projectization | `check-share-skill-private-coupling.ps1` | `check-share-skill-private-coupling.sh` |
| UTF-8 without BOM | `check-utf8-no-bom.ps1` | `check-utf8-no-bom.sh` |
| Build skill index | `build-skill-index.ps1` | `build-skill-index.sh` |
| Find skills | `find-skills.ps1` | `find-skills.sh` |
| Install from registry | `install-skill-from-registry.ps1` | `install-skill-from-registry.sh` |
| Index builder (Python) | `python/hub_build_indices.py` | (same) |

Tiering: `skills/share/agent-hub-bootstrap/references/script_tiering.md`.
