# skill-discovery — trigger / eval

## should-trigger

- 「有没有现成 skill 能处理文档治理 / prompt 提炼 / 浏览器验证？」
- 「我想找一个可复用 skill，先别新建」
- 「本地 hub 里有没有覆盖这个能力？」
- 「从外部 registry 找一个 skill，但先 dry-run 看看」
- 「这个能力应该复用已有 skill，还是新建一个？」
- 「帮我比较本地 share skill 和外部 skill 的适配度」

## should-not-trigger

- 「帮我直接创建一个新的 SKILL.md」→ `skill-engineering`
- 「帮我重构这个 skill 正文 / references」→ `skill-engineering`
- 「Cursor 找不到 skill / 链接坏了 / 怎么 install-hub」→ `agent-hub-bootstrap`
- 「把这段长 prompt 落成 `*.prompt.md` 资产」→ `prompt-engineering`
- 「用户已指定用 delivery-workflow，直接推进任务」→ 使用目标 skill，不再 discovery
- 「skill / prompt / insight / docs 该沉淀成哪种资产」→ `agent-asset-router`

## 外部安装确认门

外部 skill **默认 `reference-only` 或 dry-run**；满足以下全部条件前，**不得**建议正式安装或声称「已可用」：

1. **license** 已检查且兼容当前用途（MIT/Apache 通常可直接用；GPL/商业须用户确认）
2. **无私有依赖**：无内网 URL、token、客户名、公司专属路径、不可替代付费 CLI
3. **结构验收通过**：`check-skill-entrypoints`、`check-skill-structure`、`check-skill-size`（提取后）
4. **用户确认安装范围**：`share` / `project:<key>` / 仅保留在 `vendors/`
5. **与本地 skill 关系已说明**：替代（旧 skill 下线）还是并存（及风险）

详见 [external_repo.md](external_repo.md) §Validation & Mount Closure。
