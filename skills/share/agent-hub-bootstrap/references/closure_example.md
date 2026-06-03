# agent-hub-bootstrap — 真实闭环样例

## 场景

目标：验证 hub 当前入口与工作区链接状态可被脚本识别，而不是只靠肉眼判断。

## executed

本轮直接执行：

```text
pwsh -File scripts/check-skill-links.ps1
```

得到结果摘要：

```text
Name                      Exists SkillMd
.cursor                   True   False
agent-hub-share           True   False
private-hub-root          True   False
rules                     True   False
```

## observed

这个结果说明：

- 脚本能列出当前工作区关键入口
- 挂载问题可以通过标准入口排查，而不是手工猜路径
- 本技能的价值在“可见性与校验”，不在正文质量

## 结论

本样例证明 `agent-hub-bootstrap` 已有可执行的非破坏性校验闭环，适合作为 install / diagnose / sync 任务的入口样例。
