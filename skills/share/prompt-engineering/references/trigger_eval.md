# prompt-engineering — trigger / eval

## should-trigger

- 「把这次成功的子 Agent `Task` prompt 提成 hub 资产」
- 「设计文档里有多段系统提示词，要拆成多个 `*.prompt.md`」
- 「返工是因为 prompt 缺范围/验证，要固化一版可复用」（与 `delivery-workflow` **R3** 第三路对齐）
- 「这段长指令以后要反复给 Agent 执行，帮我做成 prompt 资产」
- 「把这段通用执行协议做成 `prompts/share/`，不要绑定某个项目」
- 「这个 prompt 多个项目都会复用，帮我做 share / project 归属判断」

## should-not-trigger

- 目标产物是 **SKILL.md / 研发 SOP** → `skill-engineering`
- 只要**面试叙事 / 案例库**、不要可执行 prompt → `project-insight-extractor`
- 只要**同步 prompts 链接 / CI** → `agent-hub-bootstrap`
- 尚未确定要做成 skill、prompt 还是 insight → `agent-asset-router`
- prompt 含客户名、内网地址、真实项目字段且用户**未**要求脱敏 → 先脱敏或降级为 project-only，不直接进入 share

开源边界见 [hub_layout.md](hub_layout.md) §开源 / public export 边界。
