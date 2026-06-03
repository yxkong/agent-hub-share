# 示例

## 输入

```text
做智能问数系统时，生成 SQL 准确率低，多表 join 经常错。
单纯优化 prompt 效果一般。
后来引入 schema linking，只保留相关表和字段。
准确率从 55% 提升到 78%。
```

## 输出

### 关键知识点

- NL2SQL 的复杂查询准确率，往往取决于结构约束而不是提示词长度。
- 通过 schema linking 缩小候选表和字段范围，可以降低模型搜索空间。

### 能力资产卡片

- 问题：多表 SQL 生成错误率高。
- 根因：模型面对完整 schema 时缺少结构约束，候选空间过大。
- 决策：从 prompt 调优转向 schema linking。
- 方案：先筛选相关表字段，再把收敛后的 schema 输入模型。
- 验证：SQL 生成准确率从 55% 提升到 78%。
- 收益：复杂查询准确率提升 23 个百分点。
- 方法论：结构化生成任务优先收敛搜索空间，再优化提示词。
- 证据等级：fact。

### 面试表达

在智能问数项目中，我发现多表 SQL 的生成准确率比较低，单纯加 prompt 效果有限。继续排查后，我判断根因是模型面对完整 schema 时缺少结构约束，候选表和字段过多。于是我把优化方向从提示词调整切到 schema linking，先筛出相关表字段，再交给模型生成 SQL。最终准确率从 55% 提升到 78%。这件事给我的方法论是：结构化生成任务要先做约束和搜索空间收敛，再做 prompt 优化。

### 简历表达（按需输出）

- 负责智能问数 SQL 生成链路优化，通过 schema linking 收敛候选表字段范围，将生成准确率从 55% 提升到 78%。

### 归档结果

> 此例 asset_type = `case`，路由说明见下方速查表。

- 事实源：`TechInsightVault/01_case_library/nl2sql/TI-nl2sql-case-schema-linking-accuracy.md`
- 面试表达：`TechInsightVault/02_interview_bank/interview-nl2sql.md`（追加章节）
- 简历表达：`TechInsightVault/03_resume_bullets/resume-ai-engineering.md`（追加 bullet）

### 归档路由速查（按 asset_type）

完整规则见 `asset_types.md`，此处给出典型示例：

| asset_type | 事实源归档目录 | 文件名示例 |
|---|---|---|
| `case` / `debug_pattern` / `capability_build` / `architecture_pattern` / `delivery_pattern` / `anti_pattern` | `01_case_library/<domain>/` | `TI-nl2sql-case-schema-linking-accuracy.md` |
| `principle` / `decision_model` | `04_methodology/` | `TI-ai-principle-output-layer-separation.md` |
| `article_seed` | `05_article_drafts/` | `TI-rag-article-observability-design.md` |
| `interview_story`（派生） | `02_interview_bank/` | `interview-rag-engineering.md` |
| `resume_bullet`（派生） | `03_resume_bullets/` | `resume-ai-engineering.md` |

---

## 反例：交付清单不要逐项提炼规则违规

输入是 RAG 交付清单时，下面这些不是高价值输出：

- "某字段没有透传，所以要补字段"
- "某开关没有生效，所以要修条件判断"
- "某状态没有展示，所以要补 tooltip"

这些只能说明规则或实现不完整。正确做法是聚合为能力资产：

- RAG 评测与可观测性体系
- RAG 质量门控体系
- RAG 可信引用与可解释体验
- 知识库运维健康闭环
