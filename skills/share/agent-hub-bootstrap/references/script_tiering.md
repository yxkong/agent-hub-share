# Hub 脚本分级

> Agent 用：决定新脚本放 **hub 根 `scripts/`** 还是 **技能 `scripts/`**。路径一律写 **hub 内相对路径**（如 `scripts/register-project.ps1`），不写本机绝对路径；执行时由 `install-hub` 写入的环境变量或 `--hub-root` 解析 hub 根。

## 修订记录

| 版本 | 日期 | 修订要点 |
|------|------|----------|
| 1.0.0 | 2026-05-21 | 首版：L1 hub / L2 skill / 兼容入口 |

---

## 两级模型

| 级别 | 目录 | 放什么 | 判定（满足任一即 L1） |
|------|------|--------|------------------------|
| **L1 Hub** | `scripts/`、`scripts/python/` | 跨技能基础设施或**独立运维/装配场景**工具：安装、注册、挂载、规则同步、索引、全 hub 校验 | 被 `register-project` / `init-project-agenting` 链路调用；或同时服务多个 share 技能；或操作 `rules/`、`prompts/indexes/` 等 hub 全局资产；或本身就是不依赖某个单 skill 的独立入口 |
| **L2 Skill** | `skills/share/<skill>/scripts/` 或 `skills/projects/<key>/<skill>/scripts/` | 只服务**一个**技能域的工具 | 备份、审计、代码生成、领域 CLI；随该 skill 文档一起演进；**默认所有非通用脚本都先放 L2** |

**禁止**：在 L1 与 L2 **各维护一套相同逻辑**（除下文「兼容入口」允许的薄封装）。

---

## L1 清单（hub `scripts/`）

| 类别 | 脚本（`.ps1` / `.sh` 成对） |
|------|------------------------------|
| 安装与注册 | `install-hub`、`register-project`、`init-project-agenting` |
| 挂载与发布 | `publish-skill`、`sync-shared-skills`、`sync-agent-rules`、`sync-prompts` |
| 校验与索引 | `check-skill-links`、`check-skill-entrypoints`、`check-skill-structure`、`check-skill-size`、`check-prompts`、`build-prompt-index`、`build-tech-insight-index`、`check-utf8-no-bom` |
| 发现与安装 | `find-skills`、`install-skill-from-registry` |
| 共享库 | `agent-hub-paths`、`ensure-hub-python`、`list-scripts`、`install-git-hooks` |
| Python 包 | `scripts/python/hub_build_indices.py`、`scripts/python/mysql_schema_diff/`（跨项目 DBA 工具，非单 skill） |

完整索引见 hub 根 **`scripts/README.md`**。

---

## L2 清单（技能 `scripts/`）

| 技能 | 脚本 | 说明 |
|------|------|------|
| `doc-script-governance` | `backup-file`、`audit-doc-script-governance` | 文档/SQL/技能资料备份与治理自检 |
| `<backend-domain-skill>`（示例） | `gen-ddd`、`gen-ddd-from-table.py` | 项目 DDD 脚手架（技能名见 PROJECT_RULES） |
| 其他 share/project skill | 按需 | 仅当工具**只属于该 skill** 时创建 |

新 L2 脚本：**必须先**在该 skill 的 `SKILL.md` 或 `references/` 中说明用途与调用方式；**不要**默认丢进 hub `scripts/`。

判定顺序（默认保守）：

1. **若脚本只为一个 skill 服务**，即使它未来可能被别的 skill 借鉴，**先放 L2**。  
2. **仅当脚本已同时服务多个技能**，或它本身是安装/挂载/校验/索引这类**独立入口**，才升为 L1。  
3. 若拿不准，**先放 L2**；等出现第二个真实调用方或明确独立场景，再迁到 hub `scripts/`。  

---

## 兼容入口（L1 薄封装 → L2 真源）

个别 L2 脚本可在 hub `scripts/` 保留**同名薄封装**，仅做路径解析并 `exec` / `&` 转发到 L2 真源，便于 `list-scripts` 与旧文档入口。

| hub 入口 | L2 真源 | 状态 |
|----------|---------|------|
| `scripts/backup-file.*`（**private hub only**） | `skills/share/doc-script-governance/scripts/backup-file.*` | **public export 仅 L2**；private 可保留 hub 薄封装转发 |

新增兼容入口须在本表登记；**不得**在 hub 再写第二套实现。

---

## 与文档治理的关系

| 主题 | 转交 |
|------|------|
| 改 docs/SQL 前备份 | `doc-script-governance` → L2 `backup-file` |
| 脚本应放哪、备份目录结构 | `doc-script-governance` |
| 挂载、注册、链接校验 | 本技能 + L1 脚本 |

研发全流程 → **`rules/common/COMMON_AGENT_RULES.md` §研发全流程**（不在本文重复）。
