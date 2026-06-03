---
title: Skill 审查清单
updated: 2026-05-28
summary: review 路由系统审查详表。每次系统修复或完整审查时逐节检查；首读入口是 quick_gate.md；收尾须过工程完成门；主文件行数按非空行计数，发现问题记录到 bad_smell_registry.md；高风险 / 纪律类 skill 需补行为验证。
---

# Skill 审查清单

> 本文件是 `review` 路由的系统审查详表，不是 30 秒首读入口。先读 `quick_gate.md` 判定门禁阻断、可用性四门与下一步；需要系统修复、评分或完整 review 时再进入本清单。主文件**非空行**上限以被审技能 `SKILL.md` 中「主文件行数」分级表为准（计数口径与该节一致；与 `wc -l` 或「路由器型一律 ≤130 物理行」等口述冲突时，以父技能表格与 trim 非空行定义为准）。

---

## 0. 入口路由确认

在开始之前，确认已走 `review` 路由：

- [ ] 明确审查类型：`review`（结构重 / 边界乱 / 难触发 / 难用）
- [ ] 选定路由：`create / extract / review / refine-trigger` 中的一个
- [ ] 声明"本次是审查，不是 create 或 extract"
- [ ] 已先读 `quick_gate.md`，并记录门禁阻断、可用性四门与下一步
- [ ] 已读 `references/governance/bad_smell_registry.md`，检查是否有相关历史教训

---

## 1. 根目录布局与 README

- [ ] 目录符合 `layout/skill_directory_layout.md`（根 `templates/`、无 `references/templates/TEMPLATE_*`）
- [ ] 根目录存在 `README.md`（规范见 `layout/skill_root_readme.md`）
- [ ] README 明确声明自己是维护章程，不是运行入口
- [ ] **核心用途** 清晰，与 `SKILL.md` frontmatter `description` 语义一致
- [ ] **设计理解 / 设计哲学** 已写出，说明为什么这个 skill 要独立存在
- [ ] **分层原则 / 结构约定** 已写出，明确 README / SKILL / references 分工
- [ ] **维护约束** 已写出，说明后续改动的联动范围
- [ ] 若存在 trigger / eval 增强文档：README 已写清它是**独立路由**还是**挂靠路由**
- [ ] **单一职责** 列表 ≤5 条，不空泛
- [ ] **不负责 / 转交** 表至少 2 个相邻 skill，无与它们重复的 SOP 正文
- [ ] README 非 SKILL 全文拷贝（细则应在 references）

## 2. 主文件规模与结构

- [ ] 选择输出级别：`lite / standard / full`
- [ ] 主文件是否是路由器（不展开细节，只指向 references）
- [ ] 主文件是否只承载稳定入口、协议、硬规则；没有混入 human-only / maintenance-only 文件枚举、具体业务样例、可变资产清单或长手册
- [ ] 触发后 30 秒内能判断首读 active 文件；不需要通读主文件或全量 references 才知道下一步
- [ ] 若存在增强文档：`SKILL.md`、README、references catalog 对其入口关系表述一致
- [ ] 如果是跨团队 / 高风险技能，应使用 `full` 模式（已过 full_mode_checklist.md）
- [ ] `references/` **深度**（与 `SKILL.md` §References 深度一致）：顶层（不含 `references/bak/**`）`*.md` **≤15** 为 flat；**>15** 须有语义子目录且每子目录 `*.md` **≤15**
- [ ] 主文件**非空行**数：对照 **Skill 类型 → 非空行上限**（纯路由 80 / 路由器+硬约束 130 / 多域 150 / 元技能 160）；用 hub 脚本 `check-skill-size.sh` / `check-skill-size.ps1`（`--type` 或 `--max`）计数并做门禁；若未声明类型，按实际结构归入最接近一类；超限必须拆并下沉 `references/`

---

## 3. 材料与证据

- [ ] 已识别 P0（当前主链路代码）、P1（当前主文档）、P2（历史文档）
- [ ] 材料充足性：能否定位到真实入口（类 / 方法 / 表 / API）
- [ ] 内容与现实一致：代码切入点是否仍然存在于代码库
- [ ] 有争议或不确定内容是否已标注 `assumption` 或 `unknown`
- [ ] 文档与代码冲突时，以代码为准（已确认）
- [ ] 多实现并存时，已确认当前主调用链（非历史链）

---

## 3. 内容质量

### 3.1 证据质量

- [ ] 切入点：精确到类 / 方法 / 表 / 文件名（不是"某服务层"这种抽象描述）
- [ ] 主链路：可逐步复述（入口 → 核心处理 → 输出），不存在跳跃
- [ ] ≥ 3 个高频场景有切入点
- [ ] ≥ 1 个真实任务可验证（有输入、有预期输出、可检查结果）
- [ ] 不确定内容有标注，未虚构规则

