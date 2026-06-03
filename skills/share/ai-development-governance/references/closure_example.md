# ai-development-governance — 真实闭环样例

## 样例目标

面对“把 share 技能做到双 92+”这类质量提升任务，先走治理判断，而不是直接去改分或只做表层修饰。

## baseline（observed）

本会话前序已暴露的失败信号：

- 先做外层结构整理，再回头补底层质量
- 在 benchmark skill 尚未深审完成前，已经提前更新 `docs/<content-domain>`

这说明质量门与学习门当时没有真正前置。

## 治理分流（observed）

本轮处理顺序改成：

1. 先把问题归类为 **quality / interop / lifecycle** 治理问题
2. 先深审 benchmark skill
3. 再处理其它 share skill
4. 所有 share 校验通过后，最后才回写 `docs/<content-domain>`

## executed

本轮质量门实际执行结果：

```text
SKILL_ENTRYPOINTS=ok
SKILL_REFERENCES_STRUCTURE=ok
SHARE_SKILL_PRIVATE_COUPLING=ok
```

并对 13 个 share skill 全量跑过 `check-skill-size`，结果均为 `SKILL_SIZE_OK`。

## Learning Gate（observed）

用户对“只处理面上的内容”的批评被保留为真实教训，本轮已据此调整顺序：

- 先 benchmark 深审
- 再 share 全量修复
- 最后再改对外文章

这与本技能“失败 / 返工必须进入 Learning Gate，并与 `delivery-workflow` R3 对齐”的规则一致。

## 结论

本样例证明本技能已经能把“质量提升任务”从直接执行，改成先过治理判断、质量门和学习门，再进入具体落盘。
