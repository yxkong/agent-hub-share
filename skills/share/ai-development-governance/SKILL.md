---
name: ai-development-governance
description: AI 研发治理总纲技能（AI development governance, spec, ADR, release gate, security gate, scorecard）。用于定义从需求入口、Spec、设计 ADR、任务契约、实现、质量验证、安全、发布回滚到失败沉淀的端到端治理闭环；不直接写代码，不替代 delivery-workflow、doc-script-governance 或 skill-engineering。
---

# AI Development Governance

## 30 秒决策区

| 任务类型 | 什么时候选它 | 先读什么 |
|------|------|------|
| `lifecycle` | 用户问 AI 开发规范、体系、总纲、如何达到高质量 | `references/lifecycle_map.md` |
| `method-enhance` | 用户问 AI 开发范式、shared 研发体系是否吸收外部优秀方法 | `references/governance/development_method_enhancement.md` |
| `spec` | 真实研发需求尚未形成 Spec，或要提升 Spec 生成稳定性 | `references/governance/spec_compiler_workflow.md`，再按路由读取模板 |
| `sdd` | Spec 已冻结，需要形成可交给实现和 TDD 的软件设计 | `templates/TEMPLATE_SDD.md` |
| `adr` | SDD 中存在多方案取舍或架构影响 | `templates/TEMPLATE_ADR.md` |
| `task-contract` | 需要拆成最小可验证任务契约 | `templates/TEMPLATE_TASK_CONTRACT.md` |
| `project-contract` | 跨项目、Java/Python 同步、共享 DB/API、项目技能一致性 | `references/gates/project_contract_gate.md` |
| `security` | 涉及权限、租户、敏感数据、密钥 | `references/security_gate.md` |
| `biz-safety` | 涉及 UGC、交互防刷、短信/通知 | `biz-safety-audit` 技能（content / interaction / sms 路由） |
| `code-review` | AI 生成代码准备合并、交付前代码质量 | `references/code_review_gate.md` |
| `release` | 要上线、灰度、回滚 | `references/release_gate.md` + `references/rollback_gate.md` |
| `quality` | 交付前治理自检、质量门禁、评分成熟度 | `references/governance_checklist.md` / `references/scorecard.md` |
| `interop` | 跨 skill 协作顺序不清楚 | `references/skill_interop_matrix.md` |

规则：本技能负责**治理总线与准入门禁**，不替代 `delivery-workflow` 的执行推进。凡是“现在具体怎么做需求/怎么改代码”，都应转回 `delivery-workflow`。

## 作用边界

**负责**：

- AI 研发生命周期阶段门（G0-G8）
- Spec / SDD / ADR / Task Contract / Security / Release / Quality 总体治理
- 跨 skill 协作矩阵与评分模型
- 风险升级与人工确认点

**不负责**：

- 具体代码实现 → `delivery-workflow` + 项目领域技能
- 文档 / SQL / 脚本备份与归档 → `doc-script-governance`
- skill 创建 / 优化 → `skill-engineering`
- prompt 资产沉淀 → `prompt-engineering`
- 人读技术洞察 → `project-insight-extractor`

## 核心原则

- **治理先于执行**：Spec / ADR / Contract 没收敛时，不进入高成本实现
- **门禁独立存在**：Security / Release / Quality 不因赶进度被吞进执行细节
- **Fast Path 可轻量，不可失控**：可简化治理产物，不可跳过必要门禁
- **执行归 delivery，治理归本技能**：避免一份技能同时承担“怎么做”和“先过哪些门”
- **知识转动作**：外部优秀方法只沉淀为目标契约、当前事实查证、风险反证、测试证据、薄切片交付与失败回灌，不把术语变成运行负担
- **Spec 是编译契约**：Full Path 先形成 Fact Pack，再生成、反证、校验和冻结 Spec；模板字段齐全不等于可实施

## 强制门禁

