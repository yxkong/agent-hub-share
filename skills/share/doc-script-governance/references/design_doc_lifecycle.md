# 终版设计 vs 过程设计（文档生命周期）

> 配合 `delivery-workflow` 设计收敛门、验证完成门使用。

## 1. 分类

| 类型 | 目录 | 命名 | 文首 metadata |
|------|------|------|----------------|
| **终版设计** | `docs/design/<domain>/` | `TOPIC_DESIGN.md` 或 `TOPIC_ARCHITECTURE.md`，**禁止** `_YYYYMMDD` | `status: canonical` |
| **过程设计** | `docs/plan/<domain>/` | `*_PLAN.md`、`*_EXECUTION_*.md`、可带日期 | `status: in_progress \| done` |
| **Review** | `docs/review/<domain>/` | 验收/审计 | — |
| **已替代的过程稿** | 原路径保留 **supersede 入口** | 旧名可保留，正文改为指向终版 | `status: superseded` |

**误判来源**：`docs/design/**/*_20260517.md` 看起来像临时稿，实为未整合的过程设计 — 应 supersede 或迁入 `plan/` / `bak/`。

## 2. 整合流程（过程 → 终版）

1. **过程稿**在 `docs/plan/` 推进，结论稳定后写入/更新 **终版**（合并、删重、补图/契约表）。  
2. **修订记录双写**（[document_revision_metadata.md](document_revision_metadata.md) §7）：  
   - 终版：追加修订行（写清并入来源 plan、变更章节）；`updated` + `version` 递增。  
   - plan：最后一行写「已并入 `<终版路径>` vX.Y」；`status: done`。  
3. 旧 `design/*_日期.md` → supersede 短页；**改前** `backup-file`；修订表一行「supersede by …」。  
4. **Agent 契约**进项目技能 `references/meta/`；design 只保留背景与拓扑。  
5. 实现完成后：更新终版 §实现状态；plan 不得与终版长期双真源。

## 3. 索引

- 模块索引示例：`docs/design/ai/README.md`  
- 改 trace：`<project-skill>` → `trace_phase_contract.md`

## 4. 禁止

- 在 `docs/design/` 新增带日期的「终版」文件名  
- 过程结论只留在 plan、不反哺终版  
- 终版与技能契约矛盾（以 **技能契约 + 代码** 为准，先改契约再改代码）
