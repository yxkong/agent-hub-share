---
name: agent-hub-bootstrap
description: 初始化、修复、发布和校验 agent hub 挂载（install-hub, skill mount, junction, symlink）。适用于 register-project、publish-skill、sync-prompts、check-skill-links、Cursor/Claude/Codex 找不到技能；不负责 skill/prompt 正文质量或 docs 放置规则。
---

# Agent Hub Bootstrap

## 30 秒决策区

| 任务类型 | 什么时候选它 | 先读什么 |
|---|---|---|
| `install` | 新机器、用户级共享技能挂载、AGENTS_HUB_ROOT 初始化 | `references/workflow.md` |
| `register-project` | 新项目接入 hub、确定 project type、同步规则/技能/prompt | `references/workflow.md` |
| `sync` | 同步规则、共享技能、项目技能或 prompt 链接 | `references/workflow.md` |
| `diagnose` | Cursor/Claude/Codex 找不到 skill、链接失效、重复入口 | `references/trigger_eval.md` + `references/workflow.md` |
| `script-tiering` | 不确定脚本放 hub 根还是技能目录 | `references/script_tiering.md` |

## 作用边界

- 一键注册新项目到 hub：先确定 `project_type`，生成项目目录结构、校验用户级工具目录、再挂载规则和技能。
- 初始化已注册项目与本地 hub 的连接：同步规则、挂载共享技能、挂载项目技能、同步提示词链接、复挂单个技能、核对链接状态。
- 负责 **hub 资产的位置、挂载、校验与分发**（rules / skills / prompts），**不负责**提示词或规则正文的提炼与评测；正文质量与 eval 设计转 `prompt-engineering`；skill 正文提炼转 `skill-engineering`；技术复盘卡片转 `project-insight-extractor`。
- 不负责文档、SQL、脚本的放置策略设计；涉及备份与治理时遵循 `doc-script-governance`。
- 领域 workflow 由 `rules/profiles/<project-type>/PROFILE_RULES.md` 决定；技能挂载由 `skills/registry.json` 决定；命令投影由 `commands/registry.json` 决定。本技能只管类型选择、规则组装、注册、挂载和分发，不把未知项目默认套入工程或自媒体 workflow。
- 技能元数据规范见 `skills/REGISTRY.md`；注册表只写 hub 相对路径，不写本机绝对路径、用户目录或生成产物路径。

## 项目类型决策

注册或初始化项目前先确定 `project_type`：

| 类型 | 适用 | 默认规则 / 技能 |
|---|---|---|
| `generic` | 通用项目、轻量资料、目标尚未落到工程或自媒体 | `global` 技能组 |
| `engineering` | 研发、debug、前后端、SQL、重构、测试、发布 | `global + engineering` 技能组 |
| `media` | 公众号、小红书、内容采集、改稿、发布包、配图、视频化网页演示 | `global + media` 技能组 |
| `hub` | 维护技能、规则、插件、命令、挂载脚本的 hub 仓库 | `global + hub-maintenance` 工作区技能 + 项目技能 |
| `mixed` | 同一项目长期承载多个主域 | `global + engineering + media` 技能组；每次任务先选子域 |

- 用户已明确类型时，注册命令传 `--project-type` / `-ProjectType`。
- 已有 `rules/projects/<project-key>/project.yaml` 时，以其中的 `project_type` 为真源。
- 不确定时先问用户选择；脚本缺省只按 `generic` 生成，不自动猜成工程。
- 规则生成只输出运行时需要的精简首跳、核心规则、环境规则、类型规则和项目增量；组装元数据不写入最终 `AGENTS.md`。
- 规则相关任务必须读取 `docs/design/ai-dev-system/AGENT_RULES_LEARNING_LEDGER.md`；普通执行任务只读最终运行时规则。

## 真实源与挂载点

