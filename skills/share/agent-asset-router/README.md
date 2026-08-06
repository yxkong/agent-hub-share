# agent-asset-router

> 维护章程，不是 Agent 运行入口；运行时只读 `SKILL.md`。

## 定位

仅服务 `project_type=engineering` 的工程资产分流。它处理工程任务中 code、Spec/ADR、docs/SQL、test、review、replay、skill、prompt、insight 的产物归属和执行顺序，不负责具体实现。

## 装配边界

- registry 组：`engineering-only`
- 允许项目类型：`engineering`
- 禁止项目类型：`generic`、`media`、`hub`、`mixed`
- 不进入用户级 `global`，也不作为其它 profile 的兜底路由器

## 维护要点

- 修改触发边界时同步 `SKILL.md` 与 `references/trigger_eval.md`。
- 修改工程产物类型时同步 `references/asset_placement_contract.md`。
- 修改 registry 后验证五类项目场景矩阵，确保只有 engineering 可解析到本技能。

## 关键 references

| 文件 | 用途 |
|---|---|
| `references/trigger_eval.md` | 工程正例与跨体系负例 |
| `references/closure_example.md` | 工程混合资产路由样例 |
| `references/asset_placement_contract.md` | 工程资产 Path Guard |

## 修订记录

| 版本 | 日期 | 修订要点 |
|---|---|---|
| 1.1.0 | 2026-08-05 | 收紧为 engineering-only；移除 media/hub/global/mixed 路由职责 |
| 1.0.0 | 2026-05-29 | 建立跨资产第一跳路由 |
