# Implementation Authorization Gate

## 唯一语义

本文件是“是否允许持久化写入”的唯一语义真源。`delivery-workflow` 负责设计与执行节奏，`agent-hub-bootstrap` 只安装技术守卫。

- 用户明确提出“实现 / 修复 / 修改 / 落地”等实施请求，即完成一次**目标授权**；Agent 不得再为设计 Hash、实现细节、依赖补齐或同一 workspace 内新增文件要求重复确认。
- 目标授权只覆盖当前 session、当前 workspace；任务明确涉及已登记 Hub 资产时，可同时覆盖 `AGENTS_HUB_ROOT`。
- “分析 / Review / 解释 / 看是否已修复 / 不要修改”等只读请求不生成目标授权。
- 生产或外部系统写入、权限/密钥、安全边界升级、删除、不可逆操作与目标越界仍须单独确认。

## 状态机

```text
DISCOVERY
  -> GOAL_AUTHORIZED
  -> IMPLEMENTING
  -> VERIFIED

高风险动作 -> HIGH_RISK_AWAITING_CONFIRMATION
用户撤销 -> REVOKED
session 变化或状态损坏 -> DISCOVERY / BLOCKED
```

`GOAL_AUTHORIZED` 只保存执行所需的最小事实：

```text
task_id: 由授权消息摘要生成的稳定标识
goal: 用户的明确实施请求
scope_roots: 当前 workspace；按任务需要附加已登记 AGENTS_HUB_ROOT
authorization: turn_id + session_id + prompt_sha256
```

依赖闭包、Spec/SDD/ADR、Self Review 和验证矩阵仍是研发质量要求，但不进入授权状态，也不触发重复确认。发现 Mapper、XML、测试、文档或同范围调用方时，Agent 直接补齐并验证。

四高二低三底座属于设计真源，不复制进授权状态，不在此逐项 PASS/N/A。设计 Review 仍需确认架构决策可追溯且没有影响方向、安全或共享契约的未决 P0；这些属于质量门，不额外制造用户确认轮次。

## 一次目标授权

普通 workspace 实施任务不使用技术口令。`UserPromptSubmit` 识别明确实施意图后生成 `GOAL_AUTHORIZED`；同一目标内直接进入设计、实现、测试和收口。新增文件、验证命令或内部设计调整不需要再次询问。

只有以下边界需要停下：

- 用户改变业务目标，或要求进入未授权根目录；
- 生产、外部系统或对他人可见的写操作；
- 权限、密钥、租户、安全边界升级；
- 删除、清空、覆盖、发布、推送及其它难恢复操作。

撤销仍使用：

```text
撤销 <task_id>
```

目标授权绑定 Codex `session_id`。跨 session 恢复时回到 `DISCOVERY`，用户重新提出明确实施请求即可，不需要复述 Hash。

## 技术执行契约

Codex 项目根使用 `.codex/state/write-authorization/active.json` 保存短期机器状态；它不是治理真源，也不得提交为正式资产。`UserPromptSubmit` 识别明确实施、只读、高风险与撤销意图；`PreToolUse` 执行范围和风险检查：

- `apply_patch` 允许写入授权根目录内的新旧文件；不再维护逐文件白名单。
- `Delete File`、跨根目录补丁和高风险 Shell 命令继续拒绝，等待单独确认。
- 目标授权后允许执行普通构建、测试、校验和安装命令；源文件修改仍统一走 `apply_patch`。
- 未分类本地工具默认拒绝；托管工具不在 Codex Hook 保证范围内。
- Hook 未受信任、未安装、配置损坏或平台不支持时，只能报告 `ADVISORY/BLOCKED`，不得宣称硬闭环。
- `status/verify/revoke/adopt-goal` 是恢复控制面，在任意状态下都必须可执行；Guard 不得锁死自身。

CLI 入口由 `agent-hub-bootstrap/scripts/write-authorization-guard.py` 提供：

```text
python .codex/hooks/write-authorization-guard.py status
python .codex/hooks/write-authorization-guard.py verify --path <file>
python .codex/hooks/write-authorization-guard.py revoke --task-id <id>
```

旧版 `propose/confirm/adopt-goal` 只为已有许可证迁移保留，不再作为新任务默认流程。授权 Harness 不建设全局“契约链 Hash 状态机”；canonical 漂移由领域验证命令和 Review 负责，避免形成第二研发系统。

## Bootstrap 边界

旧版精确确认状态迁移到 `GOAL_AUTHORIZED` 时，必须保留原 task/hash 和确认消息摘要；迁移完成后立即回到一次目标授权语义。
