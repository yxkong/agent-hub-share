---
name: project-insight-extractor
description: 从 AI 编程过程、调试记录、重构决策、代码变更和复盘材料中提炼“给人读”的技术洞察资产。适用于复盘、面试表达、简历 bullet、方法论、案例库、TechInsightVault 归档；不负责给 Agent 执行的长 prompt、SKILL.md 规则回填或真实代码 review。
---

# Project Insight Extractor

## 30 秒决策区

| 任务类型 | 什么时候选它 | 先读什么 |
|---|---|---|
| `current-session` | 从当前会话提炼技术洞察、案例、方法论 | `references/source_material_qualification.md` + `references/value_lens.md` |
| `transcript` | 从历史 Cursor 会话提炼 | `references/cursor_session_access.md` |
| `vault` | 需要写入 TechInsightVault 或去重融合 | `references/asset_taxonomy.md` + `references/deduplication.md` |
| `output` | 需要面试表达、简历 bullet、资产卡片 | `references/output_templates.md` |

## 作用边界

本技能用于把开发过程转成可复用、可表达、可验证的技术洞察资产。

覆盖：
- 从当前会话、历史会话、日志、diff、设计文档、调试记录中提炼经验
- 生成技术案例卡、面试表达、简历 bullet、方法论
- 识别多类型资产：问题模式、决策模型、优化案例、方法论、反模式、表达素材
- 帮助把材料归档到 insight vault（路径见下节 **Insight Vault 路径**）

Vault 解析、会话读取与写入模式统一按：

- `references/cursor_session_access.md`：当前/历史会话与外部材料入口
- `references/asset_taxonomy.md`：Vault 路径、写入目录与 `draft-only`

记忆规则只有一条：**Vault 不可写时必须退回 `write_action: draft-only`，不得伪装成已归档。**

不覆盖：
- 代替真实代码 review 或 bug 修复
- 编造收益、指标、职责或业务影响
- 把流水账直接包装成简历亮点

## 与 delivery-workflow / prompt-engineering 分流（失败沉淀）

| 产物 | 用哪个技能 | 说明 |
|------|------------|------|
| **给人读的**洞察、案例、面试表达 | **本技能**（insight vault） | 路径见 §Insight Vault 路径 |
| **给 Agent 的**反模式、触发词、回填到 SKILL | 见 [references/skill_anti_pattern_feedback.md](references/skill_anti_pattern_feedback.md) | 本技能**输出卡片建议**，**不**自动改写项目 SKILL |
| **给子 Agent 的**可执行长指令 | `prompt-engineering`（`*.prompt.md`） | 与 insight **并存**时可各写一份；勿把 TechInsightVault 当 prompt 仓库 |

总闸门：`delivery-workflow` [SKILL.md 中 R3](../delivery-workflow/SKILL.md)（三路分流）。

## 产物分流（与 skill-engineering / doc-script 对齐）

| 会话主交付 | 负责技能 | 本技能 |
|---|---|---|
| SKILL / references / 触发 eval / 坏味道 | `skill-engineering` | 仅 `rule_improvement_candidates` 或 discarded |
| 文档/SQL 放置、backup 规范、script_tiering | `doc-script-governance` | 不进 Vault |
| `*.prompt.md` | `prompt-engineering` | 不进 Vault |
| Agent 规则分层、loader 碰撞、运行时封装 bug | **本技能** | canonical + 派生表达 |
| Hub L1/L2 **放置表 alone** | skill references | ❌ Vault（StrictMode 脚注可 merge） |

## 何时使用

当用户出现以下意图时使用：
- "帮我复盘/提炼/沉淀/总结成面试表达"
- "把这段开发经历写成简历亮点"
- "从这次排查/优化/重构里抽方法论"
- "整理个人项目案例库"
- "把 AI 编程过程中的知识点变成技术资产"
- "从当前会话提炼技术洞察"

默认一句话触发即可：

```text
请用 project-insight-extractor 从当前会话提炼 TechInsightVault 技术资产。
```

## 核心抽象

