# agent-asset-router

## 定位

Agent 资产类任务的轻量总路由器：当任务同时涉及 skill、prompt、hub、文档、洞察或平台评审时，判定第一跳技能与执行顺序。

## 核心要点

- **只做路由**：不创建 SKILL.md、不写 prompt 正文、不跑挂载脚本。
- **先定产物**：给 Agent 用 skill/prompt；给人读 insight/review；让客户端看见归 hub bootstrap；放置备份归 docs 治理。
- **混合任务顺序**：发现/评估 -> 内容创建 -> 挂载/同步 -> 验证/归档；不并行改同一真源。
- **真源在 hub**：所有正文维护指向 `$AGENTS_HUB_ROOT/`，挂载入口仅镜像。

## 关键 references

| 文件 | 用途 |
|------|------|
| `references/trigger_eval.md` | should-trigger / should-not-trigger、第一跳分流回归 |
| `references/closure_example.md` | 混合任务的真实分诊顺序样例 |

## 协作入口

| 信号 | 第一跳 |
|------|--------|
| 有没有现成 skill | `skill-discovery` |
| 新建/审查/优化 skill | `skill-engineering` |
| 沉淀长指令/prompt | `prompt-engineering` |
| 复盘/面试/洞察 | `project-insight-extractor` |
| hub 初始化/挂载 | `agent-hub-bootstrap` |
| docs/SQL 放置 | `doc-script-governance` |
| 项目 review | `<project-review-skill>` |
