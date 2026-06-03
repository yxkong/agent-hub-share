# skill-engineering trigger eval

> 回归用：发送「用户输入」列原文，期望 Agent **只**走 `SKILL.md` 路由到「期望唯一打开」列（± 路由前必读 `governance/bad_smell_registry.md`）。

| # | 用户输入（原文） | 期望唯一打开 |
|---|------------------|--------------|
| 1 | 帮我从老项目提炼一个 BI skill | `workflow/legacy_project_extraction.md` |
| 2 | 新建 MySQL 巡检 skill，还没有现成资产 | `workflow/creation_workflow.md` |
| 3 | 这个 skill 结构太乱，帮我审查 | `review/quick_gate.md`；系统修复再进 `review/checklist.md` + `review/router_handbook_gate.md` |
| 4 | description 触发不准，优化 trigger eval | `review/eval_playbook.md` |
| 5 | skill 改完怎么跑工程门禁 | `review/engineering_completion_gate.md` |
| 6 | references 顶层超过 15 个 md 怎么拆 | `layout/skill_directory_layout.md` |
| 7 | skill 应该挂到 cursor 还是 hub 真源 | `layout/placement_and_junctions.md` |
| 8 | 上次踩过多套路由，沉淀坏味道规则 | `governance/bad_smell_registry.md` |
| 9 | 这个需求先做什么后做什么 | **不触发** → `delivery-workflow` |
| 10 | 帮我改 BiTableConfig 后端接口 | **不触发** → `<backend-domain-skill>` 等项目领域技能 |
| 11 | 沉淀成 skill 还是 prompt 还是 insight | **不触发** → `agent-asset-router` |
| 12 | full 模式还要交哪些加强项 | `review/full_mode_checklist.md` |

**通过标准**：12 条中 1–8 命中正确路由；其中 review 首读必须是 `review/quick_gate.md`；9–11 不读本 skill 主 SOP；12 命中 P2 加强清单。
