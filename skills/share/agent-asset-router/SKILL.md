---
name: agent-asset-router
description: Agent 资产类任务的轻量总路由器（asset router, skill routing）。用于 skill、prompt、hub、文档治理、技术洞察、长文内容成稿、项目评审、TDD 测试闭环等混合任务时，先判定目标产物并转交 skill-discovery、skill-engineering、prompt-engineering、project-insight-extractor、`<private-media-skill>`、agent-hub-bootstrap、doc-script-governance、ai-development-governance、biz-safety-audit、tdd-workflow 或 `<project-review-skill>`。
---

# Agent Asset Router

## 作用边界

本技能只做一件事：当任务同时落在多个 Agent 资产技能之间时，快速判断 **该先读哪个技能**，并避免重复读取无关 SOP。

覆盖：
- skill / prompt / hub / docs / insight / review 之间的路由选择
- 多产物任务的执行顺序拆分
- “要不要新增一个 skill / prompt / 文档资产”的第一跳判断

不覆盖：
- 具体创建或修改 `SKILL.md`（转 `skill-engineering`）
- 编写可执行 prompt（转 `prompt-engineering`）
- hub 挂载、同步、入口修复（转 `agent-hub-bootstrap`）
- 文档、SQL、脚本治理细则（转 `doc-script-governance`）
- 项目代码或设计评审正文（转 `<project-review-skill>`，技能名见 `rules/projects/<project-key>/PROJECT_RULES.md`）

## 30 秒路由表

| 用户目标信号 | 第一跳技能 | 后续常见协作 |
|---|---|---|
| “有没有现成技能”“找一个 skill”“外部安装技能”“这个能力该不该做成 skill” | `skill-discovery` | 无合适候选后转 `skill-engineering` |
| “新建 / 提炼 / 审查 / 优化 skill”“触发不准”“路由难用” | `skill-engineering` | 涉及真实源、挂载时再转 `agent-hub-bootstrap` |
| “把长指令 / 子 Agent prompt / 系统提示词沉淀为资产” | `prompt-engineering` | 落盘和索引后按需转 `agent-hub-bootstrap` 同步 |
| “复盘 / 面试表达 / 简历亮点 / 技术洞察 / 案例库” | `project-insight-extractor` | 若产出是给 Agent 执行的长指令，改转 `prompt-engineering` |
| “长文/图文对外成稿 / 内容频道连载 / 降 AI 味” | `<private-media-skill>` | 技能名见 maintainer hub `PROJECT_RULES.md`；素材归档可先 insight；改 docs 备份 → `doc-script-governance` |
| “hub 初始化 / 注册项目 / 同步技能 / 发布 skill / check-skill-links / Cursor 找不到技能” | `agent-hub-bootstrap` | 正文质量问题转 `skill-engineering` |
| “docs 放哪 / SQL dev 与 online / 备份策略 / 脚本治理 / review 文档目录” | `doc-script-governance` | 真实研发推进转 `delivery-workflow` |
| “项目代码评审 / 设计走查 / 上线前检查 / 领域 review” | `<project-review-skill>` | 涉及 docs 落档规则时补读 `doc-script-governance` |
| “AI 开发规范 / 体系 / 总纲 / 9.8 评分 / 生命周期门禁” | `ai-development-governance` | 真实研发推进转 `delivery-workflow`；文档落位转 `doc-script-governance` |
| “UGC/评论审核 / 防刷限流 / 短信轰炸 / 业务安全规则” | `biz-safety-audit` | 权限/租户/数据 → `ai-development-governance` G6 |
| “先写测试 / TDD / 补回归用例 / 红绿重构” | `tdd-workflow` | 真实研发阶段门仍由 `delivery-workflow` 主导 |

## 混合任务顺序

1. 先判定最终产物：给 Agent 用的是 skill 或 prompt；给人读的是 insight 或 review；让客户端看见的是 hub 挂载；放置和备份规则归 docs 治理。
2. 若用户要求“评估是否需要新增 skill”：先走 `skill-discovery` 查候选；无 exact 匹配再走 `skill-engineering create`。
3. 若需要改 hub 内真实源：执行目标技能前先确认备份要求；收尾按目标技能声明的校验脚本执行。
4. 若任务横跨多个产物：按 “发现/评估 → 内容创建 → 挂载/同步 → 验证/归档” 排序，不并行修改同一真实源。

## 冲突裁决

- 同一材料既能写成 prompt 又能写成 insight：给 Agent 复用执行则 `prompt-engineering`；给人复盘表达则 `project-insight-extractor`。
- 同一材料既能写成 insight 又能写成长文对外稿：深度复盘归 `project-insight-extractor`；对外连载正文归 `<private-media-skill>`。
- 同一需求既像 skill 又像 prompt：稳定流程、触发规则、工具路由写成 skill；一次性长指令或子 Agent 任务模板写成 prompt。
- 同一问题既像 docs 治理又像 hub bootstrap：目录、备份、命名归 `doc-script-governance`；链接、同步、入口脚本归 `agent-hub-bootstrap`。
- 项目评审输出需要落档时：评审判断归 `<project-review-skill>`；文档目录和备份策略只补读 `doc-script-governance`。

## 最小输出

路由完成后只输出一句决策即可，然后立即读取目标技能：

```text
路由决策：本次目标产物是 <产物>，第一跳使用 <skill>；若落盘/挂载，后续补 <skill>。
```

若目标产物仍不清楚，最多问一个澄清问题：**这是给 Agent 执行复用，还是给人阅读归档？**

## 闭环门

- 已明确唯一第一跳技能；不要同时展开多个主 SOP。
- 若涉及落盘，目标技能负责内容闭环，本技能只负责路由闭环。
- 若目标是 skill / prompt / docs / insight / hub 的混合任务，按“发现/评估 → 内容创建 → 挂载/同步 → 验证/归档”排序。
- 若路由后发现目标产物判断错误，回到本技能重新分流，并把误判信号沉淀给对应目标技能。

## trigger / eval

完整正负例见 `references/trigger_eval.md`。主文件只保留记忆规则：

- **should-trigger**：skill / prompt / insight / docs / hub / 内容成稿 / tdd 混合任务的第一跳判定
- **should-not-trigger**：目标技能已明确的直接执行问题

真实分诊顺序样例见 `references/closure_example.md`。
