---
title: <主题> 设计（终版）
status: canonical
version: 1.0.0
created: YYYY-MM-DD
updated: YYYY-MM-DD
summary: <一句话：解决什么业务/架构问题>
related:
  - path: docs/plan/<domain>/<TOPIC>_PLAN.md
    role: plan_for
  - path: docs/design/<domain>/README.md
    role: canonical
---

# <主题> 设计

> **文档性质**：`docs/design/<domain>/` **终版**（canonical）。执行/重构见 `docs/plan/<domain>/`；不得在此写本轮代码 diff。

## 修订记录

| 版本 | 日期 | 修订要点 | 备份/引用 |
|------|------|----------|-----------|
| 1.0.0 | YYYY-MM-DD | 初稿 | — |

---

## 1. 目标与范围

<!-- [必填] 业务目标、不做什么 -->

## 2. 角色与场景

<!-- [必填] 谁在用、主场景 -->

## 3. 概念与术语

<!-- [可选] 与代码无关的领域词汇 -->

## 4. 流程与状态

<!-- [必填] Mermaid 或步骤；语言无关 -->

```mermaid
flowchart LR
  A[起点] --> B[终点]
```

## 5. 规则与约束

<!-- [必填] 权限、租户、幂等、失败策略等 -->

## 6. 数据与接口（逻辑层）

<!-- [必填] 表/消息/API 的**逻辑**说明，不写具体类名包路径 -->

## 7. 可观测 / 非功能（若适用）

<!-- [可选] trace、指标、限流 -->

## 8. 实现状态

<!-- [必填] 已落地 / 差距 / 指向 plan 与 review -->

| 项 | 状态 | 说明 |
|----|------|------|
| 主链路 | 已落地 / 部分 / 未开始 | |
| 已知差距 | — | 链到 `docs/plan/` 或 `docs/review/` |

## 9. 相关文档

| 类型 | 路径 |
|------|------|
| 域索引 | `docs/design/<domain>/README.md` |
| 执行/重构计划 | `docs/plan/<domain>/...` |
| 实现说明 | `docs/implementation/...` |
| Review | `docs/review/<domain>/...` |
| Agent 契约 | `.claude/skills/.../references/meta/...` |
