# 子 Agent Prompt 标准模板

> 派发子 Agent 前，主模型必须用本模板组织 prompt；缺任一要素 = drift 风险。
> 本文件不决定“是否派发”。派发判定只看 `delivery-workflow/SKILL.md` § AI 执行红线；本文件只定义“已决定派发后，prompt 怎么写”。

---

## 0. 读取前提

如果还没在 `SKILL.md` 完成“派发判定”，先回到主文件，不读本模板。

只有已经决定派发子 Agent 时，才继续使用本文件完成三件事：

1. 复用 share `agent-task` prompt（如有）
2. 补齐本次任务的 7 要素
3. 做派发前 30 秒自检

---

## 0.5 Hub share 任务 Prompt（优先复用）

在 agents hub：`$AGENTS_HUB_ROOT/prompts/share/agent-task/`。派发前检索是否已有同类 **active** 资产（亦可读 `prompts/indexes/prompts.index.json`）。具体 prompt 清单属于 prompt 索引，不在本模板枚举。

**复用规则**：**不得**只转发 share 文件而省略 7 要素。标准做法是：在 **输入（必读）** 第一条贴该 `*.prompt.md` 的 hub 路径（或同步后的工作区链接路径），并写明「正文执行逻辑以该文件 `## Prompt 正文` 为准」；**范围**、**验证**、**输出格式**必须在本次 prompt 中**全文可检索**（可直接复制 share 对应段或按项目重写），以便主模型派发前自检。若 share 正文与本次白名单冲突，**以本次 §范围 为准**。

---

## 1. 七要素（缺一即 drift）

子 Agent **没有**主模型的对话历史，**只能**靠 prompt 字面理解任务。下面 7 个 section 必须齐全：

| # | Section | 必含内容 | 没写的后果 |
|---|---|---|---|
| 1 | **任务编号 + 一句话** | 「批次 X.Y / 改 A 类问题」+ 一句话目标 | Agent 把无关问题也"顺便修"导致超范围 |
| 2 | **范围**（白名单 + 黑名单）| 要改的文件/包路径清单；明确**不要改**的范围 | Agent 创建额外文件或动用例无关代码 |
| 3 | **输入**（必读上下文）| 项目技能路径、相关代码文件路径、相关已有规范条款的精准引用、**任务在整体中的位置 / 前置依赖 / 已知限制** | Agent 凭记忆动手，丢失项目硬约束或补错上下文 |
| 4 | **硬约束**（项目级 + 任务级） | 编码（UTF-8 无 BOM/LF）、命名、DDD 层依赖、禁止使用的写法 | Agent 写出违反项目铁律的代码 |
| 5 | **步骤**（有序、可勾选）| Step 1 / Step 2 … 每步含目标 + 工具 + 期望产物 | Agent 输出过程随机，无法判断对错 |
| 6 | **验证**（可观测产物 + 命令）| `mvn compile` / `npm run lint` / 文件存在性检查 等具体命令；**通过标准 / 不通过时如何报** | Agent 自称"完成"但实际未编译，或失败时主模型无法分流 |
| 7 | **输出格式** | 列出"要给主模型回什么"：**完成状态**、修改清单、行号、编译结果、剩余风险 | 主模型无法对结果做汇总和后续派发决策 |

### 三项增强包（仍属于现有 7 要素，不新增第 8 节）

1. **最小上下文包**：放在 §输入 中，至少交代：
   - 该任务在整体批次/计划中的位置
   - 已知前置依赖、可假设已完成项
   - 已知限制、黑名单与不要自行补读的内容
2. **验收/验证包**：放在 §验证 中，至少交代：
   - 什么才算通过
   - 失败时回什么，不得用“差不多完成”糊过去
3. **完成状态协议**：放在 §输出格式 中，最小四态：
   - `DONE`
   - `DONE_WITH_CONCERNS`
   - `NEEDS_CONTEXT`
   - `BLOCKED`

---

## 2. 模板（复制粘贴用）

