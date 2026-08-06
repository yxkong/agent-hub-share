# Skills Guide and How to Use the Hub

> **Language**：[简体中文](SKILLS_GUIDE.md) | [English](SKILLS_GUIDE.en.md)

What each of the **14 share skills** does, when to use it, and the shortest path from clone to daily use. Agent runtime entry is always each skill’s `SKILL.md`; this page is for **humans** choosing skills and onboarding.

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
4. **Daily work** — Delivery tasks → `delivery-workflow`; ambiguous engineering artifacts → `agent-asset-router`; non-engineering projects must use their current profile; docs/SQL/skill edits → `doc-script-governance` (backup first).

### Bundles

| Bundle | Skills | For |
|--------|--------|-----|
| **Minimal** | bootstrap + delivery + doc-script | Less rework, sane docs placement |
| **Engineering Standard** | Minimal + governance + router + scorecard + biz-safety | Engineering projects only; other profiles do not mount the router |
| **Engineering Asset Factory** | Engineering Standard + skill/prompt engineering + discovery | Maintaining agent assets inside the engineering system |
| **Full** | Engineering Asset Factory + insight + TDD + webapp-testing | Engineering insights, tests, browser checks |

See [VERIFY.md](VERIFY.md) for smoke tests.

---

## 14 skills at a glance

| Skill | One line | Path |
|-------|----------|------|
| agent-asset-router | Engineering only: route ambiguous engineering artifacts | `skills/share/agent-asset-router/` |
| agent-hub-bootstrap | Install hub, fix mounts, publish skills | `skills/share/agent-hub-bootstrap/` |
| ai-development-governance | Spec/ADR/gates/scorecard bus (no app code) | `skills/share/ai-development-governance/` |
| biz-safety-audit | UGC/interaction/SMS biz safety review | `skills/share/biz-safety-audit/` |
| delivery-workflow | Delivery stage gates (default for dev work) | `skills/share/delivery-workflow/` |
| doc-script-governance | Docs/SQL placement and backup-before-edit | `skills/share/doc-script-governance/` |
| ops-bootstrap | Cross-platform server access, service templates, deployment, read-only data checks | `skills/share/ops-bootstrap/` |
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

Available only when the registered project is `project_type=engineering`. It routes ambiguous code, Spec/ADR, docs/SQL, test, replay, skill, prompt, and insight artifacts, then hands off to the owner skill. It is not mounted for generic, media, hub, or mixed projects.

**When**: The engineering artifact or owner is unclear. If project type is unknown, resolve project identity or ask the user first.

---

### 2. `agent-hub-bootstrap`

Installs this repo into IDE skill dirs, repairs links, publishes skills. SOP for `install-hub`, `register-project`, `check-skill-links`.

**When**: First setup, broken symlinks, “client cannot see skills”.

---

### 3. `ai-development-governance`

Governance vocabulary: Feature Spec, ADR, task contract, G0–G8 gates, quality/security/release/rollback/observability gates, scorecard. Sets **bars**; `delivery-workflow` sets **rhythm**. Full Path may add `context_persistence_gate.md`; cross-project contracts → `references/gates/project_contract_gate.md`.

**When**: Spec/ADR needed, pre-release gate checklist, scoring before ship, shared DB/API alignment across repos.

---

### 4. `biz-safety-audit`

Business-layer safety: content, UX abuse, SMS rate limits, anti-spam—not IAM/tenant infra gates.

**When**: UGC, notifications, captcha/SMS policy reviews.

---

### 5. `delivery-workflow`

Default for almost all dev work: understand → design → minimal implement → verify → **replay archive** → learn. Fast/Full Path, FE/BE/SQL routes, debug triad, **mainline evidence matrix** (Gate 4), **hub replay** (Gate 5), **R3 handoff** (Gate 6).

**When**: Features, bugs, refactors, integration, “API OK but no data”. Keywords like “rd audit / evidence closure / release evidence / Task Replay” → **`rd-audit`** route (`references/gates/ai_rd_closure_audit.md`).

**Example cue**: “What should we do first?” or “Audit whether this AI dev system is truly closed-loop.”

---

### 6. `doc-script-governance`

Where `docs/` and SQL live, templates, **backup-file** before edits; includes G0 brainstorm convergence template. Aligns with AGENT-GATE-CARD G4 backup gate.

**When**: Doc placement, merging plans into design canon, SQL dev/online split, brainstorm tasks needing fact/assumption/risk before convergence.

**Example cue**: “How do I backup this skill README before editing?”

---

### 7. `ops-bootstrap`

Uses a Python core with thin PowerShell / shell wrappers for SSH and server asset mapping, base-service templates, deployment orchestration, log troubleshooting, and read-only database verification.

**When**: Connect to a server, run health checks, install base services such as Nginx/MySQL/Redis, inspect abnormal logs, or verify database structure and data. It does not store real credentials, default to production mutations, or replace project deployment scripts.

---

### 8. `project-insight-extractor`

Turns debugging/refactor/review material into **human** case studies and bullets—not executable agent prompts.

**When**: Retros, interviews, vault archives.

---

### 9. `prompt-engineering`

Shapes long sub-agent instructions into versioned prompt assets (private hub `prompts/`). Not SKILL.md bodies.

**When**: agent-task extraction, prompt eval, share vs project prompt split.

---

### 10. `skill-discovery`

Find/install/compare skills; decide if a capability should become a skill. Writing SKILL bodies → skill-engineering.

**When**: “Is there a skill for X?”, registry install.

---

### 11. `skill-engineering`

Create/refactor/review skills: triggers, references layout, size gates, bad-smell registry.

**When**: New skill, trigger misfires, bloated references.

**Example cue**: “Review this SKILL.md trigger and eval.”

---

### 12. `skill-scorecard`

Dual 100-point review of skills, prompts, references, scripts, mounts; Pass/Fix gate output.

**When**: Before publishing share bundle, vetting vendor skills.

See [SHARE_SKILL_SCORECARD.md](SHARE_SKILL_SCORECARD.md).

---

### 13. `tdd-workflow`

Test-first: failing test → minimal fix → refactor with evidence. Does not replace delivery gates.

**When**: Unit/component/contract tests, regression before bugfix.

**Example cue**: “Add a regression test before fixing this bug.”

---

### 14. `webapp-testing`

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
