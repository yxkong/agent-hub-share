# 研发生命周期阶段门（G0–G8）

> 与 `delivery-workflow` 五阶段门对齐：`delivery-workflow` 负责**执行推进**；本文件负责**治理准入门禁**与跨 skill 路由。

## 总览

```text
G0 Idea / Draft Gate    想法、草稿与需求入口门
G1 Spec Gate            规格真源门
G2 SDD / ADR Gate       设计契约与决策门
G3 Task Contract Gate   任务契约门
   └─ Project Contract  跨项目契约门（触发时）
G4 Implementation Gate  实现执行门      → delivery-workflow §实现切分门
G5 Quality Gate         质量验证门      → quality_gate.md + code_review_gate.md
G6 Security Gate        安全合规门      → security_gate.md + biz-safety-audit（业务安全）
G7 Release Gate         发布回滚门      → release_gate.md + rollback_gate.md
G8 Learning Gate        失败沉淀门      → delivery-workflow R3
```

## 横向增强门

| 增强门 | 触发 | 作用 |
|------|------|------|
| 持久上下文与多视角反证门 | Full Path、跨模块、9.8+、跨 session 返工、体系方案头脑风暴 | 约束过程区 / archive 回灌 / 反迎合检查 / 多视角反证；细则见 [context_persistence_gate.md](context_persistence_gate.md) |
| Project Contract Gate | 跨项目、共享 DB、Java-Python、前后端联动 | 冻结真源、参与项目、契约面、允许/禁止改范围、验证证据；细则见 [gates/project_contract_gate.md](gates/project_contract_gate.md) |

---

## G0 Idea / Draft Gate — 想法、草稿与需求入口门

| 字段 | 内容 |
|------|------|
| **Trigger** | 任何非 trivial 研发任务到达；用户只有想法、草稿、方向、痛点或问「规范 / 体系 / 总纲」 |
| **Owner Skill** | `delivery-workflow`（默认入口 triage）→ 头脑风暴/草稿落位读 `doc-script-governance` → 命中体系 / Spec / ADR / 门禁 / 评分时转 `ai-development-governance` |
| **Required Inputs** | 用户原始想法、草稿、现象或目标（可不完整） |
| **Required Outputs** | `[头脑风暴自检]`；Fast / Full Path 初判；若 Full Path 或需要跨轮收敛，落 `TEMPLATE_BRAINSTORM_CONVERGENCE.md` 过程稿；是否需 Spec / SDD / ADR / Task Contract |
| **Blockers** | 目标完全不明且用户拒绝澄清 → 暂停实现 |
| **Fast Path** | 单点 bugfix、验证路径明确、不改契约 → 跳过 G1–G3 完整文档 |
| **Full Path** | 需求歧义、跨模块、接口/SQL/权限/状态机 → 必须走 G1–G3 |

**文档落位**（与 `doc-script-governance` 对齐）：

| 产物 | 目录 |
|------|------|
| 头脑风暴 / 方案收敛过程稿 | `docs/plan/<domain>/<TOPIC>_BRAINSTORM.md` |

---

## G1 Spec Gate — 规格真源门

| 字段 | 内容 |
|------|------|
| **Trigger** | Full Path；或用户要求「先写 Spec / 需求文档」 |
| **Owner Skill** | `ai-development-governance`（模板）→ `delivery-workflow` §需求理解门 |
| **Required Inputs** | 业务目标、用户场景、已知约束；若 G0 已落过程稿，则引用头脑风暴 / 方案收敛稿 |
| **Required Outputs** | Feature Spec（见 `templates/TEMPLATE_FEATURE_SPEC.md`） |
| **Blockers** | In Scope / Out of Scope / 验收标准三项缺二 → 不进入 G4 |
| **Fast Path** | 口头确认目标 + 边界 + 验收即可 |
| **Full Path** | 完整 Spec，落 `docs/plan/<domain>/` 过程稿或升格 `docs/design/`；必要时启用 [context_persistence_gate.md](context_persistence_gate.md) 的过程区契约 |

**文档落位**（与 `doc-script-governance` 对齐）：

| 产物 | 目录 |
|------|------|
| Feature Spec（过程） | `docs/plan/<domain>/` |
| Spec 升格为终版设计 | `docs/design/<domain>/` |

---

## G2 SDD / ADR Gate — 设计契约与决策门

| 字段 | 内容 |
|------|------|
| **Trigger** | 架构取舍、多方案比较、跨模块影响、不可逆决策 |
| **Owner Skill** | `delivery-workflow` §设计收敛门 + `ai-development-governance`（SDD / ADR 模板） |
| **Required Inputs** | Spec 或等价需求理解产出 |
| **Required Outputs** | SDD 或等价设计契约；存在多方案取舍时补 ADR（见 `templates/TEMPLATE_SDD.md`、`templates/TEMPLATE_ADR.md`） |
| **Blockers** | 有备选方案但未记录决策原因 → 不进入 G4 |
| **Fast Path** | 只有一种方案且风险低 → 设计收敛门口头收敛即可 |
| **Full Path** | SDD 落 `docs/design/<domain>/SDD-<topic>.md`；ADR 落 `docs/design/<domain>/ADR-<topic>.md` |

---

## G3 Task Contract Gate — 任务契约门

