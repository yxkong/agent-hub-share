# Shared Skill 通用性契约

## 定位

`skills/share` 是跨项目可迁移的通用能力层。它可以规定抽象目录、占位符、证据类型、阶段门和脚本契约，但不能依赖某个 workspace、账号、仓库、客户、业务模块或私有素材才能成立。

同时区分两种“可迁移”：

- **语义通用性**：规则不绑定私有项目事实。
- **资产可搬运性**：只复制目标 skill 与显式 required skill 后，文档、模板、脚本和 smoke 仍闭环。

前者由 private-coupling 检查，后者由 package-closure 检查；只通过一项不能宣称 portable。

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

## Portable Package Contract

声明可独立安装的 share skill 必须在根目录提供 `skill-package.json`。manifest 随技能一起搬运，是版本、required dependency、optional handoff、运行时和 smoke 的唯一真源；`skills/registry.json` 只负责 Hub 分组与挂载，不重复维护这些字段。

允许的依赖：

- 当前 skill 根目录内的 `SKILL.md`、`references/`、`templates/`、`scripts/`、`assets/`、`tests/`。
- manifest `requires` 声明的其他 skill；安装、导出和隔离验证必须解析完整闭包。
- manifest `optional_skills` 声明的逻辑 handoff；缺失时主能力必须可降级。
- 用户显式提供的工程输入、工具和系统运行时。

禁止的隐式依赖：

- Hub 根 `scripts/`、`prompts/`、`docs/`、`rules/`、`plugins/`、`dist/`。
- 脚本通过多级 `../` 推导 Hub 根。
- 未声明的 `skills/share/<other-skill>/...` 物理路径。
- 指向 skill 根外的 symlink / junction。
- 依赖 registry、commands、hooks 或完整 Hub 挂载才能执行的 smoke。

技能向用户工作区写 Spec、报告、SQL 或 Replay 属于业务输出，不是控制面文件依赖；检查器不得把所有外部 I/O 一刀切禁止。

## 闭包校验与导出

标准入口：

```powershell
& <skill-root>\scripts\check-skill-package-closure.ps1 `
  -SkillsRoot <share-root> `
  -SkillRoot <target-skill-root> `
  -RunSmoke
```

```bash
sh <skill-root>/scripts/check-skill-package-closure.sh \
  --skills-root <share-root> \
  --skill-root <target-skill-root> \
  --run-smoke
```

隔离 smoke 必须把目标和 required closure 复制到临时 `skills/`，移除 Hub 环境变量后执行。导出模式只能写入空目录，并生成 `skill-package-lock.json`；不得静默使用未导出的 Hub 文件兜底。

## 完成门

shared skill 进入可挂载或标杆结论前，至少满足：

- 无当前运行环境 / 账号 / 仓库私有事实作为前置条件。
- 能说明 project skill 如何承接私有上下文。
- 验证证据区分 `share capability`、`project specialization`、`runtime assembly`。
- `check-share-skill-private-coupling` 通过。
- 若存在 `skill-package.json`：`check-skill-package-closure --run-smoke` 通过，且 required graph 无缺失、无环、无包外文件依赖。
