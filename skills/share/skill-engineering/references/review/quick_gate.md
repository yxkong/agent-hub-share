---
title: Skill 快速审查门
updated: 2026-07-16
summary: review 路由 P0 首读文件。用于 30 秒内判断问题类型、是否可挂载、要不要进入 checklist 详表。
---

# Skill 快速审查门

> 本文件是 `review` 路由的 P0 首读入口；完整详表见 `checklist.md`。

## 1. 先判门禁阻断

命中任一项，先不要给高分或“可挂载”：

- `SKILL.md` 不存在、front matter 缺失或 description 与正文不一致
- 触发后 30 秒内不知道先读哪份 active 文件
- 主文件是长手册，混入 human-only / maintenance-only、具体业务样例或可变资产清单
- README / INDEX / 子目录 README 与 `SKILL.md` 形成并列入口
- README §修订记录不是倒序（最新版本不在上方）
- 影响 Agent 行为、验收或生成结果的规则只写在 README，未同步到 `SKILL.md`、active references、模板或校验脚本
- 承诺能力没有 active 文件支撑，或只存在于 `bak/`
- share skill 含真实项目私有名、私有 URL、密钥、凭据或稳定项目路径耦合
- 交付 / 上线 / 失败学习类 skill 宣称闭环，但没有主链证据矩阵、Release Evidence、Task Replay Lite 或等价证据
- 备份脚本 / 备份契约类改动没有 `BACKUP_POLICY=ok` 证据

## 2. 四项可用性门

四项全满才算“可用”：

| 门 | 通过标准 |
|----|----------|
| 入口 | 能定位到真实入口：路由、文件、类、方法、脚本或模板 |
| 主链路 | 能复述从触发到产出的主流程 |
| 场景 | 至少 3 个高频场景有切入点 |
| 验证 | 至少 1 个真实任务可验证，且有通过/失败判据 |

## 3. 标杆门

要判断为“优秀 / 标杆”，还必须满足：

- 主文件是纯路由器，非空行在类型上限内
- README 是维护章程，不是运行入口
- README §修订记录按倒序维护，最新版本在上
- README 里的可执行约束已投射到 `SKILL.md`、active references、模板或校验脚本
- references 有 P0 / P1 / P2 或等价优先级，不要求先读全部
- 高风险 / 纪律类 skill 有无 skill 基线样本与带 skill 复测样本
- 结构、评分、触发、模板和脚本均有一致性证据
- 承诺交付/发布/失败学习时，证据等级已区分 `static / contract / runtime / user-visible / release / limitation`

## 4. 分流到详表

| 快速发现 | 下一步 |
|----------|--------|
| 只需判定是否可用 | 结束本文件后输出 findings |
| 要系统修复或打分 | 继续 `checklist.md` |
| 多域 / handbook / references 很厚 | 继续 `router_handbook_gate.md` |
| 高风险 / 纪律类 | 继续 `behavioral_eval.md` |
| 涉及目录、挂载、bak、canonical | 继续 `layout/skill_truth_source_contract.md` |

## 5. 输出最小结论

```markdown
## 快速门结论
- 门禁阻断：有 / 无
- 可用性四门：入口 / 主链路 / 场景 / 验证
- 是否具备标杆条件：是 / 否 / unknown
- 下一步：结束 / 进入 checklist / 进入 behavioral_eval / 进入 router_handbook_gate
```
