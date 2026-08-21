# ai-development-governance

AI 研发治理总线：定义从需求入口到失败沉淀的端到端阶段门、评分模型与跨 skill 协作矩阵。**不直接写代码**，不替代 `delivery-workflow` 的执行推进。

## 核心用途

为真实研发任务提供 **L1 治理总线层**：Spec 真源、ADR 决策、Task Contract、Security / Release / Quality 门禁，以及 9.8+ 量化评分；与 L2 `delivery-workflow`（交付执行）、L3 `doc-script-governance`（资产落位）分工协作。

## 单一职责（本 skill 独有）

- G0–G8 生命周期阶段门定义与准入门禁
- Spec Compiler：Fact Pack、Feature Spec、SDD、ADR、Task Contract 的生成、反证、冻结与追踪校验
- Feature Spec / SDD / ADR / Task Contract 空白模板（根 `templates/`）
- Security / Release / Rollback / Quality / Observability 专项门禁
- Release Evidence（发布证据）收敛到 Release / Rollback / Observability Gate，不新增独立 runbook
- 9.8+ 评分模型（scorecard）与治理自检清单
- 跨 skill 协作矩阵
- 持久上下文与多视角反证横向门（过程区、archive、真源回灌、反迎合检查）
- Task Replay Lite 与 Skill Health Signal：失败/重复返工时回放任务证据并回填 scorecard / bad smell / trigger eval，不新增健康度看板

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
- **跨项目契约门**：`references/gates/project_contract_gate.md`
- **Spec Compiler**：`references/governance/spec_compiler_workflow.md`
- **Spec Compiler Eval**：`references/governance/spec_compiler_eval.md`

## 真源与挂载

- Hub 真源：`$AGENTS_HUB_ROOT/skills/share/ai-development-governance/`
- 工作区入口链接不以工作区副本为真源

## 修订记录（人读；`references/` 不写）

| 版本 | 日期 | 修订要点 |
|------|------|----------|
| 1.5.0 | 2026-08-18 | 实施授权收敛为一次目标授权；设计、依赖闭包与验证不再触发逐文件重签，高风险边界仍单独确认 |
| 1.4.0 | 2026-07-28 | 引入 Spec Compiler：统一 Fact Pack、文档状态/版本、追踪 ID、Python 校验核心与 baseline/held-out |
| 1.3.0 | 2026-06-10 | 增加主链证据、Project Contract、Release Evidence、Task Replay Lite / Skill Health Signal 轻量闭环；不新增 runbook/dashboard |
| 1.2.0 | 2026-06-08 | 增强持久上下文闭环、多视角反证与反迎合检查 |
| 1.1.0 | 2026-06-04 | 统一 G0 入口 triage、七层协作模型、Realism Gate 与行为模式变更阻断 |
| 1.0.0 | 2026-05-21 | 初版：治理总线、G0–G8、scorecard、门禁与跨 skill 矩阵 |

## 维护约定

- 扩展「负责」范围前：先更新 §单一职责 / §不负责，再改 `SKILL.md`
- 改 `references/*.md` 后：在此表追加一行
- 改 Spec Compiler 字段或校验语义时：同步模板、Python 核心、两端 wrapper、回归测试和 eval 证据
- 与 `delivery-workflow` / `doc-script-governance` 冲突时：执行归 delivery，落位归 doc-script，门禁归本 skill
