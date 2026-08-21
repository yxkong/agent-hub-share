# Skill Interop Matrix

> 七层模型：**L0 路由 → L1 治理总线 → L2 交付 → L3 资产治理 → L4 能力资产 → L5 验证闭环 → L6 项目领域**。

## 层级与主 skill

| 层级 | 目标 | 主 skill |
|------|------|----------|
| L0 资产路由 | 判定产物是代码 / 文档 / prompt / skill / insight | `agent-asset-router` |
| L1 治理总线 | 生命周期、阶段门、评分、风险矩阵 | **`ai-development-governance`** |
| L2 交付执行 | 需求理解、设计收敛、实现、验证、失败沉淀 | `delivery-workflow` |
| L3 资产治理 | docs / SQL / script 放置、备份；业务安全审计 | `doc-script-governance`、`biz-safety-audit` |
| L4 能力资产 | skill / prompt / insight 创建与优化；skill 评分 | `skill-engineering`、`prompt-engineering`、`project-insight-extractor`、`skill-scorecard`、`skill-discovery` |
| L5 验证闭环 | TDD 测试先行；浏览器黑盒验证 | `tdd-workflow`、`webapp-testing` |
| L6 项目领域 | 具体前后端 / 平台实现 | 项目 dev skills |

## 横向增强层

持久上下文与多视角反证只作为横向增强，不改变七层主导关系：

| 能力 | 吸收方式 | 禁止 |
|------|------|------|
| 持久上下文 | Full Path 过程区、任务状态、archive 与真源回灌 | 把过程区当长期唯一真源 |
| 多视角反证 | 目标 / 工程 / 体验 / 评审 / 验证 / 发布 / 复盘视角 | 用视角名替代证据，或默认派发子 Agent |
| 反迎合头脑风暴 | 先暴露 fact / assumption / unknown / risk，再收敛方案 | 直接包装用户方案为最佳实践 |

细则见 [context_persistence_gate.md](context_persistence_gate.md)。

## 按阶段协作

| 阶段 | 主 skill | 辅 skill | 典型产物 |
|------|----------|----------|----------|
| 需求入口 G0 | `delivery-workflow` | `ai-development-governance`、`agent-asset-router` | Fast/Full 初判；必要时转治理或资产路由 |
| Spec G1 | `ai-development-governance` | `delivery-workflow` | Feature Spec |
| 设计 G2 | `delivery-workflow` | `ai-development-governance` | 最小设计 / ADR |
| 任务契约 G3 | `ai-development-governance` | `delivery-workflow` | Task Contract |
| 实现授权 G4a | `ai-development-governance` | `agent-hub-bootstrap` | 授权语义 / Codex Hook |
| 实现 G4b | `delivery-workflow` | 项目领域 skill | 按许可证白名单写入 |
| 子 Agent 派发 | `delivery-workflow` | `prompt-engineering` | 7 要素 / hub prompt |
| 代码审查 G5a | `ai-development-governance` | `delivery-workflow` | code review 记录 |
| 测试验证 G5b | `delivery-workflow` | `tdd-workflow`、`webapp-testing` | 测试证据 / 截图 / 日志 |
| 开发安全 G6a | `ai-development-governance` | — | security_gate 勾选 |
| 业务安全 G6b | `biz-safety-audit` | `ai-development-governance` | 业务安全审计结论 |
| 文档落档 | `doc-script-governance` | `delivery-workflow` | docs / SQL / config |
| skill 优化 | `skill-engineering` | `doc-script-governance`、`skill-scorecard` | SKILL.md / references |
| 发布 G7 | `ai-development-governance` | `doc-script-governance` | release / rollback 文档 |
| 失败 G8 | `delivery-workflow` R3 | `project-insight-extractor` / `prompt-engineering` / `skill-engineering` | insight / 反模式 / prompt |
| 持久上下文 | `ai-development-governance` | `doc-script-governance`、`delivery-workflow` | 过程区状态、archive、真源回灌 |

## 冲突裁决

| 冲突 | 裁决 |
|------|------|
| 先读 governance 还是 delivery？ | **研发任务默认先进 `delivery-workflow` 做入口 triage**；问体系/规范/门禁/评分，或 triage 判定需要 Spec/ADR/Task Contract → governance |
| Spec 放哪？ | 过程 `docs/plan/`；终版升格 `docs/design/` — **`doc-script-governance` 为准** |
| 过程区和 docs/design 谁是真源？ | 过程区只记录本次变更；长期有效规则必须回灌 `docs/design/` 或 skill / prompt / insight |
| 多视角反证和现有 skill 谁主导？ | 多视角只提供审查问题；执行仍归 `delivery-workflow`，门禁仍归 governance，落位仍归 doc-script |
| 验证清单听谁的？ | 执行细节 `delivery-workflow/checklist`；门禁框架 `ai-development-governance/quality_gate` |
| 失败沉淀去哪？ | R3 三路分流；治理缺口回填 `governance_checklist` |

## 固定顺序（真实研发）

1. `delivery-workflow` 进场做 Fast/Full triage（体系/规范/门禁/评分或需 G1–G3 产物时转 governance，再回 delivery）
2. 写/改 docs/SQL → `doc-script-governance`
3. 写代码 → 先过 governance 写入授权门，再转项目领域技能（可配合 `tdd-workflow`）
4. 代码审查 → `ai-development-governance` G5 code_review_gate
5. 测试验证 → `tdd-workflow` + `webapp-testing` + delivery-workflow 三联检
6. 安全审计 → `ai-development-governance` G6 security_gate + `biz-safety-audit`（涉及 UGC/交互/短信时）
7. 上线前 → `ai-development-governance` G7 release/rollback
8. 失败 → R3 + 可选 insight / skill 回填
