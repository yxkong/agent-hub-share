# Rollback Gate（G7  companion）

> 与 [release_gate.md](release_gate.md) 成对使用。**无回滚资产不得上线。**

## 回滚资产清单

- [ ] **代码回滚点**：tag / commit / 分支名
- [ ] **配置回滚方式**：旧值记录或配置中心版本
- [ ] **SQL 回滚脚本**：路径 `docs/db/dev/<module>/`（dev）或运维提供的 online 流程
- [ ] **feature flag 关闭方式**
- [ ] **数据修复脚本**（若 migration 不可逆）
- [ ] **回滚验证路径**：如何确认回滚成功
- [ ] **回滚后观察入口**：错误率、关键业务指标、日志查询或用户可见 smoke

## 回滚触发条件

| 指标 | 阈值（示例，按项目填） | 动作 |
|------|------------------------|------|
| 错误率 |  | 回滚 / 关 flag |
| 延迟 P99 |  | 回滚 / 扩容 |
| 数据异常 |  | 停写 + 修复脚本 |
| 用户投诉 / 业务指标 |  | 人工决策 |

## 文档落位

| 产物 | 目录 |
|------|------|
| Rollback Plan | `docs/plan/<domain>/` |
| 回滚验收记录 | `docs/review/<domain>/` |

## Fast Path

可逆的单 commit 改动 → 记录 `git revert` 目标 commit 即可。

若本轮没有实际部署，回滚资产可标 `NOT_RUN`，但必须说明一旦发布时需要补齐的最小项。

## P0

- migration 不可逆且无数据修复方案 → 阻断上线，需 ADR 补充回滚策略
