# Workflow

## 0. 新机器首次安装 hub（推荐入口）

把 hub 目录复制到目标机器，进入 `scripts/` 目录，**零参数**运行一次：

### Windows

```powershell
# 将 hub 复制到本机后，进入 hub 的 scripts/ 零参数执行（推荐）：
cd <你的 hub 目录>\scripts
.\install-hub.ps1

# 或 hub 根已在 profile 中：
& "$env:AGENTS_HUB_ROOT\scripts\install-hub.ps1"

# 预览（不写文件）
& "$env:AGENTS_HUB_ROOT\scripts\install-hub.ps1" -DryRun
```

### macOS / Linux

```bash
# 将 hub 复制到本机任意目录后，进入 <hub-root>/scripts/ 零参数执行（推荐）：
cd "$AGENTS_HUB_ROOT/scripts"
sh ./install-hub.sh

# 或从任意位置引用环境变量：
sh "$AGENTS_HUB_ROOT/scripts/install-hub.sh"

# 预览
sh "$AGENTS_HUB_ROOT/scripts/install-hub.sh" --dry-run
```

**效果：**
- 共享技能软链到 `~/.claude/skills/`、`~/.cursor/skills/`、`~/.codex/skills/`
- 全局规则同步到 `~/.claude/CLAUDE.md`、`~/.codex/AGENTS.md`
- `AGENTS_HUB_ROOT` 自动写入 shell profile（永久生效）

安装完成后，**不需要再手动设置任何环境变量**，进入项目目录直接跑 `register-project` 即可。

---

## 前置：设置 AGENTS_HUB_ROOT

所有脚本优先读 `AGENTS_HUB_ROOT` 环境变量。建议写入 shell 配置（永久生效）：

Windows（PowerShell profile）:

```powershell
# install-hub 安装时也会写入 profile；值为本机 hub 根目录
$env:AGENTS_HUB_ROOT = '<你的 hub 目录>'
```

macOS / Linux（~/.zshrc 或 ~/.bashrc）:

```bash
export AGENTS_HUB_ROOT="<你的 hub 目录>"
```

未配置时：进入 hub 的 **`scripts/`** 目录执行脚本，会自动向上一级推导 hub 根。

---

## 1. 目标

把本地项目和 hub 的内容对齐：

- 规则文件：`AGENTS.md`、`CLAUDE.md`、`.cursorrules`、`.cursor/rules/00-common.mdc`
- 共享技能：`skills/share/*`
- 项目技能：`skills/projects/<project-key>/*`
- 可复用提示词：`prompts/share/*`、`prompts/projects/<project-key>/*`（经 `sync-prompts` 进入工作区 `.agents/prompts/`、`.cursor/prompts/`）

## 1.1 路由边界

本 workflow 只处理「让资产被客户端看见」：注册、挂载、同步、索引、链接校验。

| 主题 | 转交 |
|------|------|
| 研发全流程（delivery + doc-script） | **`rules/common/COMMON_AGENT_RULES.md` §研发全流程** |
| skill 正文、trigger、references | `skill-engineering` |
| prompt 正文、eval | `prompt-engineering` |
| docs/SQL 放置、备份 | `doc-script-governance` |
| 脚本放 hub 还是 skill | **`references/script_tiering.md`** + hub 根 **`scripts/README.md`** |
| 目标产物不明 | `agent-asset-router` |

文档与技能内路径一律写 **hub 相对路径**（如 `scripts/register-project.ps1`），不写本机绝对路径。

---

## 2. 一键注册新项目（推荐入口）

`register-project` 在 `init-project-agenting` 基础上增加：

- 自动在 hub 创建项目目录结构（`rules/projects/<key>/`、`skills/projects/<key>/`、`prompts/projects/<key>/`）；**不**自动生成带 TODO 的 `PROJECT_RULES.md`（有项目增量时再手工添加）；若项目 prompts 目录无 `README.md` 则生成骨架
- 事前校验用户级 agent 工具目录（`~/.claude/`、`~/.codex/`、`~/.cursor/`）
- 未使用 `--skip-prompts` / `-SkipPrompts` 时：在 `init-project-agenting` 之后对整个 hub 执行 `check-prompts`，通过后执行 `build-prompt-index`，再执行 `check-skill-links`（任一失败则注册失败）

