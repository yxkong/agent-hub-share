# delivery-workflow — 行为证据样例

## 场景

时间：2026-05-29  
任务：把共享技能提分到双 92+，要求不靠改分，而是靠真实交付闭环。

## baseline（observed）

本会话前序已明确暴露两个交付节奏问题：

1. `subagent_prompt_template.md` 一度承载“何时派发子 Agent”的判定逻辑，导致“只有派发后才读的模板，却负责派发前判定”
2. 在三标杆技能尚未深审完成前，已经提前修改 `docs/<content-domain>`

这代表基线行为更像：

- 交付顺序不够收敛
- 先动外围产物，再补主链路
- 子 Agent 边界不够自洽

## retest（observed）

本轮实际交付顺序改成：

1. 先冻结 `docs/<content-domain>`
2. 深审三标杆技能
3. 修 `delivery-workflow` 的派发判定与模板职责
4. 统一 share trigger/eval 资产
5. 再回写 `docs/<content-domain>`

子 Agent 相关变化：

- 是否派发：只看 `SKILL.md` §AI 执行红线
- Prompt 怎么写：只看 `references/subagent_prompt_template.md`
- trigger/eval 资产命名统一为 `references/trigger_eval.md`

## executed

本轮已执行并通过的交付相关工程门：

```text
SKILL_ENTRYPOINTS=ok
SKILL_REFERENCES_STRUCTURE=ok
SHARE_SKILL_PRIVATE_COUPLING=ok
SKILL_SIZE_OK nonempty=101 max=150 file=skills/share/delivery-workflow/SKILL.md
```

## 结论

本样例证明 `delivery-workflow` 已把行为从“边修边扩、顺序漂移”收敛成“先主链路、后外围；先判定、后模板；先验证、后宣传”的交付节奏。
