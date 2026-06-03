# Skills Guide and How to Use the Hub

> **Language**：[简体中文](SKILLS_GUIDE.md) | [English](SKILLS_GUIDE.en.md)

What each of the **13 share skills** does, when to use it, and the shortest path from clone to daily use. Agent runtime entry is always each skill’s `SKILL.md`; this page is for **humans** choosing skills and onboarding.

## How it fits together

```text
Clone repo → set AGENTS_HUB_ROOT → install-hub (mount skills + sync global rules)
    → optional register-project (project overlay)
    → ask in your IDE in natural language → Agent routes by skill
    → run gate scripts before editing hub skills/docs (see VERIFY)
```

### Four steps

1. **Clone and set hub root** — See [QUICKSTART.md](QUICKSTART.md).
2. **Install to clients** — `scripts/install-hub` (try `--dry-run` first). Links `skills/share/*` into Cursor / Claude / Codex and syncs `COMMON_AGENT_RULES.md`.
3. **(Optional) Register a product repo** — `register-project` for `PROJECT_RULES.md` / `AGENTS.md`. Prompts stay in the private maintainer hub (no `prompts/` here).
4. **Daily work** — Delivery tasks → `delivery-workflow`; unclear task type → `agent-asset-router`; docs/SQL/skill edits → `doc-script-governance` (backup first).

### Bundles

| Bundle | Skills | For |
|--------|--------|-----|
| **Minimal** | bootstrap + delivery + doc-script | Less rework, sane docs placement |
| **Standard** | + governance + router + scorecard + biz-safety | Spec, gates, scoring, biz safety |
| **Asset Factory** | + skill/prompt engineering + discovery | Maintaining agent assets |
| **Full** | + insight + TDD + webapp-testing | Insights, tests, browser checks |

See [VERIFY.md](VERIFY.md) for smoke tests.

---

## 13 skills at a glance

| Skill | One line | Path |
|-------|----------|------|
| agent-asset-router | Route mixed tasks by target artifact | `skills/share/agent-asset-router/` |
| agent-hub-bootstrap | Install hub, fix mounts, publish skills | `skills/share/agent-hub-bootstrap/` |
| ai-development-governance | Spec/ADR/gates/scorecard bus (no app code) | `skills/share/ai-development-governance/` |
| biz-safety-audit | UGC/interaction/SMS biz safety review | `skills/share/biz-safety-audit/` |
| delivery-workflow | Delivery stage gates (default for dev work) | `skills/share/delivery-workflow/` |
| doc-script-governance | Docs/SQL placement and backup-before-edit | `skills/share/doc-script-governance/` |
| project-insight-extractor | Human-readable insights from sessions | `skills/share/project-insight-extractor/` |
| prompt-engineering | Reusable prompt / agent-task assets | `skills/share/prompt-engineering/` |
| skill-discovery | Find, compare, install skills | `skills/share/skill-discovery/` |
| skill-engineering | Author and review SKILL.md | `skills/share/skill-engineering/` |
| skill-scorecard | Dual 100-point skill/prompt review | `skills/share/skill-scorecard/` |
| tdd-workflow | Red-green-refactor TDD rhythm | `skills/share/tdd-workflow/` |
| webapp-testing | Local web black-box / Playwright smoke | `skills/share/webapp-testing/` |

---

## Per-skill intro and role

### 1. `agent-asset-router`

Routes when the ask mixes skills, docs, Spec, tests, etc. Picks the **artifact type** first, then hands off. Does not implement work itself.

**When**: Ambiguous or multi-artifact requests.

---

### 2. `agent-hub-bootstrap`

Installs this repo into IDE skill dirs, repairs links, publishes skills. SOP for `install-hub`, `register-project`, `check-skill-links`.

**When**: First setup, broken symlinks, “client cannot see skills”.

---

### 3. `ai-development-governance`

Governance vocabulary: Feature Spec, ADR, task contract, quality/security/release/rollback gates, scorecard. Sets **bars**; `delivery-workflow` sets **rhythm**.

**When**: Spec/ADR needed, pre-release gate checklist, scoring before ship.

---

### 4. `biz-safety-audit`

Business-layer safety: content, UX abuse, SMS rate limits, anti-spam—not IAM/tenant infra gates.

**When**: UGC, notifications, captcha/SMS policy reviews.

---

### 5. `delivery-workflow`

Default for almost all dev work: understand → design → minimal implement → verify → learn. Fast/Full Path, FE/BE/SQL routes, debug triad.

**When**: Features, bugs, refactors, integration, “API OK but no data”.

**Example cue**: “What should we do first for this request?”

---

### 6. `doc-script-governance`

Where `docs/` and SQL live, templates, **backup-file** before edits. Ties to delivery’s design integration gate.

**When**: Doc placement, merging plans into design canon, SQL dev/online split.

**Example cue**: “How do I backup this skill README before editing?”

---

### 7. `project-insight-extractor`

Turns debugging/refactor/review material into **human** case studies and bullets—not executable agent prompts.

**When**: Retros, interviews, vault archives.

---

### 8. `prompt-engineering`

Shapes long sub-agent instructions into versioned prompt assets (private hub `prompts/`). Not SKILL.md bodies.

**When**: agent-task extraction, prompt eval, share vs project prompt split.

---

### 9. `skill-discovery`

Find/install/compare skills; decide if a capability should become a skill. Writing SKILL bodies → skill-engineering.

**When**: “Is there a skill for X?”, registry install.

---

### 10. `skill-engineering`

Create/refactor/review skills: triggers, references layout, size gates, bad-smell registry.

**When**: New skill, trigger misfires, bloated references.

**Example cue**: “Review this SKILL.md trigger and eval.”

---

### 11. `skill-scorecard`

Dual 100-point review of skills, prompts, references, scripts, mounts; Pass/Fix gate output.

**When**: Before publishing share bundle, vetting vendor skills.

See [SHARE_SKILL_SCORECARD.md](SHARE_SKILL_SCORECARD.md).

---

### 12. `tdd-workflow`

Test-first: failing test → minimal fix → refactor with evidence. Does not replace delivery gates.

**When**: Unit/component/contract tests, regression before bugfix.

**Example cue**: “Add a regression test before fixing this bug.”

---

### 13. `webapp-testing`

Playwright-style local black-box: smoke, DOM recon, screenshots, console logs. Prefer calling existing scripts as black boxes.

**When**: Admin UI, FE integration, reproduce UI bugs.

**Example cue**: “Verify in the browser that submit works.”

---

## How skills relate

Global order lives in `rules/common/COMMON_AGENT_RULES.md` (delivery rhythm, doc-script for docs, governance for gates).

Machine index: [`skills/share/index.json`](../../skills/share/index.json).

## Next

- [QUICKSTART.md](QUICKSTART.md)  
- [VERIFY.md](VERIFY.md)  
- [README.md](../../README.md)  
