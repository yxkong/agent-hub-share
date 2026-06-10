---
name: doc-script-governance
description: 文档、SQL、脚本与技能资料的治理技能（docs placement, SQL dev/online, backup-file）。处理 docs 放置、dev/online SQL 分层、命名引用、标准 backup-file 备份、归档与回退边界。适用于 review 放哪、SQL 合终版、改文档前备份；不处理代码实现质量、prompt 正文或 insight vault 洞察。
---

# 文档与脚本治理

## 30 秒决策区

| 任务类型 | 什么时候选它 | 先读什么 |
|---|---|---|
| `docs-placement` | docs 放哪、设计/实现/review/plan 如何拆；头脑风暴/方案收敛过程稿路径 | 本文件 §目录模型 + `references/rules.md` |
| `backup` | 改文档、SQL、脚本、技能资料前需要备份 | 本文件 §备份 SOP |
| `sql` | dev/online SQL 分层、开发终版包 | `references/rules.md` |
| `audit` | 检查目录、命名、引用、编码、备份是否合规 | `references/checklist.md` |

## 边界

本技能负责：
- `docs/` 资产放置与目录模型
- SQL 分层与开发终版包
- 文档 / SQL / 脚本 / 技能资料的命名、引用、备份、归档
- 文档治理动作的脚本备份、归档与回退边界

本技能不负责：
- 代码实现质量 review
- 业务方案设计本身
- 具体研发任务推进

## 目录模型

| 内容类型 | 目标目录 |
|---|---|
| 业务设计、流程、规则、语言无关 Mermaid | `docs/design/<domain>/` |
| Java / Python / Vue 等语言相关实现 | `docs/implementation/<language>/<domain>/` |
| 技术 review / 审计 / 验收 / 风险清单 | `docs/review/<domain>/` |
| 执行计划、友商任务单、回执模板 | `docs/plan/<domain>/` |
| 头脑风暴、反迎合检查、方案收敛过程稿 | `docs/plan/<domain>/`（模板：`templates/TEMPLATE_BRAINSTORM_CONVERGENCE.md`） |
| Feature Spec（过程） / Release Plan / Rollback Plan | `docs/plan/<domain>/` |
| ADR | `docs/design/<domain>/ADR-*.md` |
| 配置说明、开关说明、脱敏片段、使用说明 | `docs/config/` |
| 开发期 SQL | `docs/db/dev/<module>/` |
| 上线基线 SQL | `docs/db/online/<module>/` |
| 共享技能真实源 | hub 内 `skills/share/<skill>/` |
| 项目技能真实源 | hub 内 `skills/projects/<project-key>/<skill>/` |

**禁止**：新增 review 放 `docs/design/review/`；新增仓库级文档或脚本放模块目录或 `src/main/resources/`。

## 备份 SOP

改 **文档 / SQL / 脚本 / 技能主文件或 references** 前，先执行标准 `backup-file` 脚本；**禁止** AI 自行拼 `cp` / `copy` / `Copy-Item` 代替。

### 1. 标准动作

统一调用 **L2 真源**（本技能目录）：

- `skills/share/doc-script-governance/scripts/backup-file.ps1`
- `skills/share/doc-script-governance/scripts/backup-file.sh`

兼容入口（**private hub only**）：hub 根 `scripts/backup-file.*` 可转发至上一路径；public export 仅含 L2 真源。分级见 `agent-hub-bootstrap/references/script_tiering.md`。

`git checkpoint` 只可作为**额外回退基线**，不能替代脚本备份。

### 2. 调用方式

在 hub 根已配置的前提下，可从项目仓库执行：

```powershell
& "$env:AGENTS_HUB_ROOT\skills\share\doc-script-governance\scripts\backup-file.ps1" -FilePath <文件路径>
```

```bash
bash "$AGENTS_HUB_ROOT/skills/share/doc-script-governance/scripts/backup-file.sh" --file-path <文件路径>
```

或直接调用 L2（路径相对 hub 根）：

```powershell
& "<hub>\skills\share\doc-script-governance\scripts\backup-file.ps1" -FilePath <文件路径>
```

### 3. 备份产物（全部在同级 `bak/` 下）

脚本会在目标文件同级目录生成 `bak/` 体系，至少包含：

