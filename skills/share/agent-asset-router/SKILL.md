---
name: agent-asset-router
description: 工程体系资产路由技能（engineering asset router）。仅在已确认 `project_type=engineering` 的工程项目中，当任务同时涉及代码、Spec/ADR、docs/SQL、test、review、replay、skill、prompt 或 insight 且目标产物/owner 不明确时触发；不得在 generic、media、hub、mixed 体系中挂载或触发。
---

# Agent Asset Router

## 前置门

- 仅允许 `project_type=engineering`；该身份来自已登记项目配置，不得仅凭任务含“代码”“文档”等关键词猜测。
- 项目类型未知时，先加载已登记项目身份；仍无法确认则询问用户，不得进入本技能。
- `generic / media / hub / mixed` 一律转当前 profile 或项目首跳，不得使用本技能兜底。

## 作用边界

本技能只负责工程任务中资产类型、owner skill、canonical path 和多产物顺序的裁决，不创建正文、不实现代码、不执行挂载。

覆盖：
- code / spec / ADR / docs / SQL / test / review / replay / skill / prompt / insight 的工程资产分流
- 多产物工程任务的顺序拆分
- “是否需要沉淀工程 skill / prompt / insight / replay”的第一跳判断

不覆盖：
- 媒体内容、账号运营与内容发布（转 media profile）
- Hub 维护、安装、注册、挂载和插件构建（转 `ai-hub-maintainer` / `agent-hub-bootstrap`）
- generic、mixed 或其它非纯工程体系的通用分诊
- 任何目标技能负责的正文或实现

工程资产落位的唯一真源是 `references/asset_placement_contract.md`。

## 30 秒路由表

| 工程任务信号 | 第一跳 | 后续协作 |
|---|---|---|
| “这个工程产物放哪”“spec/replay/docs/test/prompt 分不清” | `agent-asset-router` | 读 `references/asset_placement_contract.md` 后转 owner |
| feature / bug / refactor / API / frontend / backend | `delivery-workflow` | 再转项目领域技能 |
| Spec / ADR / Security / Release / 研发治理 | `ai-development-governance` | 实施节奏转 `delivery-workflow` |
| 单测 / 契约测试 / 回归测试 | `tdd-workflow` | 浏览器黑盒转 `webapp-testing` |
| docs / SQL / 脚本放置与备份 | `doc-script-governance` | 真实研发推进转 `delivery-workflow` |
| 查找或新增工程 skill | `skill-discovery` | 无候选后转 `skill-engineering` |
| 工程长指令 / agent-task prompt | `prompt-engineering` | 挂载同步另转 owner |
| 工程复盘 / 技术案例 / 面试表达 | `project-insight-extractor` | 交付事实轨迹归 replay |
| 项目代码/设计评审 | `<project-review-skill>` | 名称从项目规则解析 |

## 混合任务顺序

1. 先按 `references/asset_placement_contract.md` 判定 `asset_type / scope / owner_skill / canonical_path`。
2. 新建工程 skill 前先走 `skill-discovery`；没有 exact/partial 候选再转 `skill-engineering`。
3. 按“需求/证据 → 内容创建 → 验证 → 归档/沉淀”排序，不并行修改同一真源。
4. 路由后立即退出本技能，由 owner skill 完成内容和验证闭环。

## 最小输出

```text
工程路由决策：目标产物是 <产物>，第一跳使用 <skill>；后续验证/落盘由 <skill> 负责。
```

## 闭环门

- 已确认当前 `project_type=engineering`。
- 已确定唯一第一跳、canonical path 与 owner skill。
- 未把 media / hub / generic / mixed 任务吸入工程资产路由。
- 目标明确时直接进入目标技能，不重复经过本路由器。

## trigger / eval

完整正负例见 `references/trigger_eval.md`：

- **should-trigger**：仅工程项目中，多个工程资产类型或 owner 不明确。
- **should-not-trigger**：非 engineering 项目；项目类型未知；目标技能已明确；纯业务实现。

真实分诊样例见 `references/closure_example.md`；工程资产落位见 `references/asset_placement_contract.md`。
