# Router / Handbook / Tier 门禁

> **何时读**：`create` / `extract` 收尾；`review` 多域 skill 必查。来源：某项目 `<backend-domain-skill>` 优化复盘；细则并入 `checklist.md` §7.5 勾选项。

## 1. 单一 Agent 路由

- **唯一入口**：根 `SKILL.md` 的 §2（或等价「主路由表」）。
- **Meta 降权**：`references/INDEX.md`、根 `README.md`、`foundation/README.md`、`*TRIGGER*`、关键词表等须在文首 blockquote 写明 **禁止 Agent 当入口**。
- **禁止**：README / INDEX / TRIGGER 与 SKILL §2 并列为「先读谁都可以」的三套路由。

## 2. Tier 分层

| Tier | 放什么 | Agent 行为 |
|------|--------|------------|
| P0/P1 | rule card、checklist、SOP（通常 ≤150 行） | 按路由直接打开 |
| P2 | handbook：规约全文、模块百科、反模式汇编（常 >150 行） | **禁止通读**；仅 J-xxx / 章节检索 |

- 大文档迁入 `references/handbook/`（或等价语义目录）。
- SKILL §2 每行标注 Tier；P2 行写「按需检索、禁止通读」。

## 3. Review 默认路径

- review / 重构 / 优化页面：**默认先打开 `quick_gate.md`**，判定门禁阻断、可用性四门与下一步；需要系统修复时再打开可执行 **checklist**（含勾选与命令），**非** handbook 全文。
- handbook 仅在用户点名章节或 J-xxx 时打开。

## 4. 零孤儿 reference

- 维护 `references/INDEX.md` catalog，列全量 active `*.md`（不含 `bak/`）。
- 凡 `in_route=是` 须在 SKILL 主路由表有一行链接。
- **断链门禁**：SKILL 路由表每条链接须 `Test-Path` 存在；禁止 `references/foo.md` 指向已搬迁/已删文件。
- 物理搬迁后：若 SKILL **已直链新路径**且无外部引用 → **删除**旧 stub（不必为「少维护一行」而保留 redirect）；否则旧路径留 3–5 行 stub（禁止 stub 覆盖正文）。

## 5. 搬迁不丢正文

顺序：**backup** → 迁正文到目标目录 → 写 stub → 批量改交叉引用 → 验证 handbook 文件大小与首段标题。

## 6. trigger eval（≥9.9 目标）

多域 skill 须有**独立 trigger/eval 资产**（推荐 `references/trigger_eval.md`；若受拓扑或体量约束，可放 `references/eval/trigger_eval.md` 等稳定子路径）：

- ≥10 条：`用户输入` → 期望打开的 **唯一** reference（或 SKILL 路由 + 一条 P0）。
- 含 should-not-trigger 至少 2 条。

## 7. SKILL 结构与编号

- 主路由表前勿重复同级章节号（如两个 `## 1.`）。
- 多域 skill 主文件接近类型上限时：硬约束留 SKILL，长表格/`<details>` 深读链保留但须标注 P2。

## 8. 子目录 README 降权

- `references/foundation/README.md`、`references/meta/README.md` 等**不得**充当第二套路由表；文首 blockquote **禁止 Agent 当入口**，仅列维护索引。

## 快速核对

```powershell
Select-String -Path SKILL.md -Pattern 'references/' -AllMatches
Get-ChildItem references -Recurse -Filter '*.md' | Where-Object { $_.FullName -notmatch '\\bak\\' }
```
