# Trigger Eval

## Should Trigger

- “用 SkillOpt 优化这个 skill”
- “拿真实任务复盘后改一下这个 SKILL.md”
- “这个 skill 老是触发后没用，做 rollout 验证并优化”
- “改完 skill 后用另一个案例验证别过拟合”
- “把这次返工沉淀成 skill 规则，但别写成大作文”

## Should Not Trigger

- “给这个 skill 打分” → `skill-scorecard`
- “新建一个 skill” → `skill-engineering/create`，且先过 `skill-discovery`
- “同步 / 挂载 skill” → `agent-hub-bootstrap`
- “写一个 prompt 模板” → `prompt-engineering`
- “实现这个接口” → `delivery-workflow`

## Regression Checks

- 能区分“评分”和“优化”
- 能区分“创建新 skill”和“改进现有 skill”
- 能要求 baseline + held-out，而不是只做静态审查
