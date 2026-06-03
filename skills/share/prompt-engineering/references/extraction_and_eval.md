# 提炼与评测（从素材到定稿）

## 输入素材的常见来源

- 多轮对话里**重复出现**的「开场 + 约束 + 输出格式」骨架。
- PR / 设计 MD 里可复制的评审/诊断段落。
- 某次排查中证明有效的「**三联检**」式指令（可与 `delivery-workflow` 缺数据 triad 对齐）。
- **项目/代码/SQL 配置**：运行时会进入模型上下文的系统提示词、生成规则、Agent 约束。

## 路由边界

- 会被发送给模型执行的系统提示词、工具约束、生成规则、子 Agent 长指令：进入本技能。
- 稳定流程、触发规则、工具路由、坏味道沉淀：转 `skill-engineering`。
- 面试表达、复盘案例、简历素材：转 `project-insight-extractor`。
- 目标仍不确定：先走 `agent-asset-router`。

## 前置步骤：Prompt Inventory（先扫描，再候选）

**在进入候选扫描之前，先明确「哪里有 prompt」**。不同来源需要主动扫描，不能假设只从当前会话提炼。

| `source_kind` | 扫描位置 | 典型表现 |
| --- | --- | --- |
| `conversation` | 当前会话 / 长对话记录 | 重复出现的角色+步骤+输出骨架 |
| `design_doc` | `docs/design/**/*.md`、`docs/api/**` | 提示词章节、系统提示词描述、生成规则、拒答条件 |
| `code` | `*Prompt*.java`、`*SystemPrompt*`、`*PromptConstants*`、`src/main/resources/prompts/` | PromptTemplate 常量、`@Value` 注入的模板字符串 |
| `sql_config` | `docs/db/**/*.sql`、`ai_prompt` 表初始化脚本 | `INSERT INTO ai_prompt`；Agent/RAG 配置字段 |

**Inventory 输出**（不需要立刻写 prompt）：

```
- source_kind: design_doc
  source_anchor: docs/design/ai/SMART_DATA_QUERY_IMPROVEMENT_DESIGN.md §系统提示词
  候选摘要: NL2SQL 生成时的 SQL 安全规则

- source_kind: code
  source_anchor: <runtime-module>/src/.../AiPromptConstants.java
  候选摘要: RAG 检索时的 system role 定义
```

以 Inventory 列表为输入再进入第零步，**不要只凭印象扫描**。

## 第零步：高价值候选扫描（发现优先）

在长会话、长文档或大块代码面前，**不要默认已经知道要提炼哪一条**。先列出 **3–8 条候选**，再进入资格判定。

**会话/工作流提示词信号**：

| 信号 | 说明 |
| --- | --- |
| **重复骨架** | 同一套角色/步骤/输出标题在多轮中被复制或微调使用 |
| **稳定诊断流** | 对某一类故障有可复述的排查序列，且多次验证有效 |
| **可迁移契约** | 输入/输出结构、禁区、拒答条件可脱离当前仓库仍成立 |
| **可评测约束** | 能写出最小 eval（最小输入 / 边界 / 拒答）来检验模型行为 |

**运行时提示词信号**（从项目/设计文档/代码发现时适用）：

| 信号 | 说明 |
| --- | --- |
| **系统提示词** | 进入模型 system 字段的角色定义、场景约束、安全红线 |
| **业务生成规则** | RAG 检索指令、NL2SQL 生成约束、SQL 安全规则、格式要求 |
| **工具调用约束** | Agent 工具选择规则、fallback 条件、重试逻辑说明 |
| **评审/调试模板** | debug eval 指令、代码 review 引导、问题诊断框架 |
| **DB 配置型 prompt** | `ai_prompt` 表里由代码/SQL 加载进模型的配置化提示词 |

**过滤掉（不进入下一轮）**：

- 一次性指令（只在本轮、本分支有效）
- 强绑定项目私密（未脱敏域名、客户名、内网路径、真实密钥）
- **单纯复述**已有 skill/rule 全文而无场景化增量（应改 skill 或链到 skill，不必再造 prompt 文件）

