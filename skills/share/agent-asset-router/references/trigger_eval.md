# agent-asset-router — trigger / eval

## should-trigger

- 「这次应该沉淀成 skill、prompt 还是 insight？」
- 「帮我梳理这些共享技能的路由关系，触发更高效」
- 「Cursor 找不到我新建的 skill，同时我也想优化它的 description」
- 「这份评审 SOP 应该放 docs、prompt 还是 skill？」
- 「我要做 TDD、文档治理和长文成稿，这几个先走哪个？」

## should-not-trigger

- 「帮我修一个 Java 接口 bug」→ `delivery-workflow` / 项目领域技能
- 「给这个 Vue 页面加一个按钮」→ 前端领域技能
- 「直接执行这份已经确定的 prompt 模板」→ 直接执行目标 prompt
- 「已经明确是 skill 审查任务，直接开始 review」→ `skill-engineering`
- 「已经明确是长文对外成稿，直接写正文」→ 切 media 身份后按 `PROFILE_RULES.md` 进 workflow

## 通过标准

命中 should-trigger 时，应先判最终产物和第一跳技能，再展开后续 SOP；命中 should-not-trigger 时，直接进入目标技能，不再重复走路由器。
