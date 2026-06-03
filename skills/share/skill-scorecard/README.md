# skill-scorecard

## 核心用途

用一套统一但可分类型适配的框架，评估 AI `skill`、`prompt` 与 `bundle` 的**质量**、**能力兑现度**与**门禁结论**。

它解决的不是“这个资产写得漂不漂亮”，而是“它是否值得挂载、复用、继续维护”。

## 设计理解 / 评分哲学

### 为什么不是单总分

单总分会把两类完全不同的问题混在一起：

1. **质量问题**：边界、契约、SOP、结构、维护成本是否专业
2. **兑现问题**：路径、脚本、模板、验证、挂载链是否真的让承诺能力落地

很多资产会出现“文档写得不错，但兑现很差”的情况。  
所以本技能默认输出：

- **质量分（100）**
- **兑现分（100）**
- **门禁结论**

### 为什么要单独给门禁结论

有些 skill 质量分可以很高，但如果：

- 关键路径失效
- 脚本不可运行
- 模板漂移
- share 资产仍绑定私有项目

那它就不应该被判定为“可挂载”。  
因此门禁结论不从平均分自动推出，而由硬条件控制。

### 为什么 skill / prompt / bundle 共用一个框架

它们都要回答同一个问题：

> 这个资产是否清晰、可执行、可验证、可维护、可复用？

但细项权重不同：

- `skill` 更看脚本、路径、SOP、挂载与执行闭环
- `prompt` 更看输入/输出契约、eval、模板稳定性、去项目化
- `bundle` 更看一致性、重复资产、安装可用性与整体质量分布

所以本技能采用：

- **同一评分哲学**
- **按资产类型适配细项**

## 分层原则

- `README.md`：**给维护者读的章程**。解释为什么这样设计、哪些地方不能漂；**不参与运行入口**
- `SKILL.md`：**给 Agent 的运行入口**。只放路由、规则、P0 references
- `references/`：评分维度、workflow、适配器、模板等细则
- `scripts/` / `templates/`：若未来补充评分辅助脚本或固定输出模板，再放这里；当前不预设

## 维护约束

- 不得退化回“单总分”模型
- README / SKILL / references 的分工不得漂移
- 调整评分维度时，必须同步检查：
  - `references/scoring_dimensions.md`
  - `references/workflow.md`
  - `references/asset_type_adapters.md`
  - `references/report_template.md`
- 若门禁规则变化，必须同步更新 `skill-engineering` 的 create / review / gate 联动文档
- 若新增评分对象类型，必须补 `asset_type_adapters.md`，不能只在主文件口头提到
- 若出现 96+ 或“标杆”结论，必须对照 `references/calibration_examples.md`，说明 `executed/observed` 证据与行为复测是否足够

## 单一职责

1. 评估 skill / prompt / bundle 的质量
2. 评估承诺能力的兑现度
3. 给出门禁结论与证据等级
4. 识别脚本错层、路径漂移、share 私有耦合、模板过期等问题
5. 输出可执行的整改建议

## 不负责 / 转交

| 场景 | 转交 |
|------|------|
| 直接重写或修复 skill 正文 | `skill-engineering` |
| 直接撰写 / 发布 prompt 正文 | `prompt-engineering` |
| 同步 / 挂载 / publish skill | `agent-hub-bootstrap` |
| 真实研发任务推进 | `delivery-workflow` |

## 入口

- **运行入口（Agent）**：`SKILL.md`
- **维护章程（人读）**：`README.md`
- **评分细则**：`references/scoring_dimensions.md`
- **输出模板**：`references/report_template.md`
- **references 索引**：`references/INDEX.md`
- **executed / observed 样例**：`references/evidence_examples.md`

## 真源与挂载

- 真源：`$AGENTS_HUB_ROOT/skills/share/skill-scorecard/`
- 用户级或工作区 `skills/` 目录中的同名路径仅为挂载镜像，不是真源

## 修订记录

| 版本 | 日期 | 说明 |
|------|------|------|
| 1.2.0 | 2026-05-28 | 增加评分校准样例与 96+ 反通胀规则，避免静态审计虚高 |
| 1.1.0 | 2026-05-28 | 升级为质量分 100 + 兑现分 100 + 门禁结论；README 固化设计哲学与维护约束 |
| 1.0.0 | 2026-05-28 | 初版：覆盖 skill / prompt / bundle 评分、脚本错层、路径完整性与 share 去项目化 |
