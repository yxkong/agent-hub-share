# R3 Handoff Contract（Gate 6）

> **定位**：Gate 6 只做失败/返工后的**路由与交接**。  
> **不做**：不复制 `project-insight-extractor` / `prompt-engineering` / `skill-engineering` 的准入规则，不直接替目标技能写资产正文。

## 输入前提

仅在以下条件成立时执行：

1. Gate 5 已生成 replay（优先 `replay_contract: gate5-v2`）。
2. 本轮存在失败、返工、回滚、用户纠偏，或 replay 的 `Task Replay Lite` 指向可回填缺口。
3. 交接材料来自 replay，不从原始会话重新自由发挥。

若没有失败/返工/复用信号，Gate 6 输出 `candidate_route: none`，停在 replay。

## 交接包

Gate 6 只输出这一份 handoff packet；目标技能收到后按自己的 SOP 决定是否写资产。

```yaml
source_replay: <$AGENTS_HUB_ROOT/docs/resource/replay/<task_id>.md>
candidate_route: insight | prompt | skill_feedback | governance_feedback | none
handoff_reason:
  - <为什么需要进入该路线；引用 replay 中的事实>
fields_to_pass:
  - 任务边界
  - 关键决策与纠偏
  - 产物与终态
  - 证据与验证
  - 缺口 / 未做 / 风险
  - Task Replay Lite
target_skill: project-insight-extractor | prompt-engineering | skill-engineering | ai-development-governance | none
target_entry:
  project-insight-extractor: references/source_material_qualification.md + references/value_lens.md
  prompt-engineering: references/extraction_and_eval.md
  skill-engineering: references/governance/bad_smell_registry.md
  ai-development-governance: references/governance_checklist.md | references/scorecard.md
stop_condition: <什么时候不资产化 / 不继续>
```

## 路由边界

| candidate_route | Gate 6 只判断 | 后续资格判定真源 |
|---|---|---|
| `insight` | replay 中可能存在给人读的经验、案例、方法论 | `project-insight-extractor` 的 `source_material_qualification.md`、`value_lens.md`、`asset_types.md` |
| `prompt` | replay 中可能存在可执行长指令、子 Agent prompt、稳定诊断模板 | `prompt-engineering` 的 `extraction_and_eval.md`、`file_contract.md` |
| `skill_feedback` | replay 中可能存在 trigger 误判、SOP 空泛、反模式、重复返工 | `skill-engineering` 的 `bad_smell_registry.md` 与 review/eval 规则 |
| `governance_feedback` | replay 暴露阶段门、scorecard、release/security/quality 口径缺口 | `ai-development-governance` 的 `governance_checklist.md` / `scorecard.md` |
| `none` | 只有一次性事实、无复用价值、无返工信号 | 停在 replay |

**优先级**：

1. 若是可执行 prompt 缺口，先 `prompt`，因为它会改变后续 Agent 执行输入。
2. 若是 skill 触发 / SOP / 反模式缺口，走 `skill_feedback`，不要写成 insight。
3. 若是治理门口径缺口，走 `governance_feedback`。
4. 只有当材料有对人表达价值时，才走 `insight`。
5. 多路线并存时，可以输出多个 handoff packet，但每个 packet 只指向一个目标技能。

## 拒绝资产化

以下情况必须 `candidate_route: none`：

- 只是一次性修复细节，replay 已足够承载。
- 没有可核对证据，只有主观感受。
- 只是遵守已有规则后完成任务，没有新模式、新缺口或新复用指令。
- 用户明确要求“不要落盘 / 仅预览”。

## 闭环门

- Gate 6 不直接写 TechInsightVault 或 `*.prompt.md`，除非随后显式进入对应目标技能并执行其 SOP。
- Handoff packet 必须引用 `source_replay`，不得只写“当前会话”。
- `stop_condition` 为空时，交接未完成。
