# Task Contract: <任务标题>

> 连接 Spec 与 `delivery-workflow` 实现。可落 `docs/plan/<domain>/` 或项目技能 `references/meta/*_contract.md`。

## 任务目标

一句话描述本次最小闭环。

## 路由

frontend / backend / fullstack / debug / checklist

## 输入

- 头脑风暴 / 方案收敛：
- Spec：
- ADR：
- 参考实现：
- 项目技能：
- 相关代码：

## 范围

### 只允许改

-

### 禁止改

-

### 越界处理

- 发现必须改白名单外文件时：先停止并更新 Contract，不得顺手扩大范围。
- 发现用户/历史改动与本任务冲突时：保留现状并说明冲突，不得回退非本轮改动。
- 发现代码与文档/设计不一致时：先判定真源，再决定改代码、改文档或登记 limitation。

## 契约

- API：
- DTO：
- DB：
- 状态：
- 权限：
- 配置：

## Project Contract（跨项目时必填）

- 触发原因：跨项目 / 共享 DB / API-前端 / Java-Python / 其他：
- 当前真源：
- 参与项目 / 技能：
- 契约差异：
- 裁决结论：

## 验收标准

- [ ] 主链路：
- [ ] 失败链路：
- [ ] 自动化验证：
- [ ] 手动验证：
- [ ] 文档 / SQL / 配置落点：

## 主链证据矩阵

| 主链步骤 | 证据等级（static / contract / runtime / user-visible / release / limitation） | 实际证据 | 结论 / 局限 |
|---|---|---|---|
|  |  |  |  |

## 回退方式

- git checkpoint：
- 文件备份：
- SQL 回滚：
- feature flag：
