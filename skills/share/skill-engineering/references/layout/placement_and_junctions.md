# 技能装配与真实源治理（跨平台）

本文只说明一个原则：**真实 skill 内容与挂载入口分离**。硬约束全文见 **[skill_truth_source_contract.md](skill_truth_source_contract.md)**（真源 / 挂载 / bak 排除；原 `SKILL_ROUTER_DESIGN` 口径已合并）。

## 1. 通用原则

- 真实 skill 内容统一维护在 hub
- 用户级和项目级目录只放挂载入口，不放真实内容
- 平台相关的路径、链接方式、脚本命令都属于“按需内容”，不应作为默认阅读链的一部分

## 2. 推荐目录模型

使用抽象变量表达：

- hub 根目录：`$AGENTS_HUB_ROOT`
- 共享技能：`$AGENTS_HUB_ROOT/skills/share/<skill>`
- 项目技能：`$AGENTS_HUB_ROOT/skills/projects/<project-key>/<skill>`
- 项目挂载入口：`<repo>/.agents/skills/<skill>`、`<repo>/.cursor/skills/<skill>`、`<repo>/.claude/skills/<skill>`
- 用户挂载入口：`~/.codex/skills/<skill>`、`~/.cursor/skills/<skill>`、`~/.claude/skills/<skill>`

## 3. 平台差异怎么处理

### Windows

- 常见方式：Junction / PowerShell 脚本
- 常见脚本：`*.ps1`

### macOS / Linux

- 常见方式：symlink / shell 脚本
- 常见脚本：`*.sh`

规则：

- 主技能正文不要写死某个平台的绝对路径
- 只有在“创建 / 迁移 / 装配 skill”时，才按当前环境去读具体脚本

## 4. 什么时候读这篇文档

- **create / extract 路由**：需要理解 **真实源与挂载入口分离**、或要把 skill **挂到**用户级 / 项目级入口时，必读 **本文档 §1–§4**。脚手架、入口脚本与「工程收尾」顺序的 **单一真源** 是 [engineering_completion_gate.md](engineering_completion_gate.md)：**§1–§5** 全链路（其中 **§4–§5** 为挂载与真实触发自检）；装配与 client 验证须在该文档 **§1–§3**（入口、references 拓扑、主文件规模）满足后再执行 **§4–§5**。
- 迁移 skill 真实源路径、解释 hub 与挂载关系、排查链接断裂 / 客户端找不到 skill 时，读本篇并结合 `agent-hub-bootstrap`。

**纯 review / refine-trigger** 且不涉及新建目录、不改挂载时，可不读本文，但仍须满足父技能 `SKILL.md` 中的工程完成门（仅看 [engineering_completion_gate.md](engineering_completion_gate.md)：**review/refine-trigger** 适用步骤，通常含 **§1、§3**；若本次改了某 skill 的 `references/` 则对该 skill 做 **§2**；必要时 **§5**）。