| 字段 | 内容 |
|------|------|
| **Trigger** | Full Path 且涉及接口、字段、SQL、权限、状态机、跨模块 |
| **Owner Skill** | `ai-development-governance`（模板）→ `delivery-workflow` §实现切分门 |
| **Required Inputs** | Spec + 设计/ADR |
| **Required Outputs** | Task Contract（见 `templates/TEMPLATE_TASK_CONTRACT.md`）；触发跨项目时补 Project Contract Gate |
| **Blockers** | 范围白名单 / 禁止改清单 / 验收标准缺任一项 → 不派子 Agent |
| **Fast Path** | 单文件小改 → 口头范围即可 |
| **Full Path** | 书面 Task Contract；可并存于 plan 或项目技能 `references/meta/*_contract.md` |

---

## G4 Implementation Gate — 实现执行门

| 字段 | 内容 |
|------|------|
| **Trigger** | G1–G3 已过（或 Fast Path 已完成轻量产物） |
| **Owner Skill** | `delivery-workflow` + 项目领域技能 |
| **Required Inputs** | Task Contract 或 Fast Path 微设计；Review PASS；绑定 task/hash/精确文件范围的写入许可证；checkpoint 协议 |
| **Required Outputs** | 代码 / 配置 / SQL 改动 |
| **Blockers** | 无有效写入许可证或未输出 R1 → 禁止改代码；R1 不能替代许可证 |
| **Fast Path** | 单闭环推进 |
| **Full Path** | 最小闭环切分 + 子 Agent 7 要素 prompt |

---

## G5 Quality Gate — 质量验证门

| 字段 | 内容 |
|------|------|
| **Trigger** | 任一实现闭环完成；交付前 |
| **Owner Skill** | `delivery-workflow` §验证完成门 + [quality_gate.md](quality_gate.md) + [code_review_gate.md](code_review_gate.md) |
| **Required Inputs** | 已冻结契约 |
| **Required Outputs** | 主链路 + 失败链路 + 回归验证证据 + 代码审查记录；Full Path 补主链证据矩阵 |
| **Blockers** | 主链路未验证；「接口 200 但缺数据」未做三联检；代码审查未过 |
| **Fast Path** | 最小验证命令 + 手动冒烟 + code_review 最小检查（命名+错误处理+安全内建） |
| **Full Path** | 完整 quality_gate + code_review_gate 清单；按需补目标 / 工程 / 评审 / 验证等多视角反证证据 |

---

## G6 Security Gate — 安全合规门

| 字段 | 内容 |
|------|------|
| **Trigger** | 见 [security_gate.md](security_gate.md)；涉及 UGC/交互/短信时同时触发 `biz-safety-audit` |
| **Owner Skill** | `ai-development-governance`（开发安全）+ `biz-safety-audit`（业务安全） |
| **Required Inputs** | 改动范围与数据流 |
| **Required Outputs** | Security Gate 勾选记录 + 业务安全审计结论（若触发） |
| **Blockers** | 权限/租户/敏感数据未覆盖 → 禁止上线；业务安全 P0 项未覆盖 → 禁止上线 |
| **Fast Path** | 纯 UI 文案、无数据流、无 UGC/交互/短信 → 可跳过 |
| **Full Path** | 完整 security_gate + biz-safety-audit 对应路由清单 |

---

## G7 Release / Rollback Gate — 发布回滚门

| 字段 | 内容 |
|------|------|
| **Trigger** | 准备合并、发版、上线 |
| **Owner Skill** | `ai-development-governance` + `doc-script-governance`（文档落位） |
| **Required Inputs** | 已通过 G5；涉及安全则已通过 G6 |
| **Required Outputs** | Release Evidence：Release 检查 + Rollback 资产 + 观察窗口 / 观察入口 / 回滚触发条件 |
| **Blockers** | 无回滚路径；online SQL 由 Agent 直接写入 |
| **Fast Path** | 开发环境 / 个人分支 → 轻量化 |
| **Full Path** | [release_gate.md](release_gate.md) + [rollback_gate.md](rollback_gate.md) + [observability_gate.md](observability_gate.md)；不新增独立 `release-ops-runbook` |

**文档落位**：Release / Rollback Plan → `docs/plan/<domain>/` 或验收记录 → `docs/review/<domain>/`

---

## G8 Learning Gate — 失败沉淀门

| 字段 | 内容 |
|------|------|
| **Trigger** | 失败、回滚、返工、评分低于 98 |
| **Owner Skill** | `delivery-workflow` R3 |
| **Required Inputs** | 根因分类（需求/设计/契约/切分/验证/治理） |
| **Required Outputs** | Task Replay Lite 结论 + insight / 反模式 / hub prompt / governance checklist / scorecard 回填 |
| **Blockers** | 只写「下次注意」→ 门未过 |
| **Fast Path** | 一次性环境问题 + 明确原因 → 对话说明即可 |
| **Full Path** | 三路分流 + 若暴露治理缺口回填 [governance_checklist.md](governance_checklist.md) 或 [scorecard.md](scorecard.md)；同类返工形成 Skill Health Signal，回填 bad smell / trigger eval / scorecard，不新增 dashboard；过程稿完成后必须 archive / 回灌 / 标注 blocked |

---

## 与 delivery-workflow 映射

| delivery-workflow 阶段门 | 本文件阶段门 |
|--------------------------|--------------|
| 1. 需求理解门 | G0 + G1 |
| 2. 设计收敛门 | G1 + G2 |
| 3. 实现切分门 | G3 + G4 |
| 4. 验证完成门 | G5 (+ G6 若适用) |
| 5. 失败沉淀门 | G8 |
| 5.1 设计整合门 | G7 前置（文档归档） |
| checklist 路由 | G5 + G7 |
