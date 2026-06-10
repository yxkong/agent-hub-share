# Agent Hub (Share Skills)

> **Language**：[简体中文](README.md) | [English](README.en.md)

AI development governance **share skills**, **common rules**, and **gate scripts** for agent-assisted delivery.

This repo ships reusable `skills/share`, `COMMON_AGENT_RULES.md`, and script-verifiable gates (**no** `prompts/` or project-private overlays here). Not tied to one IDE; not a substitute for tests, review, or release engineering.

## Why prompts alone fail

Prompts alone do not fix:

- duplicated or drifting project rules
- missing delivery stage gates
- docs and SQL placed at random paths
- no proof that a client actually loaded a skill
- blurry boundaries between public assets and private overlays

Agent Hub closes the loop with **skills + common rules + gate scripts** (executable prompt assets are not published in this repo).

**0.2.0 highlights**: evidence closure and stage gates—mainline evidence matrix, Gate 5 replay archive, R3 handoff, rd-audit, and AGENT-GATE-CARD; see [CHANGELOG.md](CHANGELOG.md).

## What you get

| Layer | Contents |
|-------|----------|
| **Share skills (13)** | Routing, governance bus, delivery workflow, docs/SQL governance, biz safety audit, skill/prompt engineering, scorecard, TDD, browser validation |
| **Common rules** | `rules/common/COMMON_AGENT_RULES.md` only |
| **Scripts** | L1 subset required by share skills ([`scripts/README.md`](scripts/README.md)); L2 scripts ship with each skill |
| **CI / templates** | GitHub Actions plus issue/PR templates |

Project overlays (`PROJECT_RULES.md`, `AGENTS.md`, etc.) live in **your product repos**. **This README describes only what ships in this repository.**

## Five-minute quick start

```bash
git clone git@github.com:yxkong/agent-hub-share.git agent-hub
cd agent-hub
export AGENTS_HUB_ROOT="$PWD"

bash scripts/install-hub.sh --dry-run
bash scripts/check-utf8-no-bom.sh --repo-root "$AGENTS_HUB_ROOT"
bash scripts/check-skill-entrypoints.sh --hub-root "$AGENTS_HUB_ROOT" --only-share
bash scripts/check-skill-structure.sh --hub-root "$AGENTS_HUB_ROOT" --only-share
bash scripts/check-share-skill-private-coupling.sh --hub-root "$AGENTS_HUB_ROOT"
bash scripts/build-skill-index.sh --hub-root "$AGENTS_HUB_ROOT"
```

- Windows: [WINDOWS.md](docs/getting-started/WINDOWS.md)
- macOS / Linux: [MACOS_LINUX.md](docs/getting-started/MACOS_LINUX.md)
- Full flow: [QUICKSTART.md](docs/getting-started/QUICKSTART.md)
- Doc index: [docs/getting-started/README.md](docs/getting-started/README.md)

## Skill packages

| Package | Skills | Best for |
|---------|--------|----------|
| **Minimal** | `agent-hub-bootstrap` + `delivery-workflow` + `doc-script-governance` | Less rework, cleaner docs |
| **Standard** | Minimal + `ai-development-governance` + `agent-asset-router` + `skill-scorecard` + `biz-safety-audit` | Spec, gates, scorecard, biz safety |
| **Asset Factory** | Standard + `skill-engineering` + `prompt-engineering` + `skill-discovery` | Building skill/prompt assets |
| **Full** | Asset Factory + `project-insight-extractor` + `tdd-workflow` + `webapp-testing` | Insight, TDD, browser smoke |

Index: [`skills/share/index.json`](skills/share/index.json)

**Per-skill intro and how to use the hub** → [SKILLS_GUIDE.en.md](docs/getting-started/SKILLS_GUIDE.en.md) ([中文](docs/getting-started/SKILLS_GUIDE.md))

Share layer uses placeholders such as `<project-key>`; bind real names in your repo’s `PROJECT_RULES.md`.

## Usage docs (English mirror)

| Doc | Purpose |
|-----|---------|
| [SKILLS_GUIDE.en.md](docs/getting-started/SKILLS_GUIDE.en.md) | **13 skills + how to use the hub** |
| [getting-started/README.md](docs/getting-started/README.md) | Install & verify index (Chinese default) |
| [QUICKSTART.md](docs/getting-started/QUICKSTART.md) | Install, register, verify |
| [VERIFY.md](docs/getting-started/VERIFY.md) | Client load smoke tests |
| [SHARE_SKILL_SCORECARD.md](docs/getting-started/SHARE_SKILL_SCORECARD.md) | Bundle scorecard summary |
| [CONTRIBUTING.md](CONTRIBUTING.md) | Contribute share skills |
| [CHANGELOG.md](CHANGELOG.md) | Release notes |

## License

[MIT](LICENSE)
