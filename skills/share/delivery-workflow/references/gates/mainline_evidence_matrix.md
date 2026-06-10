# 主链证据矩阵

> 解决“看起来完成但没有行为证据”的返工源。用于 Full Path、跨模块、接口/字段/SQL/权限/状态机变更，以及任何用户要求交付闭环的任务。

## 证据等级

| 等级 | 含义 | 可接受证据 | 不足以单独证明 |
|---|---|---|---|
| `static` | 静态代码/文档检查 | diff、类型检查、编译、lint、结构审查 | 用户主链可用、数据正确 |
| `contract` | 契约对齐 | API schema、DTO、DDL、字段映射、菜单/权限配置 | 运行时实际生效 |
| `runtime` | 运行链路执行过 | 单元/集成测试、接口调用、CLI 命令、日志片段 | 页面可见或发布可观测 |
| `user-visible` | 用户可见结果已确认 | 页面截图、浏览器 smoke、生成文件、接口响应样例 | 上线后稳定性 |
| `release` | 上线/灰度/回滚证据 | CI、Release Gate、Rollback Gate、观测指标、回滚点 | 需求正确性 |
| `limitation` | 未验证或未实现边界 | `NOT_RUN`、`OUT_OF_SCOPE`、`BLOCKED`、`DDL Only` | 不能包装成完成项 |

## 最小填写格式

```markdown
| 主链步骤 | 证据等级 | 实际证据 | 结论 / 局限 |
|---|---|---|---|
| 保存配置 | runtime | `POST /api/...` 返回 200，DB 行已更新 | pass |
| 回显配置 | user-visible | 页面刷新后字段仍显示 | pass |
| 生产发布 | limitation | 本轮未部署 | NOT_RUN，不宣称上线完成 |
```

## 阻断规则

- Full Path 至少需要 `runtime` 或 `user-visible` 中的一类证据；只有 `static` / `contract` 时，结论必须降级。
- 涉及数据写入、保存后回显、详情缺字段时，先走 `missing_data_debug_triad.md`，再填矩阵。
- 涉及上线时，不新增独立 runbook；直接把 `release_gate.md`、`rollback_gate.md`、`observability_gate.md` 的结果填入 `release` 行。
- 未能运行验证不是失败，但必须写成 `limitation`，并给出最小后续验证动作。
