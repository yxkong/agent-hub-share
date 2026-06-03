# 验证技能已加载

> **语言**：[简体中文](VERIFY.md) | [English](VERIFY.en.md)

安装或更新 export 包之后，用本页确认 **客户端真的加载了技能**，而不只是磁盘上有文件。

## 1. 先跑仓库门禁

```bash
bash scripts/check-utf8-no-bom.sh --repo-root "$AGENTS_HUB_ROOT"
bash scripts/check-skill-entrypoints.sh --hub-root "$AGENTS_HUB_ROOT" --only-share
bash scripts/check-skill-structure.sh --hub-root "$AGENTS_HUB_ROOT" --only-share
bash scripts/check-share-skill-private-coupling.sh --hub-root "$AGENTS_HUB_ROOT"
bash scripts/build-skill-index.sh --hub-root "$AGENTS_HUB_ROOT"
```

```powershell
pwsh -File "$env:AGENTS_HUB_ROOT\scripts\check-utf8-no-bom.ps1" -RepoRoot $env:AGENTS_HUB_ROOT
pwsh -File "$env:AGENTS_HUB_ROOT\scripts\check-skill-entrypoints.ps1" -HubRoot $env:AGENTS_HUB_ROOT -OnlyShare
pwsh -File "$env:AGENTS_HUB_ROOT\scripts\check-skill-structure.ps1" -HubRoot $env:AGENTS_HUB_ROOT -OnlyShare
pwsh -File "$env:AGENTS_HUB_ROOT\scripts\check-share-skill-private-coupling.ps1" -HubRoot $env:AGENTS_HUB_ROOT
pwsh -File "$env:AGENTS_HUB_ROOT\scripts\build-skill-index.ps1" -HubRoot $env:AGENTS_HUB_ROOT
```

期望输出：

- `UTF8_NO_BOM=ok`
- `SKILL_ENTRYPOINTS=ok`
- `SKILL_REFERENCES_STRUCTURE=ok`
- `SHARE_SKILL_PRIVATE_COUPLING=ok`
- `SKILL_INDEX=ok items=13`（与公开技能包条目数一致）

## 2. 触发句烟测

在客户端各发一条短消息：

| 意图 | 触发句 | 期望技能 |
|------|--------|----------|
| 交付路由 | `这个需求先做什么后做什么？` | `delivery-workflow` |
| 文档备份/落位 | `这个技能 README 改前要怎么备份？` | `doc-script-governance` |
| Skill 审查 | `帮我审查这个 SKILL.md 的 trigger / eval 是否合理` | `skill-engineering` |
| TDD | `这个 bug 先补一个回归测试再修` | `tdd-workflow` |
| 浏览器冒烟 | `用浏览器验证这个页面能不能提交` | `webapp-testing` |

## 3. 成功信号（满足其一即可）

- 客户端明确列出已加载的 skill 名称
- 首轮回复按该 skill 路由行动，并引用预期 `references/` 路径
- 回复体现边界（例如文档备份路由到 `doc-script-governance` 而非自造流程）

## 4. 未触发时的顺序

1. 重跑 `install-hub`
2. 项目 overlay：重跑 `register-project`（无 prompts 时加 `-SkipPrompts`）
3. 检查链接：

```bash
bash scripts/check-skill-links.sh --repo-root "$PWD" --hub-root "$AGENTS_HUB_ROOT"
```

```powershell
pwsh -File "$env:AGENTS_HUB_ROOT\scripts\check-skill-links.ps1" -RepoRoot $PWD -HubRoot $env:AGENTS_HUB_ROOT
```

4. 用户级路径异常 → [WINDOWS.md](WINDOWS.md) / [MACOS_LINUX.md](MACOS_LINUX.md)
5. 门禁全过但客户端仍忽略 → 入口技能 [agent-hub-bootstrap](../../skills/share/agent-hub-bootstrap/SKILL.md)
