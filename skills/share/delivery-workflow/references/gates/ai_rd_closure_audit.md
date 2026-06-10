# AI 研发体系审计与验证（rd-audit）

> 用户用关键词触发的体系级审计入口，定位类似 Gate 5 复盘：有固定读序、固定证据口径、固定输出，不靠临时总结。

## 触发关键词

命中以下任一表达，走 `delivery-workflow/rd-audit`：

- 研发体系审计、AI 研发体系审计、体系审计
- 研发闭环验证、证据闭环、最终复核、闭环复核
- release evidence、发布证据、上线证据
- Task Replay、任务回放、复盘证据、Replay 质量
- Skill Health、技能健康、技能健康信号、trigger 误判
- 文档治理脚本化、脚本反复报错、校验脚本闭环

## 读序

1. 先读本文件，确认目标与边界。
2. 读 `prompts/share/agent-task/prompt-share-agent-task-ai-rd-closure-audit.prompt.md`。
3. 若涉及治理门禁细节，再读 `ai-development-governance` 对应 gate；本路由负责审计执行编排，不复制治理总纲。
4. 若需要落盘修改 docs / scripts / skill / prompt，先走 `doc-script-governance` 的 `backup-file`。

## 审计范围

| 审计项 | 必查问题 | 证据 |
|---|---|---|
| 入口与真源 | delivery / governance / skill / docs / scripts 是否有唯一入口 | 入口文件路径、索引、trigger |
| 主链证据 | 是否区分 static / contract / runtime / user-visible / release / limitation | 主链证据矩阵、验证命令 |
| Release Evidence | 是否有观察窗口、观察入口、回滚触发条件 | release / rollback / observability gate |
| Task Replay Lite | 失败或返工是否记录触发输入、缺失证据、误判 gate、回填位置 | replay / closeout / G8 |
| Skill Health Signal | 重复返工或 trigger 误判是否回填到 bad smell / trigger eval / scorecard | skill references、scorecard |
| 脚本化治理 | 入口、结构、大小、私有耦合、编码、备份策略是否可执行验证 | 脚本输出，不接受口头通过 |

## 输出格式

```markdown
## 审计结论
- fact:
- assumption:
- unknown:
- risk:

## P0/P1/P2 计划

## 不新增 / 二阶段资产裁决

## 验证命令与通过判据

## 最终闭环复核
```

## 阻断规则

- 未读取目标文件或脚本输出，不得写 `fact`。
- 未运行脚本，只能写 `NOT_RUN` / `unknown`，不得写通过。
- 只有静态证据时，不得宣称体系闭环完成。
- 不默认新增 `release-ops-runbook` 或 `skill health dashboard`；先判断现有 Gate 是否能承载。
- 若发现术语漂移，必须给出统一术语和替换位置。

## 与复盘的关系

- `delivery_replay.md`：记录一次交付会话的事实包。
- 本文件：审计一套研发体系是否能让交付、验证、发布、复盘、回填闭环。
- 审计过程中发现具体失败/返工样本时，可引用 replay；不要把审计报告伪装成 replay。
