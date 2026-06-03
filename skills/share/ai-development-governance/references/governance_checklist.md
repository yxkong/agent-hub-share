# 治理自检清单（交付前）

> 汇总 G1–G8 关键项；细节见各 gate 文件。与 `delivery-workflow/references/checklist.md` **互补**，不重复执行细节。

## Spec 与范围（G1）

- [ ] 目标与 Out of Scope 已明确
- [ ] 验收标准可执行（主链路 + 至少一条失败链路）
- [ ] Full Path 有 Spec 或等价书面收敛

## 设计与 ADR（G2）

- [ ] 关键决策有原因记录（ADR 或设计收敛门发散→收敛）
- [ ] 契约已冻结：接口 / SQL / 权限 / 状态 至少一项已书面化

## 任务契约（G3）

- [ ] Full Path 跨模块任务有 Task Contract 或 meta contract
- [ ] 范围白名单 / 禁止改清单已列出
- [ ] 子 Agent prompt 含 7 要素或 hub share prompt

## 实现（G4）

- [ ] R1 出门声明已输出
- [ ] checkpoint 协议已执行
- [ ] 未超范围改动

## 质量（G5）

- [ ] 见 [quality_gate.md](quality_gate.md) 主链路 + 失败链路
- [ ] 见 [code_review_gate.md](code_review_gate.md) 代码审查（命名/架构符合度/错误处理/安全内建/可测试性）

## 安全（G6，若触发）

- [ ] 见 [security_gate.md](security_gate.md)（权限/租户/数据/注入/AI 特有风险）
- [ ] 若涉及 UGC/交互/短信：见 `biz-safety-audit` 技能（内容安全/交互安全/短信安全）

## 发布与回滚（G7，若上线）

- [ ] 见 [release_gate.md](release_gate.md) + [rollback_gate.md](rollback_gate.md)

## 文档与资产（L3）

- [ ] docs / SQL 落位正确（`doc-script-governance` checklist）
- [ ] backup-file 已执行（改 docs/SQL/技能时）

## 学习与评分（G8）

- [ ] 若有失败：R3 三路分流已完成
- [ ] [scorecard.md](scorecard.md) 自评 ≥ 98（Full Path）或关键维度无 P0

## 治理审计输出格式（供 Agent 汇报）

```markdown
### 治理审计摘要

**路径**：Fast | Full  
**Scorecard**：__/100  

| Gate | 状态 | 备注 |
|------|------|------|
| G1 Spec | pass/skip/fail | |
| G2 ADR | pass/skip/fail | |
| G3 Task Contract | pass/skip/fail | |
| G5 Quality | pass/fail | |
| G6 Security | pass/skip/N/A | |
| G7 Release | pass/skip/fail | |
| G8 Learning | pass/N/A | |

**P0 阻断**：（无 / 列表）  
**下一步**：
```
