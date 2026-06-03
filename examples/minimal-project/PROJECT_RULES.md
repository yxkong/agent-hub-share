# my-app — example project rules overlay

> **Demo only.** Real projects receive `AGENTS.md` from `sync-agent-rules` (common rules + optional `PROJECT_RULES.md`).

## Domain skill routing

| Concern | Skill |
|---------|-------|
| Backend API / DDD | `<backend-domain-skill>` |
| Admin frontend | `<frontend-domain-skill>` |
| Code / design review | `<project-review-skill>` |

Bind real skill directory names here — share skills must not hard-code them.

## Docs index (optional)

- `<repo>/docs/README.md`

## Project constraints

- Example: all SQL migrations go through `doc-script-governance` dev/online split.
