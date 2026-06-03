# Hub 脚本（public export）

> **语言**：[简体中文](README.md) | [English](README.en.md)

> **Public `agent-hub-share` 仅发布 share 技能依赖的 L1 脚本**（成对 `.ps1` / `.sh`）。  
> 完整 L1/L2 索引与 private-only 工具见 **private maintainer hub** 的 `scripts/README.md`。

## 边界

| 层级 | public export | 说明 |
|------|---------------|------|
| **L1 hub `scripts/`** | 本页清单 | 安装、注册、挂载、校验、索引 |
| **L2 `skills/share/<skill>/scripts/`** | 随技能 export | 如 `doc-script-governance/scripts/backup-file.*` |
| **prompt / export / git-hooks 等** | 不 export | 仅在 private hub |

注册项目时若无 `prompts/`：对 `register-project` / `init-project-agenting` 使用 **`-SkipPrompts`**。

## Public L1 清单

| 功能 | PowerShell | Shell |
|------|------------|-------|
| 路径解析 | `agent-hub-paths.ps1` | `agent-hub-paths.sh` |
| 新机器安装 | `install-hub.ps1` | `install-hub.sh` |
| 注册项目 | `register-project.ps1` | `register-project.sh` |
| 项目全量初始化 | `init-project-agenting.ps1` | `init-project-agenting.sh` |
| 同步规则 | `sync-agent-rules.ps1` | `sync-agent-rules.sh` |
| 同步共享技能 | `sync-shared-skills.ps1` | `sync-shared-skills.sh` |
| 发布/复挂技能 | `publish-skill.ps1` | `publish-skill.sh` |
| 校验技能链接 | `check-skill-links.ps1` | `check-skill-links.sh` |
| 修复重复 SKILL 入口 | `fix-skill-entrypoints.ps1` | `fix-skill-entrypoints.sh` |
| 校验 SKILL 入口 | `check-skill-entrypoints.ps1` | `check-skill-entrypoints.sh` |
| 校验 references 拓扑 | `check-skill-structure.ps1` | `check-skill-structure.sh` |
| 校验主文件行数 | `check-skill-size.ps1` | `check-skill-size.sh` |
| share 去项目化 | `check-share-skill-private-coupling.ps1` | `check-share-skill-private-coupling.sh` |
| UTF-8 无 BOM | `check-utf8-no-bom.ps1` | `check-utf8-no-bom.sh` |
| 生成技能索引 | `build-skill-index.ps1` | `build-skill-index.sh` |
| 发现技能 | `find-skills.ps1` | `find-skills.sh` |
| 外部 registry 安装 | `install-skill-from-registry.ps1` | `install-skill-from-registry.sh` |
| 索引构建（Python） | `python/hub_build_indices.py` | （同上） |

分级规则：`skills/share/agent-hub-bootstrap/references/script_tiering.md`。
