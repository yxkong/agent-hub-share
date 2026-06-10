# 交付复盘（Gate 5）

> **给 Agent 后续分析用的任务记录**，不是给人读的洞察资产。  
> 落盘真源：`$AGENTS_HUB_ROOT/docs/resource/replay/` + `docs/resource/INDEX.md`

## 三层分工（避免「写了 prompt 但产物对不上」）

| 层 | 文件 | 职责 |
|----|------|------|
| **SOP** | 本文件 `delivery_replay.md` | 何时做、为谁做、范围、阻断、与 extractor 分工 |
| **结构契约** | [`replay_body_template.md`](replay_body_template.md) | replay **唯一**正文模板（二级标题真源） |
| **执行指令** | `prompt-share-agent-task-delivery-closeout-summary` | Gate 5 读序、Inventory、自检、落盘步骤（**不**再内嵌第二份模板） |

`$AGENTS_HUB_ROOT/docs/resource/replay/*.md` 是**唯一产出真源**，不是规范；历史 replay 不得作为结构样本反向绑架模板。业务工程 `<project>/docs/resource/replay/` 不是 Gate 5 真源。

**产出校验**：`scripts/check-replay-structure.ps1`（章节/header 门禁；落盘后应 exit 0）。

## 复盘是为了什么

Replay 不是「聊天摘要」或「做了什么清单」，而是**可机器扫描、可跨会话复用的交付事实包**，供后续 Agent 做这些事：

| 消费者 | 用途 |
|--------|------|
| 后续同类任务 Agent | 读 `做了什么` / `交付终态` / `Task Replay Lite`，避免重复踩坑、漏验、越界 |
| `project-insight-extractor` | 以 replay 为 `source_anchor` 抽给人读的洞察（**不**替代 replay） |
| 体系审计 / `projects/*.md` 汇总 | 批量看 evidence、返工、NOT_RUN、回填是否落地 |
| Gate 6 / `skill-engineering` | 从 `误判 gate` + `建议回填` 定位应写进哪条 skill / anti-pattern |

**必须回答的问题**（写不出来 = Gate 5 未过）：

1. **边界**：原始目标、验收口径、中途纠偏和明确不做是什么？
2. **轨迹**：交付过程分几段，每段触发、动作、产物、结果是什么？
3. **决策**：哪些方向被选择、否定或收缩，为什么？
4. **终态**：现在文件、脚本、prompt、代码或文档处于什么可核对状态？
5. **证据**：每条完成声明的证据等级是什么，哪些只是 `NOT_RUN`？
6. **缺口**：未验证、未发布、未回显、未接 CI 的地方在哪里？
7. **回填**：哪个 skill / prompt / docs / script 应该改，避免同类返工？

## 正文结构与质量协议

见 **[`replay_body_template.md`](replay_body_template.md)**（唯一契约）。它同时定义：

- 写作前 6 个账本：Intent / Artifact / Decision / Evidence / Gap / Learning
- `replay_contract: gate5-v2`
- 新 replay 必须保留的二级标题
- Fast / Full 裁剪与 outcome 规则

**禁止**：引用任何历史 replay 作为 canonical sample；历史文件只可作为事实来源或反例。

## 配套 Prompt（执行模板）

Gate 5 **必须读取并执行** hub share prompt（用户无需口述触发）：

| 项 | 值 |
|---|---|
| **id** | `prompt-share-agent-task-delivery-closeout-summary` |
| **路径** | `prompts/share/agent-task/prompt-share-agent-task-delivery-closeout-summary.prompt.md` |
| **owner_skill** | `delivery-workflow` |

**读序**：本文件 → [`replay_body_template.md`](replay_body_template.md) → closeout prompt → 落盘 → `check-replay-structure.ps1`。

工作区经 `sync-prompts` 挂载后，也可从 `.agents/prompts/hub-share/agent-task/` 读取同一文件。

## 与资产提取的分工

| 动作 | 何时 | 负责 | 产物 |
|------|------|------|------|
| **复盘落盘**（Gate 5 + 上表 prompt） | Gate 4 通过后 | `delivery-workflow` | `$AGENTS_HUB_ROOT/docs/resource/replay/*.md` |
| **洞察提取** | 用户明确要求 | `project-insight-extractor` | `TechInsightVault/` |
| **新 Prompt 沉淀** | Gate 6 返工后 R3 | `prompt-engineering` | 新的 `prompts/share/agent-task/*.prompt.md` |
| **反模式回填** | 同类 Agent 犯错 ≥2 | `skill-engineering` | SKILL / anti_patterns |

**禁止**：把 replay 正文直接写进 TechInsightVault；把洞察叙事写进 replay 代替事实记录。

**区分**：Gate 5 用的是**已有** closeout prompt 做执行模板；Gate 6 才通过 `prompt-engineering` **新建**返工类 prompt。

用户**不需要**口述「按 closeout 落盘」——命中 `delivery-workflow` 且 Gate 4 通过后，Agent **默认**读本节 prompt 并落盘。

