# 去重与唯一知识点

目标：分类知识点唯一，重复内容只合并，不复制。

## 唯一性原则

每个 canonical asset 只保留一个事实源文件。目录、标签、面试表达、简历 bullet 都是视图或派生物。

重复资产默认**融合更新**，禁止直接覆盖旧文件。

## canonical_id

推荐格式：

```text
TI-<domain>-<type>-<slug>
```

**slug 命名约束**：
- 英文小写 kebab-case，不超过 5 个词
- 只用字母和连字符，**不含数字、不含年份**（年份会随场景变化，导致同一洞察被创建为不同 ID）
- 优先选择问题或机制词，不选"fix" / "improve" / "update"等泛词
- 示例：`schema-linking-accuracy` ✓，`fix-schema-linking-accuracy-issue-2026` ✗

**年份归属**：年份记录在资产 front matter 的 `created` 字段，不进入 canonical_id。

示例：

```text
TI-nl2sql-case-schema-linking-accuracy
TI-rag-arch-recall-quality-gating
TI-engineering-principle-sample-first-codemod
TI-architecture-debug-orm-inheritance-capture
```

**错误示例**（不要这样写）：
```text
rag-observability-eval-system-2026   ← 有年份，且缺少 TI- 前缀
TI-rag-arch-rag-observability-2026   ← 有年份
```

## 去重判断

入库前检查四个维度：

| 维度 | 判断 |
|---|---|
| 问题是否相同 | 是否解决同一类问题 |
| 根因是否相同 | 是否来自同一约束或缺陷 |
| 方案是否相同 | 是否采用同一关键机制 |
| 方法论是否相同 | 是否沉淀同一条原则 |

处理策略：

- 4 项高度一致：`merge_into:<canonical_id>`，融合新证据、新表达和新源锚点，不新建文件
- 2-3 项一致但证据更强：`update:<canonical_id>`，备份旧文件后融合更新
- 问题相似但根因/方案不同：新建 asset，并互相 cross-link
- 只共享标签：不算重复

## 融合更新规则

融合不是覆盖：

- 保留旧资产的 canonical_id、created、历史证据和已验证事实。
- 新内容补充到 evidence、source_anchor、validation、interview_expression、resume_bullets 或 method sections。
- 如果新内容只是表达更好，只更新派生表达，不改事实源结论。
- 如果新内容与旧事实冲突，不覆盖；写入 `indexes/DUPLICATE_REVIEW.md` 或资产内的"冲突与待确认"。
- 每次融合必须记录 `updated` 和简短变更说明。

## 索引文件

TechInsightVault 下维护：

- `indexes/assets.index.json`：**机器索引（去重唯一性校验首选）**，由 `build-tech-insight-index.*` 生成；canonical_id 稳定、可程序比较，不可手改
- `indexes/KNOWLEDGE_INDEX.md`：人类浏览总表（辅助参考，手动维护）
- `indexes/TAG_REGISTRY.md`：标签和领域词表
- `indexes/DUPLICATE_REVIEW.md`：疑似重复待确认

**去重判定优先级**：先查 `assets.index.json`（精确 canonical_id 匹配），再用 `KNOWLEDGE_INDEX.md` 辅助语义核查。

## 冲突处理

- 旧资产有事实错误：更新旧资产，记录修正原因。
- 新资产只是表达更好：更新派生表达，不新建事实源。
- 新资产证据更完整：合并证据，保留一个 canonical_id。
