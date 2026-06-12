# 行为审计

## 偏航信号

- 没有 Spec / Task Contract 就把跨端或高风险需求推进到实现。
- 评分、门禁或成熟度结论没有对应证据矩阵。
- 把 Security / Release / Rollback 吞进普通实现总结。
- 为了赶进度跳过反方问题或人工确认点。

## 反证问题

- 哪个门禁若被省略，最可能导致返工、回滚或安全风险？
- 当前结论能否被 fresh reviewer 用同一证据复核？
- Fast Path 豁免是否真的满足低风险、低返工成本？
- 如果上线失败，回滚证据现在是否足够？

## 闭环证据

- 治理结论必须落到 Spec / ADR / Task Contract / Security / Release / Quality / Learning 的明确一类。
- G5 Quality Gate 至少引用主链证据矩阵或明确 limitation。
- Release 相关结论必须同时有发布、观察和回滚证据。

## 回灌动作

- 治理门禁被绕过导致返工，进入 bad smell 计数。
- 体系级判断沉淀到 scorecard、checklist 或 ADR 模板。
- 真实闭环案例进入 replay，再由 insight 或 prompt 按需提炼。
