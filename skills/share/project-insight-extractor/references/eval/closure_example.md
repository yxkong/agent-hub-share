# project-insight-extractor — 真实闭环样例

## 场景

本轮优化 share skill 体系时，需要把一次“先表层优化、后被用户指出底层逻辑未收、再转向深审”的过程沉淀为给人读的经验，而不是再写成 skill / prompt 正文。

## executed

本轮先确认 vault 写入条件：

```text
INSIGHT_VAULT_ROOT=
```

说明当前环境下默认不能直接写外部 vault。

## observed

因此本技能在本轮的正确行为应该是：

- 可以从当前会话提炼洞察
- 但由于 vault 路径不可解析，应输出 `draft-only`
- 不把“未归档草案”伪装成已经写入 Vault

## draft-only 结论

- `source_anchor`：当前会话关于“不要只修表面，要修逻辑底层”的连续反馈
- `asset_type`：`methodology_case`
- `write_action`：`draft-only`
- `reason`：`INSIGHT_VAULT_ROOT` 未配置，且未额外指定可写 Vault 路径

## 结论

本样例证明本技能的闭环不是“强行落盘”，而是在不可写时明确退回 `draft-only`，仍保持证据链和产物边界正确。
