# 行为审计

## 偏航信号

- `SKILL.md` 持续膨胀，主文件开始承载细节而不是路由。
- README、INDEX 或 references 被当成 Agent 入口。
- 新建 skill 没有 trigger eval，也没有真实任务验证样本。
- 目录治理绕过 backup-file、size、entrypoint 或 structure 校验。

## 反证问题

- 这个 skill 是否真的让 Agent 更快找到入口、少误改、少返工？
- 主文件能否 30 秒内完成路由，不需要通读 references？
- 若去掉该 skill，最小真实任务会差在哪里？
- 本次新增规则是否已有两次坏味道证据支撑？

## 闭环证据

- `SKILL.md` 入口、description、trigger eval、references 拓扑和 size 校验都有证据。
- 高风险纪律类 skill 必须有无 skill 基线和带 skill 复测，或标 `unknown`。
- 工程完成门按 `engineering_completion_gate.md` 的适用步骤收口。

## 回灌动作

- 同类坏味道 N≥2 后提升到 `design_principles.md`。
- 结构失败优先补脚本或 checklist，不只修一处文本。
- 可复用创建/审查任务沉淀为 prompt；给人读经验沉淀为 insight。
