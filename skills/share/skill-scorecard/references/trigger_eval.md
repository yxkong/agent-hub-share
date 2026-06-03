# trigger / eval 样例

## should-trigger

- 「帮我给这个 skill 打个分」
- 「这组 vendor 技能哪些真的能用」
- 「这个 prompt 资产值得沉淀吗，给个评分」
- 「为什么这个 skill 看起来很全但总是不生效」
- 「检查一下这个 skill 有没有闭环、路径有没有漂移」
- 「给这个 skill 出质量分、兑现分和结论」
- 「这些技能包哪些可以挂载，哪些只能参考」

## should-not-trigger

- 「直接帮我修这个 skill」→ `skill-engineering`
- 「把这个 prompt 生成出来」→ `prompt-engineering`
- 「把共享技能同步到用户目录」→ `agent-hub-bootstrap`
- 「帮我实现这个需求」→ `delivery-workflow`
