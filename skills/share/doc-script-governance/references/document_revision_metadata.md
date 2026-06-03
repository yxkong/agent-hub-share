# 文档元数据与修订记录（强制）

> 人读真源 = **主文件正文 + 文首元数据 + §修订记录**；机读回退 = **bak 归档 +（可选）git**。三者互补，不可替代。

## 0. 适用范围（必读）

| 资产 | YAML + §修订记录 | 变更历史写哪 |
|------|------------------|--------------|
| **项目** `docs/`、`docs/db/` 等 | **强制** | 该文件正文 |
| **项目** `.claude/skills/.../references/meta/*_contract.md` | **强制**（可执行契约） | 该文件正文 |
| **Hub 技能** `references/*.md`（治理规则） | **不要**（省 Agent 上下文） | 技能根 **`README.md` §修订记录**（人读） |
| **Hub 技能** `SKILL.md` | 仅 front matter `name`/`description`；无 §修订表 | 同上 README |
| 复制到项目的 **`templates/TEMPLATE_*`** | 复制**后**在项目文件内按本节填写 | 项目目标路径 |

改 hub 技能 `references/` 前仍须 `backup-file`；不必在 reference 正文追加修订表。

## 1. 三层可追溯

| 层 | 载体 | 回答的问题 | 是否强制 |
|----|------|------------|----------|
| **修订记录** | 主文件内 `## 修订记录` 表 + YAML `version`/`updated` | 改了什么、为什么改 | **是**（见 §0 适用表） |
| **文件备份** | 同级 `bak/_<文件名>` + `bak/yyyyMM/.../<时间戳>` | 改前全文长什么样 | **改前是**（`backup-file`） |
| **版本库** | git commit / diff | 谁改的、与哪些代码同批 | 推荐，不替代前两列 |

**禁止**：只有 bak、没有修订表；只有 git、文首无 `updated`；用文件名 `_v2` / `_20260521` 代替修订记录。

## 2. YAML 文首（design / plan / review / config）

### 2.1 必填字段

```yaml
---
title: <中文标题>
status: canonical | in_progress | done | superseded
version: <主版本>.<次版本>   # 语义见 §4
created: YYYY-MM-DD          # 创建日，全生命周期只写一次
updated: YYYY-MM-DD          # 本次落盘日，每次实质修订必更新
---
```

### 2.2 建议字段

| 字段 | 何时填 |
|------|--------|
| `authors` | 负责人或评审人（可多值） |
| `supersedes` | 替代的旧文档路径列表 |
| `superseded_by` | 本文被谁替代（仅 supersede 入口页） |
| `related` | 关联 plan / 技能契约 / 实现文档 |
| `archived_backup` | supersede 时指向 `bak/_<旧名>` |

**无 YAML 的旧稿**：首次实质修订时**补全文首 + 修订记录**，`created` 可取首次备份时间或标注「补录」。

### 2.3 正文首段（紧接 YAML 后）

一行说明 **文档性质**（终版 / 过程 / review）与 **索引入口**，避免读者误判临时稿。示例：

```markdown
> **文档性质**：`docs/design/ai/` 终版（canonical）。过程单见 `docs/plan/ai/xxx_PLAN.md`。
```

## 3. §修订记录（正文固定章节）

位置：YAML 与一级标题之后，**目录之前**（无目录则紧接概述）。

### 3.1 表头模板

```markdown
## 修订记录

| 版本 | 日期 | 修订要点 | 备份/引用 |
|------|------|----------|-----------|
| 1.0 | 2026-05-21 | 初稿：双层模型、默认树拓扑 | — |
| 1.1 | 2026-05-22 | 整合 trace 契约；§7 标实现差距 | `bak/202605/.../AI_RUNTIME_OBSERVABILITY_DESIGN-20260521-*.md` |
```

### 3.2 「修订要点」怎么写

每条 **1–3 句**，写清 **对象 + 变化**，禁止只写「更新文档」：

| 合格 | 不合格 |
|------|--------|
| 新增 §4 RRF 与模型重排分节点；与 Assembler 实现对齐 | 修改了一下 |
| supersede `AI_RUNTIME_TRACE_ARCHITECTURE_20260517`；合并至本文 §2 | 整理格式 |
| plan 结论并入：PRR phase 挂树约定改为契约三件套 | 同步 |

可选第四列 **备份/引用**：填当次 `backup-file` 输出的 `ARCHIVE_BACKUP` 相对路径，或 `supersedes` 旧文档名，便于审计跳转。

### 3.3 与 `version` / `updated` 同步规则

- 每次**实质修订**（新增章节、改契约、改拓扑、整合过程稿、纠错影响理解）：
  1. 更新 YAML `updated`；
  2. 递增 `version`（见 §4）；
  3. **追加**修订表一行（不删历史行）。
- 仅错字、链接、标点：`updated` 可不变；若对外发布则仍建议 patch 版本 + 一行「勘误」。

## 4. 版本号语义（文档）

| 变更类型 | 示例 | 版本 |
|----------|------|------|
| 勘误、链接、排版 | 修复笔误 | +0.0.1（1.0→1.0.1）或仅改 `updated` 并记「勘误」 |
| 增量章节、表、契约补充 | 新增 tool_kind 约定 | +0.1.0（1.0→1.1.0） |
| 结构重组、supersede、真源切换 | 合并多份过程稿为终版 | +1.0.0 |

`status: superseded` 的入口页可固定 `version: 0`，修订表只保留一行「指向终版」。

## 5. 改文档标准作业（与备份绑定）

```text
1. 确认文档类型（design 终版 / plan 过程 / review）→ design_doc_lifecycle.md
2. backup-file <主文件绝对路径>           → 得到 LATEST + ARCHIVE 路径
3. 编辑正文
4. 更新 YAML：updated（+ version）
5. 修订记录表追加一行（要点 + 可选 ARCHIVE 路径）
6. 若整合 plan → 更新终版 §实现状态；plan 标 done
7. （可选）git add 仅目标文件 + commit
8. checklist.md 自检
```

## 6. 特殊资产

### 6.1 SQL（`docs/db/dev/`）

- 文件头注释块：模块名、`-- updated: YYYY-MM-DD`、`-- 变更: 一句话`。
- 大改前同样 `backup-file`；合并进 `mysql57_dev_final.sql` 时在模块 README 或 dev 目录 `CHANGELOG.md` 追加一行（模块已有则跟模块约定）。

### 6.2 技能 `SKILL.md` / `references/*.md`

- 同 §2–§5；`created` 以技能入库日为准。
- 破坏性改 trigger/description 时，修订要点必须写 **触发词变化**。

### 6.3 新建文档

- 首行 YAML 即写 `created` = `updated` = 当日，`version: 1.0`。
- 修订表首行：`初稿：<一句话范围>`。

## 7. 与终版/过程整合的关系

过程稿（`docs/plan/`）在 `status: done` 时，修订表**最后一行**必须写清：

- 并入哪份终版路径；
- 终版版本号（如 `AI_RUNTIME_OBSERVABILITY_DESIGN.md v1.1`）。

终版整合后**追加**修订行，不要覆盖初稿历史。

## 8. Agent 执行检查（改 docs 后）

- [ ] `created` 存在且未篡改
- [ ] `updated` = 本次修改日
- [ ] `version` 与修订表最新行一致
- [ ] 修订要点可让同事 30 秒内知道「这次改了什么」
- [ ] 改前已 `backup-file`，ARCHIVE 路径可选写入表
- [ ] 未用日期后缀文件名冒充版本历史
