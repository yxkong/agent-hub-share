# webapp-testing — trigger / eval

## should-trigger

- 「用浏览器验证这个管理后台页面能不能提交」
- 「Playwright 跑一下登录到列表的主链路」
- 「页面打开了但按钮点不了，帮我黑盒排查」
- 「delivery 验证阶段需要 UI 冒烟」
- 「不用深读源码，先帮我看页面真实链路有没有问题」

## should-not-trigger

- 「帮我写这个 Vue 组件的逻辑」→ `<frontend-domain-skill>` + `delivery-workflow`
- 「单元测试怎么 mock API」→ 项目测试规范 / `tdd-workflow`
- 「docs 放哪个目录」→ `doc-script-governance`
- 「这个 bug 先补测试再修」→ `tdd-workflow`
- 「我要做上线前 Security / Release Gate」→ `ai-development-governance`

## 通过标准

命中 should-trigger 时，先走“侦察 -> 动作 -> 验证”并留下截图、日志或断言；命中 should-not-trigger 时，转交前端实现、测试先行或治理门禁技能。
