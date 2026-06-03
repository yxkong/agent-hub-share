# doc-script-governance — trigger / eval

## should-trigger

- 「docs 目录怎么按研发全流程重构？」
- 「设计文档和 Java / Python 实现要怎么拆目录？」
- 「文档修改前先 git 还是先备份脚本？」
- 「模块 SQL 怎么合并开发终版，online SQL 怎么处理？」
- 「review 应该放 design 还是独立目录？」
- 「这个技能 README / references 改前要怎么备份？」

## should-not-trigger

- 「帮我写一份业务方案」→ `delivery-workflow` / `ai-development-governance`
- 「帮我修一个 Java bug」→ 项目领域技能 + `delivery-workflow`
- 「这个接口怎么实现」→ `delivery-workflow`
- 「帮我审查这个 skill 的结构和触发」→ `skill-engineering`
- 「Cursor 找不到这个 skill / 怎么挂载」→ `agent-hub-bootstrap`

## 通过标准

命中 should-trigger 时，应进入目录放置、模板、命名或备份规则；命中 should-not-trigger 时，明确转交执行、治理总线或 skill 工程，不在本技能内扩写实现方案。
