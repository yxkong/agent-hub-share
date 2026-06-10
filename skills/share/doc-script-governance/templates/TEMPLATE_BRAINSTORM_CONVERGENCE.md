---
title: <主题> 头脑风暴与方案收敛
status: in_progress
version: 1.0.0
created: YYYY-MM-DD
updated: YYYY-MM-DD
summary: <一句话说明本次要收敛什么方案>
related:
  - path: docs/design/<domain>/<TOPIC>_DESIGN.md
    role: plan_for
  - path: docs/design/<domain>/ADR-<topic>.md
    role: plan_for
---

# <主题> 头脑风暴与方案收敛

> **文档性质**：`docs/plan/<domain>/` 过程稿。用于方案发散、反迎合检查和最小闭环收敛；完成后必须回灌 Spec / ADR / Task Contract / DESIGN，不作为长期真源。

## 修订记录

| 版本 | 日期 | 修订要点 | 备份/引用 |
|---|---|---|---|
| 1.0.0 | YYYY-MM-DD | 初稿 | — |

## 1. 触发与目标

- 用户原始诉求：
- 真实目标：
- 成功验收：
- Fast / Full Path 初判：

## 2. 反迎合自检

| 项 | 内容 | 证据 / 下一步 |
|---|---|---|
| fact | | |
| assumption | | |
| unknown | | |
| risk | | |
| 反方问题 | | |
| 更小闭环 | | |
| 不做 / 暂缓条件 | | |

## 3. 方案选项

| 方案 | 解决什么 | 代价 | 风险 | 是否保留 |
|---|---|---|---|---|
| A | | | | |
| B | | | | |

## 4. 多视角反证

| 视角 | 反证问题 | 结论 | 证据 |
|---|---|---|---|
| 目标 | 是否解决真实用户目标？是否存在更小可验证结果？ | | |
| 工程 | 数据流、状态机、接口、权限、失败模式是否冻结？ | | |
| 体验 | 可见状态、空态、错误态、恢复路径是否一致？ | | |
| 评审 | 哪些问题会绕过 happy path、单元测试或风格检查？ | | |
| 验证 | 是否有命令、日志、截图、响应体、DB 或浏览器证据？ | | |
| 发布 | 发布、回滚、开关、监控和文档是否齐备？ | | |
| 复盘 | 失败应回灌到 insight、anti-pattern、prompt 还是 skill？ | | |

## 5. 收敛决策

- 选择方案：
- 不选方案：
- 决策原因：
- 最小闭环：
- 人工确认点：

## 6. 回灌计划

| 产物 | 是否需要 | 目标路径 | 状态 |
|---|---|---|---|
| Feature Spec | 是 / 否 | `docs/plan/<domain>/...` | |
| ADR | 是 / 否 | `docs/design/<domain>/ADR-<topic>.md` | |
| Task Contract | 是 / 否 | `docs/plan/<domain>/...` 或 skill `references/meta/...` | |
| DESIGN | 是 / 否 | `docs/design/<domain>/<TOPIC>_DESIGN.md` | |
| Review | 是 / 否 | `docs/review/<domain>/...` | |
| Skill / Prompt / Insight | 是 / 否 | | |

## 7. 关闭条件

- [ ] `unknown` 已有最小验证或明确 blocked。
- [ ] 更小闭环已定义，并能进入 Spec / ADR / Task Contract。
- [ ] 长期有效结论已回灌或登记回灌计划。
- [ ] 本过程稿状态已更新为 `done` / `superseded` / `blocked`。
