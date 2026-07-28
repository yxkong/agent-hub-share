---
title: <中文标题> Task Contract
status: in_progress
document_type: task_contract
spec_id: SPEC-<topic>
spec_version: 1.0.0
version: 1.0.0
approval: draft
created: YYYY-MM-DD
updated: YYYY-MM-DD
related:
  - path: docs/design/<domain>/SDD-<topic>.md
    role: source
---

# Task Contract: <中文标题>

> **文档性质**：连接 frozen Spec/SDD 与 `delivery-workflow` 实现；`approval: frozen` 前不得进入实现。

## 修订记录

| 版本 | 日期 | 修订要点 | 备份/引用 |
|---|---|---|---|
| 1.0.0 | YYYY-MM-DD | 初稿：冻结 TASK-001 范围和验收 | — |

## 任务目标

TASK-001 实现 REQ-001，并交付 AC-001 的最小闭环。

## 路由

frontend / backend / fullstack / debug / checklist。

## 输入

- Spec：SPEC-<topic> 1.0.0
- SDD：<path>
- ADR：DEC-001 / NOT_APPLICABLE
- 项目技能：<skill §章节>
- 事实锚点：FACT-001

## 范围

### 只允许改

- <精确文件/目录白名单>

### 禁止改

- <精确黑名单和无关用户改动>

### 越界处理

- 白名单外改动先停止并更新 Contract。
- 与用户/历史改动冲突时保留现状并标 NEEDS_CONTEXT。
- 代码与设计冲突时先裁决真源，不用兼容层掩盖。

## 契约

| 契约面 | 冻结内容 | 关联需求 |
|---|---|---|
| API / DTO / DB / 状态 / 权限 / 配置 | <契约> | REQ-001 / SEC-001 |

## Project Contract

- 触发原因：跨项目 / 共享 DB / API-前端 / Java-Python / NOT_APPLICABLE
- 当前真源：<path>
- 参与项目/技能：<范围>
- 差异与裁决：<结论>

## 验收标准

| Task | 验收项 | 主链/失败链 | 通过判据 |
|---|---|---|---|
| TASK-001 | AC-001 | <链路> | <判据> |

## TDD 执行判定

| 行为 | 上游锚点 | 判定（TDD / TEST_AFTER / NOT_APPLICABLE） | Red 预期失败 | Green 命令 | Refactor 结论 |
|---|---|---|---|---|---|
| <行为> | AC-001 | TDD | <失败> | `<command>` | <结论> |

## 主链证据矩阵

| 主链步骤 | 证据等级（static / contract / runtime / user-visible / release / limitation） | 实际证据 | 结论/局限 |
|---|---|---|---|
| AC-001 | runtime | `<artifact>` | <结论> |

## 回退方式

- git checkpoint：<commit / NOT_APPLICABLE>
- 文件备份：<backup-file 产物>
- SQL/配置回滚：<路径 / NOT_APPLICABLE>
- feature flag：<key / NOT_APPLICABLE>
- 回退验证：<命令/观察入口>

## 完成状态

只允许：DONE / DONE_WITH_CONCERNS / NEEDS_CONTEXT / BLOCKED。
