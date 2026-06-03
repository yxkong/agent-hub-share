# skill-engineering

## 核心用途

创建、提炼、审查、重构和优化 Agent Skill（`SKILL.md` 与 `references`）的工程技能。

它负责把“一个想法”收敛成“一个能被正确触发、能指导 Agent 行动、能被维护”的 skill 资产。

## 设计理解 / 设计哲学

这个技能存在的目的，不是帮人堆更多 markdown，而是控制 skill 资产的**边界、触发、结构、验证和维护成本**。

它的核心判断标准只有一个：

> 这个 skill 是否真的能稳定帮助 Agent 找到正确入口并完成动作？

所以 `skill-engineering` 强调：

- 主文件先做路由器，不先写厚文档
- README 作为维护章程，不作为运行入口
- references 只按需下沉，不为了“看起来完整”而堆结构
- create / review / refine-trigger 都必须落到工程门与真实触发验证
- `description` 先服务技能发现，不提前替正文总结 workflow
- 高风险 / 纪律类 skill 除结构、效果、触发验证外，还要看是否真的改变 Agent 行为
- 指令具体度要和任务脆弱性匹配，不把所有 skill 都写成同样硬度

## 分层原则 / 结构约定

- `README.md`：维护章程，解释设计理解、职责边界与维护约束；**不是 Agent 运行入口**
- `SKILL.md`：唯一 Agent 入口，负责 30 秒决策、路由与硬规则
- `references/`：workflow、layout、review、governance、eval 等细则
- `templates/`：新建 skill 时可直接复制的固定模板
- `scripts/`：仅放技能自有可执行辅助脚本；跨技能脚本应回到 hub `scripts/`

**标准目录（强制）**：`SKILL.md` + `README.md` + 根 `templates/` + `references/`（+ 可选 `scripts/`）→ [references/layout/skill_directory_layout.md](references/layout/skill_directory_layout.md)。

## 维护约束

- 扩展 skill README 规范时，必须同步更新：
  - [references/layout/skill_root_readme.md](references/layout/skill_root_readme.md)
  - [templates/TEMPLATE_SKILL_README.md](templates/TEMPLATE_SKILL_README.md)
  - [references/workflow/creation_workflow.md](references/workflow/creation_workflow.md)
  - [references/review/quick_gate.md](references/review/quick_gate.md)
  - [references/review/checklist.md](references/review/checklist.md)
  - [references/review/engineering_completion_gate.md](references/review/engineering_completion_gate.md)
- 若新增或调整 skill 验证方法，必须同步检查：
  - [references/review/eval_playbook.md](references/review/eval_playbook.md)
  - [references/review/behavioral_eval.md](references/review/behavioral_eval.md)
  - [references/governance/skill_characteristics.md](references/governance/skill_characteristics.md)
- 若新建的是高风险 / 纪律类 skill：至少留 1 条无 skill 基线样本 + 1 条带 skill 复测样本；若暂时做不到，只能标行为验证 `unknown`，不能声称“已证明有效”
- 评分相关资产默认采用“质量分 + 兑现分 + 门禁结论”，不得无说明退回单总分
- 任何 skill 的 README 若被当成运行入口，视为分层漂移，应在 review 中降级处理
- 模板、规范和示范样例必须同向演进，不能只改其中一层
- `behavioral_eval.md` 不单开主路由，只挂靠 `review` / `refine-trigger` 处理高风险、纪律执行类 skill
- `description` 的维护默认检查三件事：是否利于发现、是否覆盖真实触发表达、是否把正文 workflow 剧透进 frontmatter
- 审查 skill 时，需判断该 skill 应给高 / 中 / 低自由度指令，而不是默认加重约束

## 单一职责

1. 新建 skill
2. 从存量项目提炼 skill
3. 审查 skill 的边界、结构、触发与可维护性
4. 优化 description / trigger / eval
5. 沉淀坏味道与工程门

## 不负责 / 转交

| 场景 | 转交技能 |
|------|----------|
| 真实研发任务怎么推进 | `delivery-workflow` |
| 文档 / SQL 放置与备份 SOP | `doc-script-governance` |
| hub 安装、挂载、`publish-skill` | `agent-hub-bootstrap` |
| 长 `*.prompt.md` 资产（非 SKILL） | `prompt-engineering` |

## 入口

- **主技能（唯一 Agent 路由）**：[SKILL.md](SKILL.md) — 30 秒路由、`create` / `extract` / `review` / `refine-trigger`；其中高风险 / 纪律类 skill 的行为验证挂靠 `review` / `refine-trigger`
- **review 首读快速门**：[references/review/quick_gate.md](references/review/quick_gate.md) — 判断阻断、可用性四门与是否进入详表
- **行为证据样例**：[references/review/behavioral_evidence.md](references/review/behavioral_evidence.md) — 高风险 / 纪律类 skill 的基线与复测
- **references catalog（维护用，非 Agent 入口）**：[references/INDEX.md](references/INDEX.md)
- **README 章程（人读）**：当前文件

## 真源与挂载

- 共享技能真源：`$AGENTS_HUB_ROOT/skills/share/skill-engineering/`
- 工作区挂载：`<repo>/.cursor/skills/skill-engineering`、`<repo>/.claude/skills/skill-engineering` 等（仅入口，内容在 hub）
- 装配与 junction 约定 → [references/layout/placement_and_junctions.md](references/layout/placement_and_junctions.md)

## 修订记录

| 版本 | 日期 | 修订要点 |
|------|------|----------|
| 1.1.4 | 2026-05-29 | 将 `review/quick_gate.md` 固化为 review 首读快速门，`checklist.md` 降为系统详表 |
| 1.1.3 | 2026-05-28 | 明确高风险 / 纪律类 skill 在 create 阶段也要交基线/复测行为证据，做不到时必须标 `unknown` |
| 1.1.2 | 2026-05-28 | 将发现性 description、行为验证挂靠、自由度与任务脆弱性匹配写入 README 维护章程 |
| 1.1.1 | 2026-05-28 | 明确 `behavioral_eval` 不单开主路由，而是挂靠 `review` / `refine-trigger` |
| 1.1.0 | 2026-05-28 | README 升级为维护章程结构；补设计理解、分层原则、维护约束，并接入双分制口径 |
| 1.0.0 | 2026-05-03 | 初版 README，说明目录、入口、真源与相关技能 |