- 没有 Spec，不进入 Full Path 实现
- 有接口、字段、SQL、权限、状态机变化，必须有 Task Contract
- 跨项目、共享库、Java/Python 同步、前后端契约联动，必须过 Project Contract Gate
- Full Path 进入实现前必须有 SDD 或等价设计契约；有架构取舍，必须有 ADR
- Full Path 进入实现前必须通过 Spec Compiler `implementation-ready` 校验；`review/proposed` 不得当作冻结契约
- 涉及用户数据、权限、租户、密钥，必须过 Security Gate
- 涉及 UGC、交互、短信/通知，必须过 `biz-safety-audit`
- AI 生成代码准备合并，必须过 Code Review Gate
- 进入上线前，必须过 Release Gate + Rollback Gate
- 发生失败、返工、回滚，必须进入 Learning Gate（`delivery-workflow` R3）

## Fast Path 豁免

满足 `delivery-workflow` Fast Path 条件时，G1 Spec / G2 ADR / G3 Task Contract 可轻量化或口头收敛，**不得**跳过 G5 Quality Gate 与 G8 Learning Gate（若发生失败）。

## 闭环门

- 治理产物必须落到 Spec / SDD / ADR / Task Contract / Security / Release / Quality / Learning 的明确一类。
- 用户要求 AI 开发范式或 shared 研发体系评估时，先按 `references/governance/development_method_enhancement.md` 判断缺口，再决定是否转 `delivery-workflow`、`tdd-workflow` 或 `skill-engineering`。
- 进入具体实现时必须转 `delivery-workflow`；本技能不直接写代码。
- 涉及测试先行、红绿重构或质量内建时，可转 `tdd-workflow` 补测试节奏，再回 `delivery-workflow` 推进实现。
- 失败、返工、回滚必须进入 Learning Gate，并与 `delivery-workflow` R3 对齐。
- 收口前按 `references/governance/behavior_audit.md` 反查治理偏航、反证问题、闭环证据与回灌动作。

## References 优先级

**P0 执行真源（按路由直接打开）**

- `references/lifecycle_map.md`
- `references/code_review_gate.md`
- `references/security_gate.md`
- `references/release_gate.md`
- `references/rollback_gate.md`
- `references/governance_checklist.md`
- `references/gates/project_contract_gate.md`
- `references/scorecard.md`
- `references/skill_interop_matrix.md`

**P1 支撑资产（命中条件再读）**

- `references/quality_gate.md`
- `references/observability_gate.md`
- `references/risk_review_matrix.md`
- `references/trigger_eval.md`
- `references/closure_example.md`
- `references/governance/behavior_audit.md`
- `references/governance/development_method_enhancement.md`
- `references/governance/spec_compiler_workflow.md`
- `templates/TEMPLATE_FEATURE_SPEC.md`
- `templates/TEMPLATE_SDD.md`
- `templates/TEMPLATE_ADR.md`
- `templates/TEMPLATE_TASK_CONTRACT.md`
- `references/governance/spec_compiler_eval.md`

其余索引和模板目录仅作维护/资产承接，不作为并列 Agent 入口。

## trigger / eval

完整正负例见 `references/trigger_eval.md`。主文件只保留记忆规则：

- **should-trigger**：AI 开发规范/体系/总纲、Spec 生成/冻结/稳定性、AI 开发范式、治理阶段门、上线前门禁、Security / Release / Quality / Code Review、评分成熟度、跨 skill 协作顺序、业务安全审计路由
- **should-not-trigger**：具体接口实现、文档放置、SKILL 审查、已满足 Fast Path 的单点执行问题

## 与其他技能关系

| 技能 | 何时转移 |
|------|----------|
| `delivery-workflow` | 进入需求推进、实现、验证、失败沉淀时 |
| `doc-script-governance` | 涉及 docs / SQL / 脚本放置与备份时 |
| `skill-engineering` | 目标产物是 `SKILL.md` / skill 结构时 |
| `prompt-engineering` | 要沉淀 `*.prompt.md` 资产时 |
| `project-insight-extractor` | 要沉淀给人读的方法论/洞察时 |
| `biz-safety-audit` | 涉及 UGC/交互/短信的业务安全审计时 |
| `tdd-workflow` | 质量内建、测试先行、回归用例保护时 |
