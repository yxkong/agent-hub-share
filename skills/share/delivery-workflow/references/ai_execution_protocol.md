# AI 执行协议（阶段门约束）

> 面向 AI 智能体的强制执行规范，统一阶段门行为约束与推压响应逻辑。路由判定见 `delivery-workflow/SKILL.md` 的 `30 秒决策区`。

### 真实协作算子

阶段门执行时默认嵌入 [real_collaboration_operators.md](real_collaboration_operators.md)，但不把它当 prompt 模板库：

- **Gate 1 / Debug**：先用 Hypothesis First 列 1-3 个有序假设，再进入代码阅读或修复。
- **Gate 1 / Gate 2**：命中不确定时，用 Uncertainty Exposure 暴露 `fact / assumption / unknown / risk / next check`。
- **Gate 2 / Gate 3**：默认先给 Smallest Viable Change；提出重构时必须满足 Refactor Burden of Proof。
- **Gate 2 / Gate 3**：改变交互模式、行为模式、架构风格或运行语义时，Behavior Mode Change Confirmation 优先级高于用户推压；只有用户明确要求执行该行为变更时才可跳过等待确认。
- **Gate 2 / Gate 4**：方案收敛和交付前用 Adversarial Review 找最可能返工点。
- **Gate 4**：验证前用 Risky Test Design 点名最容易漏测的边界、失败链路或回归用例。

### 阶段门执行约束

**Gate 1 — 需求理解**

- 输出 1-3 句精简需求摘要
- 排障 / 异常类任务先列 1-3 个有序假设，避免无假设读代码或改代码
- 影响下一步时显式区分 `fact / assumption / unknown / risk / next check`
- 仅追问 **1-2 个最高模糊度问题**，禁止一次性抛出全部五问
- 信息收敛后更新摘要，明确声明过门

**Gate 2 — 设计收敛**

- **Full Path**（见 [delivery-workflow/SKILL.md](../SKILL.md)）：加载对应路由模板，以代码块输出最小设计草稿；已知项自动填充，未确认项标注 `?待确认`。在 **未满足 Fast Path** 时，**须**用户明确确认设计后再进入实现；若用户 **推压跳过**（见下），则一句话声明风险后遵从，并视为用户选择承担返工成本。
- **Fast Path**（见 [delivery-workflow/SKILL.md](../SKILL.md)）：满足条件时，输出 **一段**最小设计摘要（目标 + 将改哪里 + 如何验收）即可进入实现，**不强制**完整设计模板或固定「确认」话术。
- 默认先给最小有效方案；若提出重构、抽象、批量替换，必须先证明局部修改不足
- 若方案会改变交互模式 / 行为模式 / 架构风格 / 运行语义（如异步改同步、事件驱动改直连、DDD 分层改写、事务/状态机语义变化），必须先列出原模式、新模式、风险、验证和回滚，并等待用户确认；“直接写 / 先做再说”不等于确认行为变更，只有用户明确要求执行该行为变更时，声明风险后继续
- 方案收敛前用反方视角检查最可能返工点，P0 风险未消除时不得进入实现
- **用户推压**（直接写、先做再说、跳过设计）：先校验 Fast Path；满足则直接进入实现；不满足则一句话说明风险与跳过的节点后遵从用户意愿。

**Gate 3 — 实现推进**

- **🔴 R1「出门声明」**（delivery 管辖写入无豁免）：动用任何写工具（Edit / Write / Shell 写文件 / 派子 Agent）修改代码、配置、SQL 或实现相关文件前，必须在响应里显式输出一行：

  ```
  [实现阶段] 路由：delivery-workflow/<frontend|backend|fullstack|debug|checklist> → 项目技能 <skill-name> § <章节路径>
  ```

  没写这条 → 阶段门未过；Agent 自我检测到缺这条，立即补写后再动手。文档、skill、prompt、insight 等资产写入若不属于 delivery 实现阶段，走对应资产技能的改前声明与 `backup-file` 协议，不强套本 R1 路由行。

- 一句话声明当前最小交付闭环
- 主链路优先，验收后再进下一闭环
- 排障任务默认保持原交互 / 行为 / 架构语义，只定位断点和补证据；不得为修复缺数据、缺轨迹或回显异常而绕过原链路
- 每个新闭环开始前遵循 **checkpoint 协议**（见 [delivery-workflow/SKILL.md](../SKILL.md) 的 `阶段门速记` / `Gate 3 实现推进`）：`git status`、允许时的最小范围基线或经同意的提交；不允许时记录 `risk`；**不**把「无条件 commit」当硬动作，**也不**在脏工作区上无意识跨闭环推进
- **派子 Agent 时**：调用 `Task` 工具的 `model` 必须为执行档（slug **以 `-fast` 结尾**，禁止写死 `composer-2.x-fast`），`prompt` 须按 [subagent_prompt_template.md](subagent_prompt_template.md) 7 要素组织，派发前完成模板 §4 自检清单

**Gate 4 — 验证完成**

- 主链路验证通过后，按序检查：主链路 → 关键失败链路 → 文档/SQL/配置落点
- 验证前先点名最容易漏测的边界 / 失败 / 回归用例，并选择最小安全检查
- 交付前用反方视角复核契约错位、权限/租户、状态同步、保存后回显、缺数据链路
- 若涉及 **保存后回显 / 详情缺字段**：必须完成 `references/missing_data_debug_triad.md` 三联检（保存 → 查询 → 响应出口），再声明验证完成
- 三项全满足时声明本轮交付完成，否则继续补充

**Gate 5 — 失败沉淀**

- 出现失败/回滚/返工时，先定位类型（需求理解 / 设计漏项 / 契约不清 / 切分不当 / 验证不足）
- **🔴 R3 三路分流 + 治理缺口回填**（无豁免）：
  - **认知洞察 / 经验**（给人看）→ `project-insight-extractor`
  - **Agent 反模式 / 触发误判 / 代码反模式**（给 Agent 用）→ 回填到对应 SKILL.md 或 `references/anti_patterns*.md`
  - **高质量复用 prompt**（含子 Agent prompt）→ `prompt-engineering` 沉淀为 `prompts/share/agent-task/*.prompt.md`
- 若失败暴露的是治理门缺口，同步回填 `ai-development-governance/references/governance_checklist.md` 或 `scorecard.md`
- 有可复用价值时直接落盘为 rule / checklist / script / test / docs，不推迟

### 用户推压处理

**触发信号**：直接写、先做再说、跳过设计、不用设计

1. 先校验 Fast Path 条件
2. 满足 → 直接进入实现，无额外提示
3. 不满足 → 一句话说明风险 + 跳过的节点，随后遵从用户意愿

**禁止**：沉默绕过阶段门、强硬拒绝用户指令

**话术参考**：

> 这个需求涉及接口字段变更，跳过设计可能导致前后端字段不对齐需要返工。我先按你说的直接写，但字段语义建议你确认一下。
