# 技能反模式回填分支

> 当源材料中出现「Agent 反复犯错」模式时，**除了**面向人的洞察资产，**额外**输出一个面向 Agent 的「反模式回填卡片」，建议回填到对应 `SKILL.md` 或反模式表。
> 与主流程互补：[../SKILL.md](../SKILL.md) 主流程产出面向人的认知洞察；本分支产出面向 AI Agent 的触发约束。
>
> **总闸门**（何时必须走本分支 vs 纯 insight vs hub prompt）：见 `delivery-workflow` 的 **R3 失败沉淀三路分流**（与「失败沉淀门」同一收口）。反模式卡片 ≠ `*.prompt.md`；可重复执行的子 Agent 指令 → `prompt-engineering`。

资产类型与「可提炼 / 丢弃」边界见 [asset_types.md](asset_types.md)（尤其 `rule_fix` / `anti_pattern`）。

## 触发条件

源材料中**同时**满足以下两条 → 启动反模式回填分支：

1. 描述了一次「Agent 错误执行 → 用户纠正」的过程
2. 用户纠正的内容是**类规则**（即同类问题未来还会发生），而非一次性 bug

例如：

- ✅ 「AI 又给我 record 写 Cmd，我都说过几次了」→ 反模式（record 用于继承链）
- ✅ 「为啥 listener 又放 infra 了」→ 反模式（监听器位置错位）
- ❌ 「这个 SQL 性能不好，索引加 ABC」→ 一次性优化，不进反模式表

## 反模式回填卡片模板

```yaml
anti_pattern_id: <模块-序号，如 AI-08 / BI-11 / GENERAL-19>
trigger: |
  <Agent 一句话现象，让其他 Agent 能识别此模式>
root_cause: |
  <为什么 Agent 容易这样做>
correct_pattern: |
  <正确做法 1-2 句>
target_skill: |
  <要回填到哪个 SKILL.md 或 references/anti_patterns*.md>
heart_method_anchor: |
  <对应 architecture_philosophy.md 的心法编号，找不到说明心法需要扩>
evidence:
  - source_anchor: <transcript URI 或 chat 行号>
  - user_quote: |
      <用户原话，最能说明问题的一句>
```

## 输出位置（与主流程产物的关系）

| 产物 | 受众 | 默认归档位置 |
|---|---|---|
| 认知洞察资产卡片 | 人（面试 / 简历 / 案例库）| `TechInsightVault/<分类>/` |
| **反模式回填卡片**（本分支）| Agent | 输出**建议路径**给主模型，由主模型决定是否回填 |

**禁止**：自动改 `SKILL.md` / `anti_patterns*.md`（这些是项目治理产物，回填由主模型评审后下手）

## 与主流程的协作

主流程 SOP（见 [../SKILL.md](../SKILL.md) 中最小 SOP）第 4 步识别 `asset_type` 时：

- 资产 type 为 `bug_fix` / `规范违反` 的，本来主流程是**丢弃**（与 [asset_types.md](asset_types.md) 中 `rule_fix` 一致）
- 但如果**同时**触发本分支条件（反复犯错模式），则**不丢弃**，转入本分支输出反模式回填卡片

## 示例

```yaml
anti_pattern_id: BI-01
trigger: |
  写 BiTableConfigCmd 这类需要解密外键 strId 的 Cmd 时，覆盖父类同名 getter 并 fallback 调用自身
root_cause: |
  Agent 想做"strId 非空就解密，为空就 fallback 父类"的双路径，写出 `return this.getTableConfigId()` 递归
correct_pattern: |
  字段名分离（tableConfigStrId vs id），getter 内只调 SignUtil.getLongId() 直接解密，无 fallback
target_skill: |
  <backend-domain-skill>/references/anti_patterns_<domain>.md（示例：BI-01 已收录）
  <backend-domain-skill>/references/ddd/anti_patterns_quickref.md（AP-14 已收录）
heart_method_anchor: |
  architecture_philosophy.md — Cmd/Query 防腐层（与项目 DDD 文档对齐）
evidence:
  - source_anchor: <chat-uuid>:<line>
  - user_quote: |
      "BiTableConfigCmd 中 getTableConfigId 调 this.getTableConfigId 是死循环"
```
