# 9.8+ 评分模型（Scorecard）

> 把端到端交付质量量化为 100 分；**低于 98 分只修薄弱 gate**，不大改全体系。

## 维度与权重

| 维度 | 权重 | 9.8 标准（≥90% 该维度满分） | 门禁来源 |
|------|-----:|----------------------------|----------|
| 需求与 Spec 真源 | 12 | 目标、范围、Out of Scope、业务规则、验收标准清楚 | G1 |
| 设计与 ADR | 10 | 关键方案有备选、决策原因、影响范围、回滚方式 | G2 |
| 任务切分 | 8 | 每个任务都是最小可验证闭环；Task Contract 完整 | G3 |
| AI 上下文治理 | 8 | 有范围、约束、参考实现、验收标准；Full Path 有持久上下文、过程区状态和反迎合检查，防漂移 | G4 / 横向门 |
| 代码审查 | 10 | 命名/架构符合度/错误处理/安全内建/可测试性/AI 生成代码额外检查 | G5 code_review_gate |
| 测试与验证 | 12 | 主链路、失败链路、回归、接口响应体均验证 | G5 quality_gate |
| 开发安全 | 8 | 权限、租户、敏感数据、密钥、日志、注入风险覆盖 | G6 security_gate |
| 业务安全 | 8 | 内容审核、交互防刷、短信防轰炸、频率限制（涉及时必评） | G6 biz-safety-audit |
| 发布与回滚 | 8 | 有 CI、灰度/feature flag、回滚、监控；Release Evidence 写明观察窗口、观察入口、回滚触发条件 | G7 |
| 文档与资产治理 | 8 | 文档 / SQL / 脚本落位正确，备份完整 | L3 |
| 失败沉淀 | 8 | 失败进入 Task Replay Lite，并回填 insight / anti-pattern / prompt / skill / scorecard | G8 |

**总分 = 各维度得分之和（满分 100）**

## Realism Gate（横向门禁）

Realism Gate 不单独加权，而是 G1 / G2 / G5 / G8 的横向扣分与阻断条件。交付不能靠“专家式总结”显得完整，必须暴露真实研发状态：

- `fact / assumption / unknown / risk / validation` 已分清，且关键 unknown 有最小验证动作。
- Debug 先有 1-3 个有序假设，再读代码或改代码。
- 方案先有最小有效路径；提出重构、抽象、批量替换时，已证明局部修改不足。
- 改变交互模式、行为模式、架构风格或运行语义前，已取得用户明确确认；用户要求直接执行时已声明风险。
- 交付前完成反方复核，指出最可能返工点。
- 验证覆盖主链路之外的关键边界、失败链路或回归用例。
- 头脑风暴 / 方案整合类任务先给反方问题、更小闭环和不做条件，再收敛路线。

## 9.8 / 10 判定

```text
总分 >= 98
且 代码审查、测试与验证、开发安全、业务安全（若触发）、发布与回滚 各维度得分率 >= 90%
且 Realism Gate 无阻断项
且没有 P0 阻断项
```

## P0 阻断项（任一项存在则不得宣称完成）

- Full Path 无 Spec / 无验收标准即实现
- 涉及权限/租户/敏感数据未过 Security Gate
- 涉及 UGC/交互/短信未做业务安全审计（biz-safety-audit）
- AI 生成代码未过代码审查（code_review_gate）
- 准备上线无 Rollback 资产
- 准备上线无 Release Evidence（观察窗口、观察入口、回滚触发条件）
- 验证仅 HTTP 200 未查响应体 / DB / 页面
- Full Path 只有 static / contract 证据，却宣称 runtime / user-visible 已完成
- 子 Agent 超范围改动未沉淀为 prompt 约束
- 改 docs/SQL/技能未做 backup-file
- Full Path 过程区未归档 / 未回灌，导致 plan、review、design 互相冲突
- 用目标 / 工程 / 验证 / 评审等视角名替代真实证据
- 头脑风暴或体系整合任务直接迎合用户方案，未提出反方问题、更小闭环或不做条件
- 用确定口吻包装未验证推断，或未暴露会影响交付的 unknown / risk
- 提出重构 / 抽象 / 批量替换但未证明局部修改不足
- 未经用户确认改变交互模式、行为模式、架构风格或运行语义（如异步改同步、事件驱动改直连、DDD 分层改写）

## 打分流程

1. 任务结束后按上表逐项自评（0–权重满分）。
2. 总分 < 98：定位最低 1–2 个维度，只补对应 gate 与产物。
3. 同类维度连续两次 < 80%：升级为 skill 反模式或 checklist 硬规则。
4. 同类失败 / 返工重复出现：做 Task Replay Lite，记录触发句、缺失证据、误判 gate、应回填位置。
5. Fast Path 任务：可跳过 Spec/ADR 维度，但 Quality 与 Learning 仍计分。

## Task Replay Lite / Skill Health Signal

不维护独立 skill health dashboard，只记录可行动信号：

| 信号 | 判定 | 回填位置 |
|---|---|---|
| 同类问题重复 ≥ 2 次 | Skill Health Signal | 对应 skill 的 bad smell / trigger eval / checklist |
| 交付总结夸大能力 | Task Replay Lite | `governance_checklist.md` / `scorecard.md` |
| 路由后仍找不到入口 | Skill Health Signal | skill `SKILL.md` 路由表或 references 索引 |
| 只有静态证据却宣称完成 | Task Replay Lite | `delivery-workflow` 主链证据矩阵 |

## 快速对照

| 分数段 | 含义 | 动作 |
|--------|------|------|
| 98–100 | 9.8+ 达标 | 可合并 / 上线 |
| 90–97 | 可用但有薄弱 gate | 补对应 gate 后再宣称完成 |
| < 90 | 治理缺口明显 | 不得上线；走 G8 Learning Gate |
