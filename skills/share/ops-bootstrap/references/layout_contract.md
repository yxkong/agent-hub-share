# ECS Ops Layout Contract

## 目录职责

| 目录 | 放什么 | 不放什么 |
|------|--------|----------|
| `SKILL.md` | Agent 入口、触发条件、硬规则、最短调用路径 | 长篇实现细节、组件安装参数矩阵 |
| `README.md` | 维护章程、修订记录、维护约束 | Agent 运行入口 |
| `references/` | 人和 Agent 都要遵守的规范、workflow、模块契约、roadmap | 可执行脚本、真实凭据、项目私有配置 |
| `templates/` | 可复制到项目 ops 目录的脱敏配置模板 | 真实 IP、密码、证书、业务域名 |
| `scripts/` | 跨平台入口、Python core、可复用工具模块 | 项目业务部署脚本、一次性临时脚本 |
| `bak/` | `backup-file` 生成的历史备份 | 手工快照目录、可执行入口 |

## 运行入口规则

- `SKILL.md` 只做 Agent 路由、触发条件和最短硬规则；规范正文下沉到本文件、`capability_model.md`、模块 references、templates 或脚本校验。
- README 是人读维护章程，不是 Agent 运行入口；README-only 规则只算维护说明，不算技能已管控。
- 会影响 Agent 执行、验收或生成结果的规则，必须至少落到一个 active 入口：`SKILL.md` 路由、被路由读取的 `references/`、`templates/` 或脚本校验。
- 扩展新运维场景时，先归入 `capability_model.md` 的生命周期能力面（Access / Inventory / Provision / Deploy / Config / Detect / Log / Data / DB / Backup / Audit），再决定补模板、plan 或脚本；禁止按单个工具名零散追加。

## references 分区规范

| 类型 | 命名 | 内容边界 |
|------|------|----------|
| 主流程 | `workflow.md` | 新机器接入、bootstrap、ops-check、项目薄封装 |
| 目录契约 | `layout_contract.md` | `references/scripts/templates` 分层和禁止项 |
| 环境安装路线图 | `roadmap.md` | Python/uv/JDK/Nginx/Node/MySQL/Redis/ZooKeeper/Kafka 的阶段计划和模块契约 |
| 开源模式抽象 | `open_source_patterns.md` | 从开源 sysadmin/Ansible/deploy/monitoring 生态抽象出的能力边界 |
| 项目配置闭环 | `project_ops_contract.md` | 把 share 模板实例化到项目 ops 目录时的必备配置和禁区 |
| 触发样例 | `trigger_eval.md` | should-trigger / should-not-trigger / held-out 样例 |
| 安全操作手册 | `safe_ops_manual.md` | 修改前备份、删除前确认、操作分级、Agent 行为约束 |
| 模块细则 | `modules/<name>.md` | 某个组件的检查、安装、回滚、模板字段说明 |

规则：

- `references/` 写稳定契约，不写某个项目的当前状态。
- 新增组件前先补 `references/modules/<component>.md` 或在 `roadmap.md` 登记 P0 契约。
- 组件真实安装命令在实现前必须有 dry-run / plan 输出，不允许文档直接诱导执行生产变更。

## scripts 分区规范

| 区域 | 路径 | 职责 |
|------|------|------|
| 稳定入口 | `scripts/bootstrap-ssh.ps1`、`scripts/bootstrap-ssh.sh`、`scripts/ops-check.ps1`、`scripts/ops-check.sh` | 外部兼容入口，只定位 Python 并转发参数 |
| CLI 路由 | `scripts/ecs_ops.py` | Python 统一命令入口，保留向后兼容 |
| Core 库 | `scripts/core/` | 配置解析、SSH 调用、计划渲染、公共执行器 |
| 命令实现 | `scripts/commands/` | bootstrap、ops-check、provision、deploy、detect、query 等命令实现 |
| 组件模块 | `scripts/modules/<component>/` | Python/uv/JDK/Nginx/Node/MySQL/Redis/ZooKeeper/Kafka 等模块的 plan/check/apply 实现 |
| Helper | `scripts/helpers/` | 单一职责工具，如公钥部署、模板渲染、远端探测 |
| 测试 | `tests/` 或 skill 既有测试目录 | 本地纯函数、模板解析、命令 plan 快照 |

兼容规则：

- 根目录现有入口不移动；需要重构时先保留转发 stub。
- 新增功能不要继续堆进单个大文件；`ecs_ops.py` 只做参数解析和分发。
- 远程有状态动作必须支持 `plan` 或 `--dry-run`，默认不执行。
- `ps1/sh` wrapper 不解析业务配置，不拼安装命令，不维护组件逻辑。

## templates 分区规范

| 区域 | 路径 | 用途 |
|------|------|------|
| ops 基础 | `templates/TEMPLATE_sync.config.json` | SSH、远程路径、检查脚本等基础配置 |
| 项目聚合配置 | `templates/project/TEMPLATE_ops.config.json` | 项目侧默认单文件配置骨架 |
| 远端检查 | `templates/TEMPLATE_ops-check.remote.sh` | 只读健康检查脚本 |
| 账号说明 | `templates/TEMPLATE_account.md` | 人工填充的账号记录格式 |
| 连接资产 | `templates/connect/TEMPLATE_target.config.json` | 目标名、别名、IP、SSH、服务端口、默认检查 |
| 环境总配置 | `templates/provision/TEMPLATE_environment.config.json` | 一键环境安装的总入口配置 |
| 组件配置 | `templates/provision/modules/TEMPLATE_<component>.json` | 单个组件的版本、源、端口、服务名、安装策略 |
| 组件配置模板 | `templates/provision/modules/<component>/TEMPLATE_*` | Redis/MySQL/Nginx/JDK 等服务真实配置模板 |
| 部署配置 | `templates/deploy/TEMPLATE_deploy.config.json` | artifact、strategy、profile、hooks、rollback |
| Java 应用参数 | `templates/deploy/TEMPLATE_java-app.jvm.options` | JDK17 应用 JVM/GC/OOM/日志参数 |
| 在线检测 | `templates/detect/TEMPLATE_online-detection.config.json` | systemd、端口、HTTP、日志、资源巡检 |
| 日志排查 | `templates/logs/TEMPLATE_log-triage.config.json` | 日志源、时间窗口、异常模式、关联检查、输出限制 |
| 数据查询 | `templates/query/TEMPLATE_query.config.json` | Redis/MySQL 只读 allowlist、denylist、limits |
| DB 核验 | `templates/db/TEMPLATE_db-verify.config.json` | schema/data 核验、代码扫描范围、只读 SQL 限制、脱敏列 |
| 规格档位 | `templates/profiles/TEMPLATE_<profile>.profile.json` | small/large/fixed 调优值 |

模板规则：

- 模板只放脱敏占位值。
- 可选字段必须给默认意图，不给真实生产值。
- 密码、私钥、证书 key、数据库 root 密码只允许引用项目私有文件或交互输入，不进入 share。
- 配置优先描述目标状态：版本、服务名、端口、安装源、数据目录、启停策略、健康检查。

## 项目侧目录建议

```text
<ops>/
  sync.config.json
  account.md
  credentials.md
  ops-check.remote.sh
  bootstrap.ps1
  ops-check.ps1
  ops.config.json
  scripts/
    install.sh
    deploy.sh
    rollback.sh
  docs/
    server-setup.md
```

项目侧 `scripts/` 可以写业务安装、部署、重启、回滚；share skill 只提供通用调度、模板和检查框架。
