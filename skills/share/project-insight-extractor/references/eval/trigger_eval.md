# project-insight-extractor — trigger / eval

## should-trigger

- 「把这次 RAG 排查过程提炼成面试案例」
- 「根据这段开发记录生成简历亮点」
- 「把 AI 编程里踩过的坑整理成方法论」
- 「这个优化点怎么讲给面试官听」
- 「一句话从当前会话生成技术洞察资产」
- 「把这次架构评估沉淀成可归档的 insight」
- 「返工了，要沉淀可讲给人的认知」

## should-not-trigger

- 「帮我修这个接口 bug」→ `delivery-workflow` + 项目领域技能
- 「这段代码有没有问题」→ 对应代码 review / 领域技能
- 「帮我写一篇完整对外长文/连载」→ `<private-media-skill>`
- 「把子 Agent prompt 落成 `*.prompt.md`」→ `prompt-engineering`
- 「回填 SKILL 反模式表」→ 主模型评审后改仓库；卡片模板见 `references/skill_anti_pattern_feedback.md`
- 「还没判断该做 skill、prompt 还是 insight」→ `agent-asset-router`

## 通过标准

命中 should-trigger 时，产物应是给人读的 insight / 面试表达 / 简历 bullet / 方法论；命中 should-not-trigger 时，转交实现、prompt 沉淀、长文成稿或资产分诊技能。
