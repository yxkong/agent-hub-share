# 工程完成门（入口合法 + 可见性）

> **何时读**：`create` / `extract` 收尾；`review` 或 `refine-trigger` 若改动了 hub 内 `SKILL.md` 或技能目录结构；排查「客户端找不到 skill」时。

## 刚性顺序

凡 **新建 skill**、**在 hub 内改动任意 `SKILL.md`**，或 **审查结论要求修复目录 / front matter**，路由收尾必须按下列顺序执行（**单一真源**；其他文档不得另起一套「仅部分步骤」的结束条件）：

### 1. 入口脚本校验

在 hub 根上运行 `check-skill-entrypoints`：

- 校验各技能**根** `SKILL.md` **文件**的 front matter（开头 `---`、闭合 `---`、`name`、`description`）
- 拒绝 skill 树下 **任意非根路径** 再出现名为 `SKILL.md` 的**文件**（含 `bak/`、`references/bak/` 等）；备份须用 `_SKILL.md`、`SKILL.legacy-*` 等命名；归档子目录须使用 `SKILL_md` 等安全名，**禁止**再使用名为 `SKILL.md` 的**目录**（脚本亦拒绝该类目录，以免与根入口混淆）
- 与 `fix-skill-entrypoints` / `agent-hub-bootstrap` 一致；**`fix-skill-entrypoints`** 会将嵌套 **文件** 改名，并将名为 `SKILL.md` 的**目录**内文件合并进同级 `SKILL_md/`（可用 `--dry-run` 预览）；仅含子目录、不含可作平移的文件集时脚本会失败，需人工整理后再跑

命令：

- macOS/Linux：`bash "$AGENTS_HUB_ROOT/scripts/check-skill-entrypoints.sh" --hub-root "$AGENTS_HUB_ROOT"`
- Windows：`& "$env:AGENTS_HUB_ROOT\scripts\check-skill-entrypoints.ps1" -HubRoot $env:AGENTS_HUB_ROOT`

**通过标准（收尾必备）**：控制台输出 `SKILL_ENTRYPOINTS=ok` 且脚本 **exit 0**。仅有人肉浏览 front matter **不能**替代本条。

若有违规：先用 hub 的 `fix-skill-entrypoints` 处理嵌套/重复入口（含 **`SKILL.md` 目录**），再重跑；整体流程见 `agent-hub-bootstrap`。

### 2. references 拓扑校验（单技能优先，全仓可审计）

按父技能 `skill-engineering` 与 `design_principles.md` 的约定校验 `references/`：**顶层并列 `*.md` 数量**（排除 `bak/` 子树口径）、**语义子目录仅一层**且其下不再嵌套目录、**每层并列 `*.md` 不超过 15**；并检测 **Markdown 行内链** 是否从某一语义子目录 **跨到** 另一语义子目录（形如 `](../<邻目录>/`、`](./../<邻目录>/` 及对应的 `.md)`），以落实「禁止跨子目录引用」的最小可脚本子集（不解析 HTML 链、脚注式 `[ref]: url`、也不解析 `../` 以外的复杂内链）。  

**新增（share only）**：对改动的 share 技能再补跑 `check-share-skill-private-coupling`，扫描 active `SKILL.md` / `README.md` / `references/**/*.md`（排除 `bak/`）中的**最小私有耦合集**；当前至少拒绝真实项目/模块前缀、legacy docs 治理命名、已知 private repo 名与本机绝对路径。命中后应改为 `<project-key>` / `<runtime-module>` / `<domain-module>` / `docs/guide/DOCS_GOVERNANCE.md` / `<hub-root>` 等通用占位符。

**日常收尾（推荐）**：只对 **本次变更涉及** 的技能根目录执行 §2（可为 1 个或多个），**避免**被 hub 内其它 project skill 的历史结构误伤：

- macOS/Linux：  
  `bash "$AGENTS_HUB_ROOT/scripts/check-skill-structure.sh" --hub-root "$AGENTS_HUB_ROOT" --skill-root "$AGENTS_HUB_ROOT/skills/share/<skill>"`
  （`--skill-root` 可重复多次，每次传入**含 `SKILL.md` 的技能目录**的绝对路径。）
- Windows：  
  `& "$env:AGENTS_HUB_ROOT\scripts\check-skill-structure.ps1" -HubRoot $env:AGENTS_HUB_ROOT -SkillRoot @('<skill 根目录绝对路径 1>', '…')`

**全仓审计 / 定期整理**：不传 `--skill-root` / `-SkillRoot`，脚本按树扫描 `skills/share`（且默认包含 `skills/projects`）；用于 CI 或专项清理。若仅能保证 share 已达标、projects 尚在迁移，可加 `--only-share`（PowerShell：`-OnlyShare`）**仅**扫 share；**不得**据此宣称全仓已合规。

**通过标准（收尾必备）**：输出 `SKILL_REFERENCES_STRUCTURE=ok` 且 **exit 0**。若是 share 技能，还需额外输出 `SHARE_SKILL_PRIVATE_COUPLING=ok` 且 **exit 0**。

