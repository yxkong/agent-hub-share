---
name: delivery-workflow
description: 面向 AI 真实研发交付的通用 workflow 技能（delivery workflow, stage gate, Fast Path, debug, fullstack）。**任何研发任务到达时自动触发**：新增功能、接口开发、Bug 修复、重构优化、前后端联动、SQL/数据迁移。按阶段门推进：需求理解→设计收敛→最小实现→验证收口→复盘落盘→失败沉淀；含路由规则、Fast/Full Path 分级、「接口成功但缺数据」三联检。Gate 5 复盘只写入 `$AGENTS_HUB_ROOT/docs/resource/replay/` 供后续 Agent 分析，禁止写业务工程 `docs/resource/`；洞察/prompt 沉淀分别走 project-insight-extractor / prompt-engineering。不负责提炼 skill 或研发 SOP；那属于 skill-engineering。
---

# Delivery Workflow

## 30 秒决策区

| 任务类型 | 什么时候选它 | 先读什么 |
|------|------|------|
| `debug` | 报错、异常、数据不对、功能不符合预期、定位根因 | `references/debug_workflow.md`（P0） |
| `frontend` | 页面、组件、UI、表单、弹窗、前端交互 | `references/frontend_workflow.md`（P0） |
| `backend` | 接口、SQL、数据库、后端服务、权限、状态机 | `references/backend_workflow.md`（P0） |
| `fullstack` | 前后端联动、字段未定、接口契约未冻结 | `references/fullstack_workflow.md`（P0） |
| `reference-first` | 跨模块重构、全仓迁移、样板工程、给其他模型派发前 | `references/gates/reference_implementation_gate.md`（P0） |
| `tdd` | 用户明确要求先写测试、补回归用例、红绿重构 | `tdd-workflow` |
| `checklist` | 上线前、交付前、自检、review 前 | `references/checklist.md`（P0） |
| `rd-audit` | 研发体系审计、闭环验证、证据复核、技能健康 / release evidence / replay 复核 | `references/gates/ai_rd_closure_audit.md`（P0） + share audit prompt |
| `ai-native` | 上下文注入、任务切分、子 Agent 调度、偏离检测 | `references/ai_context_protocol.md`（P1） |

规则：**症状优先**。只要任务以排障/定位根因为主，即使同句出现前后端词，也先走 `debug`。不是纯排障后，再按单端 / 联动决定 `frontend`、`backend`、`fullstack`。用户明确说“研发体系审计 / 闭环验证 / 体系复核 / 技能健康 / release evidence / Task Replay”时，走 `rd-audit`，不当作普通 checklist。

## 作用边界

**负责**：指导 AI 将真实研发任务按低返工成本推进到交付，覆盖需求理解、设计收敛、最小实现、验证收口、复盘落盘与失败沉淀。

**不负责**：

- 制定规范 / 总纲 / Spec / ADR / Security / Release Gate → `ai-development-governance`
- 文档类型、目录、模板、备份、SQL 放置 → `doc-script-governance`
- 创建 / 提炼 / 审查 `SKILL.md` → `skill-engineering`
- 浏览器黑盒验证 → `webapp-testing`
- 子 Agent 长指令沉淀 → `prompt-engineering`（返工后 R3，非 Gate 5 复盘）
- 给人读的洞察 / 面试表达 → `project-insight-extractor`（用户明确要求时，非 Gate 5 复盘）

## 上游治理入口

命中以下任一条件，先转 `ai-development-governance`，本技能不替代治理总线：

| 条件 | 先读 |
|------|------|
| 制定规范 / 体系 / 总纲 / 评分 | `ai-development-governance` |
| Full Path 但尚未形成 Spec | `ai-development-governance/templates/TEMPLATE_FEATURE_SPEC.md` |
| 涉及架构取舍 | `ai-development-governance/templates/TEMPLATE_ADR.md` |
| 涉及上线、灰度、回滚 | `ai-development-governance/references/release_gate.md` |
| 涉及权限、租户、敏感数据、密钥 | `ai-development-governance/references/security_gate.md` |
| 涉及 UGC、交互防刷、短信/通知 | `biz-safety-audit` 技能 |
| AI 代码准备合并 / 交付前代码质量 | `ai-development-governance/references/code_review_gate.md` |

