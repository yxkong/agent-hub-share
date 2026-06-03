---
title: <主题> Agent 契约
status: canonical
version: 1.0.0
created: YYYY-MM-DD
updated: YYYY-MM-DD
summary: <Agent 可执行的字段、阶段、枚举、禁止项>
related:
  - path: docs/design/<domain>/<TOPIC>_DESIGN.md
    role: canonical
---

# <主题> Agent 契约

> **文档性质**：技能 `references/meta/*_contract.md`。冲突时以 DESIGN 终版为准。

## 修订记录

| 版本 | 日期 | 修订要点 | 备份/引用 |
|------|------|----------|-----------|
| 1.0.0 | YYYY-MM-DD | 初稿 | — |

---

## 1. 适用范围

<!-- [必填] 哪些 Executor / 前端 / 上报点须遵守 -->

## 2. 阶段 / Phase 注册表

<!-- [必填] 与 AiTracePhaseRegistry 或等价一致 -->

| phaseKey | 展示名 | 必填 payload 字段 |
|----------|--------|-------------------|

## 3. 字段契约

<!-- [必填] 类型、枚举、默认值 -->

## 4. 树拓扑 / UI 规则（若适用）

<!-- [必填] Assembler 须实现的节点 -->

## 5. 禁止与兼容

<!-- [必填] 不得删除的字段、废弃阶段 -->

## 6. 变更流程

1. 先改 DESIGN 或确认无业务变更  
2. 再改本契约  
3. 同步 §修订记录  
