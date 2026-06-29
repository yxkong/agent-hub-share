# AI 研发方法增强映射

## 定位

本文件只服务维护与审计：把外部优秀方法拆成通用 shared skill 能执行的动作规则。Agent 运行时不需要背方法论名词，只需要按动作完成证据。

## 先回答：真正解决什么

SDD 这类方法真正要解决的不是“多写一份 Spec”，而是防止人和 AI 在需求没说清、边界没锁住、完成没证据时直接开始写代码。它要把模糊意图变成可执行、可验证、可追责的开发契约。

通用 shared 研发体系解决的是更大的运行治理问题：让 Agent 在任意项目环境里知道先读谁、该转谁、能改哪、怎么验、失败后沉淀到哪里。它不等同于 SDD，而是吸收了 SDD 要解决的问题，并把它扩展成路由、治理、执行、证据、资产真源和失败回灌的协作系统。

裁决口径：

- 需求不清时，先补目标、非目标、边界和验收，不急着实现。
- 涉及接口、字段、SQL、权限、状态机或多项目协作时，先形成任务契约。
- 涉及外部库、CLI、API、平台规则或版本敏感内容时，先查当前事实源。
- 方案影响面不确定或用户方向未经验证时，先做风险反证和更小闭环。
- 可测试行为优先补测试证据；不可单测的主链路必须有 runtime / user-visible 等证据。
- 失败不是“下次注意”，必须回灌到 insight / prompt / skill / checklist / test / docs 之一。

语言约束：主技能入口只写这些动作规则，不把外部方法名当运行时路由。外部名词只保留在本文件的来源参考中，供维护、审计和后续复盘追溯。

| 动作能力 | 本地真源 | 强化的问题 | 不解决的问题 |
|---|---|---|---|
| 目标契约 | `ai-development-governance` Spec / ADR / Task Contract | 目标、边界、验收、架构取舍 | 具体实现推进 |
| 当前事实查证 | `delivery-workflow` reference-first | 官方文档、版本、外部 API、平台规则 | 账号/项目私有决策 |
| 风险反证 | `risk_review_matrix.md` + `code_review_gate.md` | 高风险方案的反证、停止条件、替代路径 | 常规小改的执行 |
| 测试证据 | `tdd-workflow` | 行为回归、红绿重构、证据内建 | 浏览器黑盒或发布观察 |
| 薄切片交付 | `delivery-workflow` Gate 1-5 | 主链路、证据矩阵、失败沉淀 | 治理总纲制定 |
| AI 协作回灌 | `delivery-workflow` + `prompt-engineering` + `skill-engineering` | 上下文协议、子 Agent、prompt/skill 回灌 | 业务领域知识本身 |

## 执行顺序

1. **目标契约**：Full Path 先形成目标、非目标、契约、验收和风险；Fast Path 可轻量但要说明成功标准。
2. **当前事实查证**：只要涉及外部库、CLI、API、平台规则或版本敏感内容，先查官方/当前文档，再实现。
3. **风险反证**：方案影响多模块、用户方向未经验证或存在不可逆风险时，先列反方问题、失败条件和更小闭环。
4. **薄切片任务**：把任务拆成可验证小步；每片有输入、输出、验证命令和停止条件。
5. **测试与主链证据**：可测试行为优先补 Red/Green/Refactor；不可单测的主链路进入 runtime/user-visible 证据。
6. **失败回灌**：失败、返工、回滚或同类问题复现时，进入 R3，回灌到 insight / prompt / skill / checklist / test / docs。

## AI 开发扩展

- 目标契约不只描述人类需求，还描述 Agent 能安全执行的上下文包、路径白名单、验证命令和禁止动作。
- 当前事实查证不只查库文档，也包括当前仓库样板、官方平台规则、已登记 skill / account coach / registry。
- 风险反证不是拖慢执行；它只在高影响决策前做一次反证，结论必须落到更小闭环或不做条件。
- 测试证据不要求所有任务都有单测；但任何“完成”都要有 static / contract / runtime / user-visible / release / limitation 之一的证据。
- 失败回灌不是写复盘作文；必须沉淀为可复用的规则、测试、脚本、prompt 或 skill 优化。

## 审计清单

- 是否有 Spec 或 Fast Path 成功标准？
- 是否有官方/当前来源支撑外部事实？
- 是否识别了不可逆、高成本或多模块风险？
- 是否按薄切片推进，而不是一次性大改？
- 是否有主链路证据矩阵？
- 失败是否进入 R3，并能回灌到可执行资产？

## 来源参考

本文件吸收了 agent-skills 中 spec-driven development、source-driven development、doubt-driven development、planning/task breakdown、incremental implementation 等方法的有效动作。外部术语只作为维护溯源，不进入主技能运行入口。
