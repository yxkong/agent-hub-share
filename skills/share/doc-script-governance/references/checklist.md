# 文档与脚本治理检查清单

## 改前（动手编辑前）

- [ ] 已确认文档类型与目录（见 [document_types_and_templates.md](document_types_and_templates.md)、[rd_lifecycle_doc_placement.md](rd_lifecycle_doc_placement.md)）
- [ ] 新建文档已从本技能根 `templates/` 复制模板（非 `references/templates/`、非项目 `docs/guide/templates`）
- [ ] 已确认文档类型：终版 `design` / 过程 `plan` / `review` / 技能（见 [design_doc_lifecycle.md](design_doc_lifecycle.md)）
- [ ] 已调用标准 `backup-file`，且控制台有 `LATEST_BACKUP` / `ARCHIVE_BACKUP`
- [ ] 未用裸 `cp` 代替脚本

## 改后（保存主文件后）

### 元数据与修订记录（仅项目 docs / SQL / 落地后的 TEMPLATE 目标文件）

见 [document_revision_metadata.md](document_revision_metadata.md) §0。改 **hub 技能 `references/`** 时跳过本节；是否更新根 [README.md](../README.md) §修订记录按下方 “改 hub 技能 references 后” 判定。

- [ ] YAML 含 `created`（新建或已补录，且未伪造历史）
- [ ] YAML `updated` = **本次**修改日期
- [ ] YAML `version` 与修订表**最新行版本**一致
- [ ] 存在 `## 修订记录` 章节，且已**追加**一行（非仅改旧行）
- [ ] 「修订要点」说明**对象 + 变化**（非「更新文档」）
- [ ] 可选：修订表「备份/引用」列含当次 `ARCHIVE_BACKUP` 相对路径
- [ ] 未用文件名后缀表达版本（无 `_20260521` 式终版名）

### 改 hub 技能 references 后

- [ ] 未在 `references/*.md` 增加 YAML 或 §修订记录
- [ ] 若属于 material change（改变 trigger、门禁、目录、流程、公共行为），根 `README.md` §修订记录已追加一行；纯错字 / 格式修正可在汇报中说明无需追加

### 文档资产

- [ ] 业务设计在 `docs/design/<domain>/`
- [ ] 实现在 `docs/implementation/<language>/<domain>/`
- [ ] review 在 `docs/review/<domain>/`
- [ ] 计划在 `docs/plan/<domain>/`
- [ ] 未新增 `docs/design/review/` 路径
- [ ] canonical 设计已维护 `related` 或 §相关文档，且域 `README.md` 已同步（若为本域首份终版）

### 备份与回退

- [ ] `bak/_<文件名>` 与 `bak/yyyyMM/...` 已生成
- [ ] 若备份对象为 `SKILL.md`：归档在 `bak/yyyyMM/SKILL_md/`，且 `bak/**` 下**无**第二个名为 `SKILL.md` 的文件（跑 `check-skill-entrypoints` 应为 ok）
- [ ] 若用 git：仅 stage 本次目标文件

### 过程 → 终版整合（若适用）

- [ ] plan 最后一行修订写清「并入终版路径 + 终版版本」
- [ ] 终版修订表追加「整合 xxx plan」一行
- [ ] plan `status: done` 或已归档

### SQL

- [ ] 开发期 SQL 在 `docs/db/dev/<module>/`
- [ ] 未改 `docs/db/online/`
- [ ] 模块有 `mysql57_dev_final.sql` 且非空指针
- [ ] SQL 头注释含本次 `updated` 与变更一句话

### 技能（hub 真源）

- [ ] 目录模型与 `skill-engineering` → `skill_directory_layout.md` 一致（根 `templates/`）
- [ ] 改 `SKILL.md` front matter 时，README §修订记录已同步说明

## 治理总线协作（若适用）

端到端研发任务中，文档落位完成后可配合 `ai-development-governance/references/governance_checklist.md` 做 scorecard 自评；Spec/ADR/Release 目录见 [rules.md](rules.md) §1。
