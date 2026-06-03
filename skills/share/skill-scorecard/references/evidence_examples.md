# skill-scorecard — executed / observed 证据样例

## 场景

时间：2026-05-29  
目标：对 `skills/share/` 做全包评分，不再把“结构脚本通过”误判成“已经优秀”。

## baseline（observed）

来自本会话前序复盘的已知失败信号：

- 早期优化只处理入口、README、闭环门等“面层结构”
- 在三标杆技能尚未深审完成前，已经提前改写 `docs/<content-domain>`
- 对“优秀”的判断更接近静态好感，而不是 active 全包证据

这正是 `skill-scorecard` 要拦下的通胀路径。

## retest（observed）

本轮评分先按 `SKILL.md / README.md / references / templates / scripts` 盘点 active 资产，再跑 share 级门禁：

- 先深审三标杆：`skill-scorecard`、`skill-engineering`、`delivery-workflow`
- 再修其它 share skill 的 trigger/eval、P0/P1、README/INDEX 漂移
- 最后才回到 `docs/<content-domain>` 修旧口径

行为变化点：

1. 不再把 README / INDEX 当并列入口
2. 不再只看 `SKILL.md` 给总分
3. 不再把“写得像模板”直接评成 96+

## executed

本轮已实际执行的评分配套校验：

```text
SKILL_ENTRYPOINTS=ok
SKILL_REFERENCES_STRUCTURE=ok
SHARE_SKILL_PRIVATE_COUPLING=ok
```

并对 13 个 share skill 逐个跑过 `check-skill-size`，结果均为 `SKILL_SIZE_OK`。

## 结论

本样例证明 `skill-scorecard` 的执行口径已经从“静态好感评分”转成“证据优先 + 反通胀 + 全包审计”。

仍未达到 96+ 的原因也被保留下来：

- 有 executed 的工程门证据
- 但缺 3 类以上真实任务的 observed / executed 行为复测
- 因此只能进入 90-95 优秀档，而不是标杆档
