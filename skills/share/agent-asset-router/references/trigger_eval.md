# agent-asset-router — trigger / eval

## 前置条件

所有 should-trigger 样例都必须已确认 `project_type=engineering`。项目类型未知时先加载项目身份或询问用户，不得推测。

## should-trigger

- 工程项目：「这次修复既要补回归测试、写 ADR，又要沉淀 replay，先走哪个？」
- 工程项目：「这份研发复盘应该落成 prompt、skill 还是 insight？」
- 工程项目：「接口契约、实现说明和验收记录分别放哪？」
- 工程项目：「要新增一个工程 skill，但还不确定是否已有可复用能力。」

## should-not-trigger

- generic：「帮我判断这份个人笔记放哪。」→ 当前 generic 规则或询问用户
- media：「把选题、正文、配图和发布包串起来。」→ media profile
- hub：「修改 registry、构建插件并同步挂载。」→ `ai-hub-maintainer`
- mixed：「先判断这属于工程还是内容生产。」→ mixed profile 先声明子域，不使用本技能
- 项目类型未知：「这个资产该放哪？」→ 先加载已登记项目身份或询问用户
- 工程项目但目标明确：「修一个 Java 接口 bug。」→ `delivery-workflow` / 项目领域技能
- 工程项目但目标明确：「审查这个 SKILL.md。」→ `skill-engineering`

## 通过标准

1. 非 engineering 样例不得加载或触发本技能。
2. engineering 正例先判产物和唯一 owner，再退出到目标技能。
3. 目标已明确时不得增加一次无价值路由。
