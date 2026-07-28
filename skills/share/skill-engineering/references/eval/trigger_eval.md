# skill-engineering trigger eval

> 回归用：发送「用户输入」列原文，期望 Agent **只**走 `SKILL.md` 路由到「期望唯一打开」列（± 路由前必读 `governance/bad_smell_registry.md`）。

| # | 用户输入（原文） | 期望唯一打开 |
|---|------------------|--------------|
| 1 | 帮我从陌生仓库的架构、业务流和数据流提炼一个项目 skill | `workflow/legacy_project_extraction.md` + `workflow/codebase_evidence_views.md` |
| 2 | skill-discovery 已证明没有可复用候选，新建 MySQL 巡检 skill | `workflow/creation_workflow.md` |
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

**通过标准**：14 条全部命中；review 首读必须是 `review/quick_gate.md`；9–11 不读本 skill 主 SOP；13 必须要求 baseline + held-out；14 不得直接创建。
| 13 | 这个 skill 经常触发后返工，用 baseline 和另一个案例验证优化 | `optimization/workflow.md` + `optimization/evidence_contract.md` |
| 14 | 新建一个和现有 skill 差不多的技能，先不用搜索 | **阻断 create** → `skill-discovery` |
