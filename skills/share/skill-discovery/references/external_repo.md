# External Skill Repository

## 公开注册中心

**[skills.sh](https://skills.sh/)** — 主流 Agent Skills 注册中心，GitHub 托管，支持 `npx skillsadd <owner/repo>` 安装。
从注册中心安装到 hub，使用 `install-skill-from-registry.sh/.ps1`（在 `$AGENTS_HUB_ROOT/scripts/`）。

The upstream `skills` CLI repository was moved out of the shared skill directory because it is a tooling project, not a single standard skill.

## Local Location

- Repository root: `$AGENTS_HUB_ROOT/vendors/skills-cli`
- Embedded upstream skill source: `$AGENTS_HUB_ROOT/vendors/skills-cli/skills/find-skills/SKILL.md`

## Why It Was Moved

`skills/share/` should only contain standard skill directories that an agent can load directly.

The upstream repository includes:

- TypeScript source code
- tests
- CLI packaging
- agent metadata
- one embedded skill under `skills/find-skills`

That makes it a tooling repository, not a standard shared skill.

## Local Handling Rule

When an external repository contains a useful skill:

1. Keep the repository under `$AGENTS_HUB_ROOT/vendors/`（not under `skills/`）
2. Extract or adapt the actual skill into `$AGENTS_HUB_ROOT/skills/share/` or `skills/projects/<key>/`
3. Keep naming and description aligned with the local hub architecture
4. **Rewrite any hard-coded paths** to use `$AGENTS_HUB_ROOT`-relative references
5. If the repository is actually a prompt pack, workflow docs, or CLI tooling rather than a standard skill directory, keep it in `vendors/` and route the reusable content to `prompt-engineering` or `doc-script-governance`.

## Validation & Mount Closure（提取后必须验收）

提取或改写外部技能后，**必须按顺序**执行以下验收，失败则不得宣布可用：

```bash
# macOS / Linux
bash "$AGENTS_HUB_ROOT/scripts/check-skill-entrypoints.sh" --hub-root "$AGENTS_HUB_ROOT"
bash "$AGENTS_HUB_ROOT/scripts/check-skill-structure.sh" --hub-root "$AGENTS_HUB_ROOT" --skill-root <skill-dir>
bash "$AGENTS_HUB_ROOT/scripts/check-skill-size.sh" --file <skill-dir>/SKILL.md --type pure-router|router-hard|multi-domain|meta
```

```powershell
# Windows PowerShell
& "$env:AGENTS_HUB_ROOT\scripts\check-skill-entrypoints.ps1" -HubRoot $env:AGENTS_HUB_ROOT
& "$env:AGENTS_HUB_ROOT\scripts\check-skill-structure.ps1" -HubRoot $env:AGENTS_HUB_ROOT -SkillRoot @('<skill-dir>')
& "$env:AGENTS_HUB_ROOT\scripts\check-skill-size.ps1" -File '<skill-dir>\SKILL.md' -Type pure-router|router-hard|multi-domain|meta
```

全部通过后，再用 `agent-hub-bootstrap` 的安装脚本挂载到客户端目录；未通过时，保留在 `vendors/` 中，不进 `skills/`。