**与 §1 的关系**：必须在 §1 已通过后再跑 §2（入口仍违规时不必跑 references 拓扑）。

**README 联动（人工必查）**：

- 根 README 是否明确写出“维护章程，不是运行入口”
- 若本次改动影响边界、评分、门禁、分层、模板或脚本契约，README 的设计理解 / 维护约束是否同步更新
- 若本次新增或调整 trigger / eval 增强文档：README 与 `SKILL.md` 是否都写清它是**独立路由**还是**挂靠路由**

**多域 skill 附加（人工，脚本不可用时必做）**：对照 [router_handbook_gate.md](router_handbook_gate.md) 与 [checklist.md §7.5](checklist.md#75-router--handbook--tier-门禁多域-skill-必查)。

### 3. 主文件规模脚本校验（非空行）

对 **本次新建或改动的** 每个技能根 `SKILL.md` 各跑一次（与父技能 `skill-engineering` 的「主文件行数」分级表一致，用 `--type` 或 `--max`）：

- macOS/Linux：`bash "$AGENTS_HUB_ROOT/scripts/check-skill-size.sh" --file <hub 内该技能根 SKILL.md 绝对路径> --type pure-router|router-hard|multi-domain|meta`（或 `--max N`）
- Windows：`& "$env:AGENTS_HUB_ROOT\scripts\check-skill-size.ps1" -File <路径> -Type meta`（或 `-Max N`）

**通过标准（收尾必备）**：输出 `SKILL_SIZE_OK` 且脚本 **exit 0**。未在主文件声明类型时，按最接近结构归入四类之一再选 `--type`。

**与 §1、§2 的关系**：必须在 §1、§2 均已通过后再跑 §3（避免在入口或 references 拓扑仍违规时白算行数）。

### 4. 挂载（create / extract）

真实源已在 hub 后，执行 `install-hub` 或 `publish-skill`（见 `agent-hub-bootstrap`），保证 **用户级或项目级** 挂载入口存在且符号链接 / junction 有效。

### 5. 真实触发自检（可执行定义）

目标：证明「客户端确实加载了本次 skill」，而不是口头声称已验证。

| 项 | 要求 |
|----|------|
| **目标客户端** | 与本次挂载一致，至少选一：**Cursor**（`~/.cursor/skills/<name>` 或仓库 `.cursor/skills/<name>`）、**Claude Code**（`~/.claude/skills/<name>`）、**Codex**（`~/.codex/skills/<name>`） |
| **输入（触发句）** | 从该 skill 根 `SKILL.md` 的 `description:` 或正文 **should-trigger** 中摘 **1 条完整短句**（原文照抄，勿改写）作为用户消息发送 |
| **成功信号（任一）** | ① 客户端在会话上下文中列出/命中该 skill（`name:` 与之一致）；② 或首轮回复显式按该 skill 的路由/SOP 行动（可引用其 references 路径）；若该技能含挂靠型增强文档，回复中的入口关系与 `SKILL.md` / README 描述一致 |
| **失败时** | 顺序执行：`check-skill-links`（若项目挂载）→ 自 **§1** 起按需重跑 → `install-hub` 或 `publish-skill` 重挂 → **重复**本自检；仍失败则记 `unknown`，不得关闭「工程收尾」为已通过 |

**交付物（建议写在会话小结）**：客户端名、所用触发句原文、观察到的成功信号（一句）。

## `review` / `refine-trigger`

- **改动了 hub 内某技能根 `SKILL.md`**（含仅改 front matter/正文）：必须 **§1 → §3**（针对该文件的规模校验）；若本次还涉及新建目录 / 首次挂载 → **§1–§5** 全跑。
- **仅改 references、未改根 `SKILL.md`**：至少 **§1**；**§2 至少对该技能**传 `--skill-root` / `-SkillRoot` **仅校验本 skill**；若 entrypoint 脚本仍覆盖到该技能目录则与全仓一致。**建议**仍对根 `SKILL.md` 跑 **§3** 以免与其它编辑并发时漏检。
- **`create` / `extract`**：`§1–§5` 全跑（见 `workflow/creation_workflow.md` / `workflow/legacy_project_extraction.md`）；§2 对 **新建 skill** 使用其技能根 `--skill-root`。

## 评分相关资产的附加口径

若本次改动的是评分 / 审计类技能或文档：

- 输出口径默认采用“**质量分 + 兑现分 + 门禁结论**”
- 若仍使用单总分，必须在文档里明确说明原因；默认视为未完成联动

## 脚本或环境未就绪时

- **人工核对**（肉眼看 `---`、目录树、粗算行数）**仅作诊断**，**不得**作为「收尾已通过」的充分条件。
- **默认**：修复 `AGENTS_HUB_ROOT`、补全 `scripts/`、恢复脚本可执行性后，**必须**对适用步骤重新跑 **§1–§3**（及对场景的 §4–§5）至 exit 0，再结束 skill 工程任务。
- 仅在 **物理无法运行脚本** 的极端场景：在交付物中写明阻断原因与计划，并标 `risk`；不宣称已完成工程完成门。
