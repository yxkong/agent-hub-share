# agent-asset-router — 工程路由闭环样例

## 场景

项目身份已登记为 `project_type=engineering`。任务同时要求：

- 修复接口缺陷
- 先补失败回归测试
- 记录接口契约变化
- 完成后沉淀交付 replay 与技术洞察

## route decision（contract）

1. 研发推进 → `delivery-workflow`
2. 失败测试与回归保护 → `tdd-workflow`
3. 契约与 ADR 门禁 → `ai-development-governance`
4. 文档落位与修改前备份 → `doc-script-governance`
5. 交付事实 → replay；给人读的方法论 → `project-insight-extractor`

## 结果判据

- 只产生一个第一跳，后续 owner 按依赖顺序接管。
- replay 与 insight 没有混成同一真源。
- 不加载 media、hub 或 generic workflow。

## 非适用对照

若同样的“多产物”请求发生在 media、hub、generic 或 mixed 项目中，本技能不得触发；由对应 profile 或项目首跳裁决。
