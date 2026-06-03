# 输出模板

## 标准输出

```markdown
## 能力资产卡片

<!-- 每张卡片输出前自检三条：
     1. 标题能否回答"这个问题为什么不显而易见"？
     2. 决策字段有没有明确说"放弃了什么替代方案及原因"？
     3. 方法论字段是否可以在其他项目里复用？
     4. architect_view 是否为 policy_only？是 → 丢弃或转交，不写 Vault
     5. vault_admit 是否为 yes？merge_only 只更新已有 canonical 脚注
     三条中有两条答不上来 → 重写或丢弃，不是流水账修饰
     每次输出 2–5 张 -->

### 卡片 1：...
- **source_anchor**：（材料来源：当前会话 / 历史 transcript / 用户粘贴 / 文件路径）
- **source_role**：`archive_source` / `evaluation_sample` / `counterexample` / `skill_improvement_evidence`
- **target_scope**：`domain_asset`（写入 01_case_library/04_methodology）/ `skill_improvement_asset`（写入 skill 改进目录）
- **architect_view**：`strong` / `weak` / `policy_only`
- **vault_admit**：`yes` / `merge_only` / `no`（`no` 时写转交：`skill-engineering` / `doc-script-governance` / `prompt-engineering`）
- **depth_level**：L1 / L2 / L3 / L4
- **score_vault_worthy**：1–10
- **score_expressibility**：1–10
- **asset_type**：（按 asset_types.md 分类）
- **价值陈述**：（一句话说清楚"这个资产体现了什么能力 / 带来什么成长 / 创造什么业务价值"）
- **关键难点**：（为什么这个问题不显而易见 / 普通工程师容易走哪个错误方向 / 什么隐式约束让普通方案失效）
- 问题：（真实现象，不是"想做什么"）
- 根因：（为什么表面修复不够，深层机制是什么）
- 决策：（选了什么方向 + 明确说明放弃了哪些替代方案及原因）
- 方案：（关键技术机制，不是步骤列表）
- 验证：（如何确认有效，有什么证据）
- 收益：（可量化写指标；不可量化写"已验证现象 / 待补充指标"）
- 方法论：（可迁移原则：适用于哪类场景 + 识别信号 + 应对策略）
- 证据等级：fact / assumption / unknown

## 面试表达（1 分钟）
...

## 简历表达
- ...

## 归档结果
<!-- write_action 的合法性由 source_role × target_scope 共同决定。
     完整 5 行决策表见 source_material_qualification.md § target_scope 决策规则，此处不再重复维护副本。 -->
- canonical_id：
- asset_type：
- source_anchor：（材料来源：当前会话 / 历史 transcript / 用户粘贴 / 文件路径）
- source_role：`archive_source` / `evaluation_sample` / `counterexample` / `skill_improvement_evidence`
- target_scope：`domain_asset` / `skill_improvement_asset`
- write_action：`created` / `merged` / `updated` / `unchanged` / `not_archived`
- 事实源路径：`TechInsightVault/<目录>/<canonical_id>.md`（路由规则见 asset_taxonomy.md）
- 面试表达：`TechInsightVault/02_interview_bank/interview-<topic>.md`
- 简历表达：`TechInsightVault/03_resume_bullets/resume-<domain>.md`
- 机器索引：跑 `build-tech-insight-index.*` → `TechInsightVault/indexes/assets.index.json`（脚本生成，禁止手改）
- 人类视图：`TechInsightVault/indexes/KNOWLEDGE_INDEX.md`（可选，手动更新）
- 待补充证据：
```

## 技术资产卡模板

```markdown
---
title:
canonical_id:
asset_type:
domain:
tags:
source:
evidence_level:
duplicate_of:
depth_level:
score_vault_worthy:
score_expressibility:
vault_admit:
created:
updated:
---

# 背景

# 问题

# 根因

# 决策

# 方案

# 验证

# 收益

# 方法论

# 面试表达

# 简历表达

# 证据与待补充

# 重复关系
```

## 简历 bullet 规则

优先使用：

```text
负责/主导 + 场景 + 技术动作 + 可验证结果
```

示例：

```text
- 主导智能问数链路优化，通过 schema linking 收敛候选表字段范围，将复杂 SQL 生成准确率从 55% 提升到 78%。
```

没有量化指标时：

```text
- 负责 RAG 检索链路治理，建立召回参数、上下文裁剪和验证闭环，降低多轮排查成本并提升问题定位效率。
```

## 面试表达规则

**默认输出 1 分钟版**。用户说"给我 3 分钟版""深入讲一下"时，补充 3 分钟版。

**1 分钟表达（默认）**：

```text
我在什么场景下遇到什么问题。
最初现象是什么，为什么不能只靠表层修复。
我如何定位根因，做了什么关键决策。
最终方案如何落地，怎么验证。
这个经历沉淀出什么方法论。
```

**3 分钟表达（用户明确请求时）**：在 1 分钟结构基础上扩展：

```text
[背景] 项目阶段、团队角色、业务目标
[问题] 具体现象，量化规模（行数/耗时/成功率）
[排查] 排查路径，如何排除其他假设，定位过程
[决策] 比较了哪些方案，放弃了什么，为什么选这个
[落地] 关键实现细节，遇到的障碍和处理方式
[验证] 验证方法，指标或现象，复现/消除的过程
[收益] 可量化的改进，或"已验证现象 / 待补充指标"
[方法论] 这次经历的可迁移原则，适用于哪类场景
```

## 可选视图：知识点摘要 + 方法论汇总

<!-- 默认不输出。仅当用户明确要求以下任一时才生成：
     "生成复盘报告" / "周报素材" / "简历素材筛选" / "方法论汇总" -->

```markdown
## 关键知识点摘要
<!-- 每条一行，引用对应卡片的"关键难点 + 价值陈述" -->
- [领域] 一句话：为什么这个问题不显而易见，以及它体现了什么能力
- ...

## 方法论汇总
<!-- 每条一行，引用对应卡片的"方法论"字段 -->
- [领域] 可迁移原则：适用场景 + 识别信号 + 应对策略
- ...
```
