# 行为审计

## 偏航信号

- 先实现后补一个永远通过的测试，却宣称 TDD。
- 只测 happy path，不覆盖 bug 复现或契约边界。
- 测试失败原因不读，直接改生产代码猜修。
- 重构后不重跑同一组测试。

## 反证问题

- Red 阶段是否真的失败在目标行为上？
- Green 阶段的实现是否只为当前测试最小通过？
- 如果删除这条测试，回归风险会不会重新出现？
- 无法写/跑测试的原因是 blocker 还是只是成本偏好？

## 闭环证据

- Red / Green / Refactor / Evidence 四段至少有命令、结果和范围。
- bugfix 必须有回归测试或明确 limitation。
- 契约测试要标出请求、响应、错误和序列化边界。

## 回灌动作

- 同类“伪 TDD”重复出现，进入 bad smell 计数。
- 项目缺测试基础设施时，回到 project skill 或 agent-hub-bootstrap 补最小脚手架建议。
- 稳定测试模板可沉淀为 prompt 或 project reference。