- hub 内相对真源：`rules/common/`、`rules/profiles/`、`rules/projects/<project-key>/`、`skills/registry.json`、`skills/share/`、`<media-skill-layer>/`、`skills/research/`、`skills/tooling/`、`skills/projects/<project-key>/`、`commands/registry.json`、`commands/share/`、`prompts/share/`、`prompts/projects/<project-key>/`。
- 用户级入口：`~/.claude/skills/`、`~/.cursor/skills/`、`~/.codex/skills/`、Gemini CLI `~/.gemini/skills/`、Antigravity `~/.gemini/config/skills/`。`install-hub` 只挂 `skills/registry.json` 中的 `generic/global` 清单；具体名单只以 registry 为准；只有显式 `--link-user-skills` / `-LinkUserSkills` 才把当前项目类型技能追加写入用户级入口。
- 工作区入口：技能按 `skills/registry.json` 的 `project_type` 挂载到 `.agents/skills/` 等宿主技能目录；命令按 `commands/registry.json` 独立展开到 `.cursor/commands/`、`.claude/commands/` 和 Antigravity IDE 的 `.agents/workflows/`。命令不得再生成同名 `.agents/skills/<command-name>/SKILL.md`，避免职责混淆、重复 `/` 入口和 Codex 技能污染；历史受管适配 skill 由 `sync-commands` 主动清理。命令不默认写用户级 `~/.codex/prompts`。提示词是否挂载由项目 `project.yaml` 的 `prompts_enabled` 决定；关闭时清理受管的 `hub-share`、`hub-project` 链接。
- 不要把真实 skill 长期维护在工作区入口目录里；提示词真实源同样在 hub，工作区仅链接。
- 一个 skill 目录只能有一个根 `SKILL.md`（canonical 路径见 `skill-engineering/references/layout/skill_truth_source_contract.md`）；`bak/`、dated 快照中**禁止**保留名为 `SKILL.md` 的文件；`check-skill-entrypoints` 对违规 fail，`find-skills` 只列 canonical。

## 默认动作（推荐顺序）

默认只做 **workspace skills 挂载 + workspace 全局规则同步**。规则同步范围包括
`AGENTS.md`、`CLAUDE.md`、`.cursorrules`、`.cursor/rules/00-common.mdc`；技能挂载范围按
`skills/registry.json` 与项目 `project_type` 计算。`commands` 与 `prompts` 不是默认动作，只有用户明确要求
“同步命令 / workflows / prompts / 全量初始化 / register-project”时才执行对应脚本。

| 场景 | 脚本 |
|---|---|
| **新机器**：安装 hub 本身，链接共享技能到用户目录 | `install-hub.ps1` / `install-hub.sh` |
| **全新项目**：注册到 hub + 挂载所有内容 | `register-project.ps1` / `register-project.sh` |
| **空目录做自媒体任务**：注册为 media 类型；挂能力，不复制账号数据 | `register-project.* -ProjectType media`，账号真源由 `media-account-context` 连接机器级 media home |
| **默认：已注册项目同步规则** | `sync-agent-rules.ps1` / `.sh` |
| **默认：已注册项目挂载技能** | `sync-shared-skills.ps1` / `.sh` |
| 显式要求全量初始化 | `init-project-agenting.ps1` / `.sh` |
| 只同步 Gemini / Antigravity 用户级 global 技能 | `skills/share/agent-hub-bootstrap/scripts/sync-gemini-skills.ps1` / `.sh` |
| 显式要求同步提示词链接（hub → 工作区） | `sync-prompts.ps1` / `.sh` |
| 显式要求按项目类型同步命令 | `sync-commands.ps1` / `.sh` |
| 校验命令 registry 与宿主投影 | `check-commands.ps1` / `.sh` |
| 校验用户级目录只含 global 技能 | `check-user-skill-scope.ps1` / `.sh` |
| 校验 `*.prompt.md` 元数据与安全问题 | L2 `prompt-engineering/scripts/check-prompts.*`（hub forwarder 同名） |
| 生成 `prompts/indexes/prompts.index.json` | L2 `prompt-engineering/scripts/build-prompt-index.*`（hub forwarder 同名） |
| 复挂单个技能 | `publish-skill.ps1` / `.sh`（hub 内须已存在 `SKILL.md`；仅有意脚手架时加 `-CreateIfMissing` / `--create-if-missing`） |
| 校验链接结果 | `check-skill-links.ps1` / `.sh` |
| 校验重复技能入口 | L2 `skill-engineering/scripts/check-skill-entrypoints.*`（hub forwarder 同名） |
| 校验 references 拓扑（顶层 `*.md` 数量、语义子目录深度） | L2 `skill-engineering/scripts/check-skill-structure.*` |
| 统计主文件非空行 / 行数门禁 | L2 `skill-engineering/scripts/check-skill-size.*` |
| 修复历史备份中的重复入口 | L2 `skill-engineering/scripts/fix-skill-entrypoints.*` |

- 脚本分级（**hub 稳定入口 + skill 实现真源**）：见 **`references/script_tiering.md`**；索引见 hub 根 **`scripts/README.md`**。
- Agent 执行挂载类任务：只组参数并调用现成 L1/L2 脚本，**禁止**在业务仓现写临时脚本。
- 用户只要求“挂载技能 / 重挂 skills / 评估规则偏离”时，执行边界固定为 `sync-shared-skills`、
  `sync-agent-rules`（如需写规则）与 `check-skill-links` / `check-agent-rules`；不得顺手运行
  `init-project-agenting`、`sync-commands`、`sync-prompts` 或 `register-project`。
