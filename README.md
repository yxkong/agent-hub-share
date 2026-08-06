# Agent Hub（Share Skills）

> **语言**：[简体中文](README.md) | [English](README.en.md)

面向 AI 辅助软件交付的**共享技能**、**通用规则**与**门禁脚本**。

本仓库发布可复用的 `skills/share`、全局规则 `COMMON_AGENT_RULES.md`，以及可脚本验证的门禁（**不含** `prompts/` 与项目私有 overlay）。不绑定单一 IDE；不能替代测试、评审或发布工程。

## 为什么「只靠 Prompt」不够

单靠 Prompt 无法系统性解决：

- 项目规则重复、漂移
- 缺少可执行的交付阶段门
- 文档/SQL 乱放
- 无法确认 Agent 是否真的加载了技能
- public 资产与项目私有 overlay 边界不清

Agent Hub 用 **技能 + 通用规则 + 脚本门禁** 组成闭环（可执行 Prompt 资产不在本仓发布）。

**0.2.0 重点**：证据闭环与阶段门——主链证据矩阵、Gate 5 复盘落盘、R3 handoff、研发体系审计（`rd-audit`）与 AGENT-GATE-CARD；详见 [CHANGELOG.md](CHANGELOG.md)。

## 你得到什么

| 层级 | 内容 |
|------|------|
| **Share 技能（14）** | 工程路由、治理总线、交付 workflow、文档/SQL 治理、运维底座、业务安全审计、skill/prompt 工程、评分、TDD、浏览器验证 |
| **通用规则** | 仅 `rules/common/COMMON_AGENT_RULES.md` |
| **脚本** | share 技能依赖的 L1 子集（见 [`scripts/README.md`](scripts/README.md)）；L2 随各技能目录 export |
| **CI / 模板** | GitHub Actions 与 Issue/PR 模板 |

项目增量规则与 overlay 由业务仓库内的 `PROJECT_RULES.md` / `AGENTS.md` 等自行维护；**本 README 仅描述本仓已发布内容**。

## 五分钟上手

```bash
git clone git@github.com:yxkong/agent-hub-share.git agent-hub
cd agent-hub
export AGENTS_HUB_ROOT="$PWD"

bash scripts/install-hub.sh --dry-run
bash scripts/check-utf8-no-bom.sh --repo-root "$AGENTS_HUB_ROOT"
bash scripts/check-skill-entrypoints.sh --hub-root "$AGENTS_HUB_ROOT" --only-share
bash scripts/check-skill-structure.sh --hub-root "$AGENTS_HUB_ROOT" --only-share
bash scripts/check-share-skill-private-coupling.sh --hub-root "$AGENTS_HUB_ROOT"
bash scripts/build-skill-index.sh --hub-root "$AGENTS_HUB_ROOT"
```

- Windows：[WINDOWS.md](docs/getting-started/WINDOWS.md)
- macOS / Linux：[MACOS_LINUX.md](docs/getting-started/MACOS_LINUX.md)
- 完整流程：[QUICKSTART.md](docs/getting-started/QUICKSTART.md)
- 文档索引：[docs/getting-started/README.md](docs/getting-started/README.md)

## 技能套餐

| 套餐 | 包含技能 | 适用 |
|------|----------|------|
| **Minimal** | `agent-hub-bootstrap` + `delivery-workflow` + `doc-script-governance` | 降返工、规范文档 |
| **Engineering Standard** | Minimal + `ai-development-governance` + `agent-asset-router` + `skill-scorecard` + `biz-safety-audit` | 仅工程项目；router 不挂载到 generic/media/hub/mixed |
| **Engineering Asset Factory** | Engineering Standard + `skill-engineering` + `prompt-engineering` + `skill-discovery` | 工程体系内维护 skill/prompt 资产 |
| **Full** | Engineering Asset Factory + `project-insight-extractor` + `tdd-workflow` + `webapp-testing` | 工程体系内的洞察 + TDD + 浏览器验证 |

目录：[`skills/share/index.json`](skills/share/index.json)

**每个技能做什么、整体怎么用** → [SKILLS_GUIDE.md](docs/getting-started/SKILLS_GUIDE.md)（[English](docs/getting-started/SKILLS_GUIDE.en.md)）

Share 层使用 `<project-key>` 等占位符；绑定真实项目名见业务仓库 `PROJECT_RULES.md`。

## 使用说明（中文默认）

| 文档 | 说明 |
|------|------|
| [SKILLS_GUIDE.md](docs/getting-started/SKILLS_GUIDE.md) | **14 技能介绍 + 整体用法** |
| [getting-started/README.md](docs/getting-started/README.md) | 安装与验证文档索引 |
| [QUICKSTART.md](docs/getting-started/QUICKSTART.md) | 安装、注册项目、验证 |
| [VERIFY.md](docs/getting-started/VERIFY.md) | 确认客户端已加载技能 |
| [SHARE_SKILL_SCORECARD.md](docs/getting-started/SHARE_SKILL_SCORECARD.md) | 公共包评分摘要 |
| [CONTRIBUTING.md](CONTRIBUTING.md) | 贡献 share 技能（英文） |
| [CHANGELOG.md](CHANGELOG.md) | 变更记录 |

## License

[MIT](LICENSE)
