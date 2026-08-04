# doc-script-governance

文档、SQL、脚本与技能参考资料的治理：放置、命名、备份、编码与引用规则。

> **与 delivery-workflow 协作** → `rules/common/COMMON_AGENT_RULES.md` §研发全流程（Agent）；人读详述见 [../README.md](../README.md)

## 修订记录

| 版本 | 日期 | 修订要点 |
|------|------|----------|
| 1.5.0 | 2026-07-30 | 统一项目文档修订记录倒序契约：最新记录置顶，新增记录插入表格首行；同步主技能、规范示例与检查清单 |
| 1.4.0 | 2026-06-04 | 明确 hub skill references 的 material change 才强制更新根 README 修订记录 |
| 1.3.0 | 2026-05-21 | 通用双技能协作迁至 share/README；去掉项目绑定 |
| 1.2.0 | 2026-05-21 | references 无 YAML；模板在根 templates/ |
| 1.0.0 | — | 首版章程 |

## 核心要点

- **目录模型**：design / plan / implementation / review / config / db/dev / db/online；终版与重构分目录。
- **模板真源**：本技能根 `templates/` + `references/document_types_and_templates.md`。
- **改前 backup**：`backup-file`；**项目 docs** 改后 YAML + §修订记录；**hub skill references/** 无自身修订表，material change 更新技能根 README §修订记录。
- **修订顺序**：修订/版本/变更记录始终倒序，最新记录置顶；新增记录插入表格首行。
- **online SQL 只读**：Agent 不得写入 `docs/db/online/`。

## 关键 references

| 文件 | 用途 |
|------|------|
| `references/document_types_and_templates.md` | 类型 ↔ 目录 ↔ 模板 |
| `references/rd_lifecycle_doc_placement.md` | 阶段门与 docs 放置 |
| `references/document_revision_metadata.md` | **项目 docs** 修订表（非 references 正文） |
| `references/rules.md` | 禁止事项 |
| `references/checklist.md` | 改前改后自检 |
| `references/trigger_eval.md` | should-trigger / should-not-trigger、放置入口回归 |
| `references/closure_example.md` | 真实备份 + 放置 + 校验闭环样例 |

## 不负责 / 转交

| 场景 | 转交 |
|------|------|
| 研发阶段门、能否写代码 | `delivery-workflow` |
| skill 结构与目录布局 | `skill-engineering` |
| hub 挂载 | `agent-hub-bootstrap` |
| 业务实现 | 各仓库 **项目领域技能** |
