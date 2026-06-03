---
name: agent-hub-bootstrap
description: 初始化、修复、发布和校验 agent hub 挂载（install-hub, skill mount, junction, symlink）。适用于 register-project、publish-skill、sync-prompts、check-skill-links、Cursor/Claude/Codex 找不到技能；不负责 skill/prompt 正文质量或 docs 放置规则。
---

# Agent Hub Bootstrap

## 30 秒决策区

| 任务类型 | 什么时候选它 | 先读什么 |
|---|---|---|
| `install` | 新机器、用户级共享技能挂载、AGENTS_HUB_ROOT 初始化 | `references/workflow.md` |
| `register-project` | 新项目接入 hub、同步规则/技能/prompt | `references/workflow.md` |
| `sync` | 同步规则、共享技能、项目技能或 prompt 链接 | `references/workflow.md` |
| `diagnose` | Cursor/Claude/Codex 找不到 skill、链接失效、重复入口 | `references/trigger_eval.md` + `references/workflow.md` |
| `script-tiering` | 不确定脚本放 hub 根还是技能目录 | `references/script_tiering.md` |

## 作用边界

- 一键注册新项目到 hub：生成项目目录结构、校验用户级工具目录、再挂载规则和技能。
- 初始化已注册项目与本地 hub 的连接：同步规则、挂载共享技能、挂载项目技能、同步提示词链接、复挂单个技能、核对链接状态。
- 负责 **hub 资产的位置、挂载、校验与分发**（rules / skills / prompts），**不负责**提示词或规则正文的提炼与评测；正文质量与 eval 设计转 `prompt-engineering`；skill 正文提炼转 `skill-engineering`；技术复盘卡片转 `project-insight-extractor`。
- 不负责文档、SQL、脚本的放置策略设计；涉及备份与治理时遵循 `doc-script-governance`。
- 研发全流程（delivery + doc-script）→ **`rules/common/COMMON_AGENT_RULES.md` §研发全流程**（Agent 全局；本技能只管挂载）。

## 真实源与挂载点

- hub 内相对真源：`rules/common/`、`rules/projects/<project-key>/`、`skills/share/`、`skills/projects/<project-key>/`、`prompts/share/`、`prompts/projects/<project-key>/`（另有 `prompts/templates/`、`prompts/indexes/`；其它技能层由 maintainer hub 定义，见 `PROJECT_RULES.md`，**不在 public 文档列举**）
- 用户级入口：`~/.claude/skills/`、`~/.cursor/skills/`、`~/.codex/skills/`（**本 public 包**：`install-hub` / **`init-project-agenting`** 默认挂载 `skills/share/*`）。
- 工作区入口：**默认**在项目根仅链接 `skills/projects/<project-key>/*`，出现在 `.agents/skills/`、`.cursor/skills/`（以及 Claude Code 侧的 `.claude/skills/`）；不应把共享技能再重复接入工作区的 `.cursor/skills` / `.claude/skills`。若必须坚持「离线 / 仅存工作区」，可用 `-LinkShareToWorkspace` / `--link-share-to-workspace`。提示词仍经 `sync-prompts` 链到 `.agents/prompts/`、`.cursor/prompts/` 下的 `hub-share`、`hub-project`。
- 不要把真实 skill 长期维护在工作区入口目录里；提示词真实源同样在 hub，工作区仅链接。
- 一个 skill 目录只能有一个根 `SKILL.md`（canonical 路径见 `skill-engineering/references/layout/skill_truth_source_contract.md`）；`bak/`、dated 快照中**禁止**保留名为 `SKILL.md` 的文件；`check-skill-entrypoints` 对违规 fail，`find-skills` 只列 canonical。

## 默认动作（推荐顺序）

| 场景 | 脚本 |
|---|---|
| **新机器**：安装 hub 本身，链接共享技能到用户目录 | `install-hub.ps1` / `install-hub.sh` |
| **全新项目**：注册到 hub + 挂载所有内容 | `register-project.ps1` / `register-project.sh` |
| 已注册项目重新全量初始化 | `init-project-agenting.ps1` / `.sh` |
| 只同步规则 | `sync-agent-rules.ps1` / `.sh` |
| 只挂载技能 | `sync-shared-skills.ps1` / `.sh` |
| 同步提示词链接（hub → 工作区） | `sync-prompts.ps1` / `.sh` |
| 校验 `*.prompt.md` 元数据与安全问题 | `check-prompts.ps1` / `.sh` |
| 生成 `prompts/indexes/prompts.index.json` | `build-prompt-index.ps1` / `.sh` |
| 复挂单个技能 | `publish-skill.ps1` / `.sh`（hub 内须已存在 `SKILL.md`；仅有意脚手架时加 `-CreateIfMissing` / `--create-if-missing`） |
| 校验链接结果 | `check-skill-links.ps1` / `.sh` |
| 校验重复技能入口 | `check-skill-entrypoints.ps1` / `.sh` |
| 校验 references 拓扑（顶层 `*.md` 数量、语义子目录深度） | `check-skill-structure.ps1` / `.sh` |
| 统计主文件非空行 / 行数门禁 | `check-skill-size.ps1` / `.sh` |
| 修复历史备份中的重复入口 | `fix-skill-entrypoints.ps1` / `.sh` |

- 脚本分级（L1 hub `scripts/` vs L2 技能 `scripts/`）：见 **`references/script_tiering.md`**；索引见 hub 根 **`scripts/README.md`**。
- `publish-skill`：**默认**若 hub 中无该技能 `SKILL.md` 会直接失败，避免拼写错误时挂出 TODO 占位技能。

