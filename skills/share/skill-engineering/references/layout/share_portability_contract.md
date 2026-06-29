# Shared Skill 通用性契约

## 定位

`skills/share` 是跨项目可迁移的通用能力层。它可以规定抽象目录、占位符、证据类型、阶段门和脚本契约，但不能依赖某个 workspace、账号、仓库、客户、业务模块或私有素材才能成立。

## 三层分工

| 层 | 允许承载 | 不应承载 |
|---|---|---|
| share skill | 通用动作规则、路由、证据契约、质量门、占位路径 | 私有项目事实、账号人设、仓库专属字段、一次性结论 |
| project skill | 某项目/仓库的目录、技术栈、领域约束、实现习惯 | 跨项目公共治理总纲 |
| runtime environment | 挂载、commands、hooks、plugin、账号资料、真实历史产物 | 反向证明 share skill 本体更强 |

## 评估口径

- 评价 shared skill 时，只看它是否能在任意项目中指导 Agent 形成正确动作。
- 当前运行环境的 `check-hub-all`、commands/hooks/plugin 成功，属于装配层证据；只能证明该环境装配健康，不能单独证明 shared 方法优于外部技能。
- 项目技能、账号 coach、`accounts/`、真实业务样例属于私有层证据；可以证明“组合系统”有效，不能计入 shared skill 本体能力。
- `$AGENTS_HUB_ROOT`、`<project-key>`、`<skill-name>` 等通用占位符是允许的抽象，不属于私有耦合。
- 真实项目名、本机绝对路径、账号 key、客户名、内网 URL、仓库专属模块名必须留在 project skill 或 runtime 文档。

## 写法要求

- 主文件用“目标契约、当前事实查证、风险反证、测试证据、薄切片、失败回灌”等动作语言。
- reference 可记录方法来源，但不得把外部名词变成运行时路由。
- 示例默认使用 `<project-key>`、`<repo-root>`、`<domain>`、`<account-key>` 等占位符。
- 若必须引用当前环境验证结果，必须标明 `scope=runtime evidence`，不得写成通用能力结论。

## 完成门

shared skill 进入可挂载或标杆结论前，至少满足：

- 无当前运行环境 / 账号 / 仓库私有事实作为前置条件。
- 能说明 project skill 如何承接私有上下文。
- 验证证据区分 `share capability`、`project specialization`、`runtime assembly`。
- `check-share-skill-private-coupling` 通过。
