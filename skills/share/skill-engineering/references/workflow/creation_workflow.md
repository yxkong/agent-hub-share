# Create Workflow

适用于从零创建 skill，目标不是先做一份很完整的说明书，而是先做出一份结构正确、触发准确、能指导 AI 行动的最小可用 skill。

## 先做 30 秒判断

只有当前任务明确属于 `create` 时才走本文件：

- 还没有现成 skill
- 已知要服务什么任务与场景
- 目标是产出新的 skill 资产，而不是推进一个真实业务需求

如果当前主要问题是"这个需求怎么开发"，转 `delivery-workflow`。

## 默认原则

- 默认从 `standard` 起步，不默认 `full`；轻量单一任务型可降为 `lite`
- 主文件先做路由器，不先堆细节
- 先让 skill 能被触发、能指导 AI 定位和执行，再补扩展内容
- references 只按需增加，不先铺满
- 主文件只放稳定入口、协议和硬规则；不要把 human-only / maintenance-only 文件、具体业务样例或可变资产清单写进 `SKILL.md`

## 创建步骤

### Step 1：定义服务对象

先回答 4 个问题：

- 这个 skill 解决什么问题
- 在什么场景下触发
- 最终希望 AI 做出什么行为
- 它不负责什么

输出：

- 作用边界
- 一句话目标
- 不负责项

### Step 2：选择路由与输出级别

先固定两件事：

- 当前主路由就是 `create`
- 输出级别是 `lite / standard / full` 中哪一个

默认建议：

- 大多数共享技能 / 项目技能：`standard`（默认起点）
- 单一任务型 / 轻量内部技能：可降为 `lite`
- 高复用、高风险、跨团队：`full`

同时做一个风险判断：

- 如果这个 skill 容易被**时间压力、沉没成本、速度偏好、权威催促、疲惫**绕过，按**高风险 / 纪律类 skill**处理
- 这类 skill 在 create 阶段就要规划行为验证证据；细则见 `review/behavioral_eval.md`

### Step 3：固定目录布局 + 根 README.md

先按 `layout/skill_directory_layout.md` 建好：

```text
<skill>/
├── SKILL.md
├── README.md
├── templates/      # 有可复制产出时必填
├── scripts/        # 可选
└── references/
```

从 [templates/TEMPLATE_SKILL_README.md](../../templates/TEMPLATE_SKILL_README.md) 复制根 `README.md`。**禁止**把空白 `TEMPLATE_*` 放在 `references/templates/`。

章程必填项见 `layout/skill_root_readme.md`。

新增硬要求：

- README 必须明确写出：**这是维护章程，不是 Agent 运行入口**
- README 必须包含：**核心用途 / 设计理解 / 分层原则 / 维护约束 / 单一职责 / 不负责**
- 若 skill 会新增 trigger / eval / 审查增强文档：README 必须说明它是**独立主路由**还是**挂靠现有路由**
- 若你说不清“为什么这个 skill 要独立存在”，先不要进入 Step 4

### Step 4：先写主文件总纲

主文件优先只写：

- 作用边界
- 何时使用
- 任务或场景路由
- 输出级别
- 红线
- references 优先级

不要先在主文件里铺满：

- 大段背景
- 长示例
- 复杂字段映射
- 多层规则细节
- 给人读的维护索引
- 具体业务 prompt / 示例资产清单
- 会频繁变化的脚本、主题、provider、示例列表

主文件写完后做 30 秒自检：

- Agent 是否能在 30 秒内知道先读哪个 active 文件
- `SKILL.md` 是否仍是路由器，而不是手册
- README / INDEX / 子目录 README 是否已降权，未与 `SKILL.md` 并列入口

### Step 5：补最小可执行内容

**先**对照主文件里声明的**输出级别**（`lite` / `standard` / `full`，默认多为 `standard`），用 `governance/output_levels.md` 作为验收标尺，避免「声称 standard、只交付 lite」：

| 级别 | Step 4 必交付（content） |
|------|-------------------------|
| **lite** | 作用边界；精确切入点（类/方法/文件）；最小 SOP（主流程约 3 步内）；1 个验证样例；省略其它要素时写明原因 |
| **standard** | 在 lite 基线上对齐 **五要素**：设计理念（边界与核心约束）；流转/数据流（外部对接类须 Mermaid）；切入点；动作化 SOP（覆盖新增/修改/排查）；核心示例 + 可验证结论 |
| **full** | 满足 standard，并额外交付 `review/full_mode_checklist.md` 所列项（触发/评估等加强） |

与级别无关的**公共下限**（任何新建 skill 都应满足）：

- 1 份清晰 `description`（front matter + 与正文一致）
- 1 组明确切入点或场景入口
- 1 份可执行 SOP（级别越高，覆盖面越完整）
- 1 个核心示例（级别越高，越贴近真实任务）
- 1 条可操作的验证方式
- 1 条明确的首读路径：触发后先读哪份 active 文件
- 1 个主文件纯度判断：`SKILL.md` 不承担 README、INDEX、handbook 或示例库职责

### Step 5.5：闭环能力裁剪（按类型创建，不机械铺满）

新建 skill 时必须先判断它是否承诺以下能力；命中才创建对应 reference / checklist / eval，未命中则不要为了“完整”硬塞文件：

