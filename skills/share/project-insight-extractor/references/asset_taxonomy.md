# TechInsightVault 分类

推荐根目录：

```text
$AGENTS_HUB_ROOT/TechInsightVault/
```

public 用户可自建同构的 insight vault 目录，并通过 `INSIGHT_VAULT_ROOT` 指向该根；无需在 public 仓内自带真实 `TechInsightVault/`。若当前环境没有可写 vault，按 `SKILL.md` 主文件退回 `draft-only`。

## 分类规则

| 目录 | 用途 |
|---|---|
| `00_inbox/` | 临时输入，未提炼的对话、日志、diff、复盘材料 |
| `01_case_library/` | 结构化技术案例卡，按技术方向分类 |
| `02_interview_bank/` | 1 分钟/3 分钟面试表达、追问准备 |
| `03_resume_bullets/` | 简历 bullet 素材库，按岗位或能力分类 |
| `04_methodology/` | 可复用方法论、排查框架、决策原则 |
| `05_article_drafts/` | 文章、对外连载、分享稿素材 |
| `06_review_reports/` | 周/月度复盘、阶段性成长报告 |
| `indexes/` | 唯一知识点索引、标签表、重复候选 |
| `templates/` | 输入模板、技术资产卡模板 |

## 案例库二级分类不是类型全集

`01_case_library/` 下默认按能力域分类，但这只是初始视图，不是封闭枚举。

| 子目录 | 内容 |
|---|---|
| `rag/` | RAG、向量检索、chunk、rerank、context 治理 |
| `nl2sql/` | 智能问数、schema linking、SQL 生成、幻觉控制 |
| `agent_skill/` | Agent、工具调用、memory、planning、skill 工程 |
| `architecture/` | 架构重构、边界拆分、抽象收敛、技术债治理 |
| `performance/` | 性能优化、并发、缓存、成本、吞吐 |
| `frontend_backend/` | 前后端联调、契约、复杂交互回归 |
| `engineering_governance/` | 脚本化、编码治理、交付流程、质量门禁 |
| `cross_domain/` | 跨域资产，尚不适合放入单一能力域 |

新领域出现时，优先更新 `indexes/TAG_REGISTRY.md`，确认稳定后再新增目录。

## 文件命名

事实源文件名必须稳定，默认直接使用 canonical_id：

```text
<canonical_id>.md
```

示例：

```text
TI-nl2sql-case-schema-linking-accuracy.md
```

日期只写入 front matter 的 `created` / `updated` 字段，不进入文件名，也不进入 canonical_id。否则同一资产在不同日期会被误判为新资产。

派生表达文件使用语义名，不加日期：

```text
interview-rag-engineering-upgrade.md
resume-rag-and-skill-assets.md
```

## asset_type → 目录硬映射

**事实源文件（canonical asset）按 asset_type 严格路由，无需判断：**

| asset_type | 目标目录 |
|---|---|
| `capability_build` | `01_case_library/<domain>/` |
| `architecture_pattern` | `01_case_library/<domain>/` |
| `debug_pattern` | `01_case_library/<domain>/` |
| `case` | `01_case_library/<domain>/` |
| `anti_pattern` | `01_case_library/<domain>/` |
| `delivery_pattern` | `01_case_library/<domain>/` |
| `principle` | `04_methodology/` |
| `decision_model` | `04_methodology/` |

**派生表达文件路由（在事实源写完后必须同步创建）：**

| 派生类型 | 目标目录 | 文件名格式 |
|---|---|---|
| `interview_story` | `02_interview_bank/` | `interview-<topic>.md` |
| `resume_bullet` | `03_resume_bullets/` | `resume-<domain>.md` |
| `article_seed` | `05_article_drafts/` | `article-<topic>.md` |

## 归档原则

- 原始材料先放 `00_inbox/`，提炼后再移动到目标目录。
- 每个 canonical asset 只表达一个核心洞察，避免巨型复盘文。
- 事实源文件是唯一权威，派生表达从事实源提取，不另立事实源。
- 不确定收益不写成事实，先放待补证。
- 分类是标签和索引问题，不靠复制文件解决；同一知识点只保留一个事实源。

## 直接归档规则

- 默认直接写入当前 insight vault 根目录（优先 `INSIGHT_VAULT_ROOT`，其次私有 hub 默认 `TechInsightVault/`），不能停在候选路径说明。
- 新 canonical_id：创建事实源文件，更新 `indexes/KNOWLEDGE_INDEX.md`，并跑 `build-tech-insight-index.*` 更新机器索引。
- 已存在 canonical_id：先按 `doc-script-governance` 备份旧事实源，再按 `deduplication.md` 融合更新，最后跑 `build-tech-insight-index.*`。
- 面试表达写入 `02_interview_bank/`，简历表达写入 `03_resume_bullets/`，但事实源仍以 `01_case_library/` 或 `04_methodology/` 的 canonical asset 为准。
- 只在用户明确要求 `dry-run`、`不写文件` 或 `仅预览` 时，才不写入文件；这类输出必须标记为预览结果。
