---
title: 坏味道规则库
updated: 2026-05-03
summary: 技能工程中重复出现问题的模式抽象库。与主技能一致：N = 2，同一模式计数 ≥ 2 → 提升至 design_principles.md 反模式条目。分区：仅「待提升草案」含计数<2；已提升条目不得留在草案区。
---

# 坏味道规则库

> **定位**：将 skill 使用中重复发生的问题提炼为**通用可复用规则**。  
> 记录时剥离所有业务背景（不记项目名、session 日期、具体 PR）；只保留触发模式和规则。  
> **N = 2**（与 `SKILL.md` / 钩子协议一致）：同一模式累计触发 **≥ 2 次**，立即提升至 `design_principles.md` 反模式表。

---

## 记录格式

```
[PATTERN_ID] **模式名**
- 触发条件：[触发信号，与具体业务无关]
- 规则：[可执行的通用修复规则]
- 计数：N | 状态：草案（待提升）/ 已提升 → design_principles.md §六
```

---

## ✅ 已提升（规则已同步至 design_principles §六）

> **只读区**：条目已进 `governance/design_principles.md` §六，此处保留可追溯摘要。**禁止**把仍待统计的草案放在本区。

[MAIN_FILE_BLOAT] **主文件膨胀**
- 触发条件：主文件 **非空行**（trim 行首行尾空白后仍非空的物理行，见父技能 `SKILL.md` §主文件行数）超过**所属类型**上限（纯路由 80 / 路由器+硬约束 130 / 多域 150 / 元技能 160）；或以打补丁方式持续追加、未配套下移细节到 references
- 规则：超过所属类型非空行上限立即拆分；一切细节下沉 `references/`；自检须用 hub **`check-skill-size.sh` / `check-skill-size.ps1`**（见 `AGENTS_HUB_ROOT/scripts`），禁止各模型自拼 `awk`
- 计数：2 | 状态：已提升 → design_principles.md §六