1. **最近副本**：`bak/_<原文件名>`（覆盖最近一次）
2. **历史归档**：`bak/yyyyMM/<安全目录名>/<名>-yyyyMMdd-HHmmss.ext`

说明：

- `bak/` 根、最近副本、历史归档都在同一套 `bak/` 结构内。
- `safe` 目录名按脚本规则由原文件名转换，避免与技能入口或主文件路径冲突。

**备份 `SKILL.md` 时（与 `skill-engineering` 硬约束一致）**：

- 标准脚本**只会**产出 `bak/_SKILL.md` 与 `bak/yyyyMM/SKILL_md/SKILL-yyyyMMdd-HHmmss.md`（安全目录名 `SKILL.md` → `SKILL_md`，**不会**在 `bak/` 下再留名为 `SKILL.md` 的文件或目录）。
- **禁止** Agent 手工建 `bak/<dated-topic>/SKILL.md`、整包 dated 快照目录，或用 `cp`/复制代替 `backup-file`——这类路径会被 `check-skill-entrypoints` 判 fail，并污染 `find-skills` / review。
- 多文件批量快照：对每个文件分别 `backup-file`，或迁入 `bak/yyyyMM/<安全目录名>/`；细则见 `skill-engineering/references/layout/skill_truth_source_contract.md`。

### 4. 改后自检

- 已完成标准脚本备份，且备份产物位于目标文件同级 `bak/`
- 若另外做 git checkpoint，确认只包含本次目标文件
- 禁止无脚本备份直接改主文件
- 细则与目录审计 → [references/rules.md](references/rules.md)、[references/checklist.md](references/checklist.md)

## 命名与编码

- 主文件名不写 `FINAL`、`V2`、`copy`
- 最新文档禁止引用历史副本文件名
- 文档、SQL、脚本统一 `UTF-8`，文本优先 `LF`
- 每个 `docs/db/dev/<module>/` 应产出 `mysql57_dev_final.sql`

## 审计

治理完成后，至少检查：

- 文档是否进入正确目录
- SQL 是否按 dev / online 分层
- 设计 / 实现 / review 是否拆开
- 脚本备份与可选 git checkpoint 是否符合规则

## 闭环门

- 所有被修改的文档 / SQL / 脚本 / 技能资料都已用标准 `backup-file` 备份。
- 最新正文不引用 `bak/`、旧副本、`FINAL/V2/copy` 文件名。
- 文档落位与内容类型一致；业务方案归设计/计划，审计归 review，脚本说明归 config 或 implementation。
- 如果任务从“放哪/怎么备份”变成“需求怎么做”，立即转 `delivery-workflow`。

细则见 [references/rules.md](references/rules.md) 与 [references/checklist.md](references/checklist.md)；references 索引 → [references/README.md](references/README.md)。

## 治理审计输出格式

Agent 完成 docs/SQL/脚本治理后，可按此格式汇报（细节见 checklist）：

```markdown
### 1. 目录放置
- 通过：
- 违规：
- 建议移动：

### 2. 备份状态
- 已备份：
- 缺失：
- 回退点：

### 3. SQL 分层
- dev：
- online：
- final：

### 4. 引用与命名
- 历史副本引用：
- FINAL/V2/copy 命名：
- 编码风险：

### 5. 下一步
-
```

## trigger / eval

完整正负例见 `references/trigger_eval.md`。主文件只保留记忆规则：

- **should-trigger**：docs 放置、模板、命名、backup-file、dev/online SQL 分层、review 目录裁决、头脑风暴/方案收敛文档路径
- **should-not-trigger**：业务方案、接口实现、代码修复、skill 结构审查、hub 挂载修复

真实闭环样例见 `references/closure_example.md`。

## 与其他技能的关系

| 技能 | 何时转移 |
|---|---|
| `ai-development-governance` | 端到端研发治理、Spec/ADR/Release/Security 门禁、scorecard；文档落位仍归本技能 |
| `codebase-architecture` | 代码理解、架构视图、逻辑分层、读码顺序；本技能只管梳理**完成后**的落盘与备份 |
| `agent-asset-router` | 用户同时提到 skill / prompt / hub / insight / review，尚未确定目标产物时 |
| `delivery-workflow` | 问题变成需求拆解、阶段推进时 |
| `skill-engineering` | 需要系统优化 skill 内容结构和触发描述时 |
