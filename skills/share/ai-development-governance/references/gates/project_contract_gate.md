# Project Contract Gate

> 跨项目、跨技术栈共享契约的唯一治理真源。目标是让不同实现对同一调用方呈现相同的可观察行为；它不要求 Java、Python、前端或 SQL 使用相同框架和目录。

## 触发条件

- Java / Python / 前端 / SQL 任意两端以上需要同步。
- 共享 MySQL 表、DTO、API、菜单权限、状态枚举、配置 key、事件或可观测字段有变化。
- 项目技能之间出现冲突口径，例如 Java DDL 与 Python ORM、后端 DTO 与前端字段、设计文档与当前代码不一致。
- 用户要求迁移、双端实现、替换其中一端，或验证两个项目“行为一致”。

## 1. 先裁决真源

不得默认“Java 永远是真源”或“后端文档永远是真源”。按任务类型声明：

| 任务 | 默认裁决 |
|---|---|
| 明确从 A 迁移到 B | A 的当前可运行行为是迁移基线；目标栈技术实现遵守 B 的项目技能 |
| 双端共同开发 | 用户验收 / 已批准 Spec / 共享前端调用 / 当前已发布 API 中最具体且可验证者优先 |
| 共享数据库 | canonical final DDL + 已确认 migration；live drift 只作校验证据，不能静默反写真源 |
| 文档与代码冲突 | 当前可运行代码和测试优先；登记文档漂移并修正，不用兼容层掩盖 |
| 两端代码互相冲突 | 先列差异和调用方影响，再由负责人裁决；未裁决前不得单方面固化新默认 |

参考项目只能提供业务行为和共享契约证据，不得把其内部架构直接复制到另一项目。

## 2. 共享契约面

逐项填“命中 / 不适用 / 未知”，未知且影响调用方时阻断。

| 契约面 | 必须一致的可观察内容 |
|---|---|
| HTTP / SSE | route、method、transport、content-type、流事件类型、结束与错误帧 |
| 请求 | 字段名与 casing、类型、必填/可空、默认值、未知字段策略、加密 ID、批量与排序语义 |
| 响应 | `ResultBean(status/message/data/timestamp)`、`PageBean(pageNum/totalSize/pages/pageSize/data)`、空值与写操作 data 语义 |
| 错误 | 业务错误码、message 语义、HTTP status、校验错误、鉴权/权限/资源不存在/冲突/依赖失败 |
| 鉴权与租户 | 登录态、permission、tenant、DataScope、跨租户详情/更新/删除的拒绝行为 |
| 数据 | 表/列、类型、null/default、枚举、deleted/status、唯一键、加密主键与外键映射 |
| 业务行为 | 校验顺序、状态机、排序、幂等、事务结果、缓存失效、事件/通知等副作用及其顺序 |
| 可观测 | traceId、业务 ID、tenant/user、错误关联、usage、异步/SSE 失败可见性 |

硬规则：

- 一个业务语义只保留一个契约字段；不得用 `Raw/List/Json/Resolved` 或 `id/strId` 并列字段掩盖映射问题。
- 管理端纯主键详情/删除请求统一传 body `{ "id": "<encrypted strId>" }`；响应主键为 `strId`。兼容明文数字只可保留为既有过渡能力，新调用方不得依赖。
- 管理端分页默认统一为 `pageNum=1`、`pageSize=20`；`totalSize=0` 时 `pages=0`，其余按向上取整。页码最小 1，页大小范围 1..10000。
- `orderStr/fieldMappings/excludeFields/likeFields/rightLikeFields` 等内部查询控制字段默认不进入 wire schema；需要调用方排序时定义显式排序字段并做 allowlist 映射。
- 外部排序值必须经过 allowlist 字段映射和方向校验；不得把前端字符串直接拼入 SQL。
- Adapter 只提取身份上下文并做协议转换；tenant/user/permission/DataScope 的可信注入与用例裁决属于 Application。
- 租户资源的详情、更新、删除查询必须同时约束主键、tenant 和 deleted；平台全局表或租户管理表的例外要在 Task Contract 明示。

## 3. 共同分层语义与栈内自由

| 层 | 共同职责 | 不允许 |
|---|---|---|
| Adapter | HTTP/SSE 协议、Command/Response、wire ID/字段映射、调用 Application | 查库、事务、租户裁决、业务编排 |
| Application | 用例编排、可信上下文注入、权限/租户/DataScope、事务、幂等与副作用顺序 | HTTP 模型、ORM/Mapper、具体外部 SDK |
| Domain | 业务规则、Context/DTO、Port/Gateway 等稳定契约 | 框架请求对象、数据库会话、网络/缓存副作用 |
| Infrastructure | Entity/Mapper/GatewayImpl、缓存、消息、外部系统和 SDK 实现 | 提交用例事务、反向依赖 Adapter/Application |

允许的技术差异：

- Java 可将 `*Base` 持久化映射放在 Domain，并用 Spring 事务、MapStruct、领域事件。
- Python 将 ORM Entity 放在 Infrastructure，并用 UoW、AdapterMapper、Domain Port/Gateway。
- Java 的纯查询/纯技术端点可按项目技能走受控短路；Python Controller 不直连 Gateway。短路不能绕过权限、租户、事务或业务编排。

运行时主链统一表达为：

```text
Adapter -> Application -> Domain Port <- Infrastructure Impl
```

源码依赖方向统一表达为：

```text
Adapter -> Application -> Domain
Infrastructure -> Domain
```

## 4. 验证证据

静态对照只能证明“看起来一致”，不能单独判定闭环。至少交付：

1. 契约矩阵：成功、校验失败、未登录、无权限、跨租户、资源不存在、冲突/幂等、外部依赖失败。
2. 生成契约：OpenAPI/schema snapshot 或等价字段级 diff，覆盖 route、request、response、error。
3. 同输入对照：两端用同一 golden case 断言 status、data、分页、排序和副作用。
4. 写链路三联检：写入结果、读取/分页结果、响应出口字段；租户资源再补跨租户拒绝。
5. DB 与副作用：canonical DDL 对齐、事务回滚、缓存失效、事件/消息顺序按命中项验证。
6. 可观测：失败能由 traceId 关联到业务 ID 和 tenant/user；SSE/异步错误不能只留后端日志。

若其中某项无法运行，结论只能是 `limitation`，必须写明缺失证据和风险。

## 5. 阻断项

- 共享 DB 表未确认真源，却同时改 Java DDL 与 Python ORM。
- route/字段/错误码/分页/权限/租户只改一端，或只验证 HTTP 200。
- 租户资源详情/删除只按主键查询，或 Gateway 接收 tenant 却未用于 SQL。
- 外部排序片段未经 allowlist 进入 SQL。
- 为了“兼容”增加同义并列字段、公共基类改动、全局序列化或 online SQL，且无 ADR/人工确认。
- 只有文档/静态扫描证据，却表述为“行为一致、已闭环”。

## 6. 最小输出格式

```markdown
### Project Contract Gate

**真源 / 裁决规则**：
**参与项目 / 技能**：
**契约矩阵**：
**栈内实现差异**：
**允许改 / 禁止改**：
**验证命令、判据与实际产物**：
**已知漂移 / 风险**：
**结论**：pass / blocked / limitation
```