### Windows

```powershell
# 在目标项目目录内运行（自动识别项目根和 key）
cd C:\path\to\my-project
& "$env:AGENTS_HUB_ROOT\scripts\register-project.ps1"

# 显式指定
& "$env:AGENTS_HUB_ROOT\scripts\register-project.ps1" `
  -ProjectRoot 'C:\path\to\my-project' `
  -ProjectKey  'my-project'

# 预览模式（不写文件）
& "$env:AGENTS_HUB_ROOT\scripts\register-project.ps1" -DryRun
```

### macOS / Linux

```bash
# 在目标项目目录内运行
cd ~/code/my-project
sh "$AGENTS_HUB_ROOT/scripts/register-project.sh"

# 显式指定
sh "$AGENTS_HUB_ROOT/scripts/register-project.sh" \
  --project-root ~/code/my-project \
  --project-key  my-project

# 预览模式
sh "$AGENTS_HUB_ROOT/scripts/register-project.sh" --dry-run
```

---

## 3. 全量初始化（已注册项目使用）

### Windows

```powershell
& "$env:AGENTS_HUB_ROOT\scripts\init-project-agenting.ps1" `
  -ProjectRoot 'C:\path\to\my-project' `
  -ProjectKey  'my-project'
```

### macOS / Linux

```bash
sh "$AGENTS_HUB_ROOT/scripts/init-project-agenting.sh" \
  --project-root ~/code/my-project \
  --project-key  my-project
```

默认会在规则与技能同步后执行 `sync-prompts`（链上 `prompts/share` 与 `prompts/projects/<key>`）。若仅需规则/技能、暂时不需要提示词链接，可加 `--skip-prompts`（PowerShell：`-SkipPrompts`）。

**技能挂载（默认）：** `skills/share/*` 仅刷新 **`~/.claude/skills`、`~/.cursor/skills`、`~/.codex/skills`** 等用户级入口；**`skills/projects/<key>/*`** 挂载到工作区 **`.agents/skills/`、`.cursor/skills/`、`.claude/skills/`**（项目技能镜像，非真源）。若需要像以前那样把共享也挂进仓库 `.cursor/skills`/`.claude/skills`，请显式传入 **`-LinkShareToWorkspace`** / **`--link-share-to-workspace`**（`register-project` / `init-project-agenting` 均支持）。

## 4. 只做部分动作

### 只同步规则

Windows:

```powershell
& "$env:AGENTS_HUB_ROOT\scripts\sync-agent-rules.ps1" `
  -ProjectRoot 'C:\path\to\my-project' `
  -ProjectKey  'my-project'
```

Linux / macOS:

```bash
sh "$AGENTS_HUB_ROOT/scripts/sync-agent-rules.sh" \
  --project-root ~/code/my-project \
  --project-key  my-project
```

### 只挂共享技能

Windows:

```powershell
& "$env:AGENTS_HUB_ROOT\scripts\sync-shared-skills.ps1" `
  -RepoRoot    'C:\path\to\my-project' `
  -ProjectKey  'my-project' `
  -LinkProjectSkills `
  -Categories  'share'
```

Linux / macOS:

```bash
sh "$AGENTS_HUB_ROOT/scripts/sync-shared-skills.sh" \
  --repo-root   ~/code/my-project \
  --project-key my-project \
  --link-project-skills \
  --categories  share
```

### 只挂项目技能

Windows:

```powershell
& "$env:AGENTS_HUB_ROOT\scripts\sync-shared-skills.ps1" `
  -RepoRoot    'C:\path\to\my-project' `
  -ProjectKey  'my-project' `
  -LinkProjectSkills `
  -Categories  'projects\my-project'
```

Linux / macOS:

```bash
sh "$AGENTS_HUB_ROOT/scripts/sync-shared-skills.sh" \
  --repo-root   ~/code/my-project \
  --project-key my-project \
  --link-project-skills \
  --categories  projects/my-project
```

### 只同步提示词链接

与 `init-project-agenting` 末尾行为相同：在工作区 `.agents/prompts/`、`.cursor/prompts/` 下创建指向 hub 的 `hub-share`、`hub-project`。

Windows:

```powershell
& "$env:AGENTS_HUB_ROOT\scripts\sync-prompts.ps1" `
  -ProjectRoot 'C:\path\to\my-project' `
  -ProjectKey  'my-project'
```

