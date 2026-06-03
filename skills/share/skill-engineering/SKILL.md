---
name: skill-engineering
description: 创建、提炼、审查、重构和优化 AI Skill（skill creation, trigger eval, references structure）。适用于新建 skill、从项目抽 skill、优化 description/trigger/eval、沉淀坏味道；不负责长 prompt、insight vault 或 hub 挂载脚本或真实业务代码。
---

# Skill Engineering

## 30 秒决策区

| 任务类型 | 什么时候选它 | 先读什么 |
|------|------|------|
| `create` | 还没有 skill，要从零创建 | `references/workflow/creation_workflow.md` |
| `extract` | 要从存量代码 / 文档 / 老项目提炼 skill | `references/workflow/legacy_project_extraction.md` |
| `review` | 现有 skill 结构重、边界乱、难触发或难用 | `references/review/quick_gate.md`；系统修复再读 `references/review/checklist.md` + `references/review/router_handbook_gate.md`；高风险再读 `references/review/behavioral_eval.md` |
| `refine-trigger` | description / trigger / eval 不准，或要确认 skill 是否真的改变行为 | `references/review/eval_playbook.md`；若是高风险 / 纪律类 skill，再读 `references/review/behavioral_eval.md` |

规则：一次只走一条主路由；**先读路由前必读，再读对应 P0**；如果问题是"研发任务怎么推进"，立即转 `delivery-workflow`。

## 作用边界

**覆盖**：创建 / 提炼 / 审查 / 重构技能；优化 description / trigger / eval；识别坏味道并沉淀规则。

**不覆盖**：推进真实业务需求开发；代替领域技能实现业务代码。

## 输出级别

见 `references/governance/output_levels.md`；full 加强项见 `references/review/full_mode_checklist.md`。

## 7 个硬规则

- **证据优先级**：`P0 > P1 > P2`（当前主链路代码 > 当前主文档 > 历史文档）。冲突按此优先级；不确定内容标注 `assumption` 或 `unknown`。
- **最小可驱动产物**：`extract` 时先产最小包（边界 + 主链路 + 高频切入点 + 最小 SOP + 最小验证），稳定后再升档。
- **高风险 / 纪律类证据门**：若 skill 容易被时间压力、沉没成本、速度偏好或“就这一次”合理化绕过，`create` / `review` / `refine-trigger` 至少要有 1 条无 skill 基线样本 + 1 条带 skill 复测样本；做不到时明确标 `unknown`，不得宣称“已证明改变行为”。
- **完成门**：真实入口可定位、主链路可复述、≥ 3 个高频场景有切入点、≥ 1 个真实任务可验证，四项未满不算可用。
- **冲突处理**：文档与代码冲突优先代码；多实现并存优先当前主调用链；找不到主链路不允许虚构。
- **开发可驱动性优先**：先问能否让 AI 更快找到入口、减少误改漏改返工；结构再完整，两问答不了"是"也不合格。
- **工程门禁**：hub 内 skill 有改动时收尾须按 `references/review/engineering_completion_gate.md` 执行 **§1–§5**（或该文档声明的适用子集），不得以零散命令替代。

## References 优先级

**路由前必读（全路由，先于 P0）**

- `references/governance/bad_smell_registry.md`（查已知坏味道；路由结束后按需追加/计数）

**P0（按路由选读）**

- `references/workflow/creation_workflow.md` → `create`
- `references/workflow/legacy_project_extraction.md` → `extract`
- `references/review/quick_gate.md` → `review` 首读
- `references/review/checklist.md` + `references/review/router_handbook_gate.md` → `review` 系统修复（及 create/extract 收尾）
- `references/review/eval_playbook.md` → `refine-trigger`

**P1（按需）**

- `references/layout/skill_directory_layout.md`（**create** / 改目录：根 `templates/` + references 深度 ≤15）
- `references/layout/skill_truth_source_contract.md`（**create** / **review**：canonical 真源、bak 排除、挂载入口非真源）
- `references/workflow/extraction_prompt_template.md`（extract/create 三阶段 Prompt）
- `references/governance/output_levels.md` / `references/review/full_mode_checklist.md`
- `references/layout/project_elements.md`
- `references/layout/placement_and_junctions.md`（create/extract 装配与挂载）
- `references/review/behavioral_eval.md`（`create` / `review` / `refine-trigger`：高风险、纪律执行类 skill 的行为验证）
- `references/review/behavioral_evidence.md`（高风险、纪律执行类 skill 的基线 / 复测样例）
- `references/review/engineering_completion_gate.md`（收尾单一真源 §1–§5）
- `references/eval/trigger_eval.md`（本技能 trigger 回归）

