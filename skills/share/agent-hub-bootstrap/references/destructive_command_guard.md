# Destructive Command Guard — Cross-Platform Hook

## 目的

在 AI Agent 运行时（Cursor / Claude Code / Codex / Gemini CLI）**工具层**拦截破坏性 git 与文件删除命令，不依赖 Agent 自觉。

## 拦截范围

| 命令模式 | 拦截 | 说明 |
|---|---|---|
| `git restore ...` | ✅ | 覆盖工作区 / 暂存区 |
| `git reset ...` | ✅ | 覆盖 HEAD / 暂存区 / 工作区 |
| `git clean ...` | ✅ | 删除未跟踪文件 |
| `git stash ...`（所有子命令） | ✅ | 隐藏 / 丢弃工作区状态 |
| `git checkout -- <path>` | ✅ | 丢弃工作区改动（不影响 `git checkout <branch>`） |
| `Remove-Item / del / rm / rmdir / rd / unlink`（**所有删除**，不限递归/强制） | ✅ | 文件删除 |
| `git status / log / diff / add / commit` | ❌ 放行 | 只读或安全 |
| `pytest / node / npm / pip` | ❌ 放行 | 非破坏性 |

## 各平台对照

| 平台 | Hook 事件 | 配置文件 | 拦截输出 | exit code |
|---|---|---|---|---|
| **Cursor** | `beforeShellExecution` | `.cursor/hooks.json` | `{"permission":"deny"}` | 2 |
| **Claude Code** | `PreToolUse` (matcher: `Bash`) | `.claude/settings.json` | `{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny"}}` | 2 |
| **Codex CLI** | `PreToolUse` (matcher: `^Bash$`) | `.codex/hooks.json` | `{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny"}}` | 2 |
| **Gemini CLI** | `BeforeTool` (matcher: `run_shell_command`) | `.gemini/settings.json` | `{"decision":"block","reason":"..."}` | 2 |

### 关键差异

- **Cursor**：`failClosed: true` 时脚本崩溃也拦截；放行也必须输出 `{"permission":"allow"}`。
- **Claude Code**：`PreToolUse` 在所有权限模式下生效（含 `bypassPermissions`）；脚本 stdin 收到 JSON，含 `tool_name` 和 `tool_input.command`。
- **Codex**：项目配置使用顶层 `hooks` 包装；非受管 Hook 需宿主信任。当前 `PreToolUse` 可覆盖本地函数工具，托管工具不在保证范围内。
- **Gemini CLI**：hooks 默认开启（v0.26.0+）；项目级 hook 首次运行需信任；matcher 匹配工具名（`run_shell_command`）。

## 脚本真源

核心拦截逻辑在 `scripts/guard-destructive-command.py`（Python，跨平台）；各平台仅注册配置片段，不重复实现逻辑。

| 文件 | 作用 |
|---|---|
| `scripts/guard-destructive-command.py` | 核心拦截脚本，读 stdin JSON → 匹配 → 输出 deny/allow |
| `scripts/install-guard.ps1` | 一键安装到当前项目的 Cursor / Claude Code / Codex / Gemini CLI |
| `scripts/install-guard.sh` | macOS/Linux 一键安装 |

## 安装

```powershell
# Windows — 在项目根目录执行
pwsh -NoProfile -File "$AGENTS_HUB_ROOT/skills/share/agent-hub-bootstrap/scripts/install-guard.ps1"
```

```bash
# macOS/Linux — 在项目根目录执行
bash "$AGENTS_HUB_ROOT/skills/share/agent-hub-bootstrap/scripts/install-guard.sh"
```

安装脚本会：
1. 把 `guard-destructive-command.py` 复制到项目的 `.cursor/hooks/`（或对应平台目录）
2. 在各平台配置文件中注册 hook（已存在则跳过）
3. 输出安装结果

## 验证

安装后可用以下命令测试（不会真正执行破坏性命令）：

```powershell
'{"command":"git stash"}' | python .cursor/hooks/guard-destructive-command.py
# 应输出 deny 并 exit 2

'{"command":"git status"}' | python .cursor/hooks/guard-destructive-command.py
# 应输出 allow 并 exit 0
```

## 安全设计

- **fail-closed**：脚本崩溃 / 超时 / JSON 解析失败时，Cursor 配置 `failClosed: true` 会拦截。
- **不拦截只读命令**：`git status / log / diff / add / commit / show / branch` 等正常放行。
- **不夸大**：各宿主能力以当前实际 Hook 验证为准；未安装、未信任或不支持时必须明确报告限制。
- **可审计**：每次拦截在 stderr 输出日志，含命令原文和拦截原因。
