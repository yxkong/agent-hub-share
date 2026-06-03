# skill-engineering — 行为证据样例

## 场景

时间：2026-05-29  
任务：把 share 技能从“结构表层优化”推进到“全 active 文件深审 + 真正可当模具”。

## baseline（observed）

来自本会话前序用户明确反馈：

- 之前的优化只处理了入口、README、闭环门
- 其他共享技能也只是跟着补外层结构
- 还没把三标杆技能做成深层质量模具，就提前修改了 `docs/<content-domain>`

这说明基线行为仍偏向：

- 先改看得见的外壳
- 后补底层逻辑
- 没有先走全包 review

## retest（observed）

本轮实际行为改成：

1. 先冻结 `docs/<content-domain>`
2. 先深审三标杆技能的 `SKILL.md + README.md + references/** + templates/**`
3. 修 `delivery-workflow` 子 Agent 判定错位、`skill-scorecard` 校准流程、`skill-engineering` review 首读路径
4. 再批量处理其它 share skill 的 active 资产漂移

行为变化点：

- 从“局部修补”切到“先全量清单，再系统修复”
- `review` 首读统一为 `quick_gate.md`
- trigger/eval 资产开始标准化，不再允许主文件和索引各说一套

## executed

本轮与 skill 工程直接相关的工程门结果：

```text
SKILL_ENTRYPOINTS=ok
SKILL_REFERENCES_STRUCTURE=ok
SHARE_SKILL_PRIVATE_COUPLING=ok
```

并完成以下结构收口动作：

- `delivery-workflow`：`trigger_eval_examples.md` 统一为 `trigger_eval.md`
- 6 个此前只在主文件内联 trigger/eval 的 share skill，已补独立 trigger/eval 资产
- `router_handbook_gate.md` 已从写死 `references/eval/trigger_eval.md` 改成“必须有独立 trigger/eval 资产”

## 真实合理化借口

本会话已出现过的基线借口可概括为：

- “先把入口和 README 整齐一下，后面再补底层”
- “文章可以先改，底层回头再补”

本轮修复后的处理方式是：

- 不先动文章
- 先过全 active 文件审计
- 再允许对外口径同步

## 结论

本样例证明 `skill-engineering` 已能把行为从“局部整理”改成“按全包 review 和工程门执行”，满足 `behavioral_eval.md` 的最小要求：有基线、有复测、有真实借口、有最小补洞结论。
