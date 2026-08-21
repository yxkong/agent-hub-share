# Codex Write Authorization Guard

## 边界

授权语义只读 `ai-development-governance/references/gates/implementation_authorization_gate.md`。本技能仅负责安装与技术验证，不维护第二份授权规则。

Hook 事件、信任、工具覆盖与结构化决策以 [Codex Hooks 官方文档](https://developers.openai.com/codex/hooks) 为当前事实源；代码模式的嵌套工具调用仍接受 `PreToolUse` 决策。

## 安装

在目标项目根执行：

```powershell
pwsh -NoProfile -File "$env:AGENTS_HUB_ROOT/skills/share/agent-hub-bootstrap/scripts/install-guard.ps1" -Platforms codex
```

安装器会复制两个脚本到 `.codex/hooks/`，并以幂等方式合并 `.codex/hooks.json`：

- `SessionStart`：注入当前授权状态。
- `UserPromptSubmit`：把明确实施请求转换为 `GOAL_AUTHORIZED`，区分只读、高风险与撤销消息。
- `PreToolUse`：检查目标授权根目录和高风险动作；同一目标不维护逐文件白名单。
- 既有 Hook 不删除；破坏性 Shell 守卫继续保留。
- `.codex/state/write-authorization/.gitignore`：保证运行态凭证不进入版本库。

## 验证

```powershell
python .codex/hooks/write-authorization-guard.py status
python -m unittest scripts.tests.test_write_authorization_guard
pwsh -NoProfile -File scripts/check-hooks.ps1 -HubRoot $env:AGENTS_HUB_ROOT -ProjectRoot (Get-Location)
```

验证必须同时覆盖：明确实施请求自动授权、只读问句不授权、高风险请求暂停旧授权、授权根目录内新增文件直接写、跨根目录拒绝、删除补丁拒绝、普通验证命令执行、危险 Shell 拒绝、带引号的查询正则不被误判为管道，以及 `status/verify/revoke/adopt-goal` 恢复控制面始终可执行。Windows 默认环境下的真实 Hook 子进程必须输出 UTF-8 JSON。脚本哈希或配置事件不一致均视为失败。

## 同一目标的执行语义

- 用户说“实现 / 修复 / 修改 / 落地”后，Agent 直接完成设计、依赖闭包、文件补齐、测试与验证。
- 新发现的 Mapper、XML、测试、文档或同 workspace 文件不再触发确认。
- 仅目标变化、跨授权根、生产/外部写入、权限/密钥升级、删除与不可逆动作再次确认。
- 旧 `propose + design_hash + allowed_paths` 只用于迁移历史状态，不再作为新任务入口。

## 自恢复不变量

- Guard 可以拒绝高风险写入，但不得拒绝自己的 `status/verify/revoke/adopt-goal` 控制命令；控制面失效属于 P0。
- 目标授权损坏、过期或跨 session 时，先执行 `status` 获取事实，再用 `revoke` 收口旧状态；不得通过删除 Hook 绕过风险门。
- 只读命令的安全字符检查只分析引号外的 Shell 语法。`rg -n "A|B"` 中的 `|` 是查询数据；`rg A | Select-String B` 中的 `|` 是真实管道，继续拒绝。
- 安装回归必须从项目侧实际执行控制命令和至少一次 Hook 事件，不得只验证源脚本单元测试。

## 信任与能力声明

非受管项目 Hook 首次使用需要 Codex 宿主信任。静态配置和离线测试通过只代表 `INSTALLED_UNTRUSTED`；完成宿主信任并在真实工具调用中观察到拒绝后才能声明 `ENFORCED`。当前硬闭环范围只承诺 Codex 本地写工具，其他平台和托管工具标为 `ADVISORY`。
