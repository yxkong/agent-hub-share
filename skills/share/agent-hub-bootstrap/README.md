# agent-hub-bootstrap

## 定位

初始化、修复、发布和校验本地 agent hub 与工作区/用户级入口的挂载关系（rules / skills / prompts）。

## 核心要点

- **只管可见性**：注册、挂载、同步、索引、链接校验；不管 skill/prompt 正文质量。
- **真源 vs 镜像**：hub 内 skill layers 和 `skills/registry.json` 为真源；`~/.claude/skills/` 等为用户级镜像；工作区 `.agents/skills/` 等为项目技能镜像。
- **路径写法**：文档与技能内用 **hub 相对路径**（如 `scripts/register-project.ps1`），不写本机绝对路径；执行时由环境变量或 `--hub-root` 解析。
- **脚本分级**：L1 → hub `scripts/`；L2 → 各技能 `scripts/`；见 `references/script_tiering.md`。
- **新机器零参数**：`install-hub`；新项目 `register-project`；改 skill 后 `publish-skill`。
- **Guard 授权**：明确实施请求一次授权整个目标；同一目标内的依赖补齐、文件扩展和验证直接执行，仅风险边界再次确认。

## 关键 references

| 文件 | 用途 |
|------|------|
| `references/workflow.md` | 安装、注册、同步、发布、排查 |
| `references/script_tiering.md` | hub 脚本 vs 技能脚本分级与兼容入口 |
| `references/closure_example.md` | 非破坏性链接校验样例 |
| `docs/design/ai-dev-system/AGENT_RULES_LEARNING_LEDGER.md` | 规则新增、修订与回灌账本 |

## 协作入口

| 场景 | 转交 |
|------|------|
| 项目类型、首跳与技能挂载 | `rules/profiles/<project-type>/PROFILE_RULES.md` + `skills/registry.json` + 最终 `AGENTS.md` |
| 规则新增、修订与回灌 | `docs/design/ai-dev-system/AGENT_RULES_LEARNING_LEDGER.md` |
| SKILL 正文、trigger、eval | `skill-engineering` |
| prompt 正文与评测 | `prompt-engineering` |
| 文档/SQL 备份与放置 | `doc-script-governance` |
| engineering 项目内工程产物不明 | `agent-asset-router`；其它项目类型走当前 profile |

## 修订记录

| 版本 | 日期 | 修订要点 |
|------|------|----------|
| 1.3.0 | 2026-08-18 | 写入 Guard 升级为一次目标授权，保留高风险确认与旧许可证迁移能力 |
| 1.2.0 | 2026-08-15 | 项目注册不再生成 `project_skill: unknown`；首选技能未确定时省略，由全项目闭包门禁校验 |
| 1.1.0 | 2026-05-21 | 脚本分级 reference；路径改 hub 相对；链 share README |
| 1.0.0 | — | 首版 |
