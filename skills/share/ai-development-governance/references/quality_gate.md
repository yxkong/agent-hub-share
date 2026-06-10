# Quality Gate（G5）

> 与 `delivery-workflow` §验证完成门、`references/checklist.md` 对齐；本文件补充 AI 开发专项检查。
>
> **代码审查**：G5 同时包含 [code_review_gate.md](code_review_gate.md)（命名/架构/错误处理/安全内建），本文件聚焦测试验证。

## 触发条件

- 任一实现闭环完成
- 用户要求「交付前自检 / review 前确认」
- 准备进入 G7 Release Gate 前

## 必测路径

### 主链路

- [ ] 用户能完成核心动作
- [ ] API 返回符合契约（含字段名、类型、嵌套结构）
- [ ] 数据落库正确
- [ ] 页面展示正确

### 失败链路

- [ ] 参数缺失 / 非法
- [ ] 无权限 / 越权
- [ ] 数据不存在
- [ ] 重复提交 / 幂等
- [ ] 状态不允许的操作

### 回归链路

- [ ] 旧接口不破坏
- [ ] 旧页面不破坏
- [ ] 旧数据兼容
- [ ] 旧配置兼容

### AI 开发专项

- [ ] 没有超 Task Contract 范围改文件
- [ ] 跨项目任务已执行 Project Contract Gate，且共享 DB/API/前端回显未只改单端
- [ ] 没有绕过项目架构或依赖方向
- [ ] 没有凭空新增未对齐的模式
- [ ] 没有跳过验证命令就宣称完成
- [ ] Full Path 已按主链证据矩阵区分 static / contract / runtime / user-visible / release / limitation
- [ ] 若「接口 200 但缺数据」：已按 `delivery-workflow/references/missing_data_debug_triad.md` 三层排查

## Fast Path

主链路 + 1 条关键失败链路 + 最小验证命令即可。

### 性能（高并发 / 大数据量场景，按需）

- [ ] 核心接口响应时间可接受（有基线或预期）
- [ ] 批量操作 / 大列表查询有分页或流式处理
- [ ] 数据库查询有 EXPLAIN 验证（无全表扫描）
- [ ] 缓存策略合理（命中率 / 过期 / 穿透防护）

## Full Path

上表全部勾选（含 code_review_gate）；review 记录可落 `docs/review/<domain>/`。

## 未通过

- 不得进入 G7 Release Gate
- 根因记入 scorecard「测试与验证」或「代码审查」维度；返工走 G8
