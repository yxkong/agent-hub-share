# Observability Gate

> G7 Release Gate 的监控子集；Full Path 发版前建议完整执行。

## 触发条件

- 新接口 / 新异步链路 / 新集成
- 性能或稳定性敏感改动
- Release Gate 监控章节需要展开时

## 检查项

### 日志

- [ ] 关键路径有结构化日志
- [ ] 含 traceId / requestId（或项目等价物）
- [ ] 错误日志含足够上下文，不含 secrets

### 指标

- [ ] 核心接口 QPS / 延迟 / 错误率可观测
- [ ] 新业务指标已定义（若有）

### 追踪

- [ ] 跨服务调用可关联（若适用）

### 告警

- [ ] 错误率 / 延迟阈值告警已配置或已登记待办

### 调试友好

- [ ] 支持按 userId / tenantId / 业务单号定位

## Fast Path

纯内部工具 / 无生产流量 → 声明跳过。

## 与 delivery-workflow 关系

「接口成功但缺数据」类问题 → 同时参考 `missing_data_debug_triad.md` 与本文日志/追踪项。
