# 评分流程

## Step 1：确认对象类型

三选一：

1. **skill**：有 `SKILL.md` 的技能目录
2. **prompt**：`*.prompt.md`、子 Agent prompt 模板、生成规则资产
3. **bundle**：一个 vendor 包或一组技能候选

若用户没说清，先按最小证据判断，不要一上来全盘扫描。

## Step 2：盘点 active 资产

评分对象是**整个 active 技能包**，不是单个 `SKILL.md`。优先盘点：

- `SKILL.md`
- `README.md`
- `references/**/*.md`（排除 `bak/`）
- `scripts/`
- `templates/`

若存在 `themes/`、`examples/`、`assets/`、`eval/`、生成器、脚手架、provider adapter 等目录，也纳入 active 资产盘点。`bak/`、历史快照、旧报告只作 P2 旁证，不进入 active 能力兑现。

如果是 prompt，再盘点：

- front matter
- eval / examples
- 被谁引用、是否仍有真实调用场景

## Step 3：读取主证据

优先级：

1. 当前真源主文件
2. 当前活跃脚本与 wrapper
3. 活跃 references
4. README
5. 历史备份 / 旧报告

**禁止**：只看 README 就打总分。README 只提供维护章程和设计哲学，不替代运行证据。

## Step 4：补校验证据

能跑则优先跑：

- `check-skill-entrypoints`
- `check-skill-structure`
- `check-skill-size`
- `check-share-skill-private-coupling`
- `check-backup-policy`（涉及备份脚本或备份契约时）
- `check-prompts`

若不能跑，必须在结论里标 `unknown`，不要伪装成“已验证”。

## Step 5：列承诺能力与证据等级

先列出对象承诺了什么，再看证据到哪里：

1. 从 `description`、核心用途、主路由、模板说明中提炼**承诺能力**
2. 给每项能力标证据等级：`executed / observed / static / unknown`
3. 若某项能力被大篇幅承诺，但只有 `static` 或 `unknown`，兑现分要明显下调
4. 若对象是 share skill，还要单独看去项目化是否被真实兑现
5. 若对象是 share skill，必须把证据拆成 `share capability / project specialization / runtime assembly`；后两者不得直接计入 shared skill 本体兑现分
6. 若对象是高风险 / 纪律类 skill，单独判断是否有**无 skill 基线样本 + 带 skill 复测样本**；没有则行为有效性不得高分
7. 若对象声明经过真实任务优化，检查是否有 baseline rollout、reflection、bounded edit、held-out validation；缺失时按 `scoring_dimensions.md` 封顶
8. 若对象承诺研发交付、上线、质量门禁或失败学习，检查是否覆盖主链证据矩阵、Release Evidence、Task Replay Lite / Skill Health Signal；缺失时按 `scoring_dimensions.md` 封顶

## Step 6：逐维打分

按 `scoring_dimensions.md`：

1. 先判是否触发质量分 / 兑现分封顶与门禁阻断
2. 再对照 `calibration_examples.md` 选择最接近档位，明确是否具备 96+ 标杆证据
3. 再给**质量分**各维度，特别检查首读效率与主文件纯度
4. 再给**兑现分**各维度，特别检查行为有效性与 active 资产兑现
5. 最后输出双分和门禁结论

## Step 7：输出 findings-first 结论

当用户语义偏 review / 审查 / 风险排查：

1. 先列问题（高 → 中 → 低）
2. 再给质量分 / 兑现分评分表
3. 再给门禁结论、证据等级和整改建议

## bundle 额外规则

对 bundle 默认做两层判断：

1. **单技能层**：抽评分数最高的 2–5 个 active skill
2. **整体层**：看命名一致性、路径一致性、脚本层级、重复资产、安装可用性

如果 bundle 内同名能力重复、路径漂移严重、安装链不一致，整体结论应下调一档。

## 输出口径

默认按下面顺序输出：

1. Findings
2. Quality Score
3. Fulfillment Score
4. Verdict
5. Fact / Unknown / Risk
6. 建议动作
