# <skill-name>

<!-- [必填] 1–3 句：本技能解决什么问题；给谁用（人 / Agent） -->

## 核心用途

<例如：治理仓库 docs/SQL 的放置、备份与修订记录，不提供业务方案正文。>

## 设计理解 / 设计哲学

<例如：为什么这个技能要独立存在；为什么不用并入相邻 skill；它最核心的判断标准是什么。>

<若本 skill 会定义 trigger / eval / 审查规则，可额外说明：
- `description` 主要服务技能发现，不提前替正文总结 workflow
- 高风险 / 纪律类 skill 要看是否真的改变 Agent 行为
- 指令具体度要和任务脆弱性匹配，不把所有 skill 都写成同样硬度>

## 分层原则 / 结构约定

- `README.md`：维护章程，给人读；**不是 Agent 运行入口**
- `SKILL.md`：运行入口，负责触发、路由、硬约束；不承载 human-only / maintenance-only 枚举、具体业务样例或可变资产清单
- `references/`：细则、模板、workflow、补充说明
- `scripts/` / `templates/`：仅放可执行脚本或固定产物模板（若有）

## 维护约束

- 扩展「负责」范围前：先更新本 README 的边界与设计章节，再改 `SKILL.md`
- 改 `references/*.md` 后：检查 README 的设计理解 / 结构约定是否仍成立
- 若有门禁、评分、模板、脚本规则变化：同步更新相关 references，不允许 README 与运行细则漂移
- 若新增或调整 trigger / eval 方法：同步检查 `eval_playbook`、行为验证文档、完整度标准是否仍一致
- 若本 skill 有行为验证文档：明确它是独立主路由，还是挂靠现有路由；禁止只在 references 出现、不在 README / SKILL 说明
- 维护 `description` 时默认检查三件事：是否利于发现、是否覆盖真实触发表达、是否把正文 workflow 剧透进 frontmatter
- 维护 `SKILL.md` 时默认检查三件事：触发后 30 秒内是否知道先读什么、主文件是否仍是路由器、维护层/示例层是否已下沉

## 单一职责（本 skill 独有）

- 
- 

## 不负责 / 转交

| 场景 | 转交技能 |
|------|----------|
| <例：真实研发任务怎么推进> | `delivery-workflow` |
| <例：业务接口怎么设计> | `<domain-skill>` |
| | |

## 入口

- **Agent 路由器**：[SKILL.md](SKILL.md)
- **references catalog（维护用）**：[references/INDEX.md](references/INDEX.md)（若有；禁止 Agent 当入口）
- **本 README**：维护章程，说明设计理解与维护边界

<若有挂靠型增强文档，可在此写清：
- `<some-reference>.md` 仅作为 `review` / `refine-trigger` 的增强入口，不单开主路由>

## 真源与挂载

- Hub 真源：`$AGENTS_HUB_ROOT/skills/share/<skill-name>/`（或 `projects/<project-key>/`）
- 工作区：`<repo>/.claude/skills/<skill-name>` 等为入口链接，**不以工作区副本为真源**

## 修订记录（人读；`references/` 不写）

| 版本 | 日期 | 修订要点 |
|------|------|----------|
| 1.0.0 | YYYY-MM-DD | 初版 README |