## 核心原则

- **Fast Path 默认**：单点小改、契约不变、验证明确时直接实现；Full Path 是例外
- **Full Path 先发散后收敛**：需求歧义、跨端、接口/字段/SQL/权限/状态机改动时先设计
- **主链路优先**：先完成最小闭环，再补失败链路和边角
- **验证前置**：没有主链路证据，不算完成
- **失败不白费**：返工必须进入 R3 沉淀

## Fast Path / Full Path

| 模式 | 适用条件 | 执行动作 |
|------|----------|----------|
| `Fast Path` | 单文件或单点小改；不改接口/数据结构；不跨模块；验证清楚；失败成本低 | 写一段最小设计摘要后直接实现 |
| `Full Path` | 需求有歧义；涉及接口/字段契约；前后端联动；SQL/配置/权限/状态机；影响多模块或返工成本高 | 先收敛目标、边界、契约、风险、验证路径，再进入实现 |

具体模板与推压处理见 `references/ai_execution_protocol.md` 与各路由 `*_workflow.md`。跨模块重构、全仓迁移、样板工程或给其他模型派发前，必须先读 `references/gates/reference_implementation_gate.md`。

## AI 执行红线

| 规则 | 最小要求 | 细则 |
|------|----------|------|
| 主模型默认负责 | 路由、阶段门、方案权衡、白名单范围、验收与汇总 | `references/ai_execution_protocol.md` |
| 子 Agent 派发判定 | 仅当同时满足：机械落盘 + 路径/内容/验收已齐 + 硬触发 | 本节 |
| Prompt 成文 | 已决定派发后，再按 7 要素组织 prompt | `references/subagent_prompt_template.md` |

**硬触发**：写入 **≥ 2** 个文件；或单文件预计 **> 1500** 输出 token；或已有 share `agent-task` prompt 的批量机械任务。

未命中硬触发、或属调查 / 方案 / 单文件小改 → 主模型在本会话直接执行，**禁止**为偷懒派子 Agent。

**样板先行门**：跨模块重构、全仓迁移、统一标准、最终版架构或给 Gemini/子 Agent 派发前，必须先产出参考样板、范围白黑名单、分层落点、验证命令和停止条件；未完成样板验证不得批量执行。执行细则见 `references/gates/reference_implementation_gate.md`。

## R1 / R2 / R3

| 规则 | 要求 | 细则 |
|------|------|------|
| `R1` | 进入实现前先输出 `[实现阶段] 路由：delivery-workflow/<route> → 项目技能 <skill> § <章节路径>` | `references/ai_execution_protocol.md` |
| `R2` | 派子 Agent 时，`model` 必须为 `-fast` 执行档；prompt 必须含范围、最小上下文包、验收/验证标准、完成状态协议 | `references/subagent_prompt_template.md` |
| `R3` | 失败/返工必须沉淀到：认知洞察 / Agent 反模式 / 可复用 prompt 三路之一 | `references/ai_execution_protocol.md` |

本体系不引入“每任务默认三子 Agent 串行审查”。

## 阶段门速记

| Gate | 最小要求 | 细则 |
|------|----------|------|
| `Gate 1 需求理解` | 分清业务目标、现象、根因、真实边界 | `references/ai_execution_protocol.md` |
| `Gate 2 设计收敛` | 收敛目标、边界、契约、风险、验证路径；Full Path 先发散再收敛 | 各路由 `*_workflow.md` |
| `Gate 3 实现推进` | 一次一个最小闭环；进入下一闭环前做 checkpoint | `references/ai_execution_protocol.md` |
| `Gate 4 验证完成` | 主链路、关键失败链路、文档/SQL/配置落点都过；Full Path 必须给出主链证据矩阵；缺数据问题补三联检 | `references/checklist.md` + `references/gates/mainline_evidence_matrix.md` + `references/missing_data_debug_triad.md` |
| `Gate 5 复盘` | Gate 4 后读 `replay_body_template.md`（6 个账本 + `gate5-v2`）+ closeout prompt，Path Guard 通过后落盘到 hub replay + `check-replay-structure.ps1` | `references/gates/delivery_replay.md` + `references/gates/replay_body_template.md` |
| `Gate 6 失败沉淀` | 返工先归因，按 R3 handoff packet 路由到目标技能 | `references/ai_execution_protocol.md` + `references/gates/r3_handoff_contract.md` |
| `Audit 研发体系审计` | 用户用关键词触发时，按入口真源、证据闭环、发布证据、Replay/Skill Health、脚本化治理五类审计；输出 P0/P1/P2 与验证判据 | `references/gates/ai_rd_closure_audit.md` + `prompts/share/agent-task/prompt-share-agent-task-ai-rd-closure-audit.prompt.md` |

