# agent-hub-bootstrap — trigger / eval 与安全

## 安全提示

- **默认先 dry-run**：`install-hub`、`register-project`、`publish-skill`、`sync-shared-skills` 均支持 `-DryRun` / `--dry-run`，先预览将创建/替换/删除的链接再正式执行。
- **`-ReplaceRealDirs` / `--replace-real-dirs` 是破坏性操作**：会删除用户级已有真实 skill 目录后重建链接；除非用户明示确认迁移，否则不要执行。
- **本技能只管挂载与校验**：不判断 skill/prompt 正文是否适合开源或是否含私有路径；脱敏与 public export 在发布阶段处理。
- **不确定项目类型先问用户**：`register-project` / `init-project-agenting` 可用 `--project-type` / `-ProjectType` 指定 `engineering`、`media`、`generic`、`mixed`、`hub`；未指定且无 `project.yaml` 时只按 `generic` 生成，不默认工程。
- **Windows 用 Junction、macOS/Linux 用 symlink**：属正常行为，不是「链接失败」；详见 [workflow.md](workflow.md)。

## should-trigger

- 「Cursor / Claude / Codex 找不到新建的 skill」
- 「clone 了 hub，怎么把 global 基础设施技能挂到用户级目录？」
- 「帮我检查 skill 链接是否指向 hub 真源」
- 「注册新项目，让它按 project type 挂载技能 + project skills + 规则同步」
- 「注册自媒体项目，不要走工程 workflow，要挂内容生产技能组」
- 「给项目生成最终 `AGENTS.md` 首跳，让 Agent 多轮恢复后仍能零跳命中 workflow」
- 「按 engineering / media / generic / mixed / hub 类型挂载规则和技能」
- 「`check-skill-links` / `check-skill-entrypoints` 报错，帮我排查」
- 「Windows junction 和 macOS symlink 挂载差异怎么处理？」

## should-not-trigger

- 「优化这个 SKILL.md 的 description / trigger」→ `skill-engineering`
- 「把这段长指令沉淀为 `*.prompt.md`」→ `prompt-engineering`
- 「文档 / SQL / 脚本改前怎么备份、放哪」→ `doc-script-governance`
- 「这个研发需求先做什么后做什么」→ `delivery-workflow`
- 「这个公众号 / 小红书内容怎么写」→ media profile 中声明的内容 workflow
- 「这个 skill 正文应该怎么设计」→ `skill-engineering`
- 「有没有现成 skill 能覆盖这个能力」→ `skill-discovery`

## eval 检查点

- `sync-agent-rules` 生成的项目规则必须在前 30 行内包含 `首跳:`，且不得泄漏 `AGENT-*` marker、Boot Card、`project_type:` 等组装 metadata。
- `check-skill-registry` 必须通过：注册表引用的技能存在，canonical skill 无遗漏，project type 展开清单可审计。
- `project_type=media` 时，首跳不得默认 `delivery-workflow`。
- `project_type=engineering` 时，首跳不得默认 media 内容 workflow。
- `rules/common/COMMON_AGENT_RULES.md` 只保留 kernel；领域节奏必须放到 `rules/profiles/<type>/PROFILE_RULES.md`。
