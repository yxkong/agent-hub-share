# Skill Discovery 工作流

## 1. 本机检索

优先运行 `find-skills`，得到结构化候选；脚本不可用时转 `agent-hub-bootstrap` 修复，不把手工扫目录当默认路径。

```powershell
& "$env:AGENTS_HUB_ROOT\scripts\find-skills.ps1" [-Query <关键词>] [-Project <project-key>]
```

```bash
bash "$AGENTS_HUB_ROOT/scripts/find-skills.sh" [--query <关键词>] [--project <project-key>]
```

检索顺序：

1. 已明确 `project-key` 时先搜 `skills/projects/<project-key>/`。
2. 再搜 `skills/share/`。
3. 其他项目技能仅作参考，不跨项目推荐启用。
4. 本地无合适技能时才进入外部检索。
5. 外部仍无合适技能时转 `skill-engineering create`。

## 2. 候选评估

对每个候选核实：

- 是否为含 `SKILL.md` 的标准 skill 目录
- description 是否匹配用户当前任务
- 归属为 `share` 还是 `project:<key>`
- 是否绑定特定 Agent、插件或私有环境
- 建议 `use / adapt / install / create`

输出必须包含候选表：

| skill | source | path_or_url | scope | fit | match_reason | dependencies | action | risk |
|---|---|---|---|---|---|---|---|---|
| `<name>` | `local-share/local-project/external` | `<path-or-url>` | `<scope>` | `exact/partial/reference-only` | `<reason>` | `<deps-or->` | `use/adapt/install/create` | `<risk-or->` |

## 3. 去重与覆盖

- 本地 share 优先于外部；外部同类默认 reference-only。
- 项目技能只在当前项目上下文优先，不跨项目推荐启用。
- 外部技能未经安装验收，不得声称已可用。
- 安装前说明与本地 skill 是替代还是并存。

## 4. 外部检索与安装

仅当本地无合适候选时进入。

```powershell
& "$env:AGENTS_HUB_ROOT\scripts\find-skills.ps1" -Remote <关键词> -DryRun
& "$env:AGENTS_HUB_ROOT\scripts\find-skills.ps1" -Remote <关键词> -Pick N -Install
```

```bash
bash "$AGENTS_HUB_ROOT/scripts/find-skills.sh" --remote <关键词> --dry-run
bash "$AGENTS_HUB_ROOT/scripts/find-skills.sh" --remote <关键词> --pick N --install
```

安全规则：

- 默认先 dry-run，通过后再正式安装。
- license、私有依赖、付费服务、内网路径必须显式检查。
- 安装后把硬编码路径改为 `$AGENTS_HUB_ROOT` 相对引用。
- 提取外部仓中的标准 skill 时，按 `external_repo.md` 验收闭环。
