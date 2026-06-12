# Changelog

All notable changes to the **public share export** are documented here.

Format based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added

- Command layer：`commands/share/{spec,plan,build,test,review,ship}.md`，并通过 `sync-commands` / `check-commands` 分发与校验 Cursor、Claude、Codex 入口。
- Plugin layer：`plugins/ai-rd-governance`、`plugins/skill-factory` manifest，以及 `build-plugin` / `check-plugin` / `scripts/python/build_plugin.py`，用于自有 dist 装配与 drift 检测。
- Project capability cards：Java/Python/API/observability 与前端 API/accessibility 能力卡，绑定项目事实与六类证据。
- Behavior audit：5 个核心 share skill 增加“偏航信号 / 反证问题 / 闭环证据 / 回灌动作”，并新增 `check-behavior-audit.ps1`。
- L3 Hook minimal：Cursor `afterFileEdit` 备份提醒与 Claude Code `PreToolUse` Task 派发提醒。
- Closure hardening：`check-hub-all` 一键终验、`check-hooks` Hook 配置校验、WSL/bash wrapper fallback，以及已注册外部工作区的规则、命令、Hook 分发校验。
- Shell quoting guard：新增 `check-shell-quoting`，并在公共规则与脚本索引中禁止复杂 `pwsh -Command` 内联脚本块，改用 `.ps1` + `-File`；新增 `agent-pwsh-bridge.sh` 统一 `.sh` wrapper 到 PowerShell 的参数与 WSL 路径桥接。

### Fixed

- 修复外部项目前端技能 references 跨语义子目录链接结构违规，并归档外部工程根下历史 zip 包。

## [0.2.0] - 2026-06-10

### Added

- `delivery-workflow/references/gates/`：主链证据矩阵（`mainline_evidence_matrix.md`）、Gate 5 复盘落盘（`delivery_replay.md` + `replay_body_template.md`）、R3 失败 handoff（`r3_handoff_contract.md`）、研发体系审计入口（`ai_rd_closure_audit.md`）
- `delivery-workflow` 新增 `rd-audit` 路由与 `real_collaboration_operators.md`（子 Agent 派发与协作红线）
- `ai-development-governance/references/gates/project_contract_gate.md`（跨项目 / 共享 DB·API 契约门）
- `ai-development-governance/references/context_persistence_gate.md`（Full Path 过程区、归档回灌与反迎合审查）
- `doc-script-governance/templates/TEMPLATE_BRAINSTORM_CONVERGENCE.md`（G0 头脑风暴收敛模板）
- `COMMON_AGENT_RULES.md` 嵌入 **AGENT-GATE-CARD v1**（G0–G4 零跳门禁卡：头脑风暴 / 派发 / 实现 / 验证 / 文档备份）

### Changed

- `delivery-workflow` 阶段门扩展为 Gate 1–6 + Audit：Gate 4 要求 Full Path 填写 static/contract/runtime/user-visible/release/limitation 证据；Gate 5 复盘落盘到 hub `docs/resource/replay/`；Gate 6 按 R3 handoff 路由 insight / 反模式 / prompt
- `ai-development-governance`、`doc-script-governance`、`skill-engineering`、`skill-scorecard` 联动修订：证据口径、坏味道登记、trigger eval 与 scorecard 对齐
- 公共规则与 share 技能 README / references 索引同步上述 gate 资产

### Note

- 研发体系审计（`rd-audit`）的执行 prompt 在 **private hub** `prompts/share/agent-task/` 维护，**不**随 public export 发布；public 侧以 gate 入口与读序为准。

## [0.1.1] - 2026-06-03

### Added

- Share 技能 `biz-safety-audit`（UGC / 交互 / 短信等业务侧安全审计）
- 入门文档双语拆分（`*.zh-CN.md` / `*.en.md`）；export 默认中文落盘为 `*.md`

### Changed

- `public-export.config.yaml` 与 CI 拆分 export / private-prompts 工作流
- Share 技能 `codebase-architecture` 等在 private 真源维护；是否纳入 public 白名单见 manifest `share_whitelist`

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
