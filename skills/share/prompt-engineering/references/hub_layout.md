# Hub 提示词目录布局

以下路径均相对于 **agents hub 根目录**（由 `AGENTS_HUB_ROOT` 或脚本推导）。

## 一等资产

| 路径 | 用途 |
| --- | --- |
| `prompts/share/` | 跨项目通用；下面可再分子目录（如 `code-review/`、`bug-debug/`） |
| `prompts/projects/<project-key>/` | 某个仓库 / 产品线的专属 prompt |
| `prompts/templates/` | 人类维护的模板（如 `PROMPT_TEMPLATE.md`）；**不必**使用 `*.prompt.md` 后缀，以免进入 CI 扫描 |
| `prompts/indexes/prompts.index.json` | **`build-prompt-index` 生成**；正文四段由 `check-prompts` + `validate-prompt-body.awk`（或 `.ps1` 内置逻辑）校验 |

## 工作区挂载（由 bootstrap 负责）

执行 `sync-prompts` 后，项目根下会出现：

- `.agents/prompts/hub-share` → hub `prompts/share/`
- `.agents/prompts/hub-project` → hub `prompts/projects/<project-key>/`
- `.cursor/prompts/` 下同样结构（与 Cursor 约定一致）

真实源**只**在 hub；工作区链接勿当作长期编辑目标。

## 开源 / public export 边界

- **`prompts/share/`** 可进入 public export；**`prompts/projects/<project-key>/`** 默认不进入 public export。
- share prompt **不得**含真实项目名、客户名、内网 URL、密钥、个人绝对路径；升格为 share 前须泛化输入、路径、领域名与验证命令。
- 仅在当前私有项目里**一次性**使用的 prompt → 放 `prompts/projects/<project-key>/` 或会话内临时使用，不强行 share。

## 登记新项目

`register-project` 会在 hub 创建 `prompts/projects/<key>/` 与 `README.md` 骨架；内容提炼与首个 `*.prompt.md` 由本技能指导完成。
