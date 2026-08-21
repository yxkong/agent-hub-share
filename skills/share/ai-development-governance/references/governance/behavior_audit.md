# 行为审计

## 偏航信号

- 没有 Spec / Task Contract 就把跨端或高风险需求推进到实现。
- 评分、门禁或成熟度结论没有对应证据矩阵。
- 把 Security / Release / Rollback 吞进普通实现总结。
- 为了赶进度跳过反方问题或人工确认点。
- 把只读询问、Review PASS 或 R1 当作实施授权。
- 用户已经明确要求实现，却继续为设计 Hash、依赖文件或验证步骤逐次索要确认。

## 反证问题

- 哪个门禁若被省略，最可能导致返工、回滚或安全风险？
- 当前结论能否被 fresh reviewer 用同一证据复核？
- Fast Path 是否仍完成必要的轻量设计与验证，而没有把内部过程转成用户确认循环？
- 当前状态能否证明本会话有明确实施请求、稳定目标与授权根？
- 当前动作是否触及目标切换、生产/外部写入、权限密钥、安全升级、删除/不可逆或发布推送？
- 如果上线失败，回滚证据现在是否足够？

## 闭环证据

- 治理结论必须落到 Spec / ADR / Task Contract / Security / Release / Quality / Learning 的明确一类。
- G5 Quality Gate 至少引用主链证据矩阵或明确 limitation。
- Release 相关结论必须同时有发布、观察和回滚证据。
- G4 写入必须有可复核授权状态；Hook 未安装或未信任时只能标 advisory / blocked。

## 回灌动作

- 治理门禁被绕过导致返工，进入 bad smell 计数。
- 体系级判断沉淀到 scorecard、checklist 或 ADR 模板。
- 真实闭环案例进入 replay，再由 insight 或 prompt 按需提炼。
