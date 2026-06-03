# 技能目录标准布局（强制）

> **单一真源**：所有 hub 技能（`skills/share/`、`skills/projects/<key>/`）须符合本节。`create` / `review` 收尾用 `check-skill-structure` 校验 **§2 references**；布局不合规不得宣称工程门通过。

## 1. 标准树（强制最优）

```text
<skill-name>/
├── SKILL.md              # 必须：Agent 路由器（front matter + 30 秒决策）
├── README.md             # 必须：章程（核心用途、单一职责、转交表）
├── templates/            # 必须（有可复制产出时）：空白 TEMPLATE_*，复制到项目/产物目录
├── scripts/              # 可选：L2 单技能域脚本；L1 跨技能基础设施见 hub scripts/ + agent-hub-bootstrap/references/script_tiering.md
└── references/           # 必须：规则 / SOP / checklist（仅 *.md 与索引）
    ├── INDEX.md          # 建议：references catalog（meta，禁止 Agent 入口）
    └── bak/              # 备份产生，非入口
```

**禁止**：

- 在 `references/templates/` 再放空白模板（与根 `templates/` 双份）
- 在 `references/` 下再套多层语义目录（仅允许 **一层** 子目录，且优先不用——模板应放根 `templates/`）
- 技能树下任意非根路径出现 `SKILL.md` 文件（见 `engineering_completion_gate` §1）

## 2. 各目录职责（心智模型）

| 目录 | 放什么 | 不放什么 |
|------|--------|----------|
| 根 `SKILL.md` | 触发、路由表、红线、指向 references 的指针 | 长 SOP、大段模板正文、业务领域知识 |
| 根 `README.md` | 核心用途、单一职责、不负责/转交、入口链接 | 与 SKILL 全文重复 |
| 根 `templates/` | 给用户/项目复制的空白结构（`TEMPLATE_*.md`、`.sql`） | 已填好的业务实例、规则说明 |
| 根 `scripts/` | 本 skill 审计/生成类脚本 | 与 hub 完全重复的 `backup-file`（应链 hub） |
| `references/` | 治理规则、生命周期、checklist（**无 YAML、无 §修订记录**，省 Agent token） | 空白模板、项目业务 docs 正文、文首元数据块 |

## 3. 与 references 深度规则的关系

- `references/` 顶层并列 `*.md`（不含 `bak/`）**≤15** → 1 级 flat（推荐）
- 若顶层 **≥16**，须语义子目录，且**仍不得**用 `references/templates/` 代替根 `templates/`
- 空白模板**一律**根 `templates/`，避免 `references/templates/` 与 `skill-engineering/templates/` 心智分裂

## 4. 示例（合规）

**doc-script-governance**

```text
doc-script-governance/
├── SKILL.md
├── README.md
├── templates/TEMPLATE_DESIGN_CANONICAL.md
├── scripts/audit-doc-script-governance.ps1
└── references/document_types_and_templates.md
```

**skill-engineering**

```text
skill-engineering/
├── SKILL.md
├── README.md
├── templates/TEMPLATE_SKILL_README.md
└── references/creation_workflow.md
```

## 5. create / review 检查项

- [ ] 根目录存在 `SKILL.md`、`README.md`
- [ ] 有可复制产出时存在根 `templates/`，且**无** `references/templates/TEMPLATE_*`
- [ ] `references/` 仅规则类 md；顶层 ≤15 或已按语义分子目录（非 templates）
- [ ] `SKILL.md` 中模板路径写 `templates/TEMPLATE_*`，不写 `references/templates/`

## 6. 相关文档

- [skill_root_readme.md](skill_root_readme.md) — README 章程（同目录）
- `review/engineering_completion_gate.md` — §1–§5 门禁
- `governance/design_principles.md` — references 深度与 15 边界
