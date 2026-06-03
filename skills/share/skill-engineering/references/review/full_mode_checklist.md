---
title: Full 模式交付清单
updated: 2026-05-03
summary: full 模式额外交付：短 description + references 内触发材料；流程图默认 references；钩子单源。计数与 skill-engineering 主文件 References 深度规则一致。
---

# Full 模式交付清单

> full = standard 加强版。standard 五要素已满足后，逐项检查以下条目。

---

## 1. Description 与触发材料（frontmatter 保持短）

- [ ] frontmatter `description` 为 **1～2 句话** WHAT + WHEN（与 `skill_characteristics.md` 一致），**不**堆长词表、长负例列表或接口枚举
- [ ] **触发词/实体密度**：在 `references/`（如扩写 `eval_playbook.md`、或新增 `trigger_lexicon.md` / `eval_keywords.md`）维护 **≥10** 条可检索实体（类名 / 方法名 / 表名 / API 路径等），主文件仅一行指针指向该文件即可
- [ ] **负例**：应在主文件「trigger / eval」样例区或 `references/`（与 `eval_playbook` 联动）写明 **should-not-trigger** 指向哪一技能；**不**把长负例塞进 `description`
- [ ] `description` 中无仅靠模糊词充当触发（如单独使用「处理」「管理」「相关」不算有效触发词）

---

## 2. References 体系

- [ ] 每个 BX / RG / M 等 reference 文件有明确的**主题句**（第一行说清楚这个文件管什么）
- [ ] 主文件路由表中每一条路由，对应的 reference 文件已存在且内容完整
- [ ] 无跨技能目录的相对路径引用（`../other-skill/` 类路径是反模式）
- [ ] reference 文件末尾有**更深入链接**（如有层次，指向下一层文件）

---

## 3. 流程图与数据流

- [ ] 主链路有 Mermaid（`sequenceDiagram` 或 `flowchart`），**默认放在** `references/*.md`；主文件 **仅**保留一句链路摘要 + 指向该图的链接（与 `diagrams_guidelines.md` 主文件路由原则一致）
- [ ] 数据流标注输入/输出类型（不只写类名，写字段）

---

## 4. 负例与边界

- [ ] 至少 3 条 should-trigger 样例
- [ ] 至少 3 条 should-not-trigger 样例（指明转哪个技能）
- [ ] 边界说明：这个技能覆盖到哪里，下一个技能从哪里开始

---

## 5. 验证可落地

- [ ] 至少 1 个**真实任务**可端到端验证（有输入、有预期输出、可检查结果）
- [ ] SOP 每一步都有**可观测的中间产物**（不能只说"处理完成"）

---

## 6. 问题追踪钩子（自我进化）

- [ ] **未**在业务 skill 根 `SKILL.md` 内嵌 `skill-engineering` 级「钩子/反馈闭环」长文；约定见共享技能 `skill-engineering` → `## 技能钩子协议` / `## 反馈闭环协议`
- [ ] `bad_smell_registry.md` 已按路由读过；无与当前任务相关的已知模式被忽视

---

## 7. 跨平台适配（如涉及脚本/命令）

- [ ] 文件路径使用 `<绝对路径>` 参数形式，不硬编码
- [ ] 脚本类操作同时提供 `.sh` 与 `.ps1` 版本，或注明平台限制

---

## 完成门（full 版）

以下 7 项全部满足，才算 full 模式交付完成：

1. ✅ 标准五要素（design / flow / cutpoints / SOP / validation）
2. ✅ Description 短 + references 内触发词表 / 负例材料完备
3. ✅ References 体系（路由条目 ↔ 文件 100% 对应）
4. ✅ 流程图（主链路 Mermaid，**默认在 references**）
5. ✅ 负例与边界（各 ≥ 3 条）
6. ✅ 验证可落地（真实任务可测）
7. ✅ 钩子/坏味道依 `skill-engineering` 单源维护（业务主文件无重复协议节；registry 已检）
