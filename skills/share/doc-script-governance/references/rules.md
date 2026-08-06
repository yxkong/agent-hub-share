# 文档、SQL、脚本与技能资料治理规则

## 1. 目录模型

| 类型 | 目录 |
|---|---|
| 业务设计 | `docs/design/<domain>/` |
| 语言相关实现 | `docs/implementation/<language>/<domain>/` |
| 技术 review / 验收 / 风险 | `docs/review/<domain>/` |
| 执行计划 / 回执 | `docs/plan/<domain>/` |
| Feature Spec（过程） / Release / Rollback Plan | `docs/plan/<domain>/` |
| ADR | `docs/design/<domain>/ADR-*.md` |
| 配置说明 | `docs/config/` |
| 开发期 SQL | `docs/db/dev/<module>/` |
| 上线基线 SQL | `docs/db/online/<module>/` |
| 共享技能真实源 | hub 内 `skills/share/<skill>/` |
| 项目技能真实源 | hub 内 `skills/projects/<project-key>/<skill>/` |

## 2. 设计 / 实现 / review 边界

- `design` 只放业务真相，不写技术整改项。
- `implementation` 只放 Java / Python / Vue 等实现真相。
- `review` 只放技术偏差、验收和风险。

### 2.1 与 Agent 资产的分界

- **从代码理解项目并提炼技能**归 **`skill-engineering/extract`**，由其读取架构、业务流、数据流与调用链证据；本技能只管梳理产物的**目录、命名、备份**。
- `prompt` 正文、eval 与 `*.prompt.md` 归 `prompt-engineering`，本技能只管其目录与备份规则。
- `SKILL.md` 正文质量、trigger、references 拓扑归 `skill-engineering`，本技能只管真实源放置与备份策略。
- TechInsightVault 案例、面试表达、简历素材归 `project-insight-extractor`，不放入 `docs/review/`。
- 仅在已确认的 engineering 项目中，若工程产物还没确定为 docs、skill、prompt、insight 或 review，转 `agent-asset-router`；其它项目类型走当前 profile 或询问用户。

## 3. 标准备份规则

### 3.1 改前先跑脚本

修改文档 / SQL / 脚本 / Skill 主文件与 references 前，统一先调用 **L2 真源**：

- `skills/share/doc-script-governance/scripts/backup-file.ps1`
- `skills/share/doc-script-governance/scripts/backup-file.sh`

兼容入口（**private hub only**，转发至上一路径）：hub 根 `scripts/backup-file.ps1` / `.sh`。public export 使用 L2 路径即可。分级见 `skills/share/agent-hub-bootstrap/references/script_tiering.md`。

禁止自行拼接 `cp` / `copy` / `Copy-Item` 模拟同样流程。

### 3.2 备份结构

所有备份产物统一留在目标文件同级 `bak/` 体系内：

- `bak/_<文件名>`：最近副本
- `bak/yyyyMM/<安全目录名>/<时间戳文件>`：历史归档

**`SKILL.md` 专用**：安全目录名固定为 `SKILL_md`（脚本将 `.` 换为 `_`）；归档文件名带时间戳（如 `SKILL-20260525-162751.md`）。**禁止**在 `bak/` 任意子路径保留第二个名为 `SKILL.md` 的文件；**禁止**自建 `bak/20260518-<topic>/SKILL.md` 式 dated 目录。canonical 入口与 discovery 排除见 `skill-engineering/references/layout/skill_truth_source_contract.md`。

`git checkpoint` 只能作为额外回退基线，不能替代脚本备份。

完整步骤与自检要求 → 主技能 [SKILL.md §备份 SOP](../SKILL.md#备份-sop)。

## 4. SQL 规则

- 开发期 SQL 只在 `docs/db/dev/<module>/`
- 上线基线 SQL 只在 `docs/db/online/<module>/`
- 每个模块目录都应产出 `mysql57_dev_final.sql`
- `docs/db/online/` 默认只读

## 5. 禁止事项

- 新增 review 放 `docs/design/review/`
- 仓库级文档、SQL、脚本散落到模块目录
- 用 `_FINAL`、`V2`、`copy` 维护主文档
- 最新文档引用历史副本路径
