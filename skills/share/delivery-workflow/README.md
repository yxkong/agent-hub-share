# delivery-workflow

> 面向**人类维护者**的维护章程，**不是 Agent 运行入口**。真实任务入口只看同目录 `SKILL.md`；`references/README.md` 只做 references 分层索引。

面向 AI 真实研发交付的通用 workflow：需求理解、设计收敛、最小实现、验证收口与失败沉淀。

> 与 `doc-script-governance` 的协作顺序见 `rules/common/COMMON_AGENT_RULES.md` §研发全流程。

## 修订记录

| 版本 | 日期 | 修订要点 |
|------|------|----------|
| 1.1.0 | 2026-06-04 | 同步真实协作算子 P0、行为模式变更确认、trigger/eval 口径与 R1/R3 边界 |
| 1.0.0 | 2026-05-21 | 初版：delivery 节奏总线、Fast/Full Path、R1/R2/R3 与 references 分层 |

## 核心用途

用于约束 Agent 面对真实研发任务时，如何按低返工成本推进：先路由，再决定 Fast / Full Path，再按阶段门推进实现、验证与失败沉淀。

## 设计理解 / 设计哲学

- `delivery-workflow` 是**研发节奏总线**，不是某一端技术实现手册
- 主文件应保持**路由器化**：只保留边界、硬规则、读取优先级，不展开大段细节
- 具体能力分散到 references 真源，避免主文件和细则双写后漂移
- 具体业务 prompt、示例资产、human-only / maintenance-only 文件清单不进入主文件
- 默认优先解决高返工风险：先锁根因/契约，再进入实现

## 分层原则 / 结构约定

- `SKILL.md`：唯一 Agent 入口；负责路由、边界、R1/R2/R3、P0/P1 优先级
- `references/*.md`
  - `P0`：执行真源，按路由直接打开
  - `P1`：补充规则，命中特定条件再读
  - `human-only`：只给人理解，不给 Agent 当入口
  - `maintenance-only`：维护索引，不参与运行时路由
- `README.md`：维护章程，不复制 `SKILL.md` 正文

## 维护约束

- 修改 `SKILL.md` 时，必须同步检查 `README.md`、`references/README.md`、相关真源 references 是否仍一致
- 若主文件缩减或搬迁能力，优先在 `README.md` / `references/README.md` 写清承接关系，不把维护解释层搬回 `SKILL.md`
- 新增 reference 时，要先判定它属于 `P0 / P1 / human-only / maintenance-only` 的哪一层
- `human_quickstart.md`、`references/README.md` 这类文件必须持续保持“**禁止 Agent 当入口**”降权声明
- 新增 share prompt 示例时，只更新 prompt 索引或 `prompt-engineering` 相关资产；`subagent_prompt_template.md` 只保留通用 7 要素模板，不枚举具体业务场景

## 单一职责

- 定义研发任务从理解到交付的统一推进节奏
- 约束 Fast Path / Full Path 的分流条件
- 约束主模型与执行档子 Agent 的分工方式
- 统一失败沉淀与可复用 prompt 的出口
- 为前端 / 后端 / fullstack / debug 提供共同上层框架

## 不负责 / 转交

| 场景 | 转交 |
|------|------|
| 规范、Spec、ADR、Security / Release Gate | `ai-development-governance` |
| 文档类型、目录、模板、backup、SQL 放置 | `doc-script-governance` |
| 创建 / 提炼 / 审查 `SKILL.md` | `skill-engineering` |
| 浏览器黑盒验证 | `webapp-testing` |
| 子 Agent 长指令沉淀 | `prompt-engineering` |
| 给人读的技术洞察 | `project-insight-extractor` |

## 关键读取地图

| 层级 | 文件 | 用途 |
|------|------|------|
| `P0` | `references/debug_workflow.md` | 排障主链 |
| `P0` | `references/frontend_workflow.md` | 前端实现 |
| `P0` | `references/backend_workflow.md` | 后端实现 |
| `P0` | `references/fullstack_workflow.md` | 前后端联动 |
| `P0` | `references/checklist.md` | 上线前自检 |
| `P0` | `references/ai_execution_protocol.md` | 阶段门、推压处理、R1/R3 |
| `P0` | `references/real_collaboration_operators.md` | 真实协作算子与行为模式变更确认 |
| `P1` | `references/ai_context_protocol.md` | 上下文注入、任务切分、偏离检测 |
| `P1` | `references/missing_data_debug_triad.md` | 接口成功但缺数据三联检 |
| `P1` | `references/subagent_prompt_template.md` | 已判定派发子 Agent 后的 7 要素模板 |
| `P1` | `references/trigger_eval.md` | trigger / eval 回归样例 |
| `P1` | `references/behavioral_evidence.md` | 交付节奏与子 Agent 边界的行为证据样例 |
| `human-only` | `references/human_quickstart.md` | 给人快速理解整套流程 |
| `maintenance-only` | `references/README.md` | references 分层与承接索引 |
