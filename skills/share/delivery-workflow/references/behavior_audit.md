# 行为审计

## 偏航信号

- 只跑 build / lint 就宣称完成，没有主链路证据。
- 接口返回 200 但不看响应体、落库、回显或页面状态。
- 需求还没收敛就开始扩范围，或把 Full Path 伪装成 Fast Path。
- 把“实现/落地/直接写”、Review PASS 或 R1 当成写入许可证。
- 子 Agent 被用于探索、方案权衡或逃避主模型责任。

## 反证问题

- 如果这是一次假通过，最可能假在哪里：契约、运行时、用户可见还是 release？
- 有没有写入、读取、响应出口三联检可以互相印证？
- 本次最小闭环外还有哪些改动被顺手带入？
- 失败后应回到 insight、bad smell 还是 prompt？
- 当前 task/hash、确认 turn 与每个写入文件是否可一一核对？

## CLAIM 对抗审查（可选重型流程）

仅对不可逆、高成本、跨模块或强不确定判断启用；普通 Fast Path 不使用。

1. **CLAIM**：主模型用 2-3 行写下判断声明和为什么重要。
2. **EXTRACT**：抽出 artifact + contract，去掉主模型推理过程和结论诱导。
3. **DOUBT**：交给全新上下文审查者，只要求找反例、隐藏假设、契约违反和失败模式。
4. **RECONCILE**：按优先级处理：契约误读 > 可行动问题 > 取舍讨论 > 噪声。
5. **STOP**：最多 3 轮；连续无 actionable 输出，停止对抗，避免假质疑。

审查者不接收 CLAIM 本身，避免被作者结论污染。

## 闭环证据

- 主链至少覆盖 `static`、`contract`、`runtime`、`user-visible` 中的适用项。
- Full Path 必须显式列 `release` 与 `limitation`。
- 缺数据问题必须补三联检，不能只贴 HTTP 状态或截图。

## 回灌动作

- 同类偏航重复出现 2 次，进入 `skill-engineering/references/governance/bad_smell_registry.md`。
- 交付闭环后的经验进入 `$AGENTS_HUB_ROOT/docs/resource/replay/`。
- 给人读的方法论进 `project-insight-extractor`；可复用执行档进 `prompt-engineering`。