## 闭环门

- 需求已过 Gate 1 / 2，或明确属于 Fast Path。
- 实现前已满足 R1；派发子 Agent 时已满足 R2。
- 验证至少覆盖主链路；Full Path 已按 `references/gates/mainline_evidence_matrix.md` 标出 static / contract / runtime / user-visible / release / limitation 证据；缺数据类问题完成三联检。
- Full Path / 跨模块 / 交付闭环任务已在 Gate 5 复盘落盘到 `$AGENTS_HUB_ROOT/docs/resource/replay/`（或明确标 `不落盘` / `BLOCKED` 原因）。
- 失败 / 返工已按 R3 分流到 insight / 反模式 / prompt（Gate 6）。
- 收口前按 `references/behavior_audit.md` 过一遍偏航信号、反证问题、闭环证据与回灌动作。

## References 优先级

**P0 执行真源（按路由直接打开）**

- `references/debug_workflow.md`
- `references/frontend_workflow.md`
- `references/backend_workflow.md`
- `references/fullstack_workflow.md`
- `references/checklist.md`
- `references/gates/mainline_evidence_matrix.md`
- `references/gates/delivery_replay.md`
- `references/gates/r3_handoff_contract.md`
- `references/gates/ai_rd_closure_audit.md`
- `references/gates/reference_implementation_gate.md`
- `prompts/share/agent-task/prompt-share-agent-task-delivery-closeout-summary.prompt.md`（Gate 5 执行模板）
- `prompts/share/agent-task/prompt-share-agent-task-ai-rd-closure-audit.prompt.md`（研发体系审计执行模板）
- `references/ai_execution_protocol.md`
- `references/real_collaboration_operators.md`

**P1 补充规则（命中条件再读）**

- `references/ai_context_protocol.md`
- `references/missing_data_debug_triad.md`
- `references/subagent_prompt_template.md`（仅在本文件 §AI 执行红线已判定需要派发子 Agent 后读取）
- `references/ai-native/subagent_review_protocol.md`（已决定派发且需要审查实现产物时）
- `references/ai-native/plan_micro_step_contract.md`（Full Path 计划 / Task Contract 需要交给零上下文执行者时）
- `references/trigger_eval.md`
- `references/behavioral_evidence.md`
- `references/behavior_audit.md`

其余人读/维护索引文档通过协议降权，不在主文件重复枚举；见 `README.md` 与 `references/README.md`。

## trigger / eval

完整正负例见 `references/trigger_eval.md`。主文件只保留一条记忆规则：

- **should-trigger**：任何真实研发任务、排障、联动开发、交付自检、研发体系审计 / 闭环验证、流程元问题
- **should-not-trigger**：提炼/审查 skill、文档放置治理、领域实现细节本身

## 与其他技能的关系

| 技能 | 何时转移 |
|------|----------|
| `ai-development-governance` | 问体系、Spec/ADR、上线安全、评分时 |
| `skill-engineering` | 目标产物是 `SKILL.md` / SOP 时 |
| `doc-script-governance` | 涉及文档/SQL 放置、模板、备份时 |
| `tdd-workflow` | 用户要求 test-first、补回归测试、红绿重构时 |
| `project-insight-extractor` | 用户要洞察/面试表达；**读取** Gate 5 的 `docs/resource/replay/` 为 source_anchor |
| `prompt-engineering` | 返工后 R3 需可复用 `Task` prompt 时 |
| `biz-safety-audit` | 涉及 UGC/交互/短信的业务安全审计时 |
| `<frontend-domain-skill>` / `<backend-domain-skill>` | 进入具体实现阶段时 |
