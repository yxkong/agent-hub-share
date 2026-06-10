# 持久上下文与多视角反证门

> 横向增强门：补齐 Full Path 的过程上下文、归档回灌和反迎合审查，但不改变 G0-G8、`delivery-workflow`、`doc-script-governance` 的主导关系。

## 触发

命中任一条件时启用：

- Full Path 研发任务。
- 跨模块、接口、字段、SQL、权限、状态机、发布回滚变更。
- 用户要求 9.8+、一次通过评审、全链路闭环。
- 用户要求头脑风暴、方案优化、体系整合、长期闭环，且存在迎合用户方案的风险。
- 同类任务跨 session 反复返工，需要持久化上下文。

Fast Path 可轻量化：只在对话中保留目标、边界、验收，不创建重过程区。

## 过程区契约

过程区只承载“本次变更过程”，不是长期真源。

| 阶段 | 必填内容 | 回灌目标 |
|---|---|---|
| G1 Spec | 目标、范围、Out of Scope、验收标准 | `docs/design/` 或 Feature Spec |
| G2 Design | 方案、取舍、风险、回滚 | ADR / design |
| G3 Task Contract | 白名单、禁止改清单、验证命令 | Task Contract / prompt |
| G5 Quality | 主链路、失败链路、回归证据 | `docs/review/` / checklist |
| G8 Learning | 返工原因、可复用规则 | insight / anti-pattern / prompt / skill |

## 归档规则

- 过程稿完成后必须标记状态：`done` / `superseded` / `blocked`。
- 长期有效的规则必须回灌到 canonical 真源；过程稿不能与终版设计并列冲突。
- 未闭环事项下沉到 TODO / plan / review，不得混在终版设计正文里。
- 若过程区暴露治理缺口，回填 `governance_checklist.md` 或 `scorecard.md`。

## 头脑风暴与反迎合触发

命中头脑风暴或体系方案类任务时，先完成反迎合检查，再进入 Spec / ADR / Task Contract：

- `fact`：哪些来自用户明确事实、代码、文档或验证结果。
- `assumption`：哪些只是当前推断。
- `unknown`：哪些会影响路线选择，必须最小验证。
- `risk`：顺着用户原方案做，最可能制造什么返工、冲突或新真源。
- `smaller loop`：是否能先做一个更小闭环，证明价值再扩展。
- `do-not-do`：什么情况下应不做、暂缓、只评审或先试点。

需要落档时，使用 `doc-script-governance/templates/TEMPLATE_BRAINSTORM_CONVERGENCE.md`，目标路径为 `docs/plan/<domain>/<TOPIC>_BRAINSTORM.md`；收敛后回灌 Spec / ADR / Task Contract / DESIGN。

## 多视角反证矩阵

多视角反证是 gate 内问题集，不是默认子 Agent 派发。

| 视角 | 适用 gate | 审查问题 |
|---|---|---|
| 目标视角 | G0-G1 | 是否解决真实用户目标？是否存在更小但更强的切入点？ |
| 工程视角 | G2-G3 | 数据流、状态机、边界、失败模式、测试策略是否冻结？ |
| 体验视角 | G2/G5 | 用户可见状态、错误态、空态、可恢复性是否一致？ |
| 评审视角 | G5 | 哪些问题会通过 happy path、单元测试或代码风格检查？ |
| 验证视角 | G5 | 是否有浏览器/接口/DB/响应体证据？是否覆盖关键失败链路？ |
| 发布视角 | G7 | 发布、回滚、开关、监控、文档是否齐备？ |
| 复盘视角 | G8 | 失败应回灌到 insight、anti-pattern、prompt 还是 skill？ |

## P0 阻断

- Full Path 没有任何持久上下文产物，且实现范围跨模块或改契约。
- 过程稿完成后没有归档 / 回灌，导致 plan、review、design 互相冲突。
- 用视角名替代证据，例如“已做验证视角 review”但没有命令、截图、日志或响应体。
- 头脑风暴任务直接迎合用户方案，未暴露反方、unknown、risk 或更小闭环。
- 外部命令体系覆盖 hub 的零跳门禁、派发门、还原门。

## 与现有技能关系

| 场景 | 归属 |
|---|---|
| 是否启用持久上下文闭环 | `ai-development-governance` |
| 需求推进、实现、验证 | `delivery-workflow` |
| 文档落位、备份、归档 | `doc-script-governance` |
| 子 Agent prompt 成文 | `prompt-engineering` |
| 失败沉淀为人读洞察 | `project-insight-extractor` |
| 浏览器黑盒验证 | `webapp-testing` |

## 完成判定

- 过程区状态明确。
- 长期规则已回灌到 canonical 真源。
- 多视角反证至少覆盖目标 / 工程 / 评审 / 验证中与本任务相关的视角。
- 证据链可追溯到命令、日志、截图、响应体、diff 或文档链接。
