# Evidence Contract

## 最小证据包

```yaml
skillopt_rollout:
  target_skill: ""
  baseline_task:
    input: ""
    expected_behavior: ""
    observed_behavior: ""
    evidence_level: static | observed | executed
  reflection:
    failure_type: trigger | routing | execution | evidence | overfit
    root_cause: ""
    not_promoted: []
  edit:
    type: add | delete | replace
    files: []
    rationale: ""
  held_out_task:
    input: ""
    expected_behavior: ""
    observed_behavior: ""
    evidence_level: static | observed | executed
  verdict: improved | unchanged | regressed | unknown
```

## 证据等级

| 等级 | 含义 |
|---|---|
| `executed` | 实际运行脚本、测试、校验或真实任务产物 |
| `observed` | 有可靠输出、日志、diff 或用户可见产物 |
| `static` | 只读文件、路径、规则和样例 |
| `unknown` | 无法确认，不得宣称有效 |

## 通过判据

优化有效必须同时满足：

- baseline 中的问题被修正或明确降级为 trade-off
- held-out 未回归
- 目标 skill 主文件没有膨胀成案例手册
- 更新后的规则能被 `skill-scorecard` 识别为 evidence，而不是口号

## 失败判据

任一命中则不得宣称优化完成：

- 没有 baseline 任务
- 没有 held-out 任务
- 只因为一个样本改写账号/项目偏好
- 改动后路径、trigger eval 或 README 漂移
- 校验脚本失败且未解释为存量无关问题