**P2（仅复杂场景）**

- `references/governance/design_principles.md` / `references/governance/skill_characteristics.md` / `references/governance/diagrams_guidelines.md`

其余 catalog / README 仅维护用，不作 Agent 入口；catalog 见 `references/INDEX.md`。

## 红线（摘要；细则见 layout / review / governance）

### 备份

改任何主文件前调用 hub `backup-file.ps1` / `backup-file.sh`；**禁止**自拼 `cp`。未配置 `AGENTS_HUB_ROOT` → 转 `doc-script-governance` 备份 SOP。

### 主文件规模

非空行上限：纯路由 **80** / 路由器+硬约束 **130** / 多域 **150** / 元技能 **160**。用 hub `check-skill-size`；超限立即拆并下沉 `references/`。

### References 拓扑

顶层 `*.md` **≤15**（不含 `bak/`）；≥16 须语义子目录且每层 `*.md` **≤15**；禁止三层嵌套；子目录内禁止 `../邻目录/` 跨链——见 `references/layout/skill_directory_layout.md` §3。

### 技能放置

真实源只在 `$AGENTS_HUB_ROOT/skills/share|projects/`；**canonical 路径有且仅有一个 `SKILL.md`**（`bak/**`、dated 快照内禁止再出现该文件名）；挂载入口（`.cursor/skills/` 等）**不是**真源。硬约束见 `references/layout/skill_truth_source_contract.md`；挂载仅经 `agent-hub-bootstrap` 脚本，禁止手拼 `ln -s` / `mklink`。

### 工程完成门

新建 / 改 `SKILL.md` / 审查要求修目录 → 必须 `references/review/engineering_completion_gate.md` **§1–§5**（或文内适用子集）。

## 闭环门

- `review` 已先过 `quick_gate.md`；系统修复再进 checklist 详表。
- create / extract / review / refine-trigger 结束前已检查坏味道并按需沉淀。
- hub 内技能改动已过工程完成门适用步骤。
- 高风险 / 纪律类 skill 的行为有效性已给出基线/复测证据或标 `unknown`。

### 其他禁止项

- 主文件不展开 references 已覆盖的细节；不把 `delivery-workflow` 写进本技能
- 不在证据不足时虚构规则；不把绝对路径、凭据写进正文

## 反馈闭环（坏味道 → 规则）

每次路由：**开始前**读 `governance/bad_smell_registry.md`；**结束后**检查坏味道并计数。同一模式 **N≥2** → 写入 `governance/design_principles.md` §六，并修正 skill 切入点/SOP。

| 信号 | 类型 |
|------|------|
| SOP 后仍不知改哪个文件/类/方法 | SOP 空泛 |
| 触发后无实质帮助 | 内容无效 |
| 主文件需通读才懂路由 | 路由器失效 |
| 非空行超类型上限 | 主文件膨胀 |
| 同一追问跨 session 重复 | 系统性问题 |

## 技能钩子协议

由本技能创建/审查的 skill 默认遵守：SOP 无法定位 / 错误切入点返工 / 跨 session 重复 → 追加 `bad_smell_registry`；N≥2 提升 `design_principles` §六。**钩子不写入被创建 skill 主文件。**

## trigger / eval

完整正负例见 `references/eval/trigger_eval.md`。主文件只保留记忆规则：

- **should-trigger**：新建/提炼/审查 skill、优化 description / trigger、验证行为有效性、沉淀坏味道规则
- **should-not-trigger**：需求推进、具体业务实现、资产类型未决的分诊问题

## 与其他技能的关系

| 技能 | 何时转移 |
|------|----------|
| `agent-asset-router` | 产物未定在 skill / prompt / insight / hub / docs 间 |
| `delivery-workflow` | 真实研发任务怎么推进 |
| `doc-script-governance` | 文档/SQL 放置、备份、skill 目录治理 |
| `agent-hub-bootstrap` | hub 安装、挂载、`publish-skill` |
| 领域技能 | 落地业务代码 |
