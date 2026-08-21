# AI 执行协议（阶段门约束）

> 面向 AI 智能体的强制执行规范，统一阶段门行为约束与推压响应逻辑。路由判定见 `delivery-workflow/SKILL.md` 的 `30 秒决策区`。

> 工程编程方法论（先边界再诊断、最小改动、重构证明、同错重判、个人架构指纹与设计偏好）见 `docs/design/ai-dev-system/ENGINEERING_AI_PROGRAMMING_METHOD.md`；普通工程任务不强制读取，规则修订、工程提示优化、工程 workflow 设计和反复失败复盘时读取。

### 真实协作算子

阶段门执行时默认嵌入 [real_collaboration_operators.md](real_collaboration_operators.md)，但不把它当 prompt 模板库：

- **Gate 1 / Debug**：先用 Hypothesis First 列 1-3 个有序假设，再进入代码阅读或修复。
- **Gate 1 / Gate 2**：命中不确定时，用 Uncertainty Exposure 暴露 `fact / assumption / unknown / risk / next check`。
- **Gate 2 / Gate 3**：默认先给 Smallest Viable Change；提出重构时必须满足 Refactor Burden of Proof。
- **Gate 2 / Gate 3**：改变交互模式、行为模式、架构风格或运行语义时，必须显式说明风险和验证；若未越出用户目标、生产/外部、安全或不可逆边界，不新增确认轮次。
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

- **Full Path**（见 [delivery-workflow/SKILL.md](../SKILL.md)）：加载对应路由模板，形成版本化设计、影响范围和验证命令；用户已明确提出实施请求时，Self Review PASS 后直接推进。
- **Fast Path**（见 [delivery-workflow/SKILL.md](../SKILL.md)）：轻量化为一段微设计（目标 + 影响范围 + 验收），Self Review 后直接推进。
- 默认先给最小有效方案；若提出重构、抽象、批量替换，必须先证明局部修改不足
- 需要把计划或 Task Contract 交给零上下文执行者时，按 [ai-native/plan_micro_step_contract.md](ai-native/plan_micro_step_contract.md) 细化到 2-5 分钟微步；出现 `TODO`、泛化“适当处理”或“类似上一步”即视为计划未收敛
- 若方案会改变交互模式 / 行为模式 / 架构风格 / 运行语义（如异步改同步、事件驱动改直连、DDD 分层改写、事务/状态机语义变化），必须先列出原模式、新模式、风险、验证和回滚；只在目标越界或高风险边界时暂停确认
- 方案收敛前用反方视角检查最可能返工点，P0 风险未消除时不得进入实现
- **用户要求直接执行**：设计与 Review 仍由 Agent 内部完成，但不得把内部过程变成重复确认；同一目标直接实现和验证。

**Gate 3 — 实现推进**

- **🔴 R1「出门声明」**（delivery 管辖写入无豁免）：动用任何写工具（Edit / Write / Shell 写文件 / 派子 Agent）修改代码、配置、SQL 或实现相关文件前，必须在响应里显式输出一行：

  ```
  [实现阶段] 路由：delivery-workflow/<frontend|backend|fullstack|debug|checklist> → 项目技能 <skill-name> § <章节路径>
  ```

  R1 在明确实施请求形成目标授权后输出，只记录执行路由。没写这条 → 阶段门未过。文档、skill、prompt、insight 等资产仍走对应资产技能的声明与备份。

- 一句话声明当前最小交付闭环
- 主链路优先，验收后再进下一闭环
- 排障任务默认保持原交互 / 行为 / 架构语义，只定位断点和补证据；不得为修复缺数据、缺轨迹或回显异常而绕过原链路
- 每个新闭环开始前遵循 **checkpoint 协议**（见 [delivery-workflow/SKILL.md](../SKILL.md) 的 `阶段门速记` / `Gate 3 实现推进`）：`git status`、允许时的最小范围基线或经同意的提交；不允许时记录 `risk`；**不**把「无条件 commit」当硬动作，**也不**在脏工作区上无意识跨闭环推进
- **派子 Agent 时**：调用 `Task` 工具的 `model` 必须为执行档（slug **以 `-fast` 结尾**，禁止写死 `composer-2.x-fast`），`prompt` 须按 [subagent_prompt_template.md](subagent_prompt_template.md) 7 要素组织，派发前完成模板 §4 自检清单
- **子 Agent 审查时**：需要复核产物的任务按 [ai-native/subagent_review_protocol.md](ai-native/subagent_review_protocol.md) 先做规格合规审查，再做质量审查；审查上下文只给 artifact + contract，不继承主会话历史
- **异步任务登记**：凡启动后台子 Agent、后台 shell、异步验证或长任务，必须在当前轮维护一个简短 pending ledger（任务名 / 目标 / 预期产物 / 是否阻塞最终完成）。存在阻塞型 pending 时，回复只能标 `IN_PROGRESS` / `PARTIAL_DONE`，禁止使用“全部完成 / 已完成所有计划”等最终措辞。

