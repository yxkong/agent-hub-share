# 空白模板索引

| 模板 | 用途 | 项目落点 |
|------|------|----------|
| [TEMPLATE_FEATURE_SPEC.md](TEMPLATE_FEATURE_SPEC.md) | 需求规格真源 | `docs/plan/<domain>/` → 可选升格 `docs/design/` |
| [TEMPLATE_SDD.md](TEMPLATE_SDD.md) | 软件设计契约，承接 Spec 并映射 TDD | `docs/plan/<domain>/` → `docs/design/<domain>/SDD-*.md` |
| [TEMPLATE_ADR.md](TEMPLATE_ADR.md) | 架构决策记录 | `docs/design/<domain>/ADR-*.md` |
| [TEMPLATE_TASK_CONTRACT.md](TEMPLATE_TASK_CONTRACT.md) | 最小可验证任务契约 | `docs/plan/<domain>/` 或技能 `references/meta/*_contract.md` |
| [TEMPLATE_CAPABILITY_CARD.md](TEMPLATE_CAPABILITY_CARD.md) | 项目能力事实与六类证据卡 | 项目技能 `references/capabilities/` |

头脑风暴 / 方案收敛过程稿使用 `doc-script-governance/templates/TEMPLATE_BRAINSTORM_CONVERGENCE.md`，落 `docs/plan/<domain>/`；收敛后再进入本目录的 Spec / SDD / ADR / Task Contract 模板。

Spec Compiler 生成顺序见 `references/governance/spec_compiler_workflow.md`。模板结构由 Python 核心 `scripts/spec_compiler_check.py` 校验，PowerShell / sh 仅为薄入口：

- `template`：校验 Hub 模板结构，允许占位符。
- `document`：校验生成后的评审稿，拒绝空章节和占位符。
- `implementation-ready`：追加 frozen / accepted、Spec 版本和追踪覆盖门禁。

模板已内置 `doc-script-governance` 要求的 YAML 与 §修订记录；复制后必须替换占位符并按真实证据填写。
