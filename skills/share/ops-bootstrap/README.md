# ops-bootstrap

> **这是维护章程，不是 Agent 运行入口。** Agent 入口是根目录 `SKILL.md`。

## 修订记录

统一按倒序维护：最新版本在上；同日多次修订时，后发生的修订放更上方。

| 版本 | 日期 | 修订要点 |
|------|------|----------|
| 1.12.0 | 2026-08-05 | 补齐 MySQL `query run` / `db run` 只读执行器：凭据引用、SQL 防护、限行、超时、脱敏和强制回滚 |
| 1.11.0 | 2026-07-24 | 新增本机端口释放 helper：`local free-port` / `free-local-port.ps1|.sh`，覆盖 WinError 10013 / uvicorn 残留 |
| 1.10.0 | 2026-07-16 | 明确维护章程修订记录统一倒序，并补充运维能力模型优先的维护原则 |
| 1.9.0 | 2026-07-16 | 收敛项目侧默认配置为单个 `ops.config.json`，模板留在 skill，项目只写变量和目标状态 |
| 1.8.0 | 2026-07-16 | 增加项目 ops 配置闭环契约，用于把通用 skill 落到 bi/wzsy 等具体服务 |
| 1.7.0 | 2026-07-15 | 增加 Redis/MySQL/JDK/Java app 可渲染配置模板，明确 profile 只提供参数档位 |
| 1.6.0 | 2026-07-15 | 参考开源 sysadmin/Ansible/Dokku/Netdata/Redis role 模式，增加连接资产、日志排查、DB 核验、ZooKeeper/Kafka 模板 |
| 1.5.0 | 2026-07-15 | 增加部署、配置 profile、在线检测、Redis/MySQL 只读查询模板和 plan |
| 1.4.0 | 2026-07-15 | 增加 `provision plan`，输出在线安装命令和离线包准备清单 |
| 1.3.0 | 2026-07-15 | 从 `ecs-ops-bootstrap` 重命名为 `ops-bootstrap`，扩大到通用运维启动包 |
| 1.2.0 | 2026-07-15 | 增加 references/scripts/templates 分层契约与环境安装模板规划 |
| 1.1.0 | 2026-07-15 | 收敛为 Python core，PowerShell / shell 仅保留薄封装 |
| 1.0.0 | 2026-07-15 | 从 openclaw bi/wzsy 抽离通用 SSH bootstrap / ops-check |

## 核心用途

为「一台服务器或一组服务器 + 本机运维目录」提供可复用的：连接资产映射、SSH 别名写入、公钥部署、远程健康检查、环境安装、部署编排、在线检测、日志排查、只读数据查询、数据库结构/数据核验与配置模板。ECS 是首个适配对象，不是命名边界。

底层实现必须跨平台：`scripts/ecs_ops.py` 是唯一核心逻辑；`bootstrap-ssh.ps1`、`ops-check.ps1`、`bootstrap-ssh.sh`、`ops-check.sh` 只负责定位 Python 与转发参数。

说明：README 是人读章程，不控制 Agent 行为。凡要约束 Agent 执行或验收的规则，必须同步进入 `SKILL.md`、被路由读取的 `references/`、模板或脚本校验。

## 设计理解

- **L2 真源**：`skills/share/ops-bootstrap/scripts/`
- **项目私有层**：IP、别名、account、credentials、remote check 脚本、业务 docs
- 每个项目运维目录只薄封装调用 L2，不复制实现

## 骨架规范

| 层 | 内容 |
|----|------|
| share skill | `ecs_ops.py`、`core/mysql_readonly.py`、`setup_ssh_key.py`、`bootstrap-ssh.ps1`、`ops-check.ps1`、`bootstrap-ssh.sh`、`ops-check.sh`、`free-local-port.ps1`、`free-local-port.sh`、`helpers/free_local_port.py` |
| share references | `capability_model.md`、`project_ops_contract.md`、`open_source_patterns.md`、`workflow.md`、`layout_contract.md`、`roadmap.md`、`trigger_eval.md` |
| share templates | `TEMPLATE_sync.config.json`、`TEMPLATE_ops-check.remote.sh`、`templates/project/TEMPLATE_ops.config.json`、`templates/connect/`、`templates/provision/`、`templates/deploy/`、`templates/detect/`、`templates/logs/`、`templates/query/`、`templates/db/`、`templates/profiles/` |
| 项目 ops 目录 | `sync.config.json`、`ops.config.json`、`account.md`、`ops-check.remote.sh`、`credentials.md`、`docs/` |

细则：

- README 只放维护章程、骨架摘要和路线图入口。
- `references/layout_contract.md` 是目录分层的详细契约。
- `references/roadmap.md` 是环境安装与部署编排的阶段路线图。
- `references/open_source_patterns.md` 是开源运维工具抽象后的能力边界，不照搬具体工具实现。
- `templates/provision/` 是可复制到项目侧的脱敏目标状态模板。

## 维护约束

- 已纳入 git 的 scripts / references / `SKILL.md` 以 git 回退为准，不强制 `backup-file`；未纳入版本控制或远端资产变更前必须备份
- 扩展新场景时先归入 `references/capability_model.md` 的运维生命周期（Access / Inventory / Provision / Deploy / Config / Detect / Log / Data / DB / Backup / Audit），再决定补模板、plan 或脚本；禁止按单个工具名零散加功能
- `ecs_ops.py` 只做 CLI 路由；业务无关逻辑进 `scripts/core/`，命令实现进 `scripts/commands/`
- wrapper 不新增配置解析、SSH block 生成、远程检查等核心逻辑
- 新增组件安装能力先补模板和 `provision plan` 输出，再写 check/apply
- nginx 优化类配置先进 `templates/provision/modules/nginx/`，项目域名和证书只在项目侧填充
- redis/mysql/jdk 等服务必须有对应配置模板；`profiles` 只提供 small/large/fixed 参数，不替代 `redis.conf`、`mysqld.cnf`、JVM options
- 项目侧默认只落一个 `ops.config.json`，包含 `connect/provision/deploys/detect/logs/query/dbVerify`；规模变大时才按 section 拆文件
- 无公网安装必须先生成离线包清单；使用者按 `TEMPLATE_offline.bundle.json` 准备包，不允许脚本临场猜包
- 连接目标、日志排查、DB 核验都必须走脱敏模板和只读 plan；真实 IP、密码、业务库账号在项目侧落地
- 部署配置必须声明 profile；small/large/fixed 的默认调优值在 `templates/profiles/`
- MySQL 查询通过 `query run` / `db run` 执行，只接受环境变量或项目私有 JSON 凭据引用；内置安全基线不可被项目配置放宽
- Redis 查询仍停留在 plan；Redis/MySQL 写命令不属于本技能执行范围
- 不在 templates 写入真实密码
- 新增远程检查字段时同步更新 `templates/TEMPLATE_sync.config.json` 与 `references/workflow.md`

## 单一职责

只做 **目标连接、SSH 接入、通用 ops-check 编排、环境安装模块契约、部署/检测/日志/查询/DB 核验计划和可复用配置模板**。

## 不负责

| 场景 | 转交 |
|------|------|
| 挂载到 Cursor/Claude | `agent-hub-bootstrap` |
| nginx/mysql/app 项目定制安装 | 项目 scripts / provision |
| 文档落位 | `doc-script-governance` |
