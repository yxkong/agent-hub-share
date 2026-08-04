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
- `skills/registry.json` 中的 global 基础设施技能软链到各宿主个人目录，包括 Gemini CLI `~/.gemini/skills/` 与 Antigravity `~/.gemini/config/skills/`
- 默认生成各宿主个人全局 bundle；显式 `--apply-user-rules` / `-ApplyUserRules` 时才写稳定的受管用户入口，UI-only 宿主保留手工导入状态
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

- 规则文件：`AGENTS.md` 与各宿主原生项目规则；根 `CLAUDE.md`、`.cursorrules` 仅作 legacy 薄迁移提示
- 规则分层：`rules/common/COMMON_AGENT_RULES.md` + `rules/profiles/<project-type>/PROFILE_RULES.md` + `rules/projects/<project-key>/PROJECT_RULES.md`
- 技能注册表：`skills/registry.json`
- 命令注册表：`commands/registry.json`；按 `project_type` 投影，不扫描整目录
- 用户级技能：`install-hub` 只挂 global；项目类型技能默认挂工作区级入口
- 项目技能：`skills/projects/<project-key>/*`
- 可复用提示词：`prompts/share/*`、`prompts/projects/<project-key>/*`（经 `sync-prompts` 进入工作区 `.agents/prompts/`、`.cursor/prompts/`）

## 1.1 路由边界

本 workflow 只处理「让资产被客户端看见」：注册、挂载、同步、索引、链接校验。

| 主题 | 转交 |
|------|------|
| 项目类型、首跳与运行时规则 | `rules/profiles/<project-type>/PROFILE_RULES.md` + 最终 `AGENTS.md` |
| skill 正文、trigger、references | `skill-engineering` |
| prompt 正文、eval | `prompt-engineering` |
| docs/SQL 放置、备份 | `doc-script-governance` |
| 脚本放 hub 还是 skill | **`references/script_tiering.md`** + hub 根 **`scripts/README.md`** |
| 目标产物不明 | 先按当前 `project_type` 询问或收敛，不默认进入工程类路由器 |

文档与技能内路径一律写 **hub 相对路径**（如 `scripts/register-project.ps1`），不写本机绝对路径。

---

## 1.2 project type

注册或初始化前先确定项目类型；不确定时先问用户，不默认工程。

| 类型 | 适用 | 默认行为 |
|---|---|---|
| `engineering` | 研发、debug、SQL、前后端、重构、测试、发布 | 使用 engineering profile，默认 workflow 为 `delivery-workflow` |
| `media` | 公众号、小红书、内容采集、改稿、发布包、配图、视频化网页演示 | 使用 media profile，额外挂 media skill layer |
| `generic` | 通用项目、轻量资料、目标尚未落到特定领域 | 不默认工程或自媒体 |
| `hub` | 维护技能、规则、插件、命令、挂载脚本的 hub 仓库 | 使用 hub profile，默认 project skill 为 `ai-hub-maintainer` |
| `mixed` | 长期同时承载多个主域 | 生成 mixed profile，每次任务先选子域 |

类型真源优先级：命令参数 `--project-type` / `-ProjectType` > `rules/projects/<project-key>/project.yaml` > `generic` fallback。

`project.yaml` 最小结构（完整字段契约见 `docs/design/ai-dev-system/AGENT_HUB_INITIALIZATION_SDD.md`）：

```yaml
project_key: my-project
project_type: media
hosts: codex,claude,cursor
projection_mode: layered
contract_groups:
skill_groups:
project_skills:
default_workflow: none
project_skill: unknown
```

`sync-agent-rules` 的 layered 模式生成两部分：个人全局为 `首跳 + common + personal + environment`；项目增量为 `首跳 + typed personal preferences + profile + contract groups + project overlay`。项目文件不重复全局正文。