- Gemini 专用路径真源在 L2：`skills/share/agent-hub-bootstrap/scripts/gemini-skill-paths.ps1` / `.sh`；L1 脚本只 dot-source，不在 `scripts/agent-hub-paths.*` 维护 Gemini 专用路径。
- `publish-skill`：**默认**若 hub 中无该技能 `SKILL.md` 会直接失败，避免拼写错误时挂出 TODO 占位技能。

- `check-skill-structure` 可重复传入 `--skill-root` / `-SkillRoot` 仅校验指定技能根目录；不传则按树全量扫描（审计/CI）。详见 `skill-engineering` → `references/engineering_completion_gate.md` §2。

## register-project 做了什么

`register-project` = 前置校验 + scaffold + `init-project-agenting` + 后置验证：

1. 在 hub 创建 `rules/projects/<key>/` 目录（**不**自动生成 `PROJECT_RULES.md`；有项目增量时再手工添加）
2. 在 hub 创建 `skills/projects/<key>/` 目录
3. 在 hub 创建 `prompts/projects/<key>/` 及 `README.md` 骨架（若不存在）；`--dry-run` / `-DryRun` 会打印将创建的路径
4. 校验用户级工具目录（`~/.claude/`、`~/.codex/`、`~/.cursor/`）并输出状态
5. 校验项目工作区目标（`AGENTS.md`、`.cursor/rules/00-common.mdc`、技能目录等）
6. 运行 `init-project-agenting`（技能按 `skills/registry.json`、命令按 `commands/registry.json` 的 `project_type` 清单投影；项目技能进入工作区入口；提示词按 `project.yaml` 的 `prompts_enabled` 启用或清理）
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

1. 读取 `skills/registry.json` 的 `generic/global` 清单，只挂跨项目通用资产能力；工程、自媒体和 hub-maintenance 技能由项目注册/初始化按类型补挂
2. 软链 / Junction 到 `~/.claude/skills/`、`~/.cursor/skills/`、`~/.codex/skills/`、Gemini CLI `~/.gemini/skills/`、Antigravity `~/.gemini/config/skills/`；不写历史路径 `~/.gemini/antigravity/skills`、`~/.antigravity/skills`
3. 不再同步用户级 `~/.claude/CLAUDE.md`、`~/.codex/AGENTS.md`；规则按项目同步到 workspace
4. 把 `AGENTS_HUB_ROOT` 写入 shell profile（`--skip-profile` 跳过）
5. 支持 `--dry-run` / `-DryRun` 预览

执行前会先运行 `check-skill-entrypoints`，同时检查重复入口和根 `SKILL.md` front matter（必须有 `name`、`description` 和闭合 `---`）。如果发现**嵌套的** `SKILL.md` **文件**，先用 `fix-skill-entrypoints`（可用 `--dry-run` / `-DryRun`）改名为 `_SKILL.md` 或 `SKILL.legacy-<timestamp>.md`；如果发现名为 `SKILL.md` 的**目录**，同一脚本会将其中的文件合并进同级 `SKILL_md/` 后删除该目录（若目录内仍有子目录等无法自动平移的情况，脚本会失败，需人工整理后再跑）。再重新安装。

## trigger / eval 与安全

dry-run 优先、`-ReplaceRealDirs` 破坏性、挂载边界与 should-trigger / should-not-trigger → **[references/trigger_eval.md](references/trigger_eval.md)**。

真实校验样例见 `references/closure_example.md`。

## 闭环门

- 默认挂载/规则同步任务必须有后置校验：工作区跑 `check-skill-links`，规则同步或偏离评估跑
  `check-agent-rules`；入口结构跑 `check-skill-entrypoints`。用户级范围只在 `install-hub` 或用户级技能同步时跑
  `check-user-skill-scope`；涉及 prompt 时才跑 `check-prompts` / `build-prompt-index`。
- 结构或入口问题只修挂载与脚本链路；正文质量问题转 `skill-engineering` / `prompt-engineering`。
- 发现破坏性操作（如替换真实目录）时，先 dry-run 和用户确认，不在本技能内默认执行。
- 完成后输出：动作、脚本、校验结果、仍需人工确认的风险。

## 先读哪里

- 新机器安装、注册、同步、排查：`references/workflow.md`
- 新脚本放 hub 还是技能目录：`references/script_tiering.md`
- 项目类型、首跳与领域细则：最终 `AGENTS.md` + `rules/profiles/<project-type>/PROFILE_RULES.md`
- 技能检索、注册与规整：`skills/REGISTRY.md` + `skills/registry.json`
- 规则新增、修订与回灌：`docs/design/ai-dev-system/AGENT_RULES_LEARNING_LEDGER.md`
- `*.prompt.md` 正文与 eval：显式 prompt 维护任务再读 `prompt-engineering`
- 不清楚是否属于 skill / prompt / docs / plugin：先用当前项目规则判断，必要时询问用户；不要默认引入工程类路由器