### 3.2 extract 路由专项（非 extract 路由可跳过）

- [ ] 边界：模块范围说清楚了
- [ ] 主链路：已梳理出来
- [ ] 高频切入点：已识别
- [ ] 最小 SOP：已有
- [ ] 最小验证：已有

### 3.3 完成门（四项全满才算可用）

- [ ] 真实入口可定位
- [ ] 主链路可复述
- [ ] ≥ 3 个高频场景有切入点
- [ ] ≥ 1 个真实任务可验证

四项未满 → 技能不可用，继续补充。

---

## 4. 触发准确性

- [ ] description 包含 WHAT（做什么）+ WHEN（什么时候触发）
- [ ] description 没有提前总结正文 workflow；frontmatter 负责发现，不替代正文
- [ ] 关键词密度足够（精确到类名 / 方法名 / 表名，不是宽泛词）
- [ ] 若 skill 更偏症状驱动而非对象驱动：description 已覆盖症状词 / 错误词 / 同义词
- [ ] 有明确的 should-trigger 样例（≥ 3 条）
- [ ] 有明确的 should-not-trigger 样例（≥ 3 条，且指向正确的其他技能）

---

## 5. 边界清晰度

- [ ] 有明确的"覆盖"列表
- [ ] 有明确的"不覆盖"列表，且指向正确的替代技能
- [ ] 与相关技能的分工边界在本文件中有说明
- [ ] 不把相邻技能的职责混入（如 delivery-workflow 的流程不写进领域技能）

---

## 6. SOP 可执行性

- [ ] SOP 步骤从"收到任务"到"交付完成"覆盖完整
- [ ] 每一步都可以立即执行（没有"视情况而定"这种空洞步骤）
- [ ] SOP 场景覆盖：新增 / 修改 / 排查 ≥ 2 种
- [ ] SOP 没有"告诉用户该做什么"而是"AI 自己该做什么"

---

## 7. Token 成本控制

- [ ] 主文件不重复展开 references 已覆盖的细节
- [ ] P0 reference 足够薄，不需通读整个文件才找到入口
- [ ] references 按 P0 / P1 / P2 优先级组织，日常只读 P0
- [ ] 不存在"先读全部 references 再行动"这种路由失效情况
- [ ] 人读 / 维护索引文档已通过协议降权，不在 `SKILL.md` 重复枚举

---

## 7.5 Router / Handbook / Tier 门禁（多域 skill 必查）

> 细则真源：[router_handbook_gate.md](router_handbook_gate.md)；**review / create / extract 收尾必跑**。

- [ ] 已按 `router_handbook_gate.md` §1–§8 逐项勾选（单一路由、Tier、review 默认先 `quick_gate.md`、系统修复再进 checklist、INDEX 零孤儿、断链、搬迁完整、trigger eval、章节编号、子目录 README 降权）

---

## 8. trigger / eval 评估

- [ ] description 触发词是类名 / 方法名 / 表名级别（不是"相关"、"处理"等）
- [ ] should-trigger 样例与 description 触发词对应
- [ ] should-not-trigger 样例精确指向替代技能
- [ ] 正负例各 ≥ 3 条
- [ ] 若存在增强文档（如行为验证）：已说明它属于**独立主路由**还是**`review` / `refine-trigger` 挂靠增强**

## 8.5 行为验证（高风险 / 纪律类 skill 必查）

> 细则真源：[behavioral_eval.md](behavioral_eval.md)。纯参考类、layout / catalog / 挂载治理类 skill 可跳过，但应明确说明原因。

- [ ] 已至少准备 1 条**无 skill 基线样本**，观察默认行为而不是概念问答
- [ ] 已至少准备 1 条**带 skill 复测样本**，观察行为是否发生改变
- [ ] 样本足够真实，要求 Agent 做选择 / 执行，而不是只复述规则
- [ ] 若此 skill 易被赶时间、沉没成本、速度偏好绕过：样本已加入 2~3 个组合压力
- [ ] 已逐字记录至少 1 条真实合理化借口
- [ ] 结论能说清问题在 description、正文结构、SOP 还是红线表达

---

## 9. 好坏切入点对照

### 9.1 好切入点

```
- 入口：OrderController.create
- 主链路：OrderController.create → OrderService.create → OrderValidator.validate → OrderMapper.insert
- 关键扩展点：OrderStatusEnum 枚举、OrderValidator 规则、OrderService.checkDuplicate
- SOP 从 OrderController.create 开始、从 OrderService.create 展开、从数据库层验证结果
- 至少一个真实任务：新增订单重复校验功能可端到端验证
```

特征：入口确定、链路完整、关键分支有覆盖、SOP 可执行、验证可落

### 9.2 坏切入点

```
- 找 Service 层处理
- 看一下相关的 Mapper
- 修改对应的业务逻辑
- 可能需要改前端配合
```

