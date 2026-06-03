# doc-script-governance — 真实闭环样例

## 样例目标

对 share 技能做一轮 trigger/eval 资产统一，同时遵守放置、命名和改前备份规则。

## 开始前（executed）

本轮在修改以下技能文件前，已统一执行 `backup-file.ps1`：

- `ai-development-governance`
- `doc-script-governance`
- `project-insight-extractor`
- `webapp-testing`
- `agent-asset-router`
- `<private-media-skill>`（maintainer hub 登记名见 `PROJECT_RULES.md`）
- `delivery-workflow`

每个目标文件都生成了：

- 同级临时备份 `bak/_<文件名>`
- 归档备份 `bak/202605/...`

## 放置与命名（observed）

本轮新增资产遵守了本技能约束：

- trigger/eval 资产统一放在 `references/` 或其稳定子目录
- 没有使用 `_FINAL`、`V2`、`copy`
- 没有把模板放回 `references/templates/`
- `delivery-workflow` 的旧 `trigger_eval_examples.md` 已收敛为 `trigger_eval.md`

## 改后验证（executed）

与本轮文档/技能资料治理直接相关的结果：

```text
SKILL_ENTRYPOINTS=ok
SKILL_REFERENCES_STRUCTURE=ok
SHARE_SKILL_PRIVATE_COUPLING=ok
```

## 闭环结果

本样例体现了本技能的最小闭环：

1. 改前先 `backup-file`
2. 改动按 `references/` / `README.md` / 主文件职责落位
3. 不使用错误命名与历史副本引用
4. 改后跑结构与入口校验
