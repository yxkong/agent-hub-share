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
- [ ] 跨项目 / 共享 DB / Java-Python / 前后端联动任务已过 [project_contract_gate.md](gates/project_contract_gate.md)
- [ ] 若出现白名单外改动，已更新 Contract 或标为 blocked，未静默扩大范围
- [ ] 子 Agent prompt 含 7 要素或 hub share prompt

## 持久上下文与多视角反证（横向门）

- [ ] Full Path 已有过程区或等价书面上下文，覆盖目标、范围、设计、任务和验收
- [ ] 头脑风暴 / 方案收敛过程稿（若触发）已使用 `TEMPLATE_BRAINSTORM_CONVERGENCE.md` 或等价结构，并落 `docs/plan/<domain>/`
- [ ] 过程区状态明确：`done` / `superseded` / `blocked`
- [ ] 长期有效结论已回灌到 `docs/design/`、skill references、prompt 或 insight
- [ ] 头脑风暴 / 体系方案已暴露 fact / assumption / unknown / risk，并给出反方问题与更小闭环
- [ ] 多视角反证只作为问题集，已给出目标 / 工程 / 评审 / 验证等相关证据，未用视角名替代验证

## 实现（G4）

- [ ] 用户已明确提出实施请求，机器状态为当前会话的 `GOAL_AUTHORIZED`
- [ ] 同一目标内的设计细化、依赖闭包、文件扩展和验证未制造重复确认
- [ ] 只读请求、R1、Review PASS 与方案讨论未被误当作实施授权
- [ ] 目标切换、授权根外写入、生产/外部写入、权限密钥、安全升级、删除/不可逆、发布推送已单独确认
- [ ] R1 出门声明已输出
- [ ] checkpoint 协议已执行
- [ ] 未越出当前目标和授权根

## 质量（G5）

- [ ] 见 [quality_gate.md](quality_gate.md) 主链路 + 失败链路
- [ ] 见 [code_review_gate.md](code_review_gate.md) 代码审查（命名/架构符合度/错误处理/安全内建/可测试性）
- [ ] Realism Gate 已过：已暴露 fact / assumption / unknown / risk / validation，未用专家式总结掩盖未验证事实
- [ ] 已证明最小方案、重构必要性、边界测试与反方复核；不满足时回到 `delivery-workflow` 对应 Gate
- [ ] 主链证据矩阵已填写；`static only` / `contract only` / `DDL only` 能力已降级表述
- [ ] **能力声明边界表**已填写：每个交付能力标明 `Implemented / MVP Implemented / Contract Only / DDL Only / Not Implemented`，并列验证证据；禁止把 DDL-only、字段贯通、占位评分、未接运行时的配置项写成完整能力。

### 能力声明边界表（G5 必填）

用于防止 P0 / MVP 交付总结夸大能力边界。所有跨模块、AI 产品化、平台控制面、上线前汇报都必须填写：

| 状态 | 含义 | 允许表述 | 禁止表述 |
|---|---|---|---|
| `Implemented` | 数据、接口、运行时、管理端、验证均闭环 | “已实现并通过 X 验证” | — |
| `MVP Implemented` | 主链路可走通，但存在明确局限 | “MVP 已实现，局限是...” | “完整实现” |
| `Contract Only` | 字段 / DTO / API 契约已贯通，但运行时能力未闭环 | “契约已预留/透传” | “能力已支持” |
| `DDL Only` | 仅有表结构或菜单 SQL，无业务运行时 | “DDL 已落地，运行时待实现” | “已有限流/计费/策略生效” |
| `Not Implemented` | 未落地 | “未实现 / out of scope” | “后续可用” |

最小汇报格式：

```markdown
| 能力 | 状态 | 验证证据 | 局限 / 下一步 |
|---|---|---|---|
| API rate limit runtime enforcement | DDL Only | `ai_api_rate_limit_rule` DDL | 未接 QPS 运行时拦截 |
| Eval rule scoring | MVP Implemented | run_case score + pass_rate + compile | 未接真实 LLM Judge |
```

## 安全（G6，若触发）

- [ ] 见 [security_gate.md](security_gate.md)（权限/租户/数据/注入/AI 特有风险）
- [ ] 若涉及 UGC/交互/短信：见 `biz-safety-audit` 技能（内容安全/交互安全/短信安全）

## 发布与回滚（G7，若上线）

- [ ] 见 [release_gate.md](release_gate.md) + [rollback_gate.md](rollback_gate.md)
- [ ] Release Evidence 已填写：观察窗口、观察入口、回滚触发条件；若未部署则标 `release: NOT_RUN`

## 文档与资产（L3）

- [ ] docs / SQL 落位正确（`doc-script-governance` checklist）
- [ ] backup-file 已执行（改 docs/SQL/技能时）

## 学习与评分（G8）

- [ ] 若有失败：R3 三路分流已完成
- [ ] 若发生返工：已做 Task Replay Lite（触发输入、缺失证据、误判 gate、回填位置）
- [ ] 若同类返工重复出现：回填对应 skill 的 bad smell / trigger eval / scorecard 维度；本体系不新增独立技能健康度看板
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
