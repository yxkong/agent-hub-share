# tdd-workflow — 真实闭环样例

## 样例目标

用最小真实命令演示 `Red -> Green -> Evidence`，证明本技能不只是理念说明。

测试对象：`normalize_role('Admin')` 应返回 `admin`

## Red（executed）

执行命令后先得到失败测试：

```text
test_lowercases_admin (__main__.NormalizeRoleTests.test_lowercases_admin) ... FAIL
AssertionError: 'Admin' != 'admin'
FAILED (failures=1)
```

失败点很明确：实现没有先满足预期行为。

## Green（executed）

把实现改为 `value.lower()` 后再次执行，得到：

```text
test_keeps_lowercase (__main__.NormalizeRoleTests.test_keeps_lowercase) ... ok
test_lowercases_admin (__main__.NormalizeRoleTests.test_lowercases_admin) ... ok
OK
```

## Refactor

本样例为了保持“最小绿灯”，没有继续做额外结构重构；这与 `tdd-workflow` 的“绿灯时不顺手大重构”规则一致。

## Evidence

- 证据等级：`executed`
- 有明确 Red 失败输出
- 有明确 Green 通过输出
- 样例虽小，但闭环完整，可用于说明本技能的最小执行节奏

## 限制

这是技能内自证 demo，不替代项目内真实测试框架、CI、覆盖率或契约测试；实际业务任务仍应回到项目领域技能与 `delivery-workflow`。
