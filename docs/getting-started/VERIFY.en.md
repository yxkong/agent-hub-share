# Verify Loaded Skills

> **Language**：[简体中文](VERIFY.md) | [English](VERIFY.en.md)

After install or refresh, use this page to confirm a **client actually loaded** skills—not only that files exist on disk.

## 1. Run repository gates first

```bash
bash scripts/check-utf8-no-bom.sh --repo-root "$AGENTS_HUB_ROOT"
bash scripts/check-skill-entrypoints.sh --hub-root "$AGENTS_HUB_ROOT" --only-share
bash scripts/check-skill-structure.sh --hub-root "$AGENTS_HUB_ROOT" --only-share
bash scripts/check-share-skill-private-coupling.sh --hub-root "$AGENTS_HUB_ROOT"
bash scripts/build-skill-index.sh --hub-root "$AGENTS_HUB_ROOT"
```

```powershell
pwsh -File "$env:AGENTS_HUB_ROOT\scripts\check-utf8-no-bom.ps1" -RepoRoot $env:AGENTS_HUB_ROOT
pwsh -File "$env:AGENTS_HUB_ROOT\scripts\check-skill-entrypoints.ps1" -HubRoot $env:AGENTS_HUB_ROOT -OnlyShare
pwsh -File "$env:AGENTS_HUB_ROOT\scripts\check-skill-structure.ps1" -HubRoot $env:AGENTS_HUB_ROOT -OnlyShare
pwsh -File "$env:AGENTS_HUB_ROOT\scripts\check-share-skill-private-coupling.ps1" -HubRoot $env:AGENTS_HUB_ROOT
pwsh -File "$env:AGENTS_HUB_ROOT\scripts\build-skill-index.ps1" -HubRoot $env:AGENTS_HUB_ROOT
```

Expected:

- `UTF8_NO_BOM=ok`
- `SKILL_ENTRYPOINTS=ok`
- `SKILL_REFERENCES_STRUCTURE=ok`
- `SHARE_SKILL_PRIVATE_COUPLING=ok`
- `SKILL_INDEX=ok items=13` (matches the public skill bundle count)

## 2. Trigger smoke tests

Send one short message per skill in your client.

| Intent | Trigger sentence | Expected skill |
|--------|------------------|----------------|
| Delivery routing | `这个需求先做什么后做什么？` | `delivery-workflow` |
| Docs backup / placement | `这个技能 README 改前要怎么备份？` | `doc-script-governance` |
| Skill review | `帮我审查这个 SKILL.md 的 trigger / eval 是否合理` | `skill-engineering` |
| TDD | `这个 bug 先补一个回归测试再修` | `tdd-workflow` |
| Browser smoke | `用浏览器验证这个页面能不能提交` | `webapp-testing` |

## 3. Success signals

Any one of these is enough:

- The client lists the loaded skill by name.
- The first reply follows the skill route and cites the expected `references/` file.
- The reply applies the expected boundary (e.g. docs backup → `doc-script-governance`).

## 4. If a trigger does not load

1. Re-run `install-hub`.
2. Project overlay: re-run `register-project` (add `-SkipPrompts` when there is no `prompts/` tree).
3. Check links:

```bash
bash scripts/check-skill-links.sh --repo-root "$PWD" --hub-root "$AGENTS_HUB_ROOT"
```

```powershell
pwsh -File "$env:AGENTS_HUB_ROOT\scripts\check-skill-links.ps1" -RepoRoot $PWD -HubRoot $env:AGENTS_HUB_ROOT
```

4. Wrong user-level targets → [WINDOWS.md](WINDOWS.md) or [MACOS_LINUX.md](MACOS_LINUX.md).
5. Gates pass but client ignores skills → [agent-hub-bootstrap](../../skills/share/agent-hub-bootstrap/SKILL.md).
