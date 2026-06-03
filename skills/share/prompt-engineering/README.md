# prompt-engineering

## 定位

提炼、裁剪、评测和落盘可复用提示词资产（`*.prompt.md`），管理 hub 内 prompts 正文质量与归属。

## 核心要点

- **真源在 hub**：`$AGENTS_HUB_ROOT/prompts/share/` 与 `prompts/projects/<key>/`；工作区经 `sync-prompts` 得链接镜像。
- **单文件契约**：front matter、`id` 全局唯一、四段正文；落盘后跑 `check-prompts` + `build-prompt-index`。
- **与 insight 分流**：给 Agent 复用执行写 prompt；给人复盘表达写 TechInsightVault。
- **R3 联动**：研发返工若主产物为可复用子 Agent 长指令，走本技能 SOP 写入 `prompts/share/agent-task/`。

## 关键 references

| 文件 | 用途 |
|------|------|
| `references/hub_layout.md` | prompts 目录与真源/镜像关系 |
| `references/file_contract.md` | `*.prompt.md` 结构与 CI 承诺 |
| `references/extraction_and_eval.md` | 发现、资格、去重、eval |
| `references/subagent_prompt_extraction.md` | 从子 Agent 任务提炼 prompt |
| `references/closure_example.md` | `check-prompts` + `build-prompt-index` 收尾样例 |

## 协作入口

| 场景 | 转交 |
|------|------|
| prompts 链接、sync、校验脚本 | `agent-hub-bootstrap` |
| SKILL.md 与技能 references | `skill-engineering` |
| 技术洞察/面试叙事 | `project-insight-extractor` |
| 研发边界与验收 | `delivery-workflow` |
