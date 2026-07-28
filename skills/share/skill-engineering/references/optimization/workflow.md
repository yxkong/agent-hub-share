# Skill Engineering — Optimization Workflow

本流程借鉴 SkillOpt 的核心思想：skill 是可优化状态，但只能由任务证据驱动更新。

## 1. Baseline Rollout

选择一个真实任务样本，记录修改前表现：

- 用户输入
- 触发到的 skill
- 首读路径
- 输出产物
- 失败、返工或绕过规则的位置

没有 baseline 时，只能做静态 review，不能宣称优化有效。

## 2. Reflection

把问题分成四类：

| 类型 | 处理 |
|---|---|
| 触发问题 | 改 description / trigger eval |
| 路由问题 | 改 30 秒决策区或 P0 references |
| 执行问题 | 改 SOP / 门禁 / 模板 |
| 证据问题 | 改验证命令、通过判据、evidence contract |

必须同时记录 `not_promoted`：哪些只是本样本偶然偏好，不写入 skill。

## 3. Bounded Edit

每次优化只允许一种主要编辑：

| edit_type | 用途 |
|---|---|
| `add` | 增加缺失门禁、路由、reference 或 trigger 样例 |
| `delete` | 删除重复、过期、误导或第二真源 |
| `replace` | 用更准确的 SOP / contract 替换旧规则 |

禁止一次性重写整个 skill；必要时拆成多轮 rollout。

## 4. Held-out Gate

用另一个未参与修改的任务样本验证：

- 是否仍能正确触发
- 是否 30 秒内找到首读文件
- 是否减少返工或路径漂移
- 是否没有把 baseline 样本的偶然偏好泛化

held-out 失败时，回到 Reflection，不把规则提升。

## 5. Compact Best Skill

收口时执行：

- 主文件保持薄入口
- 细节下沉 references
- 历史任务只进 evidence / review，不进 `SKILL.md`
- 更新 trigger eval
- 回到父技能工程完成门，并按需转 `skill-scorecard` 做独立评分
