# Changelog

All notable changes to the **public share export** are documented here.

Format based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [0.1.0] - 2026-05-25

### Added

- MIT [LICENSE](LICENSE)
- Public [README.public.md](README.public.md) and getting-started docs (`QUICKSTART`, `VERIFY`, `WINDOWS`, `MACOS_LINUX`, `SHARE_SKILL_SCORECARD`)
- [CONTRIBUTING.md](CONTRIBUTING.md)
- 13 share skills with trigger/eval and open-source boundary polish
- `skills/share/index.json` via `build-skill-index`
- `scripts/export-public-share.ps1` / `.sh`（export manifest 仅 private hub，不随 public 包发布）
- [examples/minimal-project/](examples/minimal-project/) demo overlay
- GitHub CI workflow `.github/workflows/ci.yml`
- Issue / PR templates

### Changed

- Public README, package matrix, and verification flow now align to the 13-skill bundle
- Share skills decoupled from private project names, legacy docs-governance filenames, and local absolute paths
- `register-project` no longer scaffolds TODO `PROJECT_RULES.md`
- `skill-engineering` references reorganized into eval/governance/layout/review/workflow
- Shell / PowerShell entrypoint checks now emit a specific BOM failure reason before front matter parsing
- Public export and CI now include `check-share-skill-private-coupling` and `check-utf8-no-bom`

### Security

- Export forbidden-pattern scan expanded for private paths, legacy docs-governance names, and private repo markers
- `skill-discovery` external install confirmation gate documented

[0.1.0]: https://github.com/yxkong/ai-hub/releases/tag/v0.1.0
