---
name: "prompt-engineering"
description: 提炼、裁剪、评测和落盘可复用提示词资产（prompt asset, agent-task, eval）。适用于子 Agent 长指令沉淀、系统提示词优化、划分 prompts/share 与 projects；不负责 SKILL.md、insight vault 或 hub 链接同步。
---

# Prompt Engineering（Hub 提示词资产）

## 30 秒决策区

| 任务类型 | 什么时候选它 | 先读什么 |
|---|---|---|
| `extract` | 从会话、设计文档、一次性长指令提炼 prompt | `references/extraction_and_eval.md` |
| `contract` | 需要定义 `*.prompt.md` front matter 与正文契约 | `references/file_contract.md` |
| `layout` | 判断 prompts/share vs projects、索引与去重 | `references/hub_layout.md` |
| `subagent` | 子 Agent 长指令沉淀为 agent-task prompt | `references/subagent_prompt_extraction.md` |

## 何时读我

- 要把**可复用**的大段指令从聊天记录、一次性 MD、代码注释里**升格**为 hub 资产。
- 要**裁剪** prompt：目标、输入输出契约、禁区、验收。
- 要决定一条 prompt 进 `prompts/share` 还是 `prompts/projects/<project-key>`。
- 要写或跑 **eval case**（不必是自动化平台，结构化用例即可）。

## 与相关技能的分工

| 技能 | 职责 |
| --- | --- |
| **本技能** | 正文提炼、约束设计、评测用例、`*.prompt.md` 质量与归属判断、**默认落盘与去重融合** |
| `agent-hub-bootstrap` | `prompts/` 目录、链接、脚手架、`sync-prompts`、`check-prompts`、`build-prompt-index` |
| `project-insight-extractor` | TechInsightVault **技术洞察**资产；可借鉴其「发现优先、去重、backup、索引」闭环，**不**照搬面试/简历分类 |
| `skill-engineering` | `SKILL.md` 与技能 references，不是长提示词仓库 |
| `delivery-workflow` | 需求边界、验收口径；**失败沉淀 R3** 总分流 | 可设 `owner_skill: delivery-workflow` 的 debug 类 prompt |
| `doc-script-governance` | 文档/SQL/脚本治理与备份；prompt 变更建议同样走 backup-file |

## 失败沉淀联动

研发返工结束时：由 `delivery-workflow` **R3** 判定主产物。若主产物为**可复用子 Agent 长指令**（非反模式表、非面试叙事）→ 走本技能 SOP 写入 `prompts/share/agent-task/` 或 `prompts/projects/<key>/`，并跑 `check-prompts` + `build-prompt-index`。

## 真实源与目录

详见 `references/hub_layout.md`。结论：**唯一真实源在 hub**；工作区通过 `sync-prompts` 得到 `hub-share`、`hub-project` 链接。references 全量索引 → [references/README.md](references/README.md)。

## 单文件契约

详见 `references/file_contract.md`（front matter、`replaced_by`、四段正文、`check-prompts` 对标题与非空段的 CI 承诺）。

## 最小 SOP（发现 → 资格 → 去重 → 落盘 → 索引）

与 `project-insight-extractor` **同构的是闭环与证据约束**；**产物不同**（可执行 `*.prompt.md` + eval，而非面试叙事）。

```text
素材输入（会话 / 设计文档 / 代码 / SQL 配置）
→ Prompt Inventory：按 source_kind 扫描并列出 source_anchor（见 extraction_and_eval 前置步骤）
→ 高价值信号扫描（第零步；区分会话信号 vs 运行时提示词信号）
→ 资格判定（是否值得沉淀 / 去私密 / 是否真正进入模型上下文）
→ 类型与归属（type / share vs project-key）
→ 去重融合（先查 prompts.index.json，见 extraction_and_eval）
→ 写入 *.prompt.md（含 source_kind / source_anchor 可选字段）
→ check-prompts + build-prompt-index
→ 输出归档结果（路径、id、write_action、eval 是否已写；设计文档来源须含覆盖率验收）
```

### 写入模式（默认落盘）

- **默认直接写入 hub `prompts/`**；用户明确 `dry-run`、`仅预览`、`不写文件` 时才只给草案。
- **新建**：用 Agent 文件编辑工具（`apply_patch` / Write / Edit）；**禁止** `echo` / heredoc / `Set-Content` 拼正文。
- **更新已有**：先 `$AGENTS_HUB_ROOT/skills/share/doc-script-governance/scripts/backup-file.sh --file-path <path>`（或 `.ps1`），再融合。
- **同语义**：默认**并入已有 canonical `id`**；边界分叉才新 `id`，旧条目 `status: deprecated` + `replaced_by`（见 `file_contract.md`）。
- **收尾（强制）**：执行 `check-prompts` 与 `build-prompt-index`；未绿灯不视为完成。
- **索引**：`prompts/indexes/prompts.index.json` **禁止手改**；去重检索优先用该 JSON。

## 提炼与评测流程

详见 `references/extraction_and_eval.md`（候选扫描、去重表、eval 最小集）。

## 样例与提炼指引

具体样例资产不在主文件枚举，避免把 `SKILL.md` 变成 prompt 索引。子 Agent prompt 专项见 `references/subagent_prompt_extraction.md`，与 `delivery-workflow` 的 `references/subagent_prompt_template.md` 成对使用。

## 推荐命令（校验与索引）

在 hub 根下：

```bash
sh "$AGENTS_HUB_ROOT/scripts/check-prompts.sh"
sh "$AGENTS_HUB_ROOT/scripts/build-prompt-index.sh"
```

```powershell
& "$env:AGENTS_HUB_ROOT\scripts\check-prompts.ps1"
& "$env:AGENTS_HUB_ROOT\scripts\build-prompt-index.ps1"
```

## 闭环门

- 新 prompt 必须有清晰输入/输出契约、禁区、验收和 eval 样例。
- 默认落盘到 hub prompt 真源；已有同语义 prompt 必须融合或标 `replaced_by`，不新建重复资产。
- 收尾必须跑 `check-prompts` + `build-prompt-index`；未通过不算完成。
- 若产物不是给 Agent 执行的 prompt，而是方法论/文章/skill，转 `project-insight-extractor`、`<private-media-skill>` 或 `skill-engineering`。

## trigger / eval 与开源边界

should-trigger / should-not-trigger、share vs project 归属与 public export → **[references/trigger_eval.md](references/trigger_eval.md)**（边界细则见 [hub_layout.md](references/hub_layout.md)）。

真实闭环样例见 `references/closure_example.md`。