- `check-skill-structure` 可重复传入 `--skill-root` / `-SkillRoot` 仅校验指定技能根目录；不传则按树全量扫描（审计/CI）。详见 `skill-engineering` → `references/engineering_completion_gate.md` §2。

## register-project 做了什么

`register-project` = 前置校验 + scaffold + `init-project-agenting` + 后置验证：

1. 在 hub 创建 `rules/projects/<key>/` 目录（**不**自动生成 `PROJECT_RULES.md`；有项目增量时再手工添加）
2. 在 hub 创建 `skills/projects/<key>/` 目录
3. 在 hub 创建 `prompts/projects/<key>/` 及 `README.md` 骨架（若不存在）；`--dry-run` / `-DryRun` 会打印将创建的路径
4. 校验用户级工具目录（`~/.claude/`、`~/.codex/`、`~/.cursor/`）并输出状态
5. 校验项目工作区目标（`AGENTS.md`、`.cursor/rules/00-common.mdc`、技能目录等）
6. 运行 `init-project-agenting`（同步规则 + 挂载技能：默认 **`skills/share/*` → 用户级目录**，**`skills/projects/<key>/*` → 仓库** `.agents/skills` / `.cursor/skills` / `.claude/skills`，不再把工作区侧的 `.cursor`/`.claude/skills` 填满共享拷贝；可加 `-LinkShareToWorkspace` / `--link-share-to-workspace` 恢复旧镜像；默认接着执行 `sync-prompts`，`-SkipPrompts` / `--skip-prompts` 可跳过）
7. **未** `--skip-prompts` / `-SkipPrompts` 时：对整个 hub 跑 `check-prompts`（失败则注册失败退出），通过后跑 `build-prompt-index` 刷新 `prompts/indexes/prompts.index.json`，并输出索引路径与工作区 `hub-project` 链接对照
8. 运行 `check-skill-links` 输出技能链接验证报告
9. 支持 `--dry-run` / `-DryRun` 预览 scaffold（不写文件、不跑 init / 结束门脚本）

## 平台差异

- Windows 目录链接默认用 `Junction`，不是 `SymbolicLink`。
- macOS / Linux 目录链接默认用 `symlink`。
- Git 仓默认应忽略 `.agents/` 和 `.cursor/skills/`，避免把 hub 真实源扫进仓库。
- 所有脚本通过 `AGENTS_HUB_ROOT` 环境变量或 `--hub-root` / `-HubRoot` 参数定位 hub，无硬编码路径。

## install-hub 做了什么

`install-hub` = 零参数安装（hub 路径从脚本自身位置自动推导）；若 `~/.cursor/skills/<name>` 等处已是**真实目录**（含 `SKILL.md`）而非指向 hub 的链接，默认**跳过并整体失败退出**（避免误报 Done）；需迁移时可显式传入 **`-ReplaceRealDirs` / `--replace-real-dirs`**（**会删除**该目录后再建链，破坏性操作）。

1. 遍历 `skills/share/` 下所有有 `SKILL.md` 的目录（public 包；maintainer hub 可另有额外层，见 `PROJECT_RULES.md`）
2. 软链 / Junction 到 `~/.claude/skills/`、`~/.cursor/skills/`、`~/.codex/skills/`
3. 同步全局规则到 `~/.claude/CLAUDE.md`、`~/.codex/AGENTS.md`
4. 把 `AGENTS_HUB_ROOT` 写入 shell profile（`--skip-profile` 跳过）
5. 支持 `--dry-run` / `-DryRun` 预览

执行前会先运行 `check-skill-entrypoints`，同时检查重复入口和根 `SKILL.md` front matter（必须有 `name`、`description` 和闭合 `---`）。如果发现**嵌套的** `SKILL.md` **文件**，先用 `fix-skill-entrypoints`（可用 `--dry-run` / `-DryRun`）改名为 `_SKILL.md` 或 `SKILL.legacy-<timestamp>.md`；如果发现名为 `SKILL.md` 的**目录**，同一脚本会将其中的文件合并进同级 `SKILL_md/` 后删除该目录（若目录内仍有子目录等无法自动平移的情况，脚本会失败，需人工整理后再跑）。再重新安装。

## trigger / eval 与安全

dry-run 优先、`-ReplaceRealDirs` 破坏性、挂载边界与 should-trigger / should-not-trigger → **[references/trigger_eval.md](references/trigger_eval.md)**。

真实校验样例见 `references/closure_example.md`。

## 闭环门

- 安装/同步类任务必须有后置校验：`check-skill-links`、`check-skill-entrypoints`，涉及 prompt 时再跑 `check-prompts` / `build-prompt-index`。
- 结构或入口问题只修挂载与脚本链路；正文质量问题转 `skill-engineering` / `prompt-engineering`。
- 发现破坏性操作（如替换真实目录）时，先 dry-run 和用户确认，不在本技能内默认执行。
- 完成后输出：动作、脚本、校验结果、仍需人工确认的风险。

## 先读哪里

- 新机器安装、注册、同步、排查：`references/workflow.md`
- 新脚本放 hub 还是技能目录：`references/script_tiering.md`
- 研发任务节奏 + 文档协作：`rules/common/COMMON_AGENT_RULES.md` §研发全流程
- `*.prompt.md` 正文与 eval：`prompt-engineering`
- 目标产物不清楚：先读 `agent-asset-router`
