# Common Agent Rules (core)

高信号默认；细节进技能，公共规则只放零跳硬约束。

## 基线

- 默认 **简体中文 + Markdown**；回答简洁、可执行；必要时区分 `fact / assumption / unknown / risk`。
- 可执行命令用对应 shell 的 fenced code block。
- 保持编码；新文件优先 **UTF-8 without BOM + LF**。
- 最小有效改动；复用既有 skill / docs / 脚本，不新增并行真源。
- 非 trivial 任务先对齐目标、约束、验收；先设计后实现，除非明确满足 Fast Path。
- Windows 执行命令默认显式用 `pwsh`；仅验证 Windows PowerShell 5.1 兼容时用 `powershell.exe`。
- 复杂 PowerShell 逻辑禁止塞进 `pwsh -Command "..."`（do not inline）：只要含 `$变量`、`foreach`、scriptblock、hashtable、here-string 或多段管道，就必须落到 `.ps1` 后用 `-File` 调用；PowerShell 场景不用 `tail/head/grep/find` 管道，改用 `Select-Object` 或显式 `bash -lc`。
- 采用最小安全验证；remote / deploy / production 命令必须用户明确要求。
- 不编造工具输出、私有状态、日期或不可得事实；不可逆 / 昂贵动作先停下确认。
- 失败或返工必须定位根因，并沉淀为 insight / anti-pattern / prompt / checklist / test / docs 之一。

## 技能路由

| 场景 | 第一跳 |
|---|---|
| 研发任务 / debug / 前后端 / SQL / 重构 | `delivery-workflow` |
| 规范 / Spec / ADR / Security / Release / 9.8 评分 / 治理体系 | `ai-development-governance` |
| docs / SQL / 脚本 / skill 资料落位、备份、归档 | `doc-script-governance` |
| skill 新建 / 审查 / trigger / 目录布局 | `skill-engineering` |
| hub 安装 / 注册 / 挂载 / 脚本分级 | `agent-hub-bootstrap` |
| 产物不明：skill / prompt / docs / insight / review 混合 | `agent-asset-router` |
| 浏览器黑盒验证 | `webapp-testing` |

裁决：执行推进归 `delivery-workflow`；门禁评分归 `ai-development-governance`；落位备份归 `doc-script-governance`；项目实现只写项目增量规则和项目技能，不复制公共规则。

研发顺序：`delivery-workflow` triage → 需要 Spec/ADR/门禁则转 `ai-development-governance` → docs/SQL/脚本落位转 `doc-script-governance` → 代码进入项目技能 → 发布前过 Release/Security → 失败进 R3。plan 并入 `docs/design` 终版时，契约必须一致；项目 docs 元数据与修订记录按 `doc-script-governance`。

## 零跳门禁卡

<!-- AGENT-GATE-CARD v1 -->

> 门禁自包含；触发动作前必须先输出对应自检产物。没输出 = 未过门 = 不得执行。

### G0 头脑风暴 / 反迎合门

触发：方案讨论、体系整合、长期闭环、9.8+、一次通过评审、用户给出但未验证的方向。

必须先输出：

```text
[头脑风暴自检]
fact:
assumption:
unknown:
risk:
反方问题:
更小闭环:
不做/暂缓条件:
```

任一项为空且影响方向选择，不得宣称方案已收敛；Full Path 收敛后回到 `ai-development-governance` 的 Spec / ADR / Task Contract。

### G1 派发门

启动子 Agent / `Task` 前必须同时满足：

- 任务是机械落盘，不是探索、方案权衡、读代码或问答。
- 路径 / 内容 / 验收已锁定。
- 命中硬触发：写入 >= 2 文件，或单文件预计 > 1500 输出 token，或已有 hub `agent-task` prompt。
- 执行档 `model` slug 以 `-fast` 结尾；执行档不得再启子 Agent。
- 用户写明“不要子 Agent / 直接做 / 别后台跑”时，零派发。

派发前输出 7 要素自检：`目标 / 范围白黑名单 / 输入上下文 / 硬约束 / 步骤 / 验证命令与判据 / 输出四态`。任一项缺失不派发。完成状态只允许：`DONE` / `DONE_WITH_CONCERNS` / `NEEDS_CONTEXT` / `BLOCKED`。

派发前先按 `delivery-workflow/references/subagent_prompt_template.md` 做五维评估；并行子 Agent 必须有互斥文件所有权清单，禁止两个写者共享文件。

### G2 实现门

写代码 / 页面 / 接口 / 配置 / SQL 前必须先：

```text
[实现阶段] 路由：delivery-workflow/<route> → 项目技能 <skill> §<章节>
```

代码文件进入实现前执行 checkpoint：优先 `git status`；必要时经同意 `commit` / `stash` / 分支；否则记录 `risk`。

### G3 验证门

声称完成前必须给出：验证命令 + 通过判据 + 实际产物。主链路未验证不算完成；“接口 200 但缺数据 / 保存后回显空”必须补写入、读取、响应出口三联检。

### G4 文档/脚本/还原门

- 改文档、SQL、脚本、skill 主文件或 references 前，先调用 `doc-script-governance/scripts/backup-file`；`git checkpoint` 不能替代脚本备份。
- 已有文档 / SQL 未经负责人确认，不得删除、清空或替换为占位。
- 执行 `git restore/reset/clean` 等会覆盖、丢弃或抹掉本地状态的动作前，先列路径、命令原文、影响，并经用户明示确认；禁止整块目录一键 restore。

## 收口校验

- 规则改动后跑 `scripts/check-agent-rules`，确认 `AGENT-GATE-CARD` 已分发。
- skill / references 改动后按 `skill-engineering` 工程完成门跑入口、结构、私有耦合等适用校验。
- commands 改动后跑 `scripts/sync-commands` 与 `scripts/check-commands`，确认三端入口无漂移。
- plugin manifest / dist 改动后跑 `scripts/build-plugin` 与 `scripts/check-plugin`，确认装配层不成为第二真源。
- 体系级改造收口跑 `scripts/check-hub-all`，一键覆盖规则、命令、插件、prompt、skill 结构、行为审计、shell quoting 与编码门禁。
- 交付前按 `delivery-workflow` + `ai-development-governance` 给出最小主链路证据；失败进入 R3 学习门。
