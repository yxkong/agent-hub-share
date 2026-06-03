---
name: biz-safety-audit
description: 业务安全审计技能（content safety, interaction safety, SMS safety, rate limiting, anti-abuse）。审计内容发布、用户交互、短信/通知等业务场景的安全规则与限制是否到位；适用于 UGC 审核、频率限制、验证码策略、短信防轰炸、敏感词过滤等业务安全盲区排查。不替代 ai-development-governance 的 G6 Security Gate（权限/租户/数据），不写业务代码。
---

# Biz Safety Audit

## 30 秒决策区

| 任务类型 | 什么时候选它 | 先读什么 |
|------|------|------|
| `content` | 涉及 UGC、评论、富文本、图片/文件上传、敏感词、内容审核 | `references/content_safety_checklist.md` |
| `interaction` | 涉及频率限制、防刷、验证码、并发控制、防爬、防重放 | `references/interaction_safety_checklist.md` |
| `sms` | 涉及短信、验证码下发、通知推送、邮件频率、费用管控 | `references/sms_notification_safety_checklist.md` |
| `pattern` | 需要了解通用防御模式（滑窗限流、令牌桶、熔断、黑白名单等） | `references/common_defense_patterns.md` |

规则：一次可命中多个路由（如"评论功能"同时命中 `content` + `interaction`）；按主风险排序依次审计。

## 作用边界

**负责**：

- 内容安全规则审计（敏感词、UGC 审核流程、内容长度/格式限制）
- 交互安全规则审计（接口频率、防刷、验证码、并发、防爬）
- 短信/通知安全规则审计（防轰炸、频率上限、模板合规、费用管控）
- 通用防御模式选型建议（限流算法、熔断、黑白名单）

**不负责**：

- 权限、租户、数据脱敏 → `ai-development-governance` Security Gate (G6)
- 具体代码实现 → `delivery-workflow` + 项目领域技能
- 基础设施安全（WAF、防火墙、CDN 防护） → 运维/安全团队
- Prompt injection / AI 特有风险 → `ai-development-governance` Security Gate (G6)

## 核心原则

- **业务视角优先**：从用户行为和业务场景出发审计，不从底层协议出发
- **分层防御**：前端限制只是体验优化，后端必须强校验；客户端参数不可信
- **最小权限发送**：短信/通知/邮件按最小必要频率和范围发送
- **可观测**：所有安全规则的触发、拦截、降级必须有日志和监控
- **宁严勿松**：业务安全规则默认从严，上线后按数据逐步放宽

## 审计流程

1. **识别场景**：从功能需求或代码变更中识别涉及内容/交互/短信的业务场景
2. **选择 checklist**：按 30 秒决策区选定 1~N 个 references
3. **逐项审计**：对照 checklist 检查方案/代码是否覆盖
4. **输出结论**：按 P0 阻断 / P1 建议 / P2 可选 分级，列出缺失项和建议
5. **关联门禁**：若同时涉及权限/租户/数据 → 追加 `ai-development-governance` Security Gate

## 强制审计触发

满足**任一**条件必须执行本技能审计：

- 用户可提交任意文本/富文本/文件（UGC）
- 接口对外暴露且无认证或弱认证
- 涉及短信/验证码/通知下发
- 涉及评论、点赞、关注、分享等社交互动
- 涉及搜索、列表等可被爬虫批量调用的接口
- 涉及抽奖、秒杀、领券等防刷场景

## References 优先级

**P0（按路由直接打开）**

- `references/content_safety_checklist.md`
- `references/interaction_safety_checklist.md`
- `references/sms_notification_safety_checklist.md`

**P1（按需补充）**

- `references/common_defense_patterns.md`

## trigger / eval

- **should-trigger**：UGC 审核、敏感词、内容限制、频率限制、防刷、验证码、短信轰炸、通知频率、接口防爬、业务安全规则缺失排查
- **should-not-trigger**：权限模型设计、租户隔离、数据脱敏、AI prompt 安全、基础设施安全配置

## 与其他技能的关系

| 技能 | 何时转移 |
|------|----------|
| `ai-development-governance` | 涉及权限/租户/数据/AI 安全时，走 Security Gate (G6) |
| `delivery-workflow` | 进入需求推进、代码实现、验证阶段时 |
| `tdd-workflow` | 安全规则需要测试用例保护时 |
| `webapp-testing` | 需要浏览器黑盒验证安全规则生效时 |
