# biz-safety-audit

业务安全审计技能——审计内容发布、用户交互、短信/通知等业务场景的安全规则与限制是否到位。

## 核心用途

在研发功能涉及 UGC、交互、短信/通知时，系统性排查安全规则缺失，输出分级审计结论（P0 阻断 / P1 建议 / P2 可选），避免业务安全盲区上线。

## 设计理解 / 设计哲学

`ai-development-governance` 的 Security Gate (G6) 覆盖权限、租户、数据、注入、AI 特有风险——属于**开发安全门禁**。但真实业务中大量安全事故来自**业务层面规则缺失**：短信被轰炸、接口被刷、UGC 注入脚本、评论区垃圾内容泛滥。这些不属于传统意义的"权限/租户/数据"问题，却是上线后最高频的安全事件。

本技能填补这一空白：从**业务场景**出发，用 checklist 驱动审计，确保内容/交互/短信三大类业务安全规则在方案设计和代码实现阶段就被覆盖。

**为什么独立存在**：G6 Security Gate 是研发治理门禁的一部分，关注"开发过程中的安全合规"；本技能关注"业务功能本身的安全规则"，粒度更细、场景更具体、checklist 更贴近业务开发者日常。两者互补，不重叠。

## 分层原则 / 结构约定

- `README.md`：维护章程，给人读；**不是 Agent 运行入口**
- `SKILL.md`：运行入口，负责触发、路由、硬约束
- `references/`：三大 checklist + 通用防御模式参考

## 维护约束

- 扩展审计范围前：先更新本 README 的边界，再改 `SKILL.md`
- 新增 checklist 项时：确认不与 `ai-development-governance` Security Gate 重复
- 防御模式参考应保持技术中立（不绑定特定框架/中间件版本）
- `references/` 中的 checklist 按场景组织，不按技术栈组织

## 单一职责（本 skill 独有）

- 内容安全规则 checklist 审计
- 交互安全规则 checklist 审计
- 短信/通知安全规则 checklist 审计
- 通用防御模式选型参考

## 不负责 / 转交

| 场景 | 转交技能 |
|------|----------|
| 权限、租户、数据脱敏、AI 安全 | `ai-development-governance` (Security Gate G6) |
| 真实研发任务怎么推进 | `delivery-workflow` |
| 安全规则需要测试保护 | `tdd-workflow` |
| 浏览器黑盒验证安全规则 | `webapp-testing` |
| 基础设施安全（WAF / 防火墙） | 运维/安全团队 |

## 入口

- **Agent 路由器**：[SKILL.md](SKILL.md)
- **本 README**：维护章程，说明设计理解与维护边界

## 真源与挂载

- Hub 真源：`$AGENTS_HUB_ROOT/skills/share/biz-safety-audit/`
- 工作区：`<repo>/.claude/skills/biz-safety-audit` 等为入口链接，**不以工作区副本为真源**

## 修订记录（人读；`references/` 不写）

| 版本 | 日期 | 修订要点 |
|------|------|----------|
| 1.0.0 | 2026-06-03 | 初版：content / interaction / sms 三路由 + common patterns |
