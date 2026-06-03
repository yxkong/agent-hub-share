# tdd-workflow

## 核心用途

把“先写代码再补测试”改成可执行的 TDD 闭环：Red → Green → Refactor → Evidence。

## 设计理解

本技能不是质量治理总纲，也不是项目测试框架手册。它只解决一个问题：当任务可以被测试表达时，Agent 应先固定失败用例，再做最小实现，最后用证据证明行为没有漂。

## 分层原则

- `SKILL.md`：Agent 运行入口，负责路由、边界、闭环门。
- `README.md`：维护章程，解释设计理由；不是 Agent 运行入口。
- `references/workflow.md`：TDD 执行步骤与异常处理。
- `references/trigger_eval.md`：触发与反触发样例。
- `references/closure_example.md`：真实 Red / Green / Evidence 闭环样例。

## 维护约束

- 不把项目专属测试框架写成 share 默认。
- 不把浏览器黑盒验证并入本技能；UI E2E 转 `webapp-testing`。
- 不跳过 Red 阶段后宣称 TDD；无法先写测试时必须标 `unknown` 或说明豁免。

## 不负责 / 转交

| 场景 | 转交 |
|---|---|
| 需求拆分、阶段门 | `delivery-workflow` |
| 质量治理、上线门禁 | `ai-development-governance` |
| 浏览器黑盒验证 | `webapp-testing` |
| 项目测试框架细节 | `<project-domain-skill>` |