| 承诺能力 | 需要内建什么 | 不需要做什么 |
|---|---|---|
| 真实研发交付 / 验证收口 | 可映射到 `delivery-workflow/references/gates/mainline_evidence_matrix.md` 的主链证据口径；至少区分 `static / contract / runtime / user-visible / release / limitation` | 不把 delivery 全流程复制进领域 skill |
| 上线 / 发布 / 灰度 / 回滚 | `Release Evidence`：观察窗口、观察入口、回滚触发条件；归 `ai-development-governance` Gate | 不新增独立 `release-ops-runbook` |
| 失败学习 / 重复返工治理 | `Task Replay Lite`：触发输入、缺失证据、误判 gate、回填位置 | 不新增 skill health dashboard |
| skill 行为健康 / 触发误判 | `Skill Health Signal`：同类返工、SOP 找不到入口、trigger 误判 → bad smell / trigger eval / design principles | 不在业务 skill 主文件复制整段钩子协议 |
| 备份脚本 / 备份契约 | 工程完成门补跑 `check-backup-policy`，并说明 `BACKUP_POLICY=ok` 是通过判据 | 不用手写 `cp` 或临时备份命令替代 |

若该 skill 属于**高风险 / 纪律类**，再额外补一层最小要求：

- 1 条**无 skill 基线样本**：证明没有 skill 时，Agent 默认会怎么走老习惯
- 1 条**带 skill 复测样本**：证明加入 skill 后，行为确实发生改变
- 若当前物理上无法执行该层验证：在产物与结论中明确标 `unknown`，不要写成“已证明有效”

**不要**在业务 skill 的根 `SKILL.md` 里新增 `## 反馈闭环协议` 或整段「钩子」模板：**钩子不写入被创建技能的主文件**（见共享技能 `skill-engineering` 的 `SKILL.md` → `## 技能钩子协议`）。坏味道的路由前读、路由后写、N=2 提升等，一律以 `skill-engineering` 正文与 `governance/bad_smell_registry.md` 为单一真源；本次 `create` 在 Step 6 对 registry 与工程门负责即可。

### Step 6：按需下沉 references

只有出现下面情况才新增 references：

- 主文件已经过长
- 有长示例需要拆出
- 有图表、字段映射、装配说明需要单独维护
- 有 trigger / eval 细则需要单独维护

若该 skill 是高风险 / 纪律类，并且行为验证会长期复用，可增加挂靠型增强文档；但必须在 README 与 `SKILL.md` 说明它是**独立主路由**还是**挂靠 `review` / `refine-trigger`**。

### Step 7：反馈沉淀 + 工程完成门（必做，不可省略）

完成 Step 1-6 后，**先**对照下方「最低验收」核对**内容质量**；然后 **在本 Step 内顺序做完第 1–5 项**，**不得**在只做 1–4 时宣布 `create` 路由结束。

1. **坏味道检查**：回顾本次 create 过程，命中信号则追加到 `governance/bad_smell_registry.md`（**待提升草案**区），已有条目更新次数
2. **description 复读**：确认 frontmatter `description` 与实际内容和触发场景吻合，不同步则当场修正
3. **自我改进判断**：对照共享技能 `skill-engineering` 的 `SKILL.md`（`## 反馈闭环` / `## 技能钩子协议`），判断本次经验是否要固化为对 `creation_workflow.md` 或 `governance/design_principles.md` 的改动（**不要**往新建业务 skill 主文件抄整段协议）
4. **Router/Handbook 门禁**：多域或含 handbook 候选时，按 `review/router_handbook_gate.md` 自检；维护 `references/INDEX.md`
5. **工程完成门（收尾必备）**：对本次新建 skill 按 `review/engineering_completion_gate.md` 执行 **§1 → §2 → §3 → §4 → §5** 全链路，且各脚本 **exit 0**

第 5 项全部通过后，本次 `create` 路由方可结束。

## 新建 skill 的最低验收

- 根目录 `README.md` 已存在且 §不负责 含转交表（见 `layout/skill_root_readme.md`）

**内容**（在 Step 7 第 5 项之前应已满足）：

- 主文件声明的 `lite` / `standard` / `full` 与 `governance/output_levels.md` 及上方 Step 4 表格一致，禁止「声称 standard、只交付 lite」
- description 能回答 WHAT + WHEN
- README 说明了“为什么这样设计”，而不只是“这个 skill 做什么”
- README 说明了 README / SKILL / references 的分工，避免维护时漂移
- 若 skill 有 trigger / eval 增强文档：README 与 `SKILL.md` 已说明它的入口关系（独立 / 挂靠）
- 若 skill 属于高风险 / 纪律类：已准备 1 条无 skill 基线样本 + 1 条带 skill 复测样本；若无法执行，已明确标 `unknown`
- skill 能指导 AI 快速定位起点
- 触发后 30 秒内能判断首读 active 文件
- `SKILL.md` 未混入 human-only / maintenance-only 枚举、具体业务样例或可变资产清单
- SOP 是动作化的，不空泛
- 至少 1 条真实提示可触发并得到可用结果
- 业务 skill 根 `SKILL.md` **不含**从 `skill-engineering` 复制的整段反馈闭环/钩子协议（维护单源见 Step 4）

**工程**（必须由 Step 7 第 5 项落实，详见 `review/engineering_completion_gate.md` §1–§5）：入口校验、references 拓扑、`check-skill-size`、挂载、`§5` 真实触发自检全部通过

## 常见失败信号

- 一上来就做 full 版，导致主文件过重
- 只有理念，没有切入点
- 只有结构，没有触发验证
- references 过多，主文件失焦
- 新建 skill 但边界仍然模糊
- 缺少根目录 `README.md` 或 §不负责 未写转交
- 未完整执行 Step 7（缺 1–3 任一项，或缺第 4 项工程完成门 **§1–§5**）