Linux / macOS:

```bash
sh "$AGENTS_HUB_ROOT/scripts/sync-prompts.sh" \
  --project-root ~/code/my-project \
  --project-key  my-project
```

### 校验与索引（CI / 发布前）

- `check-prompts`：扫描 hub `prompts/share`、`prompts/projects` 下 `*.prompt.md`（排除 `bak`），检查 front matter、`id` 全局唯一、正文无 `TODO`、简易密钥模式。
- `build-prompt-index`：生成 `prompts/indexes/prompts.index.json`（脚本产物，不手写）。

---

## 5. 新增 skill 后怎么重新挂到项目

### 新增共享技能

1. 在 hub 真实源新建：`skills/share/<skill-name>/SKILL.md`（须已存在；`publish-skill` **默认不会**自动创建 TODO 占位，拼错名字会直接失败）。
2. 复挂单个技能：

Windows:

```powershell
& "$env:AGENTS_HUB_ROOT\scripts\publish-skill.ps1" `
  -SkillName   '<skill-name>' `
  -Scope       share `
  -ProjectRoot 'C:\path\to\my-project' `
  -LinkProject `
  -LinkUsers
```

Linux / macOS:

```bash
sh "$AGENTS_HUB_ROOT/scripts/publish-skill.sh" \
  --skill-name  <skill-name> \
  --scope       share \
  --project-root ~/code/my-project \
  --link-project \
  --link-users
```

### 新增项目技能

1. 在 hub 真实源新建：`skills/projects/<project-key>/<skill-name>/SKILL.md`（须已存在；需要空脚手架时再考虑 `publish-skill` 的 `--create-if-missing` / `-CreateIfMissing`。）
2. 复挂单个技能：

Windows:

```powershell
& "$env:AGENTS_HUB_ROOT\scripts\publish-skill.ps1" `
  -SkillName   '<skill-name>' `
  -Scope       category `
  -ProjectRoot 'C:\path\to\my-project' `
  -ProjectKey  'my-project' `
  -LinkProject
```

Linux / macOS:

```bash
sh "$AGENTS_HUB_ROOT/scripts/publish-skill.sh" \
  --skill-name   <skill-name> \
  --scope        category \
  --project-root ~/code/my-project \
  --project-key  my-project \
  --link-project
```

---

## 6. 参数速查

### Windows（.ps1）

| 参数 | 说明 |
|---|---|
| `-ProjectRoot` | 目标项目根目录 |
| `-ProjectKey` | 项目 key；为空时默认取项目目录名 |
| `-SkipRules` | 跳过规则同步 |
| `-SkipSharedSkills` | 跳过共享技能挂载 |
| `-SkipProjectSkills` | 跳过项目技能挂载 |
| `-SkipUserTargets` | 规则同步时不写用户级 `~/.codex`、`~/.claude` |
| `-LinkUserSkills` | 把共享技能同时挂到用户级技能入口 |
| `-DryRun` | 仅预览，不写文件（仅 register-project）|

### macOS / Linux（.sh）

| 参数 | 说明 |
|---|---|
| `--project-root` | 目标项目根目录 |
| `--project-key` | 项目 key |
| `--skip-rules` | 跳过规则同步 |
| `--skip-shared-skills` | 跳过共享技能挂载 |
| `--skip-project-skills` | 跳过项目技能挂载 |
| `--skip-user-targets` | 不写用户级目标 |
| `--link-user-skills` | 挂共享技能到用户级入口 |
| `--dry-run` | 仅预览，不写文件（仅 register-project）|

---

## 7. 排查要点

- `.agents/skills/*` 在 Windows 下看到的是 `Junction`，属于正常挂载，不是"没软链"。
- `git add .` 把 `.agents/skills/*` 扫进去，通常是仓库没有忽略 `.agents/` 或 `.cursor/skills/`。
- 新增 skill 后项目里没出现，多半是只创建了 hub 真实源，还没跑 `publish-skill` 或 `register-project`。
- 如果只想验证单个 skill，不要先全量重挂；优先指定 `-ShareSkillNames` 或 `-ProjectSkillNames`。
- `register-project --dry-run` 可预览操作而不修改任何文件。
