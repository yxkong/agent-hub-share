# 资产类型

资产类型是开放集合，不限于 RAG、NL2SQL、Agent、性能、架构这些例子。

## 主交付物门禁（先于查表）

按 `value_lens.md` §主交付物门禁：主交付为 SKILL/references/放置表/script_tiering/规则正文时，**不查下表**，直接 `skill_rule` 或转 `doc-script-governance` / `skill-engineering`。

## 可提炼判断

确定 asset_type 后，直接在下方核心类型表查 `可提炼` 列：

- ✅ 可提炼：进入后续 SOP 步骤
- ❌ 丢弃：终止，不再继续，不输出卡片
- 若候选本质是 `prompt_template` 或 `skill_rule`，不作为 TechInsightVault canonical asset；分别转 `prompt-engineering` 或 `skill-engineering`

## 核心类型

> **派生类型**（`interview_story` / `resume_bullet` / `article_seed`）不能作为 canonical asset 的 `asset_type`，只能由事实源生成。遇到这三种类型时，必须先确认对应的事实源 canonical asset 存在，再生成派生表达。

| 类型 | 说明 | 可提炼 | 归档目录 | 典型输出 |
|---|---|---|---|---|
| `capability_build` | 构建了之前没有的技术/产品能力层 | ✅ | `01_case_library/<domain>/` | 能力描述、系统设计叙述 |
| `architecture_pattern` | 架构设计决策、边界抽象、模块治理 | ✅ | `01_case_library/<domain>/` | 架构经验卡 |
| `debug_pattern` | 非显而易见的定位路径和推理链路 | ✅ | `01_case_library/<domain>/` | 排查 SOP |
| `case` | 复杂问题解决，有根因+决策+验证 | ✅ | `01_case_library/<domain>/` | 技术案例卡、面试故事 |
| `principle` | 可迁移的方法论或决策原则 | ✅ | `04_methodology/` | 方法论条目 |
| `decision_model` | 面对选择时的判断框架 | ✅ | `04_methodology/` | 取舍表、决策树 |
| `anti_pattern` | 系统性反模式，有失败依据 | ✅ | `01_case_library/<domain>/` | 反模式卡（只有规律性失败才提炼） |
| `delivery_pattern` | 质量体系、评测体系、可观测体系（**运行时**门禁，非文档 SOP） | ✅ | `01_case_library/<domain>/` | 工程 SOP |
| `rule_fix` | 规范修复、命名约定补全、bug fix（规范违反） | ❌ | — | 丢弃 |
| `prompt_template` | 给 Agent/模型执行的长指令、系统提示词、工具约束 | ❌ | — | 转 `prompt-engineering` |
| `skill_rule` | SKILL.md 触发、路由、SOP、坏味道规则；**含 Hub 脚本 L1/L2 放置表、文档 backup 规范、目录路由表** | ❌ | — | 转 `skill-engineering` / `doc-script-governance` |
| `interview_story` | 面试可讲故事（派生资产） | 派生 | `02_interview_bank/` | 1分钟/3分钟表达 |
| `resume_bullet` | 简历可用成果表达（派生资产） | 派生 | `03_resume_bullets/` | bullet 素材 |
| `article_seed` | 文章或分享的素材种子 | 派生 | `05_article_drafts/` | 大纲、观点 |

## 自动分类规则

- 构建了之前不存在的完整能力层（评测/可观测/质量管控）：优先 `capability_build`。
- 主要价值是边界、职责、抽象、系统设计决策：优先 `architecture_pattern`。
- 主要价值是定位链路，且推理过程非显而易见：优先 `debug_pattern`。
- 有明确问题、根因（非规范违反）、方案、验证：优先 `case`。
- 只有可迁移原则，没有单一项目结果：优先 `principle`。
- 多方案比较和取舍明显：优先 `decision_model`。
- 主要价值是流程/质量体系/可观测体系设计（**且改变运行时行为或度量**）：优先 `delivery_pattern`。
- 主要价值是「文档/脚本放哪、备份几步、路由表怎么写」：优先 `skill_rule`，❌ 不进 Vault。
- 表达"不要这样做"且是系统性失败模式（不是一次性规范违反）：优先 `anti_pattern`。

## 多类型处理

一个事实源可以派生多个表达资产，但 canonical asset 只能有一个主类型。

示例：

- `case` 是事实源
- `interview_story` 是派生表达
- `resume_bullet` 是派生表达
- `principle` 可以从多个 case 汇总而来
