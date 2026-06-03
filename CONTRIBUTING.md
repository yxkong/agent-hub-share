# Contributing

Thanks for improving Agent Hub share skills and scripts.

## Scope

**In scope (public share):**

- `skills/share/*`
- `rules/common/COMMON_AGENT_RULES.md`（public export **仅**此文件；`PRIVATE_OVERLAY_CONTRACT.md` 等留在 private）
- hub `scripts/` 中随公开包发布的脚本子集（见 `scripts/README.md`）；其余脚本仅维护者 private hub
- `docs/getting-started/*`, `examples/*`

**Out of scope for public PRs:**

- `skills/projects/*`, `rules/projects/*`, `prompts/**`（prompt 真源与校验仅在 private hub）
- `TechInsightVault/`, private `person` assets, `docs/plan/`, `docs/review/`, `docs/guide/`, `docs/private/` (maintainer-only; not exported)

## Add or update a share skill

1. Read [skill-engineering](skills/share/skill-engineering/SKILL.md) — router vs references, size gates, trigger/eval.
2. **Backup before edit** (private hub):
   ```powershell
   pwsh -File scripts/backup-file.ps1 -FilePath skills/share/<skill>/SKILL.md
   ```
3. Edit `skills/share/<skill>/SKILL.md`; put detail in `references/`.
4. **No private bindings** in share layer — use `<frontend-domain-skill>`, `<project-key>`, `docs/guide/DOCS_GOVERNANCE.md`, not real project names or local absolute paths.
5. Run checks:
   ```powershell
   pwsh -File scripts/check-utf8-no-bom.ps1 -RepoRoot .
   pwsh -File scripts/check-skill-entrypoints.ps1
   pwsh -File scripts/check-skill-structure.ps1 -OnlyShare
   pwsh -File scripts/check-share-skill-private-coupling.ps1
   pwsh -File scripts/check-skill-size.ps1 -File skills/share/<skill>/SKILL.md -Type pure-router
   pwsh -File scripts/check-prompts.ps1
   pwsh -File scripts/build-skill-index.ps1
   ```
6. Update [skills/share/README.md](skills/share/README.md) if boundaries or skill count changed.

## Pull request checklist

- [ ] Share skill `SKILL.md` has valid front matter (`name`, `description`, closing `---`)
- [ ] No `platform-*` / real project skill names / `D:\...` paths in share paths
- [ ] No legacy docs-governance filename, private repo marker, or local absolute path in exportable assets
- [ ] `check-utf8-no-bom` passes
- [ ] `check-skill-entrypoints` passes
- [ ] `check-skill-structure --only-share` passes
- [ ] `check-share-skill-private-coupling` passes
- [ ] `build-skill-index` run if skills changed
- [ ] `skills/share/README.md` and `index.json` consistent (if applicable)

## Commit style

- One logical change per commit when possible
- Message: what + why (Chinese or English OK)
- Example: `share: add trigger_eval to skill-discovery references`

## Private hub maintainers

**Prompt assets** (not in public export): follow [prompt-engineering](skills/share/prompt-engineering/SKILL.md); place under `prompts/share/<category>/` or `prompts/projects/<key>/`; run `check-prompts` + `build-prompt-index` (see `.github/workflows/ci-private-prompts.yml`).

After merging share changes in your private hub repo:

```powershell
pwsh -File scripts/export-public-share.ps1
```

Review diff in `agent-hub-share/` before pushing public remote.

## Questions

Open an issue using the templates under `.github/ISSUE_TEMPLATE/`.