**判定边界**：凡是**会被发送给模型作为上下文**的文本（system prompt、RAG 引导词、工具约束说明、生成规则），即使在代码或设计文档里形式像「规则」，也进入 prompt 候选。**只有纯人类流程规范**（不进入模型上下文的治理文档、开发 SOP）才归到 skill/rule，不作为 prompt 候选。

只对通过过滤的候选继续做「一句话目标」。

## 提炼步骤（建议顺序）

1. **一句话目标**：这条 prompt 帮用户完成哪一件**可命名**的事？
2. **剥离一次性内容**：commit、人名、单条日志 → 占位符或「输入要求」示例。
3. **写清反例**：模型不该做什么（只写本条特有禁区，不重抄整份 skill）。
4. **对齐归属**：单库强绑定 → `prompts/projects/<project-key>/`；多项目复用 → `prompts/share/`（可先 project 孵化再升 share）。
5. **冻结 `id`**：与 `prompts/indexes/prompts.index.json`（运行 `build-prompt-index` 后）及全文检索比对，避免冲突与重复语义。
6. **本地试跑**：至少 1 次最小输入 + 1 次边界输入（记在验收标准）。

## 去重、融合与 `deprecated`（先机器索引，再判语义）

**检索顺序**：

1. 运行或读取 `prompts/indexes/prompts.index.json`（若本地未生成，先在 hub 根执行 `build-prompt-index`）。
2. 按 **`type` + `owner_skill`** 过滤候选项；再用 **一句话目标** 与候选条目的「适用场景」首段人工比对。
3. 全文辅助：`rg` / 搜索 `id:`、`适用场景` 关键词。

**判定表**

| 情况 | 动作 |
| --- | --- |
| 同目标、同输入输出契约、仅措辞差异 | **融合**：保留 **既有 `id` 文件**，`backup-file` 后改同一文件；不新建平行文件 |
| 新候选是旧版的严格上位（增补约束、覆盖旧场景） | **替代**：旧文件 `status: deprecated`，`replaced_by: <新 id>`；新文件用新 `id` |
| 目标相似但验收/eval 关注不同（例如 debug vs review） | **新建**：新 `id`，必要时在旧条目「验收标准」中加一行「另见 `id=…`」避免误用 |
| 仅 share/project 归属不同、语义相同 | **保留一份**：通常放在 **share**；project 副本应删或改为链到 share（避免双维护） |

**`replaced_by` 规则**（与 `check-prompts` 一致）：

- `status: active` → 不得出现 `replaced_by`。
- `status: deprecated` → **必须** `replaced_by: <仍 active 的 id>`，且该 id 在 hub 中真实存在。

索引 **只列扁平条目**；替代关系靠 front matter 表达，不必手写图结构。

## Eval 最小集（不必上平台）

每条 prompt 建议至少 3 条用例，写在「验收标准」：

| # | 输入摘要 | 期望行为 |
| --- | --- | --- |
| 1 | 最小合法输入 | 结构正确、无幻觉性断言 |
| 2 | 缺一类关键上下文 | 追问或列出缺口，不乱补全 |
| 3 | 恶意/无关/敏感输入 | 礼貌拒答或收窄到任务内 |

没有自动化也要有人工「过/不过」判据。

### 提炼覆盖率验收（从设计文档/代码提炼时必加）

仅靠上方三条用例无法验证「是否把源材料里的 prompt 全拆出来了」。从项目/设计文档提炼时，必须增加覆盖率验收：

- **输入**：一份已知含 N 个独立 prompt 片段的素材（设计文档章节 / 代码文件）
- **期望**：输出 N 条候选，或给出合并/丢弃的明确理由，**每条标注 `source_anchor`**
- **不接受**：仅输出 1 个综合型大 prompt；遗漏源文件中明显独立的 prompt 片段

**示例验收**：输入含「系统提示词」「RAG 检索指令」「NL2SQL SQL安全约束」三节的设计文档 → 期望 3 条独立候选，不能合并成一个大 prompt；`source_anchor` 必须分别指向三节的文档位置。

## 升 share 前自检

- 是否去掉项目专有路径、内部域名、未公开业务名？
- 是否在索引与 `rg` 层面已做过去重？
- `check-prompts` + `build-prompt-index` 是否均已绿灯？