技能注册真源为 `skills/registry.json`：`install-hub` 只把 `generic/global` 清单挂到用户级入口，数量和名单不得在脚本/文档硬编码；`init-project-agenting` 按 `project_type` 展开注册表，默认把对应技能挂到工作区级入口；`hub` 展开为 `global + hub-maintenance`，并额外挂 `skills/projects/<project-key>/*`；只有显式 `--link-user-skills` / `-LinkUserSkills` 才追加写用户级入口。

---

## 2. 一键注册新项目（推荐入口）

`register-project` 在 `init-project-agenting` 基础上增加：

- 自动在 hub 创建项目目录结构（`rules/projects/<key>/`、`skills/projects/<key>/`、`prompts/projects/<key>/`）；传入 project type 时生成 `rules/projects/<key>/project.yaml`；**不**自动生成带 TODO 的 `PROJECT_RULES.md`（有项目增量时再手工添加）；若项目 prompts 目录无 `README.md` 则生成骨架
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
  -ProjectKey  'my-project' `
  -ProjectType engineering

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
  --project-key  my-project \
  --project-type engineering

# 预览模式
sh "$AGENTS_HUB_ROOT/scripts/register-project.sh" --dry-run
```

---

## 3. 全量初始化（已注册项目使用）

### Windows

```powershell
& "$env:AGENTS_HUB_ROOT\scripts\init-project-agenting.ps1" `
  -ProjectRoot 'C:\path\to\my-project' `
  -ProjectKey  'my-project' `
  -ProjectType engineering
```

### macOS / Linux

```bash
sh "$AGENTS_HUB_ROOT/scripts/init-project-agenting.sh" \
  --project-root ~/code/my-project \
  --project-key  my-project \
  --project-type engineering
