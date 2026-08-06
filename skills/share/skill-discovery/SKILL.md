---
name: skill-discovery
description: 发现、评估、去重和安装可复用 Agent Skill。适用于“有没有现成 skill”“找/搜索 skill”“外部 registry 安装”“本地 hub 有没有覆盖”“这个能力该不该做成 skill”；不负责创建或重构 SKILL.md 正文（转 skill-engineering）、写长 prompt（转 prompt-engineering）或 hub 挂载修复（转 agent-hub-bootstrap）。
---

# Skill Discovery

在从零新建技能之前，先判断**是否已有可复用 skill** 覆盖用户需求。

## 30 秒决策区

| 任务类型 | 什么时候选它 | 先读什么 |
|---|---|---|
| `local-search` | 查本地 share / project skill 是否已有覆盖 | `references/workflow.md` |
| `candidate-review` | 对候选 skill 做匹配、去重和可用性判断 | `references/workflow.md` |
| `remote-search` | 本地无合适候选，才查外部 registry | `references/workflow.md` + `references/external_repo.md` |
| `install-decision` | 决定安装、适配、仅参考或新建 | `references/trigger_eval.md` |

## 何时使用

用户出现以下意图时使用本技能：

- 询问某能力是否已有可复用 skill
- 按领域、工作流或任务关键词搜索 skill
- 在「安装外部 skill」与「本地新建」之间做决策
- 对比本地 hub 与外部 registry
- 想把重复提示词固化为 skill 工作流

## 基本原则

- **先查本地 hub**：已有共享技能能覆盖时，优先复用，不以公网 registry 为默认真源。
- **公网 registry 为可选补充**：仅当本地无合适候选时再外部检索。
- **不单凭名称推荐**：须核对 `SKILL.md` 正文与 description 是否匹配真实任务。
- **区分标准 skill 目录与工具仓**：部分仓库是 CLI/市场，内含多个 skill，需提取标准目录而非整仓当 skill。

## 检索顺序

检索、候选表、去重与外部安装命令见 `references/workflow.md`。仅在 engineering 项目中，若工程产物尚未确定为 skill / prompt / insight / docs / review，转 `agent-asset-router`；其它项目类型走当前 profile 或询问用户。

## 候选评估

候选输出必须是结构化表，不得仅用自由文本；字段与示例见 `references/workflow.md`。

## trigger / eval 与外部安装确认门

should-trigger / should-not-trigger、外部安装五条件确认门 → **[references/trigger_eval.md](references/trigger_eval.md)**。

真实检索样例见 `references/closure_example.md`。

## 闭环门

- 默认先查本地 hub；没有 exact / partial 候选时才进入外部检索。
- 输出必须包含候选表，不能只凭名称推荐。
- 安装前必须 dry-run、看 license / 私有依赖 / 路径耦合；挂载链路转 `agent-hub-bootstrap`。
- 本地和外部都无合适候选时，结论转 `skill-engineering create`。

## 外部仓库（非单 skill）

部分仓库并非单一 skill，可能是：

- skill 市场或包管理器
- 含多个 skill 的 mono-repo
- 向 Agent 目录安装 skill 的 CLI
- 内嵌示例 skill 的演示仓

处理方式：

- 整仓放在 `$AGENTS_HUB_ROOT/vendors/`（**不要**直接放进 `skills/`）
- 只提取需要的标准 skill 目录到 `skills/share/` 或 `skills/projects/<key>/`
- 按本地 hub 规范改写 description
- 声明可用前跑验收（见 [references/external_repo.md](references/external_repo.md)）

## 本地目录约定

| 路径 | 用途 |
|------|------|
| `$AGENTS_HUB_ROOT/skills/share/` | 标准共享 skill |
| `$AGENTS_HUB_ROOT/skills/projects/<project-key>/` | 项目专属 skill |
| `$AGENTS_HUB_ROOT/vendors/` | 外部工具仓、CLI、非标准 repo |

## References

- 外部仓与验收闭环 → [references/external_repo.md](references/external_repo.md)
- 检索 / 候选表 / 安装命令 → [references/workflow.md](references/workflow.md)
- references 索引 → [references/README.md](references/README.md)
- 新建 skill → `skill-engineering`
- hub 安装与入口 → `agent-hub-bootstrap`
