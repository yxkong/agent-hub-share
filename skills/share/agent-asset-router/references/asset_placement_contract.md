# Agent 资产放置契约

> 仅适用于已确认 `project_type=engineering` 的工程任务，是 code / spec / ADR / prompt / skill / insight / replay / docs / script / test / generated / temp 的工程落位契约。media、hub、generic、mixed 体系不得引用本文件作为路由入口，应由各自 profile 或项目规则裁决。

## 1. 先判四个维度

1. **给谁用**：Agent 执行、人阅读、运行时加载、机器生成。
2. **作用域**：跨项目、单项目、单次任务。
3. **生命周期**：canonical、过程、生成、临时。
4. **owner**：哪个 skill 对内容质量和验证负责。

## 2. Canonical 路由表

| 产物 | Canonical 路径 | Owner | 禁止 |
|---|---|---|---|
| 跨项目 skill | `$AGENTS_HUB_ROOT/skills/share/<skill>/` | `skill-engineering` | 直接写工作区挂载镜像 |
| 项目 skill | `$AGENTS_HUB_ROOT/skills/projects/<project-key>/<skill>/` | `skill-engineering` + project owner | 把项目类名/路径写进 share |
| 通用 prompt | `$AGENTS_HUB_ROOT/prompts/share/<type>/` | `prompt-engineering` | 放入 TechInsightVault 或项目 docs |
| 项目 prompt | `$AGENTS_HUB_ROOT/prompts/projects/<project-key>/` | `prompt-engineering` | 复制成工作区第二真源 |
| 人读洞察 | `$INSIGHT_VAULT_ROOT`；否则 `$AGENTS_HUB_ROOT/TechInsightVault/` | `project-insight-extractor` | 把 prompt/skill 规则当洞察 |
| 交付事实 Replay | `$AGENTS_HUB_ROOT/docs/resource/replay/` | `delivery-workflow` | 写到业务仓 `docs/resource/` |
| 业务设计/ADR | `<repo>/docs/design/<domain>/` | governance + `doc-script-governance` | 与实现说明混成一份 |
| 实现说明 | `<repo>/docs/implementation/<lang>/<domain>/` | project skill + doc governance | 冒充业务设计真源 |
| Review/验收 | `<repo>/docs/review/<domain>/` | review skill + doc governance | 放入 `docs/design/review/` |
| 计划/Spec 过程稿 | `<repo>/docs/plan/<domain>/` | governance + doc governance | 长期替代终版设计 |
| 开发 SQL | `<repo>/docs/db/dev/<module>/` | project SQL skill + doc governance | Agent 写 `docs/db/online/` |
| skill 专用脚本 | `<skill>/scripts/` | 当前 skill | 放 hub 根 scripts |
| 跨技能装配/校验脚本 | `$AGENTS_HUB_ROOT/scripts/` | `ai-hub-maintainer` | 夹带单项目业务逻辑 |
| 正式测试 | 项目既有 test 目录 | project skill / TDD | 放 `.tmp/` 后宣称已沉淀 |
| 单次临时文件/缓存 | `<repo>/.tmp/<task-id>/` | 当前任务 | 写仓库根、docs 或正式 test 目录 |
| 机器生成索引/投影 | 已登记 generated/index/dist 路径 | 对应构建脚本 | 手改或当正文真源 |

## 3. 决策规则

- 先找已有 canonical；同语义资产必须融合，禁止新建平行真源。
- 新建 skill 前必须先过 `skill-discovery`；有 exact/partial 候选时优先复用或适配。
- 给 Agent 重复执行的是 prompt；稳定触发/SOP/工具路由是 skill；给人复盘表达的是 insight；交付轨迹是 replay。
- 单次调试、下载、渲染、pytest cache、生成中间件统一进入 `.tmp/<task-id>/`。
- 项目规则可以指定正式测试和长期脚本目录，但不能把临时缓存改回仓库根。
- owner skill 决定内容契约；本文件只裁决路径和唯一真源。

## 4. Path Guard

任何落盘前输出：

```text
[资产落位]
asset_type:
scope: share | project | task
owner_skill:
canonical_path:
source_anchor:
generated_or_mounted_paths:
forbidden_paths:
validation:
```

在 engineering 项目中无法确定 `asset_type / owner_skill / canonical_path` 时，回到 `agent-asset-router`；项目类型未知或非 engineering 时，先加载对应项目身份/profile 或询问用户，不得边写边猜。

## 5. 收口检查

- canonical 只有一个，挂载和 generated 不被编辑。
- 临时产物全部位于 `.tmp/` 且不进入索引。
- prompt / insight / replay / docs 没有互相串位。
- 项目私有事实没有进入 share。
- 新资产已通过 owner skill 的验证与索引命令。
- 当前项目类型确为 engineering；其它体系没有复用本契约兜底。
