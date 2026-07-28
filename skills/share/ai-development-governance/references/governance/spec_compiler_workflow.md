# Spec Compiler Workflow

## 定位

本流程把 Full Path 的规格生成变成确定性编译闭环。它不判断业务方案是否正确，也不替代项目技能提供当前代码、DDL、API、运行时和用户事实。

```text
项目事实 → Fact Pack → Feature Spec → 反方复核 → document 校验
→ 人工评审 → frozen → SDD / ADR / Task Contract
→ implementation-ready 校验 → delivery-workflow
```

## 1. 输入契约

生成前必须具备：

- 项目身份与项目技能入口。
- 当前代码、测试、DDL、运行文档或外部官方资料中的事实锚点。
- 用户目标、非目标、约束和主链路验收。
- `fact / assumption / unknown / risk` 分离结果。

禁止：

- 把用户建议的实现直接写成已决策方案。
- 用通用最佳实践冒充项目当前事实。
- 关键 unknown 未关闭时输出 `approval: frozen`。

## 2. Fact Pack

Fact Pack 直接写入 Feature Spec §1，不创建第二份长期真源：

| 类型 | ID | 必须回答 |
|---|---|---|
| 当前事实 | `FACT-*` | 来源路径/命令是什么，证据等级是什么 |
| 假设 | `ASM-*` | 如何最小验证，失效后影响什么 |
| 未知 | `UNK-*` | 是否阻断冻结，关闭条件是什么 |
| 风险 | `RISK-*` | 等级、缓解和停止条件是什么 |

项目事实冲突时按当前可运行代码/测试、冻结契约、当前文档的优先级裁决；无法裁决则保留 unknown。

## 3. Feature Spec 生成

使用 `templates/TEMPLATE_FEATURE_SPEC.md`，并遵守：

- 功能需求：`REQ-*`
- 非功能预算：`NFR-*`
- 安全约束：`SEC-*`
- 验收标准：`AC-*`
- 每个 `REQ/NFR/SEC` 必须进入 §11 追踪矩阵。
- NFR 必须给数值预算，或说明 `NOT_APPLICABLE` 的证据。
- 安全约束必须描述确定性执行或验证机制，不能只写“注意安全”。

Spec 只写用户价值、范围、规则和可观察契约；实现结构进入 SDD。

## 4. 反方复核

Spec 初稿后逐项回答：

1. 哪个 fact 其实是 assumption？
2. 哪个 P0 可以缩成更小闭环？
3. 哪个失败链路没有用户恢复动作？
4. 哪个安全约束只写了目标，没有执行机制？
5. 哪个性能目标没有数字？
6. 哪个需求会改变共享契约或项目指纹？
7. 哪个需求没有验收或证据入口？

输出状态只允许：

- `PASS`
- `REVISION_REQUIRED`
- `BLOCKED_BY_UNKNOWN`
- `NEEDS_HUMAN_DECISION`

## 5. 编译和冻结

评审稿先运行：

```powershell
pwsh -NoProfile -File <hub-root>\skills\share\ai-development-governance\scripts\check-spec-sdd-structure.ps1 `
  -HubRoot <hub-root> `
  -Spec <spec-path> `
  -Sdd <sdd-path> `
  -Adr <adr-path> `
  -TaskContract <task-contract-path> `
  -Mode document
```

通过后由负责人把 Spec、SDD、Task Contract 设为：

```yaml
status: canonical
approval: frozen
```

ADR 若存在真实架构取舍，设为：

```yaml
status: canonical
decision_status: accepted
```

进入实现前运行同一命令并将 `-Mode` 改为 `implementation-ready`。只有输出：

```text
SPEC_SDD_STRUCTURE=ok
```

才允许转 `delivery-workflow`。

## 6. 派生规则

- SDD 必须引用全部 `REQ-* / NFR-* / SEC-* / AC-*`。
- ADR 使用 `DEC-*`，并在 SDD 中被引用。
- Task Contract 使用 `TASK-*`，覆盖全部 `AC-*`。
- 下游文档 `spec_id` 必须与 Spec 一致。
- 下游 `spec_version` 必须与 Spec `version` 一致。
- Spec 冻结后的需求变化先升级 Spec 版本，再同步 SDD / ADR / Task，不允许静默漂移。

## 7. 校验器边界

校验器负责：

- YAML 必填字段和合法状态。
- 必填章节存在且非空。
- 占位符和未关闭标记。
- Spec ID、版本和追踪覆盖。
- implementation-ready 冻结门。

校验器不负责：

- 判断方案是否有业务价值。
- 判断代码事实是否真实。
- 自动接受 ADR。
- 自动关闭风险或 unknown。

这些仍由项目技能、验证命令和人工评审提供证据。

## 8. 方案 C 演进边界

方案 B 固定以下兼容面：YAML 字段、追踪 ID、三种校验模式和 JSON 报告。后续升级 DSL 时，应先形成 ADR，决定 Markdown 是真源还是派生产物；本流程不预建数据库、API 或 UI。