```markdown
## 任务：[批次 X.Y] [一句话目标]

### 范围

**只允许改这些文件/包**：
- `<相对路径 1>`
- `<相对路径 2>`

**禁止改**：
- 任何不在上面清单中的文件
- 测试 / 文档 / SQL（除非任务明确包含）

### 输入（必读，按顺序）

1. **任务上下文包**：
   - 本任务在整体中的位置：`<批次/阶段/所属任务组>`
   - 前置依赖 / 可直接假设已完成项：`<依赖说明>`
   - 已知限制 / 不要自行扩读的内容：`<例如：不要自行通读 plan 全文；仅按下列路径执行>`
2. **架构心法**：`$AGENTS_HUB_ROOT/skills/projects/<project-key>/<backend-domain-skill>/references/ddd/architecture_philosophy.md` §[X.Y]（`<backend-domain-skill>` 见 PROJECT_RULES；工作区技能目录仅为挂载镜像）
3. **项目领域技能**：`$AGENTS_HUB_ROOT/skills/projects/<project-key>/<project-skill>/SKILL.md` §[相关章节]
4. **现状代码**：`<具体 Java 文件路径>`
5. **同类已存在的标准实现**（参考模板）：`<参考文件路径>`

### 硬约束

**项目级**：
- 编码 UTF-8 无 BOM + LF；中文注释保留不丢失
- DDD 层依赖：Application 禁止 import `infra.*.impl.*` / `infra.*.convert.*` / `infra.*.mapper.*`
- 多租户：写操作必须含 tenantId

**任务级**（按本次需求补充）：
- [例] `*Cmd extends *Context`，禁止重声明 strId / 禁止 `@Override getId()`
- [例] strId → Long 转换只能在 Adapter 层（Cmd setter 或 AdapterConvert）

### 步骤

1. **Step 1**：[做什么] → 工具 `Read/Edit` → 期望产物 `<文件路径已修改>`
2. **Step 2**：[做什么] → 期望产物
3. **Step 3**：编译验证 `mvn compile -DskipTests -pl <module> -am`
4. **Step 4**：若失败，修复编译错误后重跑 Step 3，直到 BUILD SUCCESS

### 验证

通过判据（必须全满足）：
- [ ] 所有目标文件已修改（列清单）
- [ ] `<编译命令>` BUILD SUCCESS
- [ ] `<其他检查>` 通过

不通过时：
- 不得伪装成 `DONE`
- 必须在输出中给出 `DONE_WITH_CONCERNS` / `NEEDS_CONTEXT` / `BLOCKED` 之一，并说明原因

### 输出格式

请按以下结构回复主模型：

\`\`\`
## 完成状态
- `DONE | DONE_WITH_CONCERNS | NEEDS_CONTEXT | BLOCKED`
- 一句话说明：`<为什么是这个状态>`

## 修改文件清单
- `<path>` lines `<range>`: 改动要点一句话
...

## 编译结果
- module-A: BUILD SUCCESS / FAILED + 错误摘要

## 剩余风险或决策项
1. [若有] ...
\`\`\`
```

---

## 3. 反模式（基于真实项目踩坑沉淀；具体 AP 编号见项目 `<backend-domain-skill>` references）

| 反模式 | 现象 | 修复 |
|---|---|---|
| **缺架构心法引用** | prompt 不给 architecture_philosophy 路径，Agent 凭记忆改 Cmd 继承 | 输入 §1 永远包含项目相关心法路径 |
| **范围模糊** | "BI 模块所有 Cmd 检查一下" → Agent 扫到 100 个文件，超时或漏改 | 列具体文件/包路径白名单 |
| **没给参考实现** | Agent 自己发明新模式，与项目存量不一致 | 给一份"标准范例文件路径"作为模板 |
| **缺最小上下文包** | 子 Agent 不知道本任务在整体中的位置，擅自补读 plan 或错误假设前置依赖 | 在 §输入 第一条明确任务位置 / 依赖 / 已知限制 |
| **缺编译验证** | Agent 说"已完成"但工程未编译，主模型派下一波时雪崩 | 验证步骤必含 `mvn compile` / `npm run build` |
| **验收标准缺失** | Agent 做了修改但不知道什么算“完成”，主模型也无法判断是否收口 | §验证 同时写通过标准 + 失败时如何报 |
| **输出格式自由** | Agent 写大段叙述，主模型还要再读一遍才能汇总 | 强制结构化输出（清单 / 表格 / 编译结果块） |
| **完成状态缺失** | Agent 遇到缺上下文/被阻塞时仍输出“已做完一部分”，主模型误判可进入下一任务 | 输出格式固定四态，失败/阻塞不得混成 DONE |
| **硬约束散落** | Agent 把项目命名规范、编码规则当"建议"忽略 | 集中放在 §硬约束 块，分项目级 / 任务级 |

---

## 4. 主模型自检（派发前 30 秒）

派发前对照 7 要素，**任一缺失 = 不派发，先补全**：

- [ ] 任务编号 + 一句话目标
- [ ] 范围白名单 + 黑名单
- [ ] 输入：最小上下文包 + 心法 + 项目技能 + 现状代码 + 参考实现
- [ ] 硬约束：项目级 + 任务级
- [ ] 步骤：有序、可勾选、含工具
- [ ] 验证：具体命令 + 通过判据 + 不通过时如何报
- [ ] 输出格式：完成状态 + 结构化清单

---

## 5. 与其他文件的关系

| 文件 | 关系 |
|---|---|
| `rules/common/COMMON_AGENT_RULES.md` § Agent 协作模型（sync 后亦在 `AGENTS.md` / `.mdc`） | 与 delivery SKILL **执行档硬触发** 同步；本文件定义**怎么派**（prompt 模板） |
| `delivery-workflow/SKILL.md` | 阶段门约束、派发判定与主模型分工的运行入口 |
| `delivery-workflow/references/ai_context_protocol.md` §子 Agent 调度规则 | 并行 / 串行决策；与本模板互补 |
| `prompt-engineering` 技能 | 高质量子 Agent prompt 完成后，可提炼为 `prompts/share/agent-task/*.prompt.md` 复用 |
