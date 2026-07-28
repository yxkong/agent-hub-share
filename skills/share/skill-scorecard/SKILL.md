---
name: skill-scorecard
description: 以双 100 分制审查 AI skill、prompt、references、scripts 与挂载资产的质量和能力兑现度，并输出门禁结论。适用于给单个 skill 打分、比较多个 vendor skill、审查 prompt 资产是否可复用、发现路径漂移、脚本放错层、缺契约/缺验证/缺执行闭环等问题。
---

# Skill Scorecard

## 30 秒决策区

| 路由 | 什么时候用 | 先读 |
|------|------------|------|
| `score-skill` | 评分单个 skill / 共享技能 / 项目技能 | `references/workflow.md` + `references/scoring_dimensions.md` + `references/calibration_examples.md` |
| `score-prompt` | 评分 `*.prompt.md`、子 Agent prompt 模板、生成规则资产 | `references/workflow.md` + `references/asset_type_adapters.md` + `references/scoring_dimensions.md` |
| `compare-bundle` | 比较一组 vendor skills / 候选技能包 | `references/workflow.md` + `references/calibration_examples.md` + `references/report_template.md` |

默认先走 `score-skill`；只有目标不是完整 skill 时才切到 `score-prompt`。

## 作用边界

**覆盖**：

- 给 `SKILL.md`、`README.md`、`references/`、`scripts/`、`templates/`、相关 prompt 资产做结构化评分
- 识别触发不准、契约不全、SOP 空泛、验证缺失、脚本错层、路径失效、share 私有耦合、Release Evidence / Task Replay Lite / Skill Health Signal 缺口
- 识别真实任务优化证据缺口：baseline rollout、reflection、bounded edit、held-out validation 是否存在
- 输出 findings-first 的评分报告，包含**质量分（100）**、**兑现分（100）**、**门禁结论**与证据等级
- 为后续修复提供 P0 / P1 / P2 整改建议

**不覆盖**：

- 代替 `skill-engineering` 直接重构 skill 正文
- 代替 `agent-hub-bootstrap` 做挂载、同步、发布
- 代替领域技能落地业务代码
- 代替 `prompt-engineering` 直接编写/发布 prompt 正文

## 输出级别

默认 `standard`。当目标是完整产品型 skill（含脚本、模板、索引、跨平台入口）时，按 `full` 心智执行，至少覆盖脚本行为、路径完整性和派生资产一致性。

## 评分硬规则

1. **证据先于分数**：没有读到 `SKILL.md` / `README.md` / 关键 references / 关键脚本时，不给最终分。
2. **findings first**：用户说“review / 审查 / 看问题”时，先列问题，再给分数。
3. **事实 / 假设 / unknown 分开**：读不到的脚本、没跑过的校验、找不到的路径必须标 `unknown`。
4. **闭环优先**：缺验证、缺执行、缺路径更新、脚本不可用、只有 static 证据却宣称完成时，优先扣“闭环分”，不要只夸文档写得好。
5. **脚本放置按 L1/L2 判断**：只服务一个 skill 的脚本默认应在技能目录；跨技能或独立运维入口才应在 hub `scripts/`。
6. **share 去项目化必查**：share skill 若硬编码项目名、私有路径、内网 URL、真实模块前缀，应降分并标为可迁移性问题。
7. **share 证据归因**：当前运行环境装配、项目技能、账号/仓库私有事实只能作为组合系统证据；不得直接计入 shared skill 本体兑现分。
8. **active 全包口径**：评分对象是整个技能包；必须盘点同目录 active 文件，排除 `bak/`，不能只看 `SKILL.md`。
9. **行为与首读要单独看**：高风险 / 纪律类 skill 要看是否真的改变 Agent 行为；所有 skill 都要看触发后能否 30 秒内找到首读入口。
10. **96+ 反通胀**：没有 `executed/observed` 证据、校准样例对齐、行为复测和必要的 held-out 验证时，不得把“写得好”评成标杆分。

## 证据优先级

`SKILL.md` / 活跃脚本 / 活跃 references > `README.md`（维护章程，非运行入口） > 历史备份 / 旧评分 / 口头说明

## 闭环门

- 已盘点 active 全包资产，且排除 `bak/`。
- 已按质量分、兑现分、门禁结论三层输出。
- 96+ 或“标杆”结论已对齐 `references/calibration_examples.md`，不能只靠静态好感。
- 若对象经历过“优化 skill”，已检查 `skill-engineering/references/optimization/` 的 rollout / reflection / held-out 证据。
- 评分后若需要修复正文，转 `skill-engineering`；若需要挂载发布，转 `agent-hub-bootstrap`。

## 最小评分流程

1. 确认目标类型：完整 skill / prompt 资产 / skill bundle
2. 盘点 active 资产：`SKILL.md`、`README.md`、`references/`、`scripts/`、`templates/`
3. 若存在 `themes/`、`examples/`、`assets/`、脚手架、provider adapter，也纳入 active 资产；`bak/` 不计证据
4. 先列承诺能力清单，再按 `references/scoring_dimensions.md` 分别计算**质量分**与**兑现分**
5. 对照 `references/calibration_examples.md` 选择最接近档位，先判是否具备 96+ 标杆证据
6. 若能运行门禁，优先补充：
   - `check-skill-entrypoints`
   - `check-skill-structure`
   - `check-skill-size`
   - `check-share-skill-private-coupling`
   - `check-backup-policy`（涉及备份脚本/备份契约时）
   - `check-prompts`（prompt 资产）
7. 用 `references/report_template.md` 输出结论

## P0 references

- `references/scoring_dimensions.md`：质量分 / 兑现分 / 门禁与封顶规则
- `references/workflow.md`：逐步审计顺序与证据等级
- `references/calibration_examples.md`：分数档位校准与 96+ 反通胀规则
- `references/asset_type_adapters.md`：skill / prompt / bundle 的适配差异
- `references/report_template.md`：统一输出模板
- `references/trigger_eval.md`：触发与反触发样例
- `references/evidence_examples.md`：executed / observed 证据样例

## trigger / eval

完整正负例见 `references/trigger_eval.md`。主文件只保留记忆规则：

- **should-trigger**：skill / prompt / bundle 评分、闭环审计、路径漂移、脚本放错层
- **should-not-trigger**：直接修 skill、直接生成 prompt、同步发布 skill、推进真实研发需求

## 与其他技能的关系

| 技能 | 何时转交 |
|------|----------|
| `skill-engineering` | 评分后决定重构/新建/抽取 skill |
| `skill-engineering/optimize` | 评分后需要基于真实任务证据迭代优化 skill |
| `prompt-engineering` | 评分对象变成 `*.prompt.md` 正文生产与 eval 落盘 |
| `agent-hub-bootstrap` | 需要挂载、发布、同步、校验入口 |
| `delivery-workflow` | 目标变成真实研发交付，而不是审计资产 |

## 默认产物

- 质量分：`XX / 100`
- 兑现分：`XX / 100`
- 门禁结论：`可挂载 / 可复用 / 仅参考 / 暂缓使用`
- 证据等级：`executed / observed / static / unknown`
- 分维度评分表
- 最高优先级 findings（若有）
- P0 / P1 / P2 整改建议