**Gate 4 — 验证完成**

- 主链路验证通过后，按序检查：主链路 → 关键失败链路 → 文档/SQL/配置落点
- **主链证据矩阵**：Full Path 或跨模块任务必须按 [mainline_evidence_matrix.md](gates/mainline_evidence_matrix.md) 输出 static / contract / runtime / user-visible / release / limitation 六类证据；若只能提供 static evidence，最终只能表述为“静态检查通过，运行链路未验证”，不得宣称完整完成。
- 验证前先点名最容易漏测的边界 / 失败 / 回归用例，并选择最小安全检查
- 交付前用反方视角复核契约错位、权限/租户、状态同步、保存后回显、缺数据链路
- **异步归并门**：若本轮启动过子 Agent / 后台命令 / 异步任务，最终完成前必须完成 integration pass：
  1. 所有阻塞型任务均已返回，或明确标为 `BLOCKED / NOT_RUN / OUT_OF_SCOPE`；
  2. 多任务结果已交叉核对（前后端 API 路径、Controller 端点、SQL 脚本、菜单路径、验证命令）；
  3. 子任务的 `CONCERNS` 已进入最终风险/局限，不得被主模型总结吞掉；
  4. 未满足以上三项时，只能输出阶段性进度，不得声明交付完成。
- 若涉及 **保存后回显 / 详情缺字段**：必须完成 `references/missing_data_debug_triad.md` 三联检（保存 → 查询 → 响应出口），再声明验证完成
- 三项全满足时声明本轮 Gate 4 通过，否则继续补充

**Gate 5 — 复盘落盘**

- Gate 4 通过后**默认**执行，用户**无需**口述 closeout 口令
- 读序：`delivery_replay.md` → `replay_body_template.md`（6 个账本 + `gate5-v2` 契约）→ closeout prompt → 落盘 → `check-replay-structure.ps1`
- 写入 `$AGENTS_HUB_ROOT/docs/resource/replay/<task_id>.md`（含 `replay_contract: gate5-v2`）并更新 `$AGENTS_HUB_ROOT/docs/resource/INDEX.md`；业务工程 `docs/resource/` 禁止作为 Gate 5 落盘点
- 产物供后续 Agent 分析、extractor 的 `source_anchor`；**不是** TechInsightVault 洞察
- Full Path / 跨模块 / 交付闭环：**必须**落盘；Fast Path trivial 可无文件，回复内迷你复盘即可
- 对用户只汇报 task_id、outcome、主要 limitation（≤3 行）

**Gate 6 — 失败沉淀**

- 出现失败/回滚/返工时，先定位类型（需求理解 / 设计漏项 / 契约不清 / 切分不当 / 验证不足 / **premature completion：异步任务未归并就宣称完成**）
- 先按 [r3_handoff_contract.md](gates/r3_handoff_contract.md) 输出 handoff packet；Gate 6 只做路由与交接，不复制目标技能准入规则
- **🔴 R3 三路分流 + 治理缺口回填**（无豁免；在 Gate 5 复盘之后，仅当失败/返工时）：
  - **认知洞察 / 经验**（给人看）→ `project-insight-extractor`
  - **Agent 反模式 / 触发误判 / 代码反模式**（给 Agent 用）→ 回填到对应 SKILL.md 或 `references/anti_patterns*.md`
  - **高质量复用 prompt**（含子 Agent prompt）→ `prompt-engineering` 沉淀为 `prompts/share/agent-task/*.prompt.md`
- 若失败暴露的是治理门缺口，同步回填 `ai-development-governance/references/governance_checklist.md` 或 `scorecard.md`
- 有可复用价值时直接落盘为 rule / checklist / script / test / docs，不推迟

### 一次目标授权处理

**触发信号**：实现、修复、修改、优化、重构、新增、创建、更新、同步、安装、配置、落地、处理。

1. 判断 Fast / Full Path，只决定设计产物轻重。
2. 记录目标、边界和验证；同一目标内直接推进，不生成设计 Hash 确认轮次。
3. 发现依赖文件、测试或文档时直接补齐；仅目标变化、跨授权根、生产/外部写入、安全升级、删除或不可逆操作时停下确认。

**禁止**：把只读咨询解释为写入授权；把设计细化或白名单补漏包装成新的用户确认点；以旧目标授权执行高风险新动作。
