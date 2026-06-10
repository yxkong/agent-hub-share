# Release Gate（G7）

> 上线 / 合并前必做。文档落位见 `doc-script-governance`；online SQL **禁止** Agent 直接写入。本体系不新增独立 `release-ops-runbook`，发布前/发布后证据直接收敛在本文、`rollback_gate.md` 与 `observability_gate.md`。

## 触发条件

- 准备合并到主分支、发版、部署 staging / prod
- 用户说「上线前检查」「可以发布了吗」

## 上线前必须确认

### CI

- [ ] build 通过
- [ ] lint 通过
- [ ] typecheck 通过（若项目有）
- [ ] test 通过（至少与改动相关的测试）

### 配置

- [ ] 新配置有默认值或安全降级
- [ ] 配置说明已落 `docs/config/`（若新增开关）
- [ ] prod / staging / dev 差异已说明

### 数据库

- [ ] migration 可重复执行或有幂等保护
- [ ] rollback SQL 准备完成（见 [rollback_gate.md](rollback_gate.md)）
- [ ] dev SQL 在 `docs/db/dev/`；**未**改 `docs/db/online/`

### 灰度与开关

- [ ] 是否需要 feature flag
- [ ] 是否需要分租户 / 分用户 / 分流量灰度
- [ ] 是否有关闭开关（kill switch）

### 监控（详见 [observability_gate.md](observability_gate.md)）

- [ ] 错误率可观测
- [ ] 响应时间 / 关键链路延迟
- [ ] 关键业务指标
- [ ] 日志含定位字段（traceId / userId / tenantId 等）

### 发布后观察

- [ ] 已写明观察窗口（如 15m / 30m / 1h，按项目风险确定）
- [ ] 已写明观察入口（日志、指标、后台页面、业务报表、用户反馈渠道）
- [ ] 已写明回滚触发条件，并与 `rollback_gate.md` 一致
- [ ] 若本轮未实际部署，交付结论标 `release: NOT_RUN`，不得宣称上线完成

### 通知

- [ ] 是否通知前端 / 运维 / 业务方（按项目约定）

### 文档

- [ ] Release Plan 落 `docs/plan/<domain>/`（Full Path）
- [ ] 终版 design / implementation 已同步（若有设计变更）

## Fast Path

个人分支 / 纯开发环境 smoke → CI + 主链路即可。

## 未通过

不得部署生产；补全后重新过门。
