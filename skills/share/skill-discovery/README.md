# skill-discovery

## 定位

发现、评估、去重和安装可复用 Agent Skill：在新建 skill 前先查本地 hub 与外部 registry 是否已有覆盖。

## 核心要点

- **本地 hub 优先**：`$AGENTS_HUB_ROOT/skills/share/` 与 `skills/projects/<key>/` 为检索真源。
- **先跑 find-skills 脚本**：结构化枚举候选；脚本不可用转 `agent-hub-bootstrap` 修复。
- **验证内容非名字**：打开 SKILL.md 确认职责边界，不单凭目录名推荐。
- **无合适候选再 create**：转 `skill-engineering` 新建，不重复造轮子。

## 关键 references

| 文件 | 用途 |
|------|------|
| `references/external_repo.md` | 外部 registry 检索与安装注意 |
| `references/closure_example.md` | `find-skills` 结构化候选样例 |

## 协作入口

| 场景 | 转交 |
|------|------|
| 创建/重构 SKILL.md 正文 | `skill-engineering` |
| hub 挂载、脚本修复 | `agent-hub-bootstrap` |
| 写可执行 prompt | `prompt-engineering` |
| 多产物路由不明 | `agent-asset-router` |
