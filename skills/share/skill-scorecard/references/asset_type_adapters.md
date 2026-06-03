# 资产类型适配

## 1. 完整 skill

适用于有 `SKILL.md` 的目录。

重点看质量分时：

- 触发是否准
- SOP 是否能驱动 AI
- README / SKILL / references / templates 是否分工清楚

重点看兑现分时：

- 验证是否闭环
- scripts / wrapper / 挂载入口是否真实可用
- 路径 / references / 模板是否仍与当前规则同步
- description 与 should-trigger 承诺的能力是否被真的覆盖

## 2. prompt 资产

适用于：

- `*.prompt.md`
- 子 Agent prompt 模板
- 生成规则 / system prompt 资产

评分时质量分更看重：

- 输入/输出契约
- eval 设计与示例质量
- 去项目化
- 复用性

兑现分更看重：

- eval / 示例是否真能支撑所承诺的输出
- 模板漂移
- 路径过期
- 被谁引用、是否仍有真实调用场景

脚本分和挂载分可弱化，但不能因此虚高兑现分。

## 3. bundle / vendors

适用于 vendor 包、skills collection、外部仓导入集。

质量分重点看：

- 是否存在重复技能
- 路径/脚本/命名是否一致

兑现分重点看：

- 是否有无法挂载的假 skill
- 高兑现 skill 占比
- 安装链 / 路径 / wrapper / 依赖是否一致
- 同名能力是否导致真实使用歧义

## 4. 只有脚本没有 skill

此类对象不应被当作完整 skill 打分。

先判：

1. 它是不是只服务某一个 skill？  
2. 如果是，应放回该 skill 的 `scripts/` 并按“资产适配度”扣质量分与兑现分。  
3. 如果本身是独立运维入口，再按 bundle/L1 工具视角评价。  

## 统一判断原则

1. 先判对象类型，再决定兑现证据怎么取
2. 先问“它承诺了什么”，再问“承诺兑现了多少”
3. 兑现证据不足时，不用质量分去掩盖
