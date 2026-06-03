# skill-discovery — 真实闭环样例

## 场景

目标：验证“先找再建”不是口号，而是能通过标准脚本得到结构化候选。

## executed

本轮实际执行：

```text
pwsh -File scripts/find-skills.ps1 -Query testing
```

输出结果：

```text
skill          scope project path
webapp-testing share -       skills\share\webapp-testing\SKILL.md

Total: 1 skill(s)
```

## observed

这个结果说明：

- `find-skills` 能直接给出结构化候选
- 搜索不是靠手工扫目录
- 候选路径落在 canonical `skills/share/.../SKILL.md`

## 结论

本样例证明本技能已经具备“本地检索 -> 结构化候选 -> 后续 use/adapt/create 决策”的最小闭环。
