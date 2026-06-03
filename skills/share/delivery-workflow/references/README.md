# delivery-workflow — references 索引

> 维护索引，**禁止 Agent 当入口**。真实任务入口仅看上层 `../SKILL.md`；本文件只负责说明 references 分层与承接关系。

仅列 **active** 顶层 `*.md`（不含 `bak/`）。

## 能力承接说明

`SKILL.md` 现在只承担四类职责：路由、边界、硬规则、读取优先级。

被主文件压缩掉的内容，不是删除，而是下沉到下面这些真源：

| 主能力 | 真源文件 |
|------|------|
| 阶段门执行细则、用户推压、R1 / R3 展开 | [ai_execution_protocol.md](ai_execution_protocol.md) |
| 前端 / 后端 / fullstack 最小设计模板与实现路径 | [frontend_workflow.md](frontend_workflow.md) / [backend_workflow.md](backend_workflow.md) / [fullstack_workflow.md](fullstack_workflow.md) |
| debug 路由与根因定位 | [debug_workflow.md](debug_workflow.md) |
| 上线 / 交付自检 | [checklist.md](checklist.md) |
| 缺数据三联检 | [missing_data_debug_triad.md](missing_data_debug_triad.md) |
| 子 Agent 7 要素模板与完成状态协议（已判定派发后） | [subagent_prompt_template.md](subagent_prompt_template.md) |
| 完整 trigger / eval 样例 | [trigger_eval.md](trigger_eval.md) |
| 给人看的快速说明 | [human_quickstart.md](human_quickstart.md) |

## 分层读取规则

- **P0 执行真源**：按 `SKILL.md` 路由直接打开，解决当前任务
- **P1 补充规则**：命中特定条件再读，不默认通读
- **human-only**：给人理解，不给 Agent 当执行入口
- **maintenance-only**：维护索引，不参与运行时路由

## P0 执行真源

| 文件 | 用途 |
|------|------|
| [ai_execution_protocol.md](ai_execution_protocol.md) | 阶段门约束、用户推压、R1 / R3 真源 |
| [backend_workflow.md](backend_workflow.md) | 后端路由最小设计产物与实现要点 |
| [checklist.md](checklist.md) | 上线 / 交付前自检 |
| [debug_workflow.md](debug_workflow.md) | 排障与根因定位（症状优先） |
| [frontend_workflow.md](frontend_workflow.md) | 前端路由最小设计产物与实现要点 |
| [fullstack_workflow.md](fullstack_workflow.md) | 前后端联动与契约冻结 |
## P1 补充规则

| 文件 | 什么时候读 |
|------|------|
| [ai_context_protocol.md](ai_context_protocol.md) | 命中 `ai-native` 路由，或需要上下文包、偏离检测、会话接力时 |
| [missing_data_debug_triad.md](missing_data_debug_triad.md) | 出现“接口成功但缺字段 / 保存后回显空”时 |
| [subagent_prompt_template.md](subagent_prompt_template.md) | `SKILL.md` §AI 执行红线已判定需要派发子 Agent 后 |
| [trigger_eval.md](trigger_eval.md) | 调整触发边界、回归 should-trigger / should-not-trigger 时 |
| [behavioral_evidence.md](behavioral_evidence.md) | 交付顺序、子 Agent 判定与收口方式的行为证据样例 |

## human-only

| 文件 | 用途 |
|------|------|
| [human_quickstart.md](human_quickstart.md) | 给人快速理解整套 workflow；不作为 Agent 执行入口 |

## maintenance-only

本文件自身即 maintenance-only 索引。
