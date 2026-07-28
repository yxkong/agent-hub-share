# Spec Compiler Optimization Evidence

## Baseline

```yaml
skillopt_rollout:
  target_skill: ai-development-governance
  baseline_task:
    input: "为一个跨运行时、知识检索、动态查询和安全审计能力生成 Product Spec、ADR 与实施计划"
    expected_behavior: "Fact Pack → Spec → SDD/ADR → Task Contract → frozen gate"
    observed_behavior: "生成内容丰富，但状态未冻结、缺 SDD、Task Contract 不完整，普通 diff 检查未覆盖未跟踪文件"
    evidence_level: observed
  reflection:
    failure_type: execution
    root_cause: "模板、生成 SOP、文档元数据和校验脚本没有形成单一编译契约"
    not_promoted:
      - "特定检索、数据库和查询安全规则"
      - "业务项目路径、类名和数据源事实"
```

## Bounded Edit

本轮主编辑类型为 `replace`：用 Spec Compiler 契约替换“复制模板 + 标题字符串检查”的旧生成方式。为兑现该替换，新增 Python 核心、回归测试和本说明；没有创建平行 Skill。

## Held-out

| 样例 | 目标 | 证据 | 结果 |
|---|---|---|---|
| backend | 单端后端需求的冻结与追踪 | `test_three_held_out_bundles_are_implementation_ready` | executed / pass |
| fullstack | 前后端契约联动 | 同上 | executed / pass |
| security | 权限和安全约束 | 同上 | executed / pass |
| negative | review Spec、proposed ADR、版本漂移、缺追踪 | 对应 unittest | executed / rejected |

## Execution Evidence

- `python skills/share/ai-development-governance/tests/test_spec_compiler_check.py`：`Ran 10 tests`，`OK`。
- PowerShell template + JSON：`SPEC_SDD_STRUCTURE=ok checked=5 mode=template`。
- POSIX sh：语法检查与 template 执行均通过。
- 旧 NL2SQL 文档 baseline：`document` 模式按预期 exit 1，JSON 记录 88 条 violations；未修改业务文档。
- Hub 全量门禁：重建 `ai-rd-governance` 插件后，`CHECK_HUB_ALL=ok checked=21`。

## 行为与限制

- 已证明：确定性校验器能阻断结构、状态、版本和追踪错误。
- 已证明：PowerShell wrapper 与 Python 核心在模板模式下行为一致。
- `unknown`：尚未用多个独立 Agent 会话证明生成文本本身的质量提升。
- 方案 C 前置：收集至少三个真实项目 Spec 的重复生成稳定性、人工返工次数和追踪完整率。

## Verdict

```yaml
verdict: improved
evidence_level: executed
remaining_risk:
  - "业务事实真实性仍依赖项目技能和验证命令"
  - "生成行为的跨模型 held-out 仍需后续复测"
```