- 先判视角层级：能力 / 洞察 / 案例；详细结构见 `references/output_templates.md`
- 先区分 `fact` / `assumption` / `unknown` / `risk`
- 不提炼规范补全、纯执行流水账或普通 bug fix 过程

## 最小 SOP

1. **确定范围**：用户未指定时，默认抽取当前会话的有效技术片段。
2. **源材料资格判定**：按 `references/source_material_qualification.md` 为每段材料打 `source_anchor`、`source_role` 和 `target_scope`；按 `source_role × target_scope` 决策表判断是否可归档。`source_role != archive_source` 的材料不得归档为 `domain_asset`，只有决策表允许时才可归档为 `skill_improvement_asset`。
3. **扫描提炼**：按 `references/session_extraction.md` 对合格材料做分段、聚类、去噪。
3.5. **主交付物门禁**：按 `references/value_lens.md` §主交付物门禁 + `references/asset_types.md` §主交付物门禁；主交付为 skill/doc 正文 → 转交，终止 Vault 路径。
3.6. **架构师快测 + 双轴评分**：每张候选填 `architect_view`、`vault_admit`、`score_vault_worthy`、`score_expressibility`（见 `value_lens.md`）；`policy_only` 或 vault_worthy ≤4 → 不写 Vault。
4. **识别资产类型**：按 `references/asset_types.md` 确定 asset_type；❌ 不可提炼的直接丢弃，不继续后续步骤。
5. **提取事实**：按 `references/extraction_contract.md` 建立证据链，不把尝试过程当结果。
6. **去重合并**：按 `references/deduplication.md` 生成 canonical_id；已存在的 ID 做融合，不新建重复文件。
7. **写入归档**：按 `references/asset_taxonomy.md` 路由；新建用编辑工具，已有文件先 backup 再融合；人类索引与机器索引规则同样遵循该文档。
8. **输出卡片**：按 `references/output_templates.md` 输出能力资产卡、面试表达、简历 bullet 与归档结果。

## 闭环门

- 每个洞察必须有 source_anchor 与事实证据；收益、指标、业务影响不能编造。
- 主交付若是 skill / prompt / docs 正文，立即转交，不写入 Vault。
- 可写 vault 时：新建用编辑工具，已有文件先备份再融合，机器索引由脚本生成。
- 不可写 vault 时输出 `draft-only`，不得伪装成已归档。

详细模板与红线见 `references/output_templates.md` 与 `references/extraction_contract.md`。主文件只保留三条记忆规则：

- 产物必须给人读，而不是给 Agent 执行
- 每条洞察都要回答“为什么不显而易见 / 为什么这么做 / 效果是什么”
- 指标、收益、客户信息与私有路径都不能编造或泄露

## References

**P0 执行真源**

- `references/source_material_qualification.md`
- `references/value_lens.md`
- `references/extraction_contract.md`
- `references/asset_types.md`
- `references/output_templates.md`

**P1 条件规则**

- `references/cursor_session_access.md`（历史会话）
- `references/session_extraction.md`（长会话分段）
- `references/asset_taxonomy.md`（写入 Vault）
- `references/deduplication.md`（去重融合）
- `references/skill_anti_pattern_feedback.md`（Agent 反模式分流）
- `references/eval/trigger_eval.md`（触发边界回归）
- `references/eval/closure_example.md`（Vault 不可写时的 `draft-only` 样例）

## trigger / eval

完整正负例见 `references/eval/trigger_eval.md`。主文件只保留记忆规则：

- **should-trigger**：把开发/排查/返工过程提炼成给人读的 insight、面试表达、简历 bullet、方法论
- **should-not-trigger**：代码实现、代码 review、长文对外成稿、prompt 落盘、资产类型未决的分诊问题

## 反馈闭环协议

执行后若出现以下情况，回到 `skill-engineering` 的坏味道规则库沉淀：
- SOP 执行完仍无法判断哪些内容值得提炼
- 生成结果像流水账，不能用于面试或简历
- 多次出现收益编造、证据缺失、分类混乱
- 重复知识点被写成多个互相竞争的事实源
