# Cursor 环境下的会话材料访问

跨工具会话历史入口见 `session_history_sources.md`。本文只保留 Cursor 细节。

## 两种场景

### 场景 A：从当前会话提炼

用户说"从这次会话提炼"或未指定范围时，默认走此场景。

- Agent 本身处于会话上下文内，直接基于可见的对话历史和工具调用输出进行提炼。
- **不需要读任何文件**，直接进入 SOP 第 2 步扫描当前上下文即可。
- 上下文窗口之外的历史轮次不可见；如需覆盖更长历史，改用场景 B。

### 场景 B：从历史会话 / 外部材料提炼

用户说"从上次的会话""从某次开发记录""从这段日志"时，走此场景。

#### 1. Cursor agent-transcript 文件

Cursor 会把历史会话保存为 `.jsonl` 文件，路径格式：

```
~/.cursor/projects/<workspace-id>/agent-transcripts/<uuid>.jsonl
```

当系统注入当前对话元数据时，`<agent_transcripts>` 块会包含可引用的 transcript uuid。
可通过以下方式确定 `workspace-id`：

```bash
ls ~/.cursor/projects/
```

#### 2. 读取 transcript 文件的 SOP

1. 请用户提供 transcript uuid（或说"帮我找最近一条"，AI 列出 `agent-transcripts/` 目录后由用户确认）。
2. 读取该 `.jsonl` 文件，每行是一条消息 JSON，按 `role` 字段区分 `user` / `assistant` / `tool`。
3. 提取有效文本：
   - `user` 消息：需求、反馈、纠正、验收结论
   - `assistant` 消息：方案、分析、代码、归因
   - `tool` 消息（result）：命令输出、测试结果、日志——重要的验证证据
4. 忽略纯 UI 操作或无实质内容的轮次。
5. 进入 `session_extraction.md` 的两遍抽取流程。

#### 3. 其他外部材料

用户直接粘贴日志、diff、文档内容时，以粘贴内容为输入材料，不需要读文件。

用户提供文件路径时，先用 Read 工具读取，再进入提炼流程。

## 隐私与脱敏

- 读取 transcript 前确认用户已同意
- 输出中不暴露：内网地址、客户名、密钥、私有仓库路径、个人信息
- 如果材料中出现上述内容，提取时自动替换为占位符并标注 `[已脱敏]`
