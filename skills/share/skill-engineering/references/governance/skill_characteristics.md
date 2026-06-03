# 优秀技能特征（通用模式）

以下特征用于判断一个 skill 长什么样才算完整、好扫描、好触发、好维护。

---

## 一、默认结构标准

默认结构标准是：`standard = 五要素完整版`。

五要素是：

1. 设计理念
2. 流转图 + 数据流
3. 切入点
4. AI 开发者使用 SOP
5. 核心示例

`full` 不是另一套结构，而是 `standard` 的加强版：补更完整的 eval、负例、references、图表和跨平台说明。

---

## 二、Frontmatter 特征

| 特征 | 要求 |
|------|------|
| `name` | 与技能目录一致，简短、清晰、可识别 |
| `description` | 用 1～2 句话写清 WHAT + WHEN + 触发场景 |

好的 `description` 应满足：

- 先说做什么
- 再说什么时候用
- 触发词覆盖对象词、动作词、场景词；必要时补症状词 / 错误词 / 同义词
- 不把“不负责项”和大量细节堆进去
- 不在 frontmatter 里总结正文 workflow；`description` 负责发现，不负责替代正文

示例：

```yaml
description: 创建、优化、审查并从存量项目提炼 AI 技能。适用于用户提及技能抽取、陌生代码库、快速定位改动点、优化 description 触发等场景。
```

---

## 三、主文件应具备什么

优秀主文件通常应具备：

- 30 秒决策区或关键词 -> 路由表
- 作用边界
- 任务分类门
- 输出级别说明
- 核心红线
- 最小 trigger / eval 样例
- 与其他技能的关系

主文件不应具备：

- references 已完整覆盖的长流程细节
- 多篇 reference 的重复内容
- 大量平台专属装配信息

---

## 三点五、指令自由度要匹配任务脆弱性

不是所有 skill 都该写成同样硬度。高质量 skill 要根据任务脆弱性决定“写到多死”：

- **高自由度**：多种做法都可能对，重点是给判断框架而不是固定步骤
- **中自由度**：存在推荐模式，但允许按上下文微调
- **低自由度**：动作脆弱、顺序关键、跳步代价高，必须给明确步骤和验证点

经验判断：

- `review`、分析、抽象方法论类 skill，通常更偏高自由度
- 有固定脚本、固定验证门、固定顺序的 skill，通常更偏低自由度
- 如果一旦走错就会返工、误改或漏验，宁可更具体，不要只写原则口号

---

## 四、30 秒决策区推荐格式

优先使用表格，而不是纯文字段落：

```markdown
| 任务类型 | 什么时候选它 | 先读什么 |
|----------|--------------|----------|
| create | 从零新建 skill | `workflow/creation_workflow.md` |
| extract | 从存量项目提炼 | `workflow/legacy_project_extraction.md` |
| review | 审查现有 skill | `review/quick_gate.md` 首读；系统修复再进 `review/checklist.md` |
| refine-trigger | 修正 description / eval | `review/eval_playbook.md` |
```

原因：

- 扫描更快
- 路由更明确
- 更符合“先判断任务，再读文档”的理念

---

## 五、references 应具备什么

references 一般按职责拆分：

- 为什么：`design_principles.md`
- 怎么创建：`creation_workflow.md`
- 怎么提炼：`workflow/legacy_project_extraction.md`
- 怎么审查：先 `review/quick_gate.md` 判阻断与下一步；系统修复再用 `checklist.md`
- 怎么验证：`review/eval_playbook.md`；高风险 / 纪律类补 `review/behavioral_eval.md`
- 特定补充：`project_elements.md`、`diagrams_guidelines.md`、平台装配说明

要求：

- 只允许一层引用
- 每篇职责单一
- 不与主文件重复平铺

---

## 六、核心红线长什么样

优秀 skill 的红线一般只有 3～5 条，但都必须高信号、可执行：

- 主文件只做路由器，不重复 references 细节
- 默认 `standard`，不盲目 full 化
- 切入点必须落到具体位置
- 修改后必须做 trigger / eval 校验

---

## 七、最小 trigger / eval 样例

每个 skill 至少应带：

- should-trigger 3～5 条
- should-not-trigger 3～5 条

目的不是凑格式，而是让 skill 吃自己的狗粮。

---

## 八、验证闭环

高质量 skill 至少要做三类验证：

- 结构验证：主文件、references、路径、层级是否一致
- 效果验证：真实提示下能否回答“改哪、先看哪、如何验证”
- 触发验证：description 是否存在漏触发或误触发

对高风险、纪律执行类 skill，再加一层：

- 行为验证：Agent 是否从“默认老习惯”切到“按 skill 约束行动”

行为验证不是所有 skill 的强制门，但这类 skill 如果没有行为变化，只能说明“文档能读”，不能说明“skill 真有效”。