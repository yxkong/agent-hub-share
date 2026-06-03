# ai-development-governance

AI 研发治理总线：定义从需求入口到失败沉淀的端到端阶段门、评分模型与跨 skill 协作矩阵。**不直接写代码**，不替代 `delivery-workflow` 的执行推进。

## 核心用途

为真实研发任务提供 **L1 治理总线层**：Spec 真源、ADR 决策、Task Contract、Security / Release / Quality 门禁，以及 9.8+ 量化评分；与 L2 `delivery-workflow`（交付执行）、L3 `doc-script-governance`（资产落位）分工协作。

## 单一职责（本 skill 独有）

- G0–G8 生命周期阶段门定义与准入门禁
- Feature Spec / ADR / Task Contract 空白模板（根 `templates/`）
- Security / Release / Rollback / Quality / Observability 专项门禁
- 9.8+ 评分模型（scorecard）与治理自检清单
- 跨 skill 协作矩阵

## 不负责 / 转交

| 场景 | 转交技能 |
|------|----------|
| 需求拆解、实现推进、验证收口、R3 失败沉淀 | `delivery-workflow` |
| docs / SQL / 脚本放置、backup-file | `doc-script-governance` |
| skill / prompt / insight 资产工程 | `skill-engineering` / `prompt-engineering` / `project-insight-extractor` |
| 资产类任务第一跳路由 | `agent-asset-router` |
| 具体业务代码实现 | 项目领域技能 |

## 入口

- **Agent 路由器**：[SKILL.md](SKILL.md)
- **references 索引**：[references/README.md](references/README.md)
- **空白模板**：[templates/](templates/)
- **trigger / eval**：`references/trigger_eval.md`
- **真实闭环样例**：`references/closure_example.md`

## 真源与挂载

- Hub 真源：`$AGENTS_HUB_ROOT/skills/share/ai-development-governance/`
- 工作区入口链接不以工作区副本为真源

## 修订记录（人读；`references/` 不写）

| 版本 | 日期 | 修订要点 |
|------|------|----------|
| 1.0.0 | 2026-05-21 | 初版：治理总线、G0–G8、scorecard、门禁与跨 skill 矩阵 |

## 维护约定

- 扩展「负责」范围前：先更新 §单一职责 / §不负责，再改 `SKILL.md`
- 改 `references/*.md` 后：在此表追加一行
- 与 `delivery-workflow` / `doc-script-governance` 冲突时：执行归 delivery，落位归 doc-script，门禁归本 skill