```

规则与技能同步后，命令按 `commands/registry.json` 的当前类型展开。提示词由 `project.yaml` 的 `prompts_enabled` 控制；`false` 时移除受管的 workspace prompt 链接。命令行可用 `--skip-prompts` / `-SkipPrompts` 强制关闭，用 `--enable-prompts` / `-EnablePrompts` 强制开启。

命令的 canonical `audience` 与宿主显示的 Personal / Workspace 是两件事：前者表示 hub 资产归属，后者由挂载路径决定。真实 `SKILL.md` 只承担能力发现与自然语言触发，不写团队/个人分发语义，也不依赖非 Antigravity 标准的 `user-invocable`。反重力 IDE 的显式 `/` 入口只投影到 `.agents/workflows/<command>.md`；禁止再把同一 command 生成为 `.agents/skills/<command>/SKILL.md`，否则菜单会重复且 Codex 会把命令误当技能。

**规则生成（默认）：** 新项目使用 `projection_mode: layered`。个人全局入口先建立，项目只写类型、契约组和项目增量；宿主目标由 `rules/hosts/registry.json` 解析。所有 live/generated 目标记录 hash manifest，`check-agenting-closure` 使用完整内容比较。规则新增或修订任务必须先读 `docs/design/ai-dev-system/AGENT_RULES_LEARNING_LEDGER.md` 并在完成后追加 entry，普通执行任务不读完整 ledger。

**技能挂载（默认）：** 工作区级入口挂 `skills/registry.json` 计算出的当前 `project_type` 清单；`generic` 只有 global，`engineering` 为 global + engineering，`media` 为 global + media，`hub` 为 global + hub-maintenance，`mixed` 为 global + engineering + media。用户级入口只由 `install-hub` 放 global 基础设施；若确实要把当前项目类型技能也写入用户级目录，显式传入 **`-LinkUserSkills`** / **`--link-user-skills`**。Gemini CLI 用户级入口是 `~/.gemini/skills`，Antigravity 用户级入口是 `~/.gemini/config/skills`；二者的工作区共同使用 `.agents/skills`。**`skills/projects/<key>/*`** 同样挂载到工作区 **`.agents/skills/`、`.cursor/skills/`、`.claude/skills`**（项目技能镜像，非真源）。

### 空目录接入 media

空目录没有账号真源时，不复制 `accounts/`，也不生成第二份 registry。先用 `register-project` 将目录注册为 `project_type=media`，挂载 media skills 和 6 个 commands；`media-account-context` 再按显式 workspace、`MEDIA_WORKSPACE_ROOT`、向上 marker、`MEDIA_HOME_CONFIG` / `~/.agents/media/home.json` 的顺序连接唯一账号主页。

通用写稿可以保持 accountless；只有账号级任务才要求 media home。机器级 home config 只存本机路径指针，账号事实仍留在 media home 的 `accounts/registry.yaml`。换机器只更新指针，不改 Skill 或复制账号资料。

## 4. 只做部分动作

### 只同步规则

Windows:

```powershell
& "$env:AGENTS_HUB_ROOT\scripts\sync-agent-rules.ps1" `
  -ProjectRoot 'C:\path\to\my-project' `
  -ProjectKey  'my-project' `
  -ProjectType media
```

Linux / macOS:

```bash
sh "$AGENTS_HUB_ROOT/scripts/sync-agent-rules.sh" \
  --project-root ~/code/my-project \
  --project-key  my-project \
  --project-type media
```

### 只挂指定共享技能

Windows:

```powershell
& "$env:AGENTS_HUB_ROOT\scripts\sync-shared-skills.ps1" `
  -RepoRoot    'C:\path\to\my-project' `
  -ProjectKey  'my-project' `
  -LinkProjectSkills `
  -Categories  'share' `
  -SkillNames  'agent-hub-bootstrap','skill-discovery'
```

Linux / macOS:

```bash
sh "$AGENTS_HUB_ROOT/scripts/sync-shared-skills.sh" \
  --repo-root   ~/code/my-project \
  --project-key my-project \
  --link-project-skills \
  --categories  share \
  --skill-names agent-hub-bootstrap,skill-discovery
```

不带 `--skill-names` / `-SkillNames` 会按物理层遍历，属于维护者显式操作；日常项目初始化必须走 registry 计算出的清单。

### 只挂 media 技能

Windows:

```powershell
& "$env:AGENTS_HUB_ROOT\scripts\sync-shared-skills.ps1" `
  -RepoRoot    'C:\path\to\my-project' `
  -ProjectKey  'my-project' `
  -LinkUserSkills `
  -Categories  'media'
```

Linux / macOS:

```bash
sh "$AGENTS_HUB_ROOT/scripts/sync-shared-skills.sh" \
  --repo-root   ~/code/my-project \
  --project-key my-project \
  --link-user-skills \
  --categories  media
```

### 只同步 Gemini / Antigravity 用户级技能

Gemini 专用路径规则在本技能 L2 脚本内维护：Gemini CLI 用户级为 `~/.gemini/skills/`，Antigravity / 反重力用户级为 `~/.gemini/config/skills/`，工作区统一为 `.agents/skills/`。该入口固定只同步 registry 的 `generic/global` 清单；`media`、`engineering` 等类型技能必须通过项目注册进入工作区，不能借用户级同步扩散。

Windows:

```powershell
& "$env:AGENTS_HUB_ROOT\skills\share\agent-hub-bootstrap\scripts\sync-gemini-skills.ps1"
```

Linux / macOS:

```bash
sh "$AGENTS_HUB_ROOT/skills/share/agent-hub-bootstrap/scripts/sync-gemini-skills.sh"
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

只有项目 `project.yaml` 的 `prompts_enabled: true` 或命令行显式启用时，才在工作区 `.agents/prompts/`、`.cursor/prompts/` 下创建指向 hub 的 `hub-share`、`hub-project`；关闭时调用 `-Disable` / `--disable` 清理受管链接。命令和技能不依赖此入口。

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
| `-ProjectType` | `engineering` / `media` / `generic` / `mixed` |
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
| `--project-type` | `engineering` / `media` / `generic` / `mixed` |
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
- 项目生成物缺首跳、环境规则、profile 正文或出现组装元数据时，重跑 `sync-agent-rules`，再跑 `check-agent-rules`。
