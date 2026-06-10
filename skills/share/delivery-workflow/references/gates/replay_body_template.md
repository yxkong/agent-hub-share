# Replay 质量协议与正文模板（Gate 5 唯一契约）

> **真源**：本文件。  
> **执行**：Gate 5 读 `delivery_replay.md` → 读本文件 → 读 `prompt-share-agent-task-delivery-closeout-summary` → 落盘。  
> **禁止**：把 `docs/resource/replay/*.md` 当模板；历史 replay 只能作为事实来源或反例。

Replay 的目标不是“总结聊天”，而是让下一个 Agent 能回答：

1. 这个任务原本要解决什么，后来有没有被用户纠偏？
2. 哪些交付物真的落盘了，当前终态是什么？
3. 哪些结论有证据，哪些只是未验证的边界？
4. 哪个 gate / skill / prompt 该被回填，避免下次重复返工？

## 写作前分析账本

落盘前必须先在草稿中完成 6 个账本；正文可合并呈现，但不得跳过。

| 账本 | 必填问题 | 失败信号 |
|------|----------|----------|
| Intent Ledger | 初始目标、验收口径、中途纠偏是什么？ | 只写最后一句需求 |
| Artifact Ledger | 改了哪些文件/脚本/文档/prompt？状态是新增、更新、废弃还是未做？ | 只有“做了优化”无路径 |
| Decision Ledger | 做过哪些关键取舍？为什么不做另一个方案？用户否定过什么？ | 没有“为什么” |
| Evidence Ledger | 每条完成声明对应什么证据等级、命令、输出或 `NOT_RUN`？ | 静态检查包装成完成 |
| Gap Ledger | 哪些主链、发布、回显、观察、数据证据缺失？ | 风险只写“后续完善” |
| Learning Ledger | 误判 gate / skill 缺口 / prompt 缺口是什么？回填到哪里？ | Task Replay Lite 写空话 |

## 正文模板

新 replay 必须声明 `replay_contract: gate5-v2`，并保留下列二级标题。

```markdown
---
task_id: <YYYY-MM-DD-<短主题>>
replay_contract: gate5-v2
replay_scope: session | task
coverage_status: full | partial | unknown
project: <project-key>
path: Fast | Full
outcome: DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT
source_anchor: <transcript / run-id / 时间>
created: "<yyyy-mm-dd>"
updated: "<yyyy-mm-dd>"
related:
  - path: <tracks|contract|implements 产物相对 hub 或项目根>
    role: tracks | contract | implements | supersedes
tags: []
---

# 任务 closeout：<一句话总主题>

## 落盘位置核验

- hub_root：
- target_path：
- index_path：
- path_guard：pass | blocked
- 说明：（若 hub_root 不可定位，必须 `outcome: BLOCKED`，不得写业务工程 `docs/resource/`）

## 覆盖范围核验

- replay_scope：
- coverage_status：
- source_anchor 可访问性：（可访问 / 不可访问 / 仅摘要）
- 覆盖起点：
- 覆盖终点：
- 已排除片段：
- 范围结论：（为什么是 full / partial / unknown）

## 任务边界

- 初始目标：
- 中途纠偏：
- 本轮验收口径：
- 明确不做：

## 交付轨迹

| 阶段 | 用户意图/触发 | 关键动作 | 产物路径 | 结果 |
|---|---|---|---|---|
| 1 | | | | |

## 关键决策与纠偏

| 决策/纠偏 | 原因 | 影响 | 证据 |
|---|---|---|---|
| | | | |

## 产物与终态

| 产物 | 类型 | 当前状态 | 终态 fact |
|---|---|---|---|
| | skill / prompt / docs / script / code | added / updated / deprecated / NOT_RUN | |

## 证据与验证

| 完成声明 | 证据等级 | 实际证据 | 结论 |
|---|---|---|---|
| | static / contract / runtime / user-visible / release / limitation | | pass / NOT_RUN |

## 缺口 / 未做 / 风险

| 缺口 | 类型 | 为什么没做 | 后续触发条件 |
|---|---|---|---|
| | unknown / risk / limitation / out-of-scope | | |

## Task Replay Lite

| 字段 | 内容 |
|---|---|
| 触发输入 | |
| 缺失证据 | |
| 误判 gate | |
| 建议回填 | |

## Release Evidence

- 观察窗口：
- 观察入口：
- 回滚触发条件：
- 结论：（未部署写 `release: NOT_RUN`）

## 后续接续清单

- [ ] <下一步动作>：触发条件 / 验收证据
```

## 质量门

- `replay_scope: session` 必须满足 `coverage_status: full`，且 `覆盖范围核验` 说明起点、终点、排除片段；否则必须降级为 `replay_scope: task` 或 `coverage_status: partial|unknown`。
- `落盘位置核验.path_guard` 必须为 `pass`；`target_path` 必须位于 `$AGENTS_HUB_ROOT/docs/resource/replay/`，`index_path` 必须为 `$AGENTS_HUB_ROOT/docs/resource/INDEX.md`。
- hub root 不可定位时禁止落盘，`outcome` 必须为 `BLOCKED` 或 `NEEDS_CONTEXT`；不得回退写业务工程 `docs/resource/`。
- 若 source transcript / run-id 不可访问，禁止声明 `coverage_status: full`；`outcome` 最高 `DONE_WITH_CONCERNS`，必要时 `NEEDS_CONTEXT`。
- 标题或 source_anchor 若只写 R13-R18、后半段、最后几轮、某批次等局部范围，不能同时声明 `replay_scope: session` + `coverage_status: full`。
- `交付轨迹` 每一行必须至少有一个路径、命令、验证输出或 `NOT_RUN`。
- `证据与验证` 不得只写“已验证”；必须写命令、脚本输出、文件路径、响应样例或 limitation。
- `关键决策与纠偏` 必须记录用户否定过的方向、范围收缩或设计取舍；没有则写“无明确纠偏”。
- `Task Replay Lite.建议回填` 必须指向具体 skill / prompt / docs / script；不能写“下次注意”。
- `outcome` 规则：
  - 无落盘或缺 transcript 关键事实：`NEEDS_CONTEXT`
  - 只有 static / contract 证据：最高 `DONE_WITH_CONCERNS`
  - Full Path 缺 runtime/user-visible/release 主链：不得写 `DONE`
  - 阻塞型验证未完成：`BLOCKED` 或 `DONE_WITH_CONCERNS`

## Fast Path 裁剪

Fast Path trivial 且无文件改动时可不落盘；若仍落盘，可保留同一结构但允许：

- `关键决策与纠偏` 写“无明确纠偏”
- `Release Evidence` 写 `release: NOT_RUN`
- `证据与验证` 至少 1 行

Full Path 不允许裁剪任何二级标题。
