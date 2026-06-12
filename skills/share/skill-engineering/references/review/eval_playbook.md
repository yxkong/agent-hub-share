# Trigger / Eval Playbook

适用于 `refine-trigger`，目标是验证 skill 是否会在正确场景下被触发，并且触发后真的能帮助 AI 行动。

## 核心原则

- 先验证“会不会被正确命中”
- 再验证“命中后是否真的有用”
- `description` 负责“让系统决定要不要读这个 skill”，不负责提前总结正文 workflow
- CSO 规则：`description` 只写触发条件、适用场景和可搜索症状，禁止摘要正文工作流；否则 Agent 可能读 description 走捷径，跳过 SKILL 正文
- 不用明显无关的负例糊弄测试
- 漏触发和误触发都要看
- 高风险 / 纪律执行类 skill，除了触发验证，还要看是否真正改变了默认行为
- 先确认目标确实是 skill；若更像 prompt、insight、hub 挂载或 docs 治理，先转 `agent-asset-router`

## 四层验证

### 1. 结构验证

检查：

- frontmatter 是否合规
- description 是否清楚表达 WHAT + WHEN，且没有把正文 workflow 摘要提前写进 frontmatter
- 主文件与 references 是否边界清楚

### 2. 效果验证

检查：

- 命中后能否定位入口 / 主链路 / 切入点
- 命中后能否给出最小 SOP
- 命中后能否减少无效扩读

### 3. 触发验证

检查：

- 会不会漏触发
- 会不会误触发
- 近义表达能不能命中
- 症状词 / 错误词 / 别名表达能不能命中
- 没说 skill 名时能不能命中

### 4. 行为验证（按类型启用）

适用于高风险、纪律执行类、容易被合理化绕过的 skill：

- 是否有 1 轮无 skill 的基线样本
- 是否有 1 轮带 skill 的复测样本
- 行为有没有从“直接开干 / 跳步骤”变成“按 skill 约束行动”
- 是否记录了真实合理化借口，而不是事后脑补

细则见 [behavioral_eval.md](behavioral_eval.md)。

纯参考类、目录治理类、layout / catalog / 挂载约束类 skill，通常不强制这一层。

## description 细化规则

优先检查：

- 先写 WHAT，再写 WHEN
- 触发词覆盖对象词、动作词、场景词
- 对非代码类或症状驱动 skill，补症状词 / 错误词 / 同义词
- 只描述何时加载，不写“加载后按 A→B→C 执行”这类 workflow 摘要
- 不把长负例、长枚举、workflow 细节堆进 `description`

避免：

- 用 `description` 代替正文 SOP
- 只写宽泛词，如“处理”“相关”“管理”
- 只靠 skill 名称命中，不覆盖真实用户会说的话

## 样本设计

至少准备两组样本：

### should-trigger

要求：

- 是真实用户会说的话
- 不依赖用户准确说出 skill 名
- 场景要贴近实际任务

### should-not-trigger

要求：

- 是近似但不该命中的请求
- 不是明显无关废样本
- 能帮助识别边界是否过宽
- 至少覆盖 1 条相邻资产误触发样本，例如“把长指令做成 prompt”“沉淀面试案例”“Cursor 找不到 skill”

## 最小样本数

默认建议：

- `should-trigger`：3 到 5 条
- `should-not-trigger`：3 到 5 条

如果 skill 是共享高复用技能，可扩到 6 到 10 条。

## 压力场景法

新建或强化高风险 / 纪律类 skill 前，先准备 2-3 个压力场景，观察无 skill 基线下 Agent 会如何绕过规则。

常见压力：

- 时间压力：“先快点做，验证后面再说”。
- 沉没成本：“已经写完大半了，就在现有基础上补测”。
- 权威压力：“用户明确说不用门禁，直接上”。
- 疲惫压力：长上下文、连续失败后要求“再试一次”。

记录要求：

- 逐字记录 Agent 的原生合理化借口。
- 技能正文只封堵真实出现的借口，不脑补规则。
- 带 skill 复测后，行为必须从“直接开干 / 跳步骤”变成“按 skill 约束行动”；做不到只能标 `unknown`。

## 优先修复顺序

出现问题时按这个顺序修：

1. 先修切入点
2. 再修 SOP
3. 再修核心示例
4. 最后修 description

原因：

- 切入点决定能不能定位
- SOP 决定能不能执行
- description 只决定能不能命中

## 通过标准

至少满足：

- 一轮 should-trigger 通过
- 一轮 should-not-trigger 通过
- 命中后能给出可执行结果，而不是空泛解释
- 至少有 1 条样本能证明 skill 确实减少了定位成本
- 若是高风险 / 纪律执行类 skill：至少再补 1 轮行为验证，证明 skill 确实改变了默认动作

## 路由收尾（改动了 hub 内 `SKILL.md` 时）

若本次 `refine-trigger` 伴随正文或 front matter 的回写，收尾须完整执行 [engineering_completion_gate.md](engineering_completion_gate.md) 适用步骤（通常至少 **§1、§3**；若改动了 `references/` 则补 **§2**；新建 skill 或调整挂载时 **§1–§5**）。
