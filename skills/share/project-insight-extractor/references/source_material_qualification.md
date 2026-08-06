# 源材料资格判定

目标：防止把用户贴出的评估样例、反例、友商输出或旧版提炼结果误当成可归档事实源。

## 材料角色

| 材料角色 | 是否可归档为领域资产 | 处理方式 |
|---|---|---|
| 用户明确指定的待提炼源码、设计文档、交付记录、真实复盘 | 是 | 按 SOP 提炼并直接归档 |
| 当前助手真实处理过的工作结果 | 是 | 只提炼本次真实工作本身 |
| 用户贴出的旧版提炼结果、友商输出、验证对比 | 否 | 只作为评估样本，用于优化 skill |
| 用户贴出的反例、错误输出、质量问题 | 否 | 只提炼规则缺口和 skill 改进点 |
| 为解释问题而粘贴的 RAG / Agent / BI 示例片段 | 默认否 | 除非用户明确说“从这段归档资产” |

## 硬规则

- 如果用户的任务是“评估/优化 project-insight-extractor”，会话中出现的业务片段默认是测试材料，不是业务事实源。
- 不能把测试材料里的 RAG、Agent、BI、代码修复内容写入 TechInsightVault 领域资产。
- 只能从测试材料中提炼“skill 需要如何改进”“知识提取方法论如何修正”“SOP 哪里容易跑偏”。
- 当源材料角色不清楚时，禁止直接归档业务资产；先输出未归档原因或只归档 skill 改进资产。
- 如果目标产物是给 Agent 执行的长指令或系统提示词，转 `prompt-engineering`；如果目标是改 `SKILL.md` / trigger / references，转 `skill-engineering`。
- 如果用户只说“沉淀一下”但未说明给人读还是给 Agent 用：engineering 项目可走 `agent-asset-router`；其它项目类型追问一句或走当前 profile。

## target_scope 决策规则

`source_role` 决定"材料从哪来"，`target_scope` 决定"资产要去哪"，两者共同决定是否可以写入：

| source_role | target_scope | 是否可归档 | 归档目标 |
|---|---|---|---|
| `archive_source` | `domain_asset` | ✅ | `01_case_library/` / `04_methodology/` |
| `archive_source` | `skill_improvement_asset` | ✅ | skill 改进目录（如 `agent_skill`） |
| `evaluation_sample` / `counterexample` | `domain_asset` | ❌ `not_archived` | — |
| `evaluation_sample` / `counterexample` | `skill_improvement_asset` | ✅ | 只限 `agent_skill/knowledge_management` 域 |
| `skill_improvement_evidence` | `skill_improvement_asset` | ✅ | skill 改进目录 |

**`counterexample` 映射说明**：反例材料处理方式和 `evaluation_sample` 完全一致，对应枚举值为 `counterexample`，不映射到 `skill_improvement_evidence`（后者表示材料本身就是用于改进 skill 的证据输入）。

## 输出要求

归档结果必须写明：

- `source_anchor`：材料来自哪里（当前会话 / 历史 transcript / 用户粘贴 / 文件路径）。
- `source_role`：`archive_source` / `evaluation_sample` / `counterexample` / `skill_improvement_evidence`。
- `target_scope`：`domain_asset` / `skill_improvement_asset`。
- `write_action`：`created` / `merged` / `updated` / `unchanged` / `not_archived`。

写入前查上方决策表，行为唯一确定，不再依赖单条硬规则。
