# Hub 脚本分级

> Agent 用：决定新脚本放 **hub 根 `scripts/`** 还是 **技能 `scripts/`**。路径一律写 **hub 内相对路径**（如 `scripts/register-project.ps1`），不写本机绝对路径；执行时由 `install-hub` 写入的环境变量或 `--hub-root` 解析 hub 根。通用脚本登记真源为 `scripts/registry.json`，`commands/registry.json` 只登记 slash command。

## 修订记录

| 版本 | 日期 | 修订要点 |
|------|------|----------|
| 1.0.0 | 2026-05-21 | 首版：L1 hub / L2 skill / 兼容入口 |
| 1.1.0 | 2026-07-14 | 融合模型：**hub 稳定入口 + skill 实现真源**；技能专属校验迁入 L2 |

---

## 模型（融合后）

| 层级 | 目录 | 放什么 |
|------|------|--------|
| **L1 Hub 底座** | `scripts/` | 自举与装配总线：`install-hub`、路径库、`register/init/sync/publish`、`check-hub-all` 等；**技能未挂载前也必须能跑** |
| **L1 Forwarder** | `scripts/<name>.*` | 同名薄封装，只转发到 L2；**禁止**第二套实现 |
| **L2 Skill 真源** | `skills/share/<skill>/scripts/` | 只服务一个技能 SOP 的实现；Agent 优先按技能文档调用 L2，兼容旧入口可走 hub forwarder |

**禁止**：在 L1 与 L2 **各维护一套相同逻辑**（除薄 forwarder）。

判定顺序：

1. 只为一个 skill 服务 → **L2**（hub 可留 forwarder）。
2. 安装 / 挂载 / 同步 / 全 hub 编排、或技能未挂载前就要跑 → **L1 底座**。
3. 拿不准 → 先 L2。

---

## L1 底座清单（实现留在 hub）

| 类别 | 脚本 |
|------|------|
| 安装与注册 | `install-hub`、`register-project`、`init-project-agenting` |
| 挂载与同步 | `publish-skill`、`sync-shared-skills`、`sync-agent-rules`、`sync-prompts`、`sync-commands` |
| 装配校验 | `check-skill-links`、`check-user-skill-scope`、`check-commands`、`check-hooks`、`check-agent-rules`、`check-shell-quoting`、`check-hub-all` |
| Plugin | `build-plugin`、`check-plugin`、`export-public-share` |
| 共享库 | `agent-hub-paths`、`agent-pwsh-bridge`、`ensure-hub-python`、`list-scripts`、`registry.json`、`agent_hub.py`、`scripts/python/hub_build_indices.py`（索引引擎，被 L2 调用） |

Private 工具（mysql / llm-local / mineru / cursor-chat-rename / install-git-hooks）本轮不迁，另开 tooling 归属。

---

## L2 真源 + hub Forwarder

| 技能 | L2 真源 | hub 入口（forwarder） |
|------|---------|------------------------|
| `doc-script-governance` | `backup-file`、`audit-doc-script-governance`、`check-backup-policy`、`check-utf8-no-bom`、`normalize-utf8-lf` | 同名（`backup-file` 等） |
| `prompt-engineering` | `check-prompts`、`build-prompt-index`、`validate-prompt-body.awk` | `check-prompts`、`build-prompt-index` |
| `skill-engineering` | `check-skill-size`、`check-skill-structure`、`check-share-skill-private-coupling`、`check-skill-entrypoints`、`fix-skill-entrypoints` | 同名 |
| `skill-discovery` | `find-skills`、`install-skill-from-registry` | 同名 |
| `project-insight-extractor` | `build-tech-insight-index` | 同名 |
| `ai-development-governance` | `check-spec-sdd-structure`、`check-behavior-audit` | 同名 |
| `delivery-workflow` | `check-replay-structure` | 同名 |
| `agent-hub-bootstrap` | `gemini-skill-paths`、`sync-gemini-skills`、`migrate-scripts-to-skill-l2`、`fix-l2-script-hub-paths`、`regen-l1-forwarders` | Gemini：技能内调用；迁移工具仅 maintainer |

完整索引真源：`scripts/registry.json`；人读：`scripts/README.md`。

---

## Agent 调用约定

1. 用户说「挂载 / 注册 / 同步」→ `agent-hub-bootstrap` SOP → **只组参数** → 调 hub L1：`register-project` / `init-project-agenting` / `sync-*` / `check-skill-links`。
2. 用户说「校验 prompt / skill 结构 / 备份」→ 对应技能 SOP → **优先 L2 路径**；旧文档写的 `scripts/<name>` 仍可走 forwarder。
3. **禁止**在业务仓现写临时挂载/校验脚本。

---

## 与文档治理的关系

| 主题 | 转交 |
|------|------|
| 改 docs/SQL 前备份 | `doc-script-governance` → L2 `backup-file` |
| 脚本应放哪 | 本文 |
| 挂载、注册、链接校验 | `agent-hub-bootstrap` + L1 底座 |

研发全流程 → `rules/profiles/engineering/PROFILE_RULES.md`（不在本文重复）。
