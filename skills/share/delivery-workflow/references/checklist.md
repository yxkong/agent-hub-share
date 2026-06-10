# 交付检查清单

## 第一阶段

- [ ] 已明确任务属于前端、后端或前后端联动
- [ ] 已识别用户真正目标，而不是只拿到表面方案
- [ ] 已明确目标、边界、不改范围
- [ ] 已找到当前主文档与主代码入口
- [ ] 已明确验收结果与失败判定
- [ ] 已暴露影响下一步的 fact / assumption / unknown / risk
- [ ] 非 trivial 需求已先完成设计收敛

## 设计完成前

- [ ] 目标已清楚
- [ ] 边界已清楚
- [ ] 契约已清楚
- [ ] 风险已清楚
- [ ] 验证路径已清楚
- [ ] 已判断本次任务走 Fast Path 还是 Full Path
- [ ] 已先给最小有效方案；若提出重构 / 抽象 / 批量替换，已证明局部修改不足
- [ ] 若改变交互模式 / 行为模式 / 架构风格 / 运行语义，已列出原模式、新模式、风险、验证、回滚，并取得用户确认
- [ ] 已用反方视角指出最可能返工点

## 实现中

- [ ] 每个最小实现单元开始前，已执行 checkpoint 协议（`git status` → 视情况 commit / stash / 记录风险；详见 `SKILL.md` 的 `阶段门速记` / `Gate 3 实现推进`，以及 `ai_execution_protocol.md`）
- [ ] 按最小闭环切分，不做无边界并行开发
- [ ] 前后端联动场景已先确认接口契约
- [ ] 排障任务保持原运行语义；未把异步链路、事件驱动、DDD 分层、事务/状态机语义顺手改掉
- [ ] 主链路优先于异常链路和边界链路
- [ ] 文档、SQL、配置说明都落到 `docs/` 正确目录
- [ ] 没有把脚本或文档写进模块目录或 `src/main/resources`

## 验证前

- [ ] 主链路已完成
- [ ] Full Path / 跨模块任务已填写主链证据矩阵：static / contract / runtime / user-visible / release / limitation
- [ ] 关键失败链路和边界链路已考虑
- [ ] 只做了当前需求范围内的最小必要改动
- [ ] 若存在「接口成功但缺字段 / 保存后回显空」：已按 `missing_data_debug_triad.md` 检查 **写入 → 读取 → HTTP 响应出口** 三层，而非只改单点代码

## 排查中（任务是 bug fix / 数据异常 / 功能不符合预期时）

- [ ] 已用一句话精确描述症状（含报错信息 / HTTP 状态码 / 具体现象）
- [ ] 已列出 1-3 个有序假设，未开始代码阅读
- [ ] 调查起点选择了"距症状最近的位置"，而非从模块顶层扫起
- [ ] 每次打开新文件，能说出具体证据链（"日志在 X 报错 → 指向 Y 文件的 Z 方法"）
- [ ] 未在排查阶段修改任何非直接相关的代码
- [ ] 修复范围已明确（具体文件 + 方法 + 行数），不超出根因直接影响链
- [ ] 修复后验证：原症状消失 + 相邻功能正常（不做全量回归）
- [ ] 若仍有 unknown，已说明最小验证动作或可信边界

## 结束后

- [ ] 已完成最小可验证检查
- [ ] Gate 5：已读 `replay_body_template.md`（6 个账本 + `gate5-v2` 契约）+ closeout prompt，Path Guard 通过，落盘 `$AGENTS_HUB_ROOT/docs/resource/replay/`、`check-replay-structure.ps1=ok`、更新 `$AGENTS_HUB_ROOT/docs/resource/INDEX.md`（见 `gates/delivery_replay.md`）
- [ ] 交付总结没有把 `static only`、`contract only`、`DDL only` 或未运行验证的能力表述为完整实现
- [ ] 已说明主链路之外最容易漏测的边界 / 失败 / 回归用例
- [ ] 如有失败或返工，Gate 6 已定位根因属于需求、设计、契约、切分还是验证问题
- [ ] 如有 R3 候选，已按 `gates/r3_handoff_contract.md` 输出 handoff packet（含 `source_replay`、`candidate_route`、`target_skill`、`stop_condition`）
- [ ] 可复用经验只做 R3 路由交接；是否写 insight / prompt / bad smell 由目标技能自己的准入规则决定
