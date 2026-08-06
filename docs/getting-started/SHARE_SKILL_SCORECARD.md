# Share 技能评分卡（公共包）

> **语言**：[简体中文](SHARE_SKILL_SCORECARD.md) | [English](SHARE_SKILL_SCORECARD.en.md)

当前 **14** 个 share 技能的公共包摘要。

最近复核：**2026-08-05**

## 当前结果

| 项 | 分数 | 说明 |
|----|------|------|
| 质量 | **94 / 100** | 14 技能包、套餐矩阵清晰、门禁对齐 |
| 兑现 | **93 / 100** | 仓库门禁已执行；客户端烟测见 VERIFY |
| 门禁 | **可 public export** | share/public 资产无 P0 矛盾 |
| 证据 | **executed** | 本仓门禁已跑通；多客户端触发见 VERIFY |

## 已覆盖门禁

```text
UTF8_NO_BOM=ok
SKILL_ENTRYPOINTS=ok
SKILL_REFERENCES_STRUCTURE=ok
SHARE_SKILL_PRIVATE_COUPLING=ok
SKILL_INDEX=ok items=14
（prompts：仅 private hub）
```

## 包内自检

- 14/14 有 `README.md` 与 `references/**/trigger_eval.md`
- 14/14 保留「30 秒」决策区
- 14/14 通过 `check-skill-size` 配置

## 残余风险

- Cursor / Claude / Codex 的 live 触发未在本轮全部观测；安装后请按 [VERIFY.md](VERIFY.md) 做烟测。
