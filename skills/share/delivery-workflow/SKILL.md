---
name: delivery-workflow
description: 面向 AI 真实研发交付的通用 workflow 技能（delivery workflow, stage gate, Fast Path, debug, fullstack）。**任何研发任务到达时自动触发**：新增功能、接口开发、Bug 修复、重构优化、前后端联动、SQL/数据迁移。按阶段门推进：需求理解→设计收敛→最小实现→验证收口→失败沉淀；含路由规则、Fast/Full Path 分级、「接口成功但缺数据」三联检。不负责提炼 skill 或研发 SOP；那属于 skill-engineering。
---

# Delivery Workflow

## 30 秒决策区

| 任务类型 | 什么时候选它 | 先读什么 |
|------|------|------|
| `debug` | 报错、异常、数据不对、功能不符合预期、定位根因 | `references/debug_workflow.md`（P0） |
| `frontend` | 页面、组件、UI、表单、弹窗、前端交互 | `references/frontend_workflow.md`（P0） |
| `backend` | 接口、SQL、数据库、后端服务、权限、状态机 | `references/backend_workflow.md`（P0） |
| `fullstack` | 前后端联动、字段未定、接口契约未冻结 | `references/fullstack_workflow.md`（P0） |
| `tdd` | 用户明确要求先写测试、补回归用例、红绿重构 | `tdd-workflow` |
| `checklist` | 上线前、交付前、自检、review 前 | `references/checklist.md`（P0） |
| `ai-native` | 上下文注入、任务切分、子 Agent 调度、偏离检测 | `references/ai_context_protocol.md`（P1） |

规则：**症状优先**。只要任务以排障/定位根因为主，即使同句出现前后端词，也先走 `debug`。不是纯排障后，再按单端 / 联动决定 `frontend`、`backend`、`fullstack`。

## 作用边界

**负责**：指导 AI 将真实研发任务按低返工成本推进到交付，覆盖需求理解、设计收敛、最小实现、验证收口与失败沉淀。

**不负责**：

- 制定规范 / 总纲 / Spec / ADR / Security / Release Gate → `ai-development-governance`
- 文档类型、目录、模板、备份、SQL 放置 → `doc-script-governance`
- 创建 / 提炼 / 审查 `SKILL.md` → `skill-engineering`
- 浏览器黑盒验证 → `webapp-testing`
- 子 Agent 长指令沉淀 → `prompt-engineering`

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

具体模板与推压处理见 `references/ai_execution_protocol.md` 与各路由 `*_workflow.md`。

## AI 执行红线

| 规则 | 最小要求 | 细则 |
|------|----------|------|
| 主模型默认负责 | 路由、阶段门、方案权衡、白名单范围、验收与汇总 | `references/ai_execution_protocol.md` |
| 子 Agent 派发判定 | 仅当同时满足：机械落盘 + 路径/内容/验收已齐 + 硬触发 | 本节 |
| Prompt 成文 | 已决定派发后，再按 7 要素组织 prompt | `references/subagent_prompt_template.md` |

**硬触发**：写入 **≥ 2** 个文件；或单文件预计 **> 1500** 输出 token；或已有 share `agent-task` prompt 的批量机械任务。

未命中硬触发、或属调查 / 方案 / 单文件小改 → 主模型在本会话直接执行，**禁止**为偷懒派子 Agent。

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
| `Gate 4 验证完成` | 主链路、关键失败链路、文档/SQL/配置落点都过；缺数据问题补三联检 | `references/checklist.md` + `references/missing_data_debug_triad.md` |
| `Gate 5 失败沉淀` | 返工先归因，再落到 R3 三路之一 | `references/ai_execution_protocol.md` |

## 闭环门

- 需求已过 Gate 1 / 2，或明确属于 Fast Path。
- 实现前已满足 R1；派发子 Agent 时已满足 R2。
- 验证至少覆盖主链路；缺数据类问题完成三联检。
- 失败 / 返工已按 R3 分流到 insight / 反模式 / prompt。

## References 优先级

**P0 执行真源（按路由直接打开）**

- `references/debug_workflow.md`
- `references/frontend_workflow.md`
- `references/backend_workflow.md`
- `references/fullstack_workflow.md`
- `references/checklist.md`
- `references/ai_execution_protocol.md`

**P1 补充规则（命中条件再读）**

- `references/ai_context_protocol.md`
- `references/missing_data_debug_triad.md`
- `references/subagent_prompt_template.md`（仅在本文件 §AI 执行红线已判定需要派发子 Agent 后读取）
- `references/trigger_eval.md`
- `references/behavioral_evidence.md`

其余人读/维护索引文档通过协议降权，不在主文件重复枚举；见 `README.md` 与 `references/README.md`。

## trigger / eval

完整正负例见 `references/trigger_eval.md`。主文件只保留一条记忆规则：

- **should-trigger**：任何真实研发任务、排障、联动开发、交付自检、流程元问题
- **should-not-trigger**：提炼/审查 skill、文档放置治理、领域实现细节本身

## 与其他技能的关系

| 技能 | 何时转移 |
|------|----------|
| `ai-development-governance` | 问体系、Spec/ADR、上线安全、评分时 |
| `skill-engineering` | 目标产物是 `SKILL.md` / SOP 时 |
| `doc-script-governance` | 涉及文档/SQL 放置、模板、备份时 |
| `tdd-workflow` | 用户要求 test-first、补回归测试、红绿重构时 |
| `project-insight-extractor` | 失败需沉淀给人看的方法论/洞察时 |
| `prompt-engineering` | 高质量 `Task` prompt 可复用时 |
| `biz-safety-audit` | 涉及 UGC/交互/短信的业务安全审计时 |
| `<frontend-domain-skill>` / `<backend-domain-skill>` | 进入具体实现阶段时 |
