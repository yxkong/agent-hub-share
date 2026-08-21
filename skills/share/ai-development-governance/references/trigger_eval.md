# ai-development-governance — trigger / eval

## should-trigger

- 「AI 开发规范怎么定，阶段门怎么拆？」
- 「这个需求上线前要过哪些治理门禁？」
- 「需要补 Spec / ADR / Task Contract 吗？」
- 「Security / Release / Quality Gate 分别什么时候介入？」
- 「跨多个 share skill 时，先走哪个治理入口？」
- 「怎么判断这个任务能不能走 Fast Path？」

## should-not-trigger

- 「帮我直接实现这个接口 / 页面 / SQL」→ `delivery-workflow` 做设计/授权映射，再转项目领域技能
- 「文档放哪个目录、改前怎么备份」→ `doc-script-governance`
- 「帮我审查这个 SKILL.md 结构」→ `skill-engineering`
- 「已经满足 Fast Path，直接推进这个单点改动」→ `delivery-workflow`
- 「写一篇给人看的复盘 / 面试表达」→ `project-insight-extractor`

## 通过标准

命中 should-trigger 时，优先进入生命周期、门禁或治理模板路由；命中 should-not-trigger 时，转交实现、文档治理或 skill 工程相关技能，不在本技能内展开执行细节。