[SUBSKILL_MERGE_INCOMPLETE] **子技能合并不彻底**
- 触发条件：子技能被设为重定向文件后，主技能 references 中仍存在跨目录相对路径（`../other-skill/references/`）
- 规则：合并时必须物理迁移 references/*.md 到主技能目录；所有链接改为主技能内相对路径；原目录保留为只读归档
- 计数：2 | 状态：已提升 → design_principles.md §六

[REFS_DEPTH_VIOLATION] **references 目录层级违规**
- 触发条件：`references/` **顶层**（不含 `bak/`）`*.md` **多于 15 个**（≥16）仍未按语义划分子目录；或路由表无法覆盖全部文件，部分 references 成为孤儿文件
- 规则：顶层 **`*.md` >15** 时必须划分语义子目录（≤4 个子目录，**每个**子目录内 `*.md` ≤15）；子目录名用语义词（`ddd/` `core/` `platform/`），禁用序号；SKILL.md 路由表同步更新路径；分组时先做路由补全，再做物理搬迁（降低链接断裂风险）
- 计数：2 | 状态：已提升 → design_principles.md §六

[BAK_SKILLMD_DISCOVERABLE] **bak 或 dated 快照中保留 SKILL.md 文件名**
- 触发条件：skill 包或 project 级 `bak/**`、dated 目录内存在名为 `SKILL.md` 的文件；或挂载入口与 hub 真源被当并列 truth source
- 规则：仅 canonical 路径可为 `SKILL.md`；备份用 `_SKILL.md` / `SKILL-<stamp>.md` / `SKILL_md/`；`check-skill-entrypoints` fail；见 `layout/skill_truth_source_contract.md`
- 计数：2 | 状态：已提升 → design_principles.md §六

[VALUE_GATE_MISSING] **价值门禁缺失导致规则违规被包装成资产**
- 触发条件：经验提炼类 skill 把字段补齐、命名规范、软删除缺失、普通 bug、AI 未遵守用户规则导致的返工输出为优化点；或用户提供局部片段时混入输入范围外的旧上下文
- 规则：经验提炼前必须先做输入范围隔离、历史会话来源识别、价值门禁和外部读者表达转换；候选至少能回答技术能力、个人成长、业务价值之一，否则进入 discarded 或 rule_improvement_candidates，不生成优化点卡片；遵循既有 SQL/工程规范即可避免的问题默认不入资产；主表达必须讲清"原系统问题 -> 解决方案 -> 效果"，内部编号只进证据附录
- 计数：3 | 状态：已提升 → design_principles.md §六（历史累计；提升协议以 N=2 为准）

[PRODUCT_REVIEW_INCREMENTAL_TRAP] **产品级 review 陷入一次一点**
- 触发条件：同一个完整产品型 skill 连续多轮 review，每轮只发现一个局部问题；用户要求"不要一次一点，做全量 review"
- 规则：先做全量文件清单，再交叉检查主流程、脚本行为、文档承诺、模板、示例、生成物；最终结论前重新读最新文件；经过至少两轮检查后一次性输出所有剩余问题，已确认修好的点不重复输出
- 计数：2 | 状态：已提升 → design_principles.md §六

[DOC_SCRIPT_CONTRACT_DRIFT] **文档、脚本、模板契约漂移**
- 触发条件：脚本行为已经改变，但 README、reference、模板、示例或脚本头注释仍保留旧规则，导致后续模型按旧文档执行
- 规则：改脚本必须同步 grep 旧关键词并更新所有对外承诺；脚本通过只是行为验证，不代表产品闭环通过；review 必须同时看脚本、wrapper、文档、模板和生成物
- 计数：2 | 状态：已提升 → design_principles.md §六

[HIDDEN_SCRIPT_MODE] **内部能力未暴露到标准脚本入口**
- 触发条件：底层 Python/Node/内部实现新增 flag 或能力，但标准 `.ps1` / `.sh` wrapper 未暴露，用户或模型只能绕过脚本调用内部入口
- 规则：任何用户可用能力都必须通过跨平台 wrapper 暴露；新增 flag 同步 PowerShell / POSIX 两端、用法注释和关联文档；禁止把内部入口当默认操作路径
- 计数：2 | 状态：已提升 → design_principles.md §六

[MACHINE_INDEX_ID_FABRICATION] **机器索引伪造资产身份**
- 触发条件：索引脚本为缺失 id 的文件生成路径 hash、占位 id 或其它伪身份，导致非资产文件、派生文件或路径变化被误判为新 canonical asset
- 规则：资产身份必须由真实源显式声明；机器索引只收 canonical 事实源；缺必需 id 默认失败，审计/迁移模式只能显式开启并跳过报告，不得伪造 id
- 计数：2 | 状态：已提升 → design_principles.md §六

[CROSS_PLATFORM_WRAPPER_DRIFT] **双平台 wrapper 语义漂移**
- 触发条件：PowerShell 与 POSIX 脚本参数、默认失败策略或解析行为不一致；例如一端支持 flag，另一端缺失或参数分支未消费导致死循环
- 规则：`.ps1` 与 `.sh` 必须同语义；shell case 分支必须 `shift`；新增 flag 要验证默认模式、flag 模式和错误模式；文档示例同时覆盖两端
- 计数：2 | 状态：已提升 → design_principles.md §六

[LAYOUT_SIZE_OVER_ARCHITECTURE] **用尺寸修补信息架构问题**
- 触发条件：页面/技能产物出现长表单、复杂配置、多个大文本/JSON 字段时，只通过加宽弹窗/抽屉、调 label-width、加滚动容器来修，而没有先判断是否应拆成 tabs、steps、分段导航或统一布局抽象
- 规则：先做信息架构分流，再做布局参数；配置型复杂对象优先 tabs，流程型优先 steps，仍需大量滚动时升级独立页面；可复用布局能力必须沉到公共组件/公共样式/公共 hook，不得让每个页面复制 drawer body/footer/width 处理
- 计数：2 | 状态：已提升 → design_principles.md §六

[MULTI_ROUTER_PARALLEL] **多套路由并存**
- 触发条件：除 `SKILL.md` §2 外，`README`/`INDEX`/`TRIGGER_KEYWORDS`/子目录 README 也可被 Agent 当作任务入口；或三表路由不一致
- 规则：仅 `SKILL.md` §2 为 Agent 入口；meta 文件头 blockquote 禁止入口；维护 catalog 与关键词表同步 SKILL，不得独立路由；见 `review/router_handbook_gate.md`
- 计数：2 | 状态：已提升 → design_principles.md §六

[HANDBOOK_NO_TIER] **大文档未分层为 P2 handbook**
- 触发条件：规约摘录/模块百科/反模式全文（通常 >150 行）与 rule card 同级且 SKILL 未标注 P2「禁止通读」；review 跳过 `quick_gate.md` 直接指向 handbook 或系统详表
- 规则：迁入 `references/handbook/`；SKILL §2 标 Tier；旧路径 stub；review 默认先 `quick_gate.md`，系统修复再进 checklist；见 `review/router_handbook_gate.md`
- 计数：2 | 状态：已提升 → design_principles.md §六

[REDIRECT_STUB_NO_VALUE] **无外部引用的中转索引仍保留**
- 触发条件：SKILL 已能直达 active reference，旧 `modes/*.md` 或 redirect stub 只重复阅读顺序、无外部依赖
- 规则：删除中转文件并从 INDEX 移除；把必要顺序与裁决直接写入 SKILL 路由，勿为 stub 而 stub
- 计数：2 | 状态：已提升 → design_principles.md §六

---

## 📋 待提升草案（仅计数 < 2）

> 新条目**只加在本区**。计数到达 2 并完成 design_principles 写入后，将全文**移动**到「已提升」区，并从本区**删除**，避免「已提升」与「待决策」混排。

[HUB_PLACEMENT_BYPASS] **技能直接写入挂载入口而非 hub**
- 触发条件：`create`/`extract` 写回时，技能真实文件直接创建在挂载入口（`.cursor/skills/`、`.agents/skills/`、`~/.claude/skills/`、`~/.cursor/skills/`、`~/.codex/skills/` 等）而非 hub，或未先写 hub 就跑挂载
- 规则：先在 `$AGENTS_HUB_ROOT/skills/share/<skill>/` 或 `$AGENTS_HUB_ROOT/skills/projects/<key>/<skill>/` 落真实源；挂载**仅**通过 `install-hub` / `publish-skill` / `init-project-agenting` 等 **`agent-hub-bootstrap` 脚本**完成，**禁止**手拼 `ln -s`、junction、`mklink`；装配必读 `layout/placement_and_junctions.md` 与 `review/engineering_completion_gate.md`
- 计数：1

[BACKUP_SCRIPT_BYPASS] **备份脚本被绕过**
- 触发条件：执行备份时 agent 自行组装 `cp` + 时间戳命令，而不是调用 `backup-file.sh / backup-file.ps1`
- 规则：备份必须调用标准脚本；若 `AGENTS_HUB_ROOT` 未配置，优先修复环境变量，而不是降级为手工命令
- 计数：1

[BACKUP_POLICY_DRIFT] **备份策略脚本与实现漂移**
- 触发条件：`backup-file.*` 行为、脚本注释、`check-backup-policy.*` 期望不一致；或在 Windows PowerShell 5.1 下使用不兼容参数导致校验脚本反复报错。
- 规则：改备份脚本或备份契约时必须同步 wrapper、检查脚本、文档说明，并跑 `check-backup-policy`；输出应包含 `BACKUP_POLICY=ok`。
- 计数：1

[TEMPLATES_UNDER_REFERENCES] **空白模板放在 references/templates**
- 触发条件：技能将可复制的 `TEMPLATE_*` 放在 `references/templates/` 而非技能根 `templates/`，与 `skill-engineering` 及 `skill_directory_layout` 不一致，导致路径与 `doc-script-governance` 双心智
- 规则：空白模板一律迁到根 `templates/`；`references/` 只放规则 md；`references/templates/` 仅留跳转 README；见 `layout/skill_directory_layout.md`
- 计数：1

[DDD_TEMPLATE_INCOMPLETE] **DDD 四层模板不完整**
- 触发条件：开发者按模板操作后，仍需额外查其他文件才能搭出标准骨架
- 规则：模板文件必须覆盖全部四层产物（Domain / Infra / Application / Adapter），且每层有可直接复制的代码骨架
- 计数：1

[CLASS_PATH_SHALLOW] **类路径写法过浅，子目录缺失**
- 触发条件：skill references 中类路径写为 `service/impl/Foo`，实际为 `service/prompt/impl/Foo`；代码对照校验时出现路径不对、找不到类的情况；同类问题在多个 reference 文件重复出现
- 规则：技能中引用类路径必须精确到实际子目录（从代码验证，不从猜测）；full 模式校验时必须用 Glob 确认路径存在再写入；不确定的标 assumption 而非省略子目录层
- 计数：1

[SKILL_ROUTE_BROKEN_LINK] **SKILL 路由指向不存在或已搬迁路径**
- 触发条件：SKILL 主路由表链接 `references/xxx.md` 但文件已删/已迁子目录（如 `dynamicFormFields.md` vs `patterns/dynamicFormFields.md`）；Agent 打开 404 等价空链
- 规则：review 时对 SKILL 每条 `references/` 链接做存在性核对；搬迁后批量 grep 旧路径；INDEX catalog 同步删条目
- 计数：1

[ORPHAN_ACTIVE_REFERENCE] **active reference 未进主路由**
- 触发条件：`references/` 存在业务 active `*.md`（非 redirect/meta/bak）但 SKILL 主路由表无对应行（如 `anti_patterns_bi.md`、`bi_module_conditions.md`）
- 规则：要么补 SKILL 一行 + INDEX `in_route=是`；要么迁入 handbook/P2 并标注「禁止通读」；禁止长期 orphan
- 计数：1

---

## 使用说明

### 路由开始前

读本文件：**先看「待提升草案」**有无与当前任务相关的模式；再扫「已提升」避免重复造轮。

### 路由结束后

检查本次操作是否触发了已知模式（增加计数）或新模式（新增条目）：

1. **命中「待提升草案」中某条** → 计数 +1；若达到 2 → 执行 **提升协议**，将条目**移入「已提升」区**，并从草案区删除
2. **发现新模式** → 按格式追加到 **「待提升草案」**，计数=1
3. **未发现问题** → 不追加（保持信噪比）

### 提升协议（计数达到 2）

1. 将条目的「规则」部分写入 `design_principles.md §六 反模式`
2. 将本条**完整正文**追加到本文件 **「已提升」** 区，并标注 `状态：已提升`
3. 从 **「待提升草案」** 区**删除**该条目，避免双区重复

---

## 已提升历史索引（条目 ID）

按需检索设计原则正文时，用下列 ID 对齐 `design_principles.md §六`：

`MAIN_FILE_BLOAT` · `SUBSKILL_MERGE_INCOMPLETE` · `REFS_DEPTH_VIOLATION` · `BAK_SKILLMD_DISCOVERABLE` · `VALUE_GATE_MISSING` · `PRODUCT_REVIEW_INCREMENTAL_TRAP` · `DOC_SCRIPT_CONTRACT_DRIFT` · `HIDDEN_SCRIPT_MODE` · `MACHINE_INDEX_ID_FABRICATION` · `CROSS_PLATFORM_WRAPPER_DRIFT` · `MULTI_ROUTER_PARALLEL` · `HANDBOOK_NO_TIER` · `REDIRECT_STUB_NO_VALUE`
