# tdd-workflow trigger eval

| # | 用户输入 | 期望 |
|---|---|---|
| 1 | 这个 bug 先补一个回归测试再修 | 触发 `tdd-workflow` |
| 2 | 先写失败用例，再实现这个校验逻辑 | 触发 `tdd-workflow` |
| 3 | 给这个接口字段加契约测试 | 触发 `tdd-workflow` |
| 4 | 老代码先补安全网再重构 | 触发 `tdd-workflow` |
| 5 | 页面点一下看看能不能提交 | 不触发 → `webapp-testing` |
| 6 | 这个需求怎么拆阶段 | 不触发 → `delivery-workflow` |
| 7 | 上线前质量门禁怎么过 | 不触发 → `ai-development-governance` |
| 8 | 文档放哪个目录 | 不触发 → `doc-script-governance` |

通过标准：1-4 进入 TDD Red → Green → Refactor → Evidence；5-8 转交正确技能。