## 复盘范围（会话级，硬规则）

Gate 5 复盘对象是**整段 Agent 交付会话的有效产出**，不是最后一轮 assistant 回复的摘要。

**宿主无关**：会话可来自任意 Agent 运行时（Cursor、Claude Code、Codex、CLI SDK 等）。事实来源用 transcript、对话历史、已落盘 diff、验证输出即可；`source_anchor` 写 run-id / transcript id / 时间或人类可读标识，**不得**写死某一 IDE 为前置条件。

| 必须覆盖 | 说明 |
|----------|------|
| 用户初始目标 | 会话第一条有效研发/治理意图 |
| 中途转向 | 用户纠偏、追加需求、范围变更、否定方向 |
| 分阶段产物 | 每次落盘的 skill / docs / prompt / replay / 代码 |
| 分阶段验证 | 各阶段跑过的命令与 `=ok` / `NOT_RUN` |
| 决策链 | 为什么这么改，为什么没走另一个方向 |
| 返工链 | 为何返工、改了什么、最后怎么验证 |

**Coverage Check（硬规则）**：

- `replay_scope: session` 必须同时满足：source 可访问、覆盖起点/终点明确、无未说明排除片段、`coverage_status: full`。
- 只能覆盖某批次、某阶段、后半段、最后几轮时，必须写 `coverage_status: partial`，并把 `replay_scope` 降级为 `task` 或在 `覆盖范围核验` 中明确说明不是整会话。
- source transcript / run-id 不可访问时，`coverage_status` 只能是 `partial` 或 `unknown`；不得声称全会话复盘。

| 禁止 | 说明 |
|------|------|
| 只写最后一轮 | 不得把 Gate 5 当成「刚才那段总结」 |
| 只写主话题 | 同会话内公众号、resource 落盘、prompt 修正等不得漏 |
| scope 冒充 | 不得用 `replay_scope: session` 包装阶段 replay |
| 把讨论当交付 | 纯问答、未落盘方案可写在「未交付讨论」 |

**一份 vs 多份 replay**：

- 同一连续会话、同一交付线（哪怕多阶段）→ **一份** replay，`## 做了什么` 内用分批/分阶段表覆盖。
- 用户明确「上一个任务已结束，开始新任务」且上一任务已 Gate 5 → 可另开 `task_id`。

执行 closeout prompt 前，必须先按 `replay_body_template.md` 完成 **6 个分析账本**，再写正文。

## 触发

| 条件 | 是否落盘 |
|------|----------|
| Full Path / 跨模块 / 用户要求交付闭环 | **必须**落盘 |
| Fast Path 单点 trivial 且无文件改动 | 回复内迷你复盘即可；**可不**写文件 |
| 用户明确「不要落盘 / 仅预览」 | 只输出复盘块，不写文件 |

## 落盘步骤（默认执行）

1. 读取 `replay_body_template.md` + `prompt-share-agent-task-delivery-closeout-summary`。
2. 完成 6 个账本；按模板生成 `replay_contract: gate5-v2` replay。
3. 执行 **Path Guard**：确认 hub root 已解析，目标路径必须是 `$AGENTS_HUB_ROOT/docs/resource/replay/<task_id>.md`；不得写业务工程 `docs/resource/replay/`。
4. 写入 `$AGENTS_HUB_ROOT/docs/resource/replay/<task_id>.md`。
5. 更新 `$AGENTS_HUB_ROOT/docs/resource/INDEX.md`（task_id 不重复）。
6. 运行 `$AGENTS_HUB_ROOT/scripts/check-replay-structure.ps1`；失败则补全后重跑。
7. 对用户回复 **3 行以内**：task_id、outcome、主要 limitation（若有）。

改 `docs/resource/` 前按 `doc-script-governance` 执行 `backup-file`（更新 INDEX 时）。

## 阻断规则

- 不得编造未执行的命令或未验证的结论。
- Full Path 只有 `static` / `contract` 时，`outcome` 不得为 `DONE`。
- 未读模板和 closeout prompt 就落盘 → Gate 5 未过。
- 只覆盖会话最后一轮、漏掉同会话早期已交付产物 → Gate 5 未过。
- `Task Replay Lite` 只写“下次注意”或不指向回填资产 → Gate 5 未过。
- 写入业务工程 `docs/resource/replay/` 或未能定位 `$AGENTS_HUB_ROOT` → Gate 5 未过，必须标 `BLOCKED`。
- 落盘失败时标 `risk`，不得假装已写入 INDEX。

## 后续分析入口

- **洞察提取**：用户触发 `project-insight-extractor`，`source_anchor` 指向 replay 文件
- **体系审计**：`prompt-share-agent-task-ai-rd-closure-audit` 或 `docs/resource/projects/<project-key>.md`
- **失败沉淀路由**：Gate 6 先按 [r3_handoff_contract.md](r3_handoff_contract.md) 生成 handoff packet，再交给 `project-insight-extractor` / `prompt-engineering` / `skill-engineering` 等目标技能自行判定准入
