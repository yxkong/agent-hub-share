# 子 Agent Prompt 提炼专项

> 主模型派 **执行档**（`model` slug 以 `-fast` 结尾）子 Agent 时使用的 prompt，若被验证为高质量（任务成功 / 输出结构化 / 无 drift），值得提炼为可复用 prompt 资产。
> 与通用提炼流程互补：通用流程见 [../SKILL.md](../SKILL.md) 中最小 SOP。

## 触发条件

满足以下**全部**条件 → 进入本分支提炼：

1. **来源**：主模型 ↔ 子 Agent 的对话（`Task` 工具派发的 prompt + 返回的 user_visible_high_level_summary）
2. **质量**：
   - 子 Agent 一次完成任务（无 drift / 无追加澄清轮次）
   - 输出结构化（清单 / 表格 / 编译结果），主模型能直接汇总
   - 任务复用价值高（同类任务在未来仍会发生）
3. **模板对齐**：prompt 已遵循 [../../delivery-workflow/references/subagent_prompt_template.md](../../delivery-workflow/references/subagent_prompt_template.md) 的 7 要素，且显式包含：
   - 最小上下文包
   - 验收 / 验证标准
   - 完成状态协议

## 提炼步骤

### Step 1：识别 prompt 类型

根据任务性质归类：

| 类型 | 命名规范 | 归档位置 |
|---|---|---|
| 重复机械改写（如批量 record→class）| `prompt-share-agent-task-batch-rewrite-*.prompt.md` | `prompts/share/agent-task/` |
| 项目特化重构（如 BI 表逐表治理）| `prompt-project-<key>-<topic>.prompt.md` | `prompts/projects/<project-key>/` |
| 文档同步（如四份同源规则同步）| `prompt-share-agent-task-doc-sync-*.prompt.md` | `prompts/share/agent-task/` |
| 全模块扫描+修复 | `prompt-share-agent-task-codebase-sweep-*.prompt.md` | `prompts/share/agent-task/` |

### Step 2：去项目化（仅 share 类）

将项目特化的路径、模块名、表名替换为占位符：

| 原 | 占位符 |
|---|---|
| `<project-module>/<domain-module>/.../<EntityName>Cmd.java` | `<MODULE_PATH>/<EntityName>Cmd.java` |
| `bi_table_configs` 表 | `<table_name>` |
| `mvn compile -DskipTests -pl <module-path> -am` | `<build-command>` |

同时检查以下三项是否已抽象成可复用结构，而不是绑定某次会话：

- **上下文包**：任务在整体中的位置、依赖、已知限制
- **验收/验证包**：通过标准、验证命令、失败时如何报
- **完成状态协议**：`DONE / DONE_WITH_CONCERNS / NEEDS_CONTEXT / BLOCKED`

### Step 3：补充 eval case

每个提炼出来的 prompt 必须配 1-2 个最小 eval case：

```yaml
- name: 反例 — 缺范围白名单
  input: <模板去掉「范围」一节后的 prompt>
  expected_failure: Agent 超范围修改其他文件
- name: 反例 — 缺最小上下文包
  input: <模板去掉「任务位置/依赖/限制」后的 prompt>
  expected_failure: Agent 错误假设前置依赖，或自行扩读计划导致 drift
- name: 反例 — 缺完成状态协议
  input: <模板去掉状态输出后的 prompt>
  expected_failure: Agent 无法区分 DONE / BLOCKED，主模型不能稳定分流
- name: 正例 — 7 要素齐全
  input: <模板完整>
  expected_success: Agent 一次完成 + 输出结构化 + 状态可判定
```

### Step 4：写入 hub

按 [../SKILL.md](../SKILL.md) 中「写入模式」操作。

## 子 Agent prompt 高价值信号

- **本会话黄金样例**：
  - 「逐表 DDD 治理 11 步法」prompt → 提炼为 `prompts/share/agent-task/codebase-sweep-ddd-table-by-table.prompt.md`
  - 「全局规则三份同源 + 项目技能强引用」prompt → 提炼为 `prompts/share/agent-task/doc-sync-multi-source.prompt.md`
  - 「批量 record → class 转换」prompt → 提炼为 `prompts/share/agent-task/batch-rewrite-record-to-class.prompt.md`

高价值 prompt 通常同时满足：

- 子 Agent **不需要再读计划全文** 也能理解任务位置与边界
- 完成标准在 prompt 内即可判断，而不是靠主模型脑补
- 遇到上下文不足 / 真阻塞时，能用固定状态协议回传，而不是自由发挥

## 与 delivery-workflow / SKILL.md 的关系

```
../../delivery-workflow/references/subagent_prompt_template.md（模板）
   ↓ 主模型按模板派发 Task
子 Agent 完成 + 主模型验证
   ↓ 通过本分支提炼
prompts/share/agent-task/*.prompt.md（资产）
   ↑ 下次同类任务直接复用 / 主模型按 id 引用
```

形成「模板 → 实例 → 提炼回模板」的闭环。

**失败与返工**：若子 Agent **漂移、超范围、缺验证、状态不可判定**，优先检查主模型是否省略 7 要素、最小上下文包、验收标准或可用的 hub share prompt；此类返工的主产物常为**新/改 `*.prompt.md`**，见 `delivery-workflow` **R3** 第三路（与「反模式回填」分列）。