特征：抽象模糊、无法直接定位、依赖上下文猜测、每个 session 结果不一样

### 9.3 好主文件

```md
## 30 秒决策区
| 任务类型 | 什么时候选它 | 先读什么 |
| ... |

## References 优先级
- P0：按路由直接打开
- P1：命中条件再读
```

特征：入口稳定、首读明确、细节下沉；不会把 README / INDEX / human-only / 具体业务样例搬回主文件。

### 9.4 坏主文件

```md
## References
- human-only: references/human_quickstart.md
- maintenance-only: references/README.md
- 具体业务样例 A / B / C
```

特征：把维护层和示例层暴露给 Agent，主文件不再只是运行入口。

---

## 10. 问题分类表

| 问题现象 | 根因类型 | 修复方向 |
|----------|----------|----------|
| 不知道改哪个文件 / 类 / 方法 | 切入点空泛 | 精确到具体类 + 方法 + references |
| 触发了但没实质帮助 | 内容无效 | 验证切入点存活性；补 references |
| 主文件需通读才理解路由 | 路由器失效 | 主文件只保留路由表，细节下沉 |
| SOP 步骤无法执行 | SOP 空泛 | 每步有可观测产物；覆盖新增/修改/排查 |
| 触发后仍按老习惯行动 | 行为约束不足 | 补做行为验证；看是 description 不准、正文不清还是红线不够显眼 |
| 同一问题重复出现 | 系统性缺失 | 提升到 design_principles.md 或 bad_smell_registry |
| Token 成本失控 | 主文件膨胀 | 拆分 references；按该 skill 类型的**非空行**上限收敛主文件 |

---

## 11. 产品级全量 review 收口

当被审对象是完整产品型 skill（含脚本、索引、模板、示例、生成物、跨平台入口）时，不能按"发现一个问题 -> 修一个问题 -> 下一轮再看"结束。必须先做全量收口：

- [ ] **重新读取最新文件**：最终结论前重新读当前文件，不复用上一轮缓存或旧 finding。
- [ ] **全量文件清单**：列出本技能根 `SKILL.md`、references、相关脚本、模板、索引生成物、黄金样例；确认 review 覆盖了这些文件。
- [ ] **脚本行为验证**：主路径脚本跑通；若新增审计/迁移/跳过类 flag，正向和该 flag 路径都至少验证一次。
- [ ] **跨平台入口一致**：PowerShell 与 POSIX wrapper 暴露同一能力、同一默认失败策略、同一参数语义；shell 参数分支确认有 `shift`，避免死循环。
- [ ] **内部能力不可裸奔**：Python/Node/内部脚本新增能力时，必须通过标准 `.ps1` / `.sh` wrapper 暴露；文档不得要求用户绕到内部入口。
- [ ] **文档承诺一致**：全局搜索旧关键词和旧规则；README、reference、模板、示例、脚本头注释与真实脚本行为一致。
- [ ] **机器索引治理**：机器索引只收真实源；不得把 README、模板、派生物、备份或缺身份文件伪装成 canonical item；缺必需 id 默认失败，审计模式只能显式开启。
- [ ] **模板与 CI 一致**：模板/front matter/body 约束必须被校验脚本覆盖；若只靠人工校验，文档必须明确写为人工质量门。
- [ ] **Router / Handbook / Tier**：已按 **§7.5** 逐项通过（单一路由、handbook 分层、review 默认先 `quick_gate.md`、系统修复再进 checklist、零孤儿、搬迁完整、trigger eval）
- [ ] **主文件纯度**：`SKILL.md` 不含维护层枚举、具体业务样例或可变资产清单；这些信息已下沉 README / references / 索引
- [ ] **一次性输出剩余问题**：经过至少两轮交叉检查后，集中输出所有仍需修改的问题；已确认修好的点不重复输出。

---

## 12. 审查结束动作

- [ ] 若本次改动了 hub 内被审技能的 `SKILL.md` 或目录结构：已按 [engineering_completion_gate.md](engineering_completion_gate.md) 完成适用步骤（含 **§1–§5** 中路由要求的全集，不得只跑子集）；脚本均以 exit 0 为准
- [ ] 执行反馈闭环：按 `skill-engineering` 约定检查坏味道，有则追加/计数 `bad_smell_registry.md`（协议正文不写入被审 skill 主文件）
- [ ] 若触发次数达到 2 → 立即提升到 `design_principles.md §六 反模式`
- [ ] 审查结论写入**会话小结、PR 描述或团队约定位置**；**不要**在 skill 主文件末尾追加「已过审查清单」+ 日期类标语（避免无实质改动的 churn）
- [ ] 若被审文件的 YAML 头等已有 `updated` 字段：**仅当本次改了该文件实质内容**时更新日期；禁止为「打卡」而改日期
- [ ] 若被审对象带评分结论：采用“质量分 + 兑现分 + 门禁结论”口径，不退回单总分
