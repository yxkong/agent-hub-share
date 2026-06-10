# references 索引

> 维护索引，禁止当 Agent 第一入口；运行入口仍以根 `SKILL.md` 为准。

| 文件 | 用途 |
|------|------|
| [lifecycle_map.md](lifecycle_map.md) | G0–G8 阶段门：触发、输入、输出、Blocker、Fast/Full Path |
| [scorecard.md](scorecard.md) | 9.8+ 量化评分模型（100 分制） |
| [quality_gate.md](quality_gate.md) | G5 质量验证门禁 |
| [security_gate.md](security_gate.md) | G6 安全合规门禁 |
| [release_gate.md](release_gate.md) | G7 发布门禁 |
| [rollback_gate.md](rollback_gate.md) | G7 回滚门禁 |
| [observability_gate.md](observability_gate.md) | 可观测性与监控门禁 |
| [risk_review_matrix.md](risk_review_matrix.md) | 风险分级与人工确认矩阵 |
| [skill_interop_matrix.md](skill_interop_matrix.md) | 跨 skill 协作矩阵 |
| [governance_checklist.md](governance_checklist.md) | 交付前治理自检清单 |
| [context_persistence_gate.md](context_persistence_gate.md) | 持久上下文与多视角反证横向门 |
| [gates/project_contract_gate.md](gates/project_contract_gate.md) | 跨项目 / 共享 DB / Java-Python / 前后端联动契约门 |
| [trigger_eval.md](trigger_eval.md) | should-trigger / should-not-trigger、治理入口回归 |
| [closure_example.md](closure_example.md) | 真实质量门 / 学习门闭环样例 |

## 轻量闭环术语

- `Release Evidence`：发布证据，归 [release_gate.md](release_gate.md) / [rollback_gate.md](rollback_gate.md) / [observability_gate.md](observability_gate.md)，不新增 `release-ops-runbook`。
- `Task Replay Lite`：失败或重复返工时回放任务证据，归 G8 Learning Gate 与 [governance_checklist.md](governance_checklist.md)。
- `Skill Health Signal`：由同类返工、trigger 误判、SOP 无法定位等信号回填 scorecard / bad smell / trigger eval，不新增 skill health dashboard。

空白模板在技能根 [templates/](../templates/)，不在本目录。
