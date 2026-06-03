# prompt-engineering — 真实闭环样例

## 场景

目标：证明 prompt 资产不是只写正文，还要过校验和索引生成。

## executed

本轮已实际执行：

```text
PROMPTS_CHECK=ok
PROMPT_INDEX=ok items=8 file=<hub-root>/prompts/indexes/prompts.index.json
```

## observed

这个结果说明：

- `check-prompts` 能通过 front matter / 正文契约校验
- `build-prompt-index` 能刷新机器索引
- prompt 资产已经具备“落盘 -> 校验 -> 索引”的最小闭环

## 结论

本样例证明本技能的兑现不止在 prompt 结构，还在于收尾必须过 `check-prompts` 与 `build-prompt-index`。
