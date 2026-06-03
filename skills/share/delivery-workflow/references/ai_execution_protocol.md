# AI 执行协议（阶段门约束）

> 面向 AI 智能体的强制执行规范，统一阶段门行为约束与推压响应逻辑。路由判定见 `delivery-workflow/SKILL.md` 的 `30 秒决策区`。

### 阶段门执行约束

**Gate 1 — 需求理解**

- 输出 1-3 句精简需求摘要
- 仅追问 **1-2 个最高模糊度问题**，禁止一次性抛出全部五问
- 信息收敛后更新摘要，明确声明过门

**Gate 2 — 设计收敛**

- **Full Path**（见 [delivery-workflow/SKILL.md](../SKILL.md)）：加载对应路由模板，以代码块输出最小设计草稿；已知项自动填充，未确认项标注 `?待确认`。在 **未满足 Fast Path** 时，**须**用户明确确认设计后再进入实现；若用户 **推压跳过**（见下），则一句话声明风险后遵从，并视为用户选择承担返工成本。
- **Fast Path**（见 [delivery-workflow/SKILL.md](../SKILL.md)）：满足条件时，输出 **一段**最小设计摘要（目标 + 将改哪里 + 如何验收）即可进入实现，**不强制**完整设计模板或固定「确认」话术。
- **用户推压**（直接写、先做再说、跳过设计）：先校验 Fast Path；满足则直接进入实现；不满足则一句话说明风险与跳过的节点后遵从用户意愿。

**Gate 3 — 实现推进**

- **🔴 R1「出门声明」**（无豁免）：动用任何写工具（Edit / Write / Shell 写文件 / 派子 Agent）前，必须在响应里显式输出一行：

  ```
  [实现阶段] 路由：delivery-workflow/<frontend|backend|fullstack|debug|checklist> → 项目技能 <skill-name> § <章节路径>
  ```

  没写这条 → 阶段门未过；Agent 自我检测到缺这条，立即补写后再动手。

- 一句话声明当前最小交付闭环
- 主链路优先，验收后再进下一闭环
- 每个新闭环开始前遵循 **checkpoint 协议**（见 [delivery-workflow/SKILL.md](../SKILL.md) 的 `阶段门速记` / `Gate 3 实现推进`）：`git status`、允许时的最小范围基线或经同意的提交；不允许时记录 `risk`；**不**把「无条件 commit」当硬动作，**也不**在脏工作区上无意识跨闭环推进
- **派子 Agent 时**：调用 `Task` 工具的 `model` 必须为执行档（slug **以 `-fast` 结尾**，禁止写死 `composer-2.x-fast`），`prompt` 须按 [subagent_prompt_template.md](subagent_prompt_template.md) 7 要素组织，派发前完成模板 §4 自检清单

**Gate 4 — 验证完成**

- 主链路验证通过后，按序检查：主链路 → 关键失败链路 → 文档/SQL/配置落点
- 若涉及 **保存后回显 / 详情缺字段**：必须完成 `references/missing_data_debug_triad.md` 三联检（保存 → 查询 → 响应出口），再声明验证完成
- 三项全满足时声明本轮交付完成，否则继续补充

**Gate 5 — 失败沉淀**

- 出现失败/回滚/返工时，先定位类型（需求理解 / 设计漏项 / 契约不清 / 切分不当 / 验证不足）
- **🔴 R3 双路径分流**（无豁免）：
  - **认知洞察 / 经验**（给人看）→ `project-insight-extractor`
  - **Agent 反模式 / 触发误判 / 代码反模式**（给 Agent 用）→ 回填到对应 SKILL.md 或 `references/anti_patterns*.md`
  - **高质量复用 prompt**（含子 Agent prompt）→ `prompt-engineering` 沉淀为 `prompts/share/agent-task/*.prompt.md`
- 有可复用价值时直接落盘为 rule / checklist / script / test / docs，不推迟

### 用户推压处理

**触发信号**：直接写、先做再说、跳过设计、不用设计

1. 先校验 Fast Path 条件
2. 满足 → 直接进入实现，无额外提示
3. 不满足 → 一句话说明风险 + 跳过的节点，随后遵从用户意愿

**禁止**：沉默绕过阶段门、强硬拒绝用户指令

**话术参考**：

> 这个需求涉及接口字段变更，跳过设计可能导致前后端字段不对齐需要返工。我先按你说的直接写，但字段语义建议你确认一下。
