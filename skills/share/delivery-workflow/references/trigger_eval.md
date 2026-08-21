# delivery-workflow — trigger / eval

主技能仅保留指针；完整样例在本文件维护。

## should-trigger

**研发任务（自动触发，无需用户先问流程）**：

| 任务类型 | 触发信号示例 | 默认路由 |
|---|---|---|
| 新增/实现功能 | 「帮我实现 X」「新增 Y 功能」「写 Z 接口」 | backend / frontend / fullstack |
| Bug 修复/排查 | 「修复 X 问题」「接口 500」「数据不对」「为什么 Y 不生效」 | debug → 改动 |
| 重构/优化 | 「重构 X」「优化 Y 性能」「把 Z 拆成模块」 | backend / frontend |
| 前后端联动 | 「前后端联调」「前端对接 X 接口」「接口字段未定」 | fullstack |
| **交付与可观测性** | 「你压根都没有改」「验收没过」「子 Agent 漂移了」 | Full Path：优先补足范围白名单 + 验证命令 + R3 沉淀 |
| **方案设计/探索** | 「怎么设计 X」「有没有更好的方案」「这个架构合理吗」「如何做最合理」 | Full Path Gate 2（发散→收敛） |
| **问题左移/架构原则** | 「问题越早暴露成本越低」「设计时考虑四高二低三底座」「不要等实现后再审计」 | Gate 1/2：先暴露问题，再用架构透镜形成决策与取舍 |
| 上线/交付前自检 | 「上线前检查」「帮我 review 一下」「提交前确认」 | checklist |
| **研发体系审计与验证** | 「审计我的研发体系」「做一次闭环验证」「复核 release evidence / Task Replay / Skill Health」「脚本化治理是否闭环」 | rd-audit |

**流程元问题（也触发）**：

- 「直接写 / 先做再说 / 小 Bug 不用确认」→ 仍走 Fast/Full 判定与写入授权门，不得用催促绕过
- 「继续上次实现」但无当前 task/hash/确认状态 → 降回等待确认，不从旧对话猜授权
- 「四高二低三底座」→ 默认解释为设计期架构问题发现透镜；只有用户明确要求审计已完成产物时才走 checklist/rd-audit

- 「这个需求先做什么后做什么？」
- 「什么时候必须先设计，什么时候可以直接写代码？」
- 「前后端怎么分工，契约怎么定？」
- 「如何减少联调返工？」
- 「这个功能怎么拆成最小可验证单元？」
- 「需求理解完了，接下来怎么推进？」
- 「接口 200 但缺数据 / 报错 / 功能不符合预期 / 如何定位根因？」（→ `debug_workflow.md`）
- 「研发体系是否闭环？」「证据闭环是否够？」「技能健康信号怎么验证？」「release evidence 要不要单独 runbook？」（→ `gates/ai_rd_closure_audit.md`）

## should-not-trigger

- 「帮我从这个项目提炼一个 skill」（→ `skill-engineering`）
- 「帮我审查这个 SKILL.md」（→ `skill-engineering`）
- 「文档放哪个目录？」（→ `doc-script-governance`）
- 「给这段交付写事实复盘」但不审计体系（→ Gate 5 replay，不走 `rd-audit`）

说明：具体接口 / 页面实现仍 should-trigger `delivery-workflow` 做流程门与范围约束；进入实现阶段后，具体代码落地转项目领域技能。
