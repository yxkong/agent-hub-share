# Skill 真源 / 挂载 / 备份契约（硬约束）

> **单一真源**：Agent 与 hub 工具只认本文 + `review/engineering_completion_gate.md` §1。  
> 历史别名 `SKILL_ROUTER_DESIGN.md` 指同一契约，已合并进本文。

---

## 1. 三类路径（禁止混读）

| 路径 | 角色 | Agent / 工具是否当「技能正文真源」 |
|------|------|----------------------------------|
| `$AGENTS_HUB_ROOT/skills/share/<name>/SKILL.md` | **Share 真源** | **是**（唯一合法 share 入口） |
| `$AGENTS_HUB_ROOT/skills/projects/<key>/<name>/SKILL.md` | **Project 真源** | **是**（唯一合法 project 入口） |
| `~/.cursor/skills/<name>/SKILL.md`、`<repo>/.cursor/skills/<name>/SKILL.md`、`.agents/skills/<name>/` 等 | **挂载入口（junction/symlink 镜像）** | **否** — 只读链路，**禁止**在此改正文 |
| `…/bak/**`、`…/references/bak/**`、dated 快照目录 | **历史备份** | **否** — 非并列 truth source |

**结论示例**：`.cursor/skills/<skill-name>/SKILL.md` 是挂载入口；`skills/projects/<project-key>/<skill-name>/SKILL.md` 才是 active 真源。

---

## 2. 合法入口（canonical entrypoint）

每个 skill 包在 hub 内**有且仅有一个**名为 `SKILL.md` 的文件，且路径必须恰好为：

```text
skills/share/<skill-name>/SKILL.md
skills/projects/<project-key>/<skill-name>/SKILL.md
```

**禁止**在下列位置再出现名为 `SKILL.md` 的**文件**：

- `bak/`、`references/bak/` 及任意 dated 快照子目录（如 `bak/20260518-*/SKILL.md`）
- 任意嵌套子目录（`references/foo/SKILL.md` 等）
- 名为 `SKILL.md` 的**目录**（与根入口混淆）

备份须用 `backup-file` 产出 `_SKILL.md`、`SKILL-<stamp>.md`，或归档子目录 `SKILL_md/`（目录名**不是** `SKILL.md`）。

---

## 3. Hub 工具排除规则

下列脚本**只扫描 canonical entrypoint**，显式跳过 `bak/`、`.` 前缀目录与非法嵌套 `SKILL.md`：

| 工具 | 行为 |
|------|------|
| `check-skill-entrypoints` | **fail**：任意非 canonical 的 `SKILL.md`（含 bak 内） |
| `find-skills` | **只列** canonical；不递归扫 dated 快照 |
| `build-skill-index` | 只读 `skills/share/<dir>/SKILL.md` 一层 |
| `agent_skill_names_from_root` / `Get-AgentCanonicalSkillMdFiles` | 挂载/sync 枚举时跳过 `bak/` |

实现真源：`scripts/agent-hub-paths.ps1` / `.sh` → `Test-AgentSkillCanonicalEntrypointRel` / `agent_skill_canonical_entrypoint_rel`。

---

## 4. 维护者动作

| 场景 | 动作 |
|------|------|
| 改 skill 正文 | 只改 hub 真源 → `backup-file` → 跑 `check-skill-entrypoints` |
| 需要历史快照 | `backup-file` 或迁入 `bak/yyyyMM/`，**不得**保留 `…/SKILL.md` 文件名 |
| 发现 dated 目录含 `SKILL.md` | 重命名为 `SKILL-<date>-<tag>.md` 或移入 `bak/yyyyMM/SKILL_md/` |
| 挂载与工作区副本不一致 | 以 hub 真源为准；重跑 `install-hub` / `publish-skill` / `init-project-agenting` |

---

## 5. 与 export / 挂载的关系

- **Public export** 镜像复制 hub 真源；挂载入口不在 export 包内。
- **install-hub** 创建的 junction 指向 hub 真源；Agent 在 IDE 里 `@` 技能时读到的是镜像，编辑仍须回 hub。

---

## 修订记录

| 版本 | 日期 | 修订要点 |
|------|------|----------|
| 1.0.0 | 2026-05-25 | 首版：真源/挂载/bak 硬约束；合并 SKILL_ROUTER_DESIGN 口径 |
