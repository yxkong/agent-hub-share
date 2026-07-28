---
title: <中文标题> Feature Spec
status: in_progress
document_type: feature_spec
spec_id: SPEC-<topic>
version: 1.0.0
approval: draft
created: YYYY-MM-DD
updated: YYYY-MM-DD
related:
  - path: docs/plan/<domain>/<TOPIC>_BRAINSTORM.md
    role: source
---

# Feature Spec: <中文标题>

> **文档性质**：Full Path 的需求规格真源。`approval: frozen` 前不得进入实现。

## 修订记录

| 版本 | 日期 | 修订要点 | 备份/引用 |
|---|---|---|---|
| 1.0.0 | YYYY-MM-DD | 初稿：冻结目标、范围、契约和验收 | — |

## 1. Fact Pack

| ID | 类型 | 事实或判断 | 来源路径/命令 | 证据等级 |
|---|---|---|---|---|
| FACT-001 | current_code | <当前可验证事实> | `<source-anchor>` | static / contract / runtime / user-visible |

### Assumptions

| ID | 假设 | 最小验证动作 | 失效影响 |
|---|---|---|---|
| ASM-001 | <当前假设> | <验证命令或人工确认> | <影响> |

### Unknowns

| ID | 未知项 | 是否阻断冻结 | 关闭条件 |
|---|---|---|---|
| UNK-001 | <未知项> | yes / no | <证据或人工裁决> |

### Risks

| ID | 风险 | 等级 | 缓解或停止条件 |
|---|---|---|---|
| RISK-001 | <风险> | P0 / P1 / P2 / P3 | <动作> |

## 2. 目标与价值

- 目标用户：<用户角色>
- 当前问题：<基于 FACT 的问题>
- 用户价值：<为什么值得做>
- 可观察结果：<用户或系统能观察到的变化>
- 更小闭环：<先证明价值的最小切片>

## 3. 范围

### In Scope

- <本次必须完成的能力>

### Out of Scope

- <明确不做的能力>

## 4. 用户场景

| ID | 用户 | 触发条件 | 期望结果 | 失败时可恢复动作 |
|---|---|---|---|---|
| SCN-001 | <用户> | <触发> | <结果> | <恢复动作> |

## 5. 需求与业务规则

| ID | 需求/规则 | 事实来源 | 优先级 | 异常情况 |
|---|---|---|---|---|
| REQ-001 | <可观察功能需求> | FACT-001 | P0 / P1 | <异常> |

## 6. 契约

| 契约面 | 唯一术语/字段 | 输入 | 输出 | 错误/空值语义 |
|---|---|---|---|---|
| 页面 / API / DTO / DB / 状态 / 权限 / 配置 | <契约> | <输入> | <输出> | <语义> |

## 7. 非功能与安全

| ID | 类型 | 可量化约束 | 验证入口 |
|---|---|---|---|
| NFR-001 | latency / throughput / cost / availability / compatibility / observability | <数值预算或 NOT_APPLICABLE 原因> | <命令/指标> |
| SEC-001 | auth / tenant / data / injection / secret / AI safety / rollback | <确定性约束或 NOT_APPLICABLE 原因> | <测试/审计> |

## 8. 验收标准

| ID | 对应需求 | 场景 | 可观察结果 | 通过判据 |
|---|---|---|---|---|
| AC-001 | REQ-001 | 主链路 / 失败 / 权限 / 数据 / 回归 | <结果> | <判据> |

## 9. TDD / 验证映射

| 验收项 | 可测试行为 | 验证类型（TDD / TEST_AFTER / MANUAL / NOT_APPLICABLE） | 证据等级（static / contract / runtime / user-visible / release / limitation） |
|---|---|---|---|
| AC-001 | <行为> | TDD | runtime |

## 10. 风险与人工确认点

| 风险/决策 | 影响 | 是否需要人工确认 | 确认人/结论 |
|---|---|---|---|
| RISK-001 | <影响> | yes / no | <确认记录> |

## 11. 追踪矩阵

| 需求/约束 | 设计锚点 | 验收项 | 状态 |
|---|---|---|---|
| REQ-001 | SDD §<章节> | AC-001 | covered |
| NFR-001 | SDD §<章节> | AC-001 | covered |
| SEC-001 | SDD §<章节> | AC-001 | covered |
