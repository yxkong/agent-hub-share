# biz-safety-audit — trigger / eval

## should-trigger

- 「评论需要审核吗」「UGC 有没有敏感词/内容审核」
- 「接口要限流/防刷/验证码吗」「短信会不会被轰炸」
- 「通知/邮件频率上限怎么定」「搜索/列表接口防爬」
- 「抽奖/秒杀/领券防刷规则缺了哪些」
- 方案或代码涉及用户可提交文本/文件、对外弱认证接口、短信/验证码下发

## should-not-trigger

- 权限模型、租户隔离、数据脱敏、AI prompt 注入 → `ai-development-governance` Security Gate (G6)
- 需求拆解、阶段门、实现与验证 → `delivery-workflow`
- 安全规则要落成测试用例 → `tdd-workflow`（本技能只审计规则清单）
- 浏览器黑盒验证规则是否生效 → `webapp-testing`
