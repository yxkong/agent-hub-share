---
title: skill-engineering references catalog
updated: 2026-05-28
---

> **禁止 Agent 当任务入口。** 路由只读根 [`SKILL.md`](../SKILL.md) § References 优先级；本文件供人工维护、review 零孤儿核对。

## 维护约定

| 列 | 含义 |
|----|------|
| `in_route` | 是否在 `SKILL.md` 路由表出现 |
| `tier` | P0 主链 / P1 装配治理 / P2 按需百科 |

## workflow/

| 文件 | tier | in_route | 用途 |
|------|------|----------|------|
| `workflow/creation_workflow.md` | P0 | 是 | `create` 主 SOP |
| `workflow/legacy_project_extraction.md` | P0 | 是 | `extract` 主 SOP |
| `workflow/extraction_prompt_template.md` | P1 | 是 | 提炼三阶段 Prompt 母版 |

## review/

| 文件 | tier | in_route | 用途 |
|------|------|----------|------|
| `review/quick_gate.md` | P0 | 是 | `review` 首读快速门：30 秒判断阻断、可用性与下一步 |
| `review/checklist.md` | P1 | 是 | `review` 系统审查详表 |
| `review/router_handbook_gate.md` | P0 | 是 | Router/Handbook/Tier 门禁（create/review/extract 收尾） |
| `review/eval_playbook.md` | P0 | 是 | `refine-trigger` |
| `review/behavioral_eval.md` | P1 | 是 | `review` / `refine-trigger`：高风险 / 纪律类 skill 的行为验证 |
| `review/behavioral_evidence.md` | P1 | 是 | 高风险 / 纪律类 skill 的基线 / 复测证据样例 |
| `review/engineering_completion_gate.md` | P1 | 是 | 工程收尾 §1–§5 单一真源 |
| `review/full_mode_checklist.md` | P2 | 是 | full 级别加强项 |

## layout/

| 文件 | tier | in_route | 用途 |
|------|------|----------|------|
| `layout/skill_directory_layout.md` | P1 | 是 | 技能根目录标准树 + references 深度 |
| `layout/skill_root_readme.md` | P1 | 是 | 根 README 章程 |
| `layout/placement_and_junctions.md` | P1 | 是 | hub 真源与挂载 |
| `layout/skill_truth_source_contract.md` | P0 | 是 | canonical 入口 / bak 排除 / 挂载非真源（硬约束） |
| `layout/project_elements.md` | P1 | 是 | 从项目提素材 |

## governance/

| 文件 | tier | in_route | 用途 |
|------|------|----------|------|
| `governance/bad_smell_registry.md` | P0 | 是 | 路由前必读；坏味道计数 |
| `governance/output_levels.md` | P1 | 是 | lite / standard / full |
| `governance/design_principles.md` | P2 | 是 | 设计原则与 §六 反模式 |
| `governance/skill_characteristics.md` | P2 | 是 | skill 完整度结构 |
| `governance/diagrams_guidelines.md` | P2 | 是 | Mermaid 等图规范 |

## eval/

| 文件 | tier | in_route | 用途 |
|------|------|----------|------|
| `eval/trigger_eval.md` | P1 | 是 | 本技能 trigger 回归（≥10 条） |

## 零孤儿核对

```powershell
Select-String -Path (Join-Path $PSScriptRoot '..\SKILL.md') -Pattern 'references/' -AllMatches
# 凡 in_route=是 的行，须在 SKILL.md 出现对应路径
```
