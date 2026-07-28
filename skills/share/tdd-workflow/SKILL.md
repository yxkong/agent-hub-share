---
name: tdd-workflow
description: 测试驱动开发共享技能（TDD, test-first, red-green-refactor）。用于新增或修复逻辑时先写失败测试、最小实现、重构并保留验证证据；适用于单元测试、组件测试、契约测试、回归用例补齐。不替代 delivery-workflow 的研发阶段门、项目领域技能的实现细节或 webapp-testing 的浏览器黑盒验证。
---

# TDD Workflow

## 30 秒决策区

| 任务类型 | 什么时候选它 | 先读什么 |
|---|---|---|
| `unit` | 纯函数、服务、领域逻辑、bugfix 回归 | `references/workflow.md` |
| `contract` | 接口字段、DTO、序列化、数据库边界 | `references/workflow.md` |
| `component` | 前端组件状态、交互、渲染分支 | `references/workflow.md` |
| `legacy-safe` | 老代码缺测试，需要先补安全网再改 | `references/workflow.md` |

规则：本技能只管测试先行节奏；负责行为证据与回归保护，不替代目标契约、ADR、当前事实查证或风险反证。真实需求推进仍由 `delivery-workflow` 主导，具体实现仍回项目领域技能。

## 作用边界

**负责**：把 Spec / SDD / Task Contract 中的可验证需求转成红绿重构闭环，补回归测试、最小实现、重构与证据。

**不负责**：

- 需求拆分、Fast/Full Path、阶段门 → `delivery-workflow`
- 测试框架安装、项目脚手架大改 → 项目领域技能 / `agent-hub-bootstrap`
- 浏览器黑盒验证 → `webapp-testing`
- 质量治理总纲、上线门禁 → `ai-development-governance`

## 核心原则

- **先失败再实现**：没有可复现失败测试，不宣称 TDD。
- **最小绿灯**：只写让当前测试通过的最小实现。
- **重构不改行为**：绿灯后再清理结构，重构前后测试结果一致。
- **证据优先**：输出测试命令、失败摘要、通过摘要和未覆盖风险。
- **契约对齐**：Red 用例必须追溯到 Spec / SDD / Task Contract / bug 复现之一，不能凭空扩大需求。

## 闭环门

| 阶段 | 必须产物 |
|---|---|
| Red | 失败测试或明确说明无法先写测试的原因 |
| Green | 最小实现 + 对应测试通过 |
| Refactor | 结构清理后测试仍通过；没有重构则说明原因 |
| Evidence | 命令、结果、覆盖范围、剩余风险 |

若无法创建或运行测试，标 `unknown` / `blocked`，不要伪装成已 TDD。
若只是先实现再补测试，必须标 `TEST_AFTER`，不能宣称 TDD；只有记录 Red 失败摘要、Green 通过摘要和 Refactor 后结论，才算 TDD 闭环。
收口前按 `references/behavior_audit.md` 反查伪 TDD、happy path 偏航、证据缺口与回灌动作。

## References 优先级

**P0**

- `references/workflow.md`
- `references/trigger_eval.md`
- `references/closure_example.md`
- `references/behavior_audit.md`

其余索引文档仅维护用，不作 Agent 入口。

## trigger / eval

完整样例见 `references/trigger_eval.md`。主文件只保留记忆规则：

- **should-trigger**：先写测试、补回归用例、红绿重构、给 bug 加测试保护、接口契约测试
- **should-not-trigger**：只做页面黑盒点检、只问上线门禁、只问 docs 放置、无可验证行为的纯文案任务

## 与其他技能的关系

| 技能 | 何时转移 |
|---|---|
| `delivery-workflow` | 需求推进、实现阶段门、验证收口 |
| `ai-development-governance` | 质量门禁、Release/Security/治理要求 |
| `webapp-testing` | 浏览器黑盒、端到端 UI 主链路 |
| `<project-domain-skill>` | 具体测试框架、代码实现与项目约定 |
