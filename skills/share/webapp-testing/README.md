# webapp-testing

## 核心用途

用浏览器自动化和黑盒验证方式，确认本地 Web 应用主链路是否真实可用。

## 设计理解

本技能不替代前端实现、单元测试或后端契约测试。它的价值是把“代码看起来没问题”推进到“页面上真实链路能跑通”，并留下截图、日志、断言或复现步骤。

## 分层原则

- `SKILL.md`：Agent 运行入口，放场景、流程、闭环门。
- `README.md`：维护章程，不作为 Agent 运行入口。
- `references/trigger_eval.md`：should-trigger / should-not-trigger、验证入口回归。
- `references/closure_example.md`：真实黑盒闭环样例。
- 若未来新增脚本或模板，放 `scripts/` / `templates/`，并在 `SKILL.md` 的闭环门补校验口径。

## 维护约束

- 不把项目专属启动命令写成 share 层默认。
- 不把浏览器黑盒验证扩展成前端实现 SOP。
- 新增示例时保留“侦察 -> 动作 -> 验证”的顺序。

## 不负责 / 转交

| 场景 | 转交 |
|---|---|
| 需求推进、debug 根因定位 | `delivery-workflow` |
| 前端实现 | `<frontend-domain-skill>` |
| 文档放置与备份 | `doc-script-governance` |
| 技能结构优化 | `skill-engineering` |
