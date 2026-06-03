# project-insight-extractor

## 定位

从 AI 编程过程、调试记录、重构决策与代码变更中提炼**给人读**的技术洞察资产（insight vault，如 TechInsightVault、面试表达、简历 bullet、方法论）。

## 核心要点

- **产物给人读**：案例卡、面试叙事、方法论；不是给 Agent 执行的长 prompt 或 SKILL 正文。
- **默认落盘 insight vault**：优先 `INSIGHT_VAULT_ROOT`；未设置时私有 hub 默认 `$AGENTS_HUB_ROOT/TechInsightVault/`；两者都不可用则只输出草案。
- **证据约束**：不编造收益/指标；不把规则复述当洞察。
- **Deliverable Gate**：主交付为 SKILL/doc 放置表 → 转 skill-engineering / doc-script，不进 Vault。
- **双轴评分**：`vault_worthy` + `expressibility`；治理会话最多 1 张 canonical。
- **R3 分流**：Agent 反模式回填见 `skill_anti_pattern_feedback.md`；可执行长指令转 `prompt-engineering`。

## 关键 references

| 文件 | 用途 |
|------|------|
| `references/value_lens.md` | Deliverable Gate、域准入、双轴评分、深度 L1–L4 |
| `references/source_material_qualification.md` | 源材料资格与 `source_role × target_scope` 决策 |
| `references/extraction_contract.md` | 提炼契约与输出结构 |
| `references/deduplication.md` | 去重与融合 |
| `references/cursor_session_access.md` | 历史会话读取 |
| `references/skill_anti_pattern_feedback.md` | 与 skill 规则回填的分流 |
| `references/eval/trigger_eval.md` | should-trigger / should-not-trigger、洞察入口回归 |
| `references/eval/closure_example.md` | Vault 不可写时的 `draft-only` 样例 |

## 协作入口

| 场景 | 转交 |
|------|------|
| 子 Agent 可复用长指令 | `prompt-engineering` |
| SKILL.md 创建/审查 | `skill-engineering` |
| 研发失败沉淀总闸门 | `delivery-workflow` R3 |
