---
name: ops-bootstrap
description: 跨平台运维技能包（Python core + ps1/sh thin wrapper），覆盖服务器连接与资产映射、SSH alias、公钥部署、ops-check、在线/离线环境安装规划、Nginx/MySQL/Redis/JDK/Node/ZooKeeper/Kafka 等服务模板、部署编排、微信/小程序校验 txt 下发、在线检测、日志排查和只读数据核验；用于用户要求连接某台服务器、安装基础服务、排查服务异常日志、核验数据库结构/数据、下发小程序校验文件或抽取通用运维能力时；不负责保存真实凭据、默认执行生产变更或替代项目业务部署脚本。
---

# Ops Bootstrap

> 通用运维底座。在 `htyc` 项目运维包内作为跨项目可复用能力层；HTYC 专属资产、环境配置与业务脚本不放本目录。  
> 项目侧目录契约见 `../docs/layout.md`（若在 htyc 包内）或各项目 ops 包的 layout 文档。

## 30 秒决策区

| 任务类型 | 什么时候选它 | 先读什么 |
|---|---|---|
| `bootstrap` | 新 ECS / 新电脑：写 SSH 别名、部署公钥、跑检查 | `references/workflow.md` |
| `ops-check` | 只检查远程服务是否起来 | `references/workflow.md` |
| `new-ops-dir` | 为新机器建同类运维目录 | `templates/` + `references/workflow.md` |
| `cross-os-wrapper` | 需要 Windows/macOS/Linux 统一调用方式 | `references/workflow.md` §实现分层 |
| `layout` | 讨论 references / scripts / templates 怎么分层 | `references/layout_contract.md` |
| `skill-maintenance` | 讨论 README 是否生效、规范放哪、能力扩展怎么收口 | `references/layout_contract.md` + `references/capability_model.md` |
| `connect` | 用户说“连接 xxx / xxx 有哪些服务 / IP 名称映射” | `templates/connect/TEMPLATE_target.config.json` |
| `provision` | 规划 Python/uv/JDK/Nginx/Node/MySQL/Redis/ZooKeeper/Kafka 一键环境安装 | `references/roadmap.md` + `templates/provision/` |
| `offline-provision` | 无公网环境需要准备离线安装包 | `ecs_ops.py provision plan` + `templates/provision/TEMPLATE_offline.bundle.json` |
| `deploy` | 部署计划、配置档位、systemd/app env 模板、回滚钩子 | `references/capability_model.md` + `templates/deploy/` |
| `online-detect` | 在线检测、端口/HTTP/systemd/日志/资源巡检 | `templates/detect/TEMPLATE_online-detection.config.json` |
| `local-free-port` | 本机端口被占 / WinError 10013 / uvicorn 残留 | `scripts/free-local-port.ps1` + `ecs_ops.py local free-port` |
| `data-query` | MySQL 只读查询执行、Redis/MySQL allowlist、限制和示例 | `templates/query/TEMPLATE_query.config.json` |
| `log-triage` | 排查 Nginx/服务异常日志，先定位日志源和只读关联检查 | `templates/logs/TEMPLATE_log-triage.config.json` |
| `db-verify` | 执行数据库表结构/数据只读检查并与本地代码核验 | `templates/db/TEMPLATE_db-verify.config.json` |
| `project-ops-config` | 给某个项目落本地 ops 配置骨架 | `references/project_ops_contract.md` + `templates/project/TEMPLATE_ops.config.json` |
| `ops-patterns` | 用户要求参考开源运维工具完善技能边界 | `references/open_source_patterns.md` |
| `triage-case` | 服务器死机/OOM/SSH不通/磁盘满等故障，先查历史案例 | `references/case_library_index.md`（先读索引，再按行号读具体案例） |
| `disk-triage` | 磁盘满 / 磁盘 100% / 日志满了，定位是哪块满 | `scripts/helpers/disk_triage.sh` + `references/case_library_index.md` -> CASE-003 |
| `nginx-crash` | Nginx 突然崩溃、"systemctl status nginx failed"、无人操作但服务挂了 | `scripts/helpers/nginx_crash_triage.sh` + `references/case_library_index.md` -> CASE-004 |
| `security-audit` | 服务器 CPU 飙高、疑似被入侵、挖矿木马、端口暴露公网 | `scripts/helpers/security_audit.sh` + `references/case_library_index.md` -> CASE-005 |
| `nginx-cert` | SSL 证书过期、OCSP 错误刷屏、证书有效期检查 | `scripts/helpers/nginx_cert_check.sh` + `references/case_library_index.md` -> CASE-006 |
| `nginx-drift` | 多台 Nginx 配置不一致、部分域名行为异常、配置漂移 | `scripts/helpers/nginx_drift_check.sh` + `references/case_library_index.md` -> CASE-007 |
| `kafka-topic-id-drift` | producer 成功但所有 consumer group 超时/不消费，broker 报 partition topic ID mismatch | `ecs_ops.py kafka topic-id plan/apply` + `references/case_library_index.md` -> CASE-008 |
| `kafka-repush` | 消费 Kafka 历史消息、按条件过滤后重新推送到同一/另一 topic | `references/case_library_index.md` -> CASE-009（含 dry-run→小批量→全量 SOP、限速、断点续推、验证闭环） |
| `nginx-mp-verify` | 微信/小程序校验 txt 下发到业务域名静态根 | `scripts/deploy-mp-verify.ps1` + `references/modules/nginx_mp_verify.md` |
| `safe-ops` | 任何修改/删除/重启操作前，必须查阅安全操作规范 | `references/safe_ops_manual.md` |

## 作用边界

**负责**：跨项目可复用的目标资产解析、SSH 接入、健康检查、环境安装规划、部署编排模板、在线检测模板、日志排查计划、只读数据查询和数据库核验模板（L2），本机开发端口释放 helper，以及 Nginx 站点根上的微信/小程序校验 txt 下发（`scripts/deploy-mp-verify.ps1`）；实现入口真源是 `scripts/ecs_ops.py`（校验 txt 为 Nginx helper，与 `nginx_cert_check.sh` 同类）。

**不负责**：

- 业务部署真实执行、项目定制安装、证书、数据库用户和写数据命令 → 各项目 `scripts/` / `provision/` / `credentials.md`
- hub 挂载发布 → `agent-hub-bootstrap`
- 凭据内容编写策略 → 项目 `credentials.md`（勿进 share）

## 硬规则

- 项目目录只留 **薄封装** + `sync.config.json` + `account.md` + `ops-check.remote.sh` + 凭据/文档。
- 通用逻辑只改本技能 `scripts/ecs_ops.py`；`*.ps1` / `*.sh` 只能做薄封装，禁止承载核心逻辑。
- 新增功能按 `references/layout_contract.md` 分区；新增环境安装能力先补 `templates/provision/` 和 `references/roadmap.md`。
- `profiles` 只保存档位参数；服务启动必须有对应配置模板，例如 `redis.conf`、`mysqld.cnf`、Nginx conf、JVM options、systemd unit。
- 项目侧默认只保留一个 `ops.config.json`；通用模板留在 skill，项目侧只写变量、目标状态和私有引用。
- 项目侧配置必须反映真实拓扑；没有本机 MySQL/Redis 就不要在 provision 里启用，只保留 query/db verify 引用。
- 环境安装必须先跑 `provision plan`；`apply` 必须显式指定模块并支持 dry-run。
- 部署、检测、查询都先跑 `plan`；MySQL `query run` / `db run` 还必须显式传 `--confirm-readonly`，查询默认只读 allowlist，写命令禁止放行。
- 连接、日志排查、数据库核验都先生成只读 plan；真实 SSH、日志读取、DB 查询必须来自项目私有配置和人工明确目标。
- MySQL `run` 使用的数据库账号自身也必须是只读账号；客户端 SQL 防护不能替代服务端最小权限。
- 禁止在项目运维目录各自维护一份完整 bootstrap。
- **禁止**把密码、私钥写进本技能或 templates。
- **安全操作**：git 内资产以 git 回退为准；未纳入版本控制或远端资产修改前必须备份；任何删除前必须人工确认；除非用户明确要求"删除"，不得执行 `rm`。详见 `references/safe_ops_manual.md`。
- **校验 txt**：必须先 `-DryRun`；路径只来自当前环境 `conf.d` 的 `root`；不为静态 txt reload Nginx。细则 `references/modules/nginx_mp_verify.md`。
- **凭证隔离**：项目目录内不存放明文密码；通过 SSH 密钥直连跳板机操作所有节点；项目内 `account.md` 只保留 IP、SSH 别名和密钥路径。

## 调用

```powershell
$L2 = "$env:AGENTS_HUB_ROOT\skills\share\ops-bootstrap\scripts"
& "$L2\bootstrap-ssh.ps1" -OpsRoot <ops-dir>
& "$L2\ops-check.ps1" -OpsRoot <ops-dir>
& "$L2\free-local-port.ps1" -Port 9100
& "$L2\deploy-mp-verify.ps1" -OpsRoot <ops-dir> -LocalFile <txt> -Domain a.example,b.example -DryRun
```

macOS/Linux：

```bash
L2="$AGENTS_HUB_ROOT/skills/share/ops-bootstrap/scripts"
bash "$L2/bootstrap-ssh.sh" --ops-root /path/to/ops
bash "$L2/ops-check.sh" --ops-root /path/to/ops
bash "$L2/free-local-port.sh" --port 9100
```

Python 直调（调试真源）：

```bash
python "$AGENTS_HUB_ROOT/skills/share/ops-bootstrap/scripts/ecs_ops.py" ops-check --ops-root /path/to/ops
python "$AGENTS_HUB_ROOT/skills/share/ops-bootstrap/scripts/ecs_ops.py" connect plan --config /path/to/ops/ops.config.json
python "$AGENTS_HUB_ROOT/skills/share/ops-bootstrap/scripts/ecs_ops.py" provision plan --ops-root /path/to/ops
python "$AGENTS_HUB_ROOT/skills/share/ops-bootstrap/scripts/ecs_ops.py" deploy plan --config /path/to/ops/ops.config.json
python "$AGENTS_HUB_ROOT/skills/share/ops-bootstrap/scripts/ecs_ops.py" detect plan --config /path/to/ops/ops.config.json
python "$AGENTS_HUB_ROOT/skills/share/ops-bootstrap/scripts/ecs_ops.py" query plan --config /path/to/ops/ops.config.json
python "$AGENTS_HUB_ROOT/skills/share/ops-bootstrap/scripts/ecs_ops.py" query run --config /path/to/ops/ops.config.json --sql "SELECT 1" --confirm-readonly
python "$AGENTS_HUB_ROOT/skills/share/ops-bootstrap/scripts/ecs_ops.py" logs plan --config /path/to/ops/ops.config.json
python "$AGENTS_HUB_ROOT/skills/share/ops-bootstrap/scripts/ecs_ops.py" db plan --config /path/to/ops/ops.config.json
python "$AGENTS_HUB_ROOT/skills/share/ops-bootstrap/scripts/ecs_ops.py" db run --config /path/to/ops/ops.config.json --confirm-readonly
python "$AGENTS_HUB_ROOT/skills/share/ops-bootstrap/scripts/ecs_ops.py" local free-port --port 9100
python "$AGENTS_HUB_ROOT/skills/share/ops-bootstrap/scripts/ecs_ops.py" kafka topic-id plan --log-dir /var/lib/kafka/logs --topic __consumer_offsets --expected-topic-id <topic-id-from-cluster-metadata>
# apply 前必须停 broker；命令会先备份全部目标 partition.metadata，再原子替换漂移项
python "$AGENTS_HUB_ROOT/skills/share/ops-bootstrap/scripts/ecs_ops.py" kafka topic-id apply --log-dir /var/lib/kafka/logs --topic __consumer_offsets --expected-topic-id <topic-id-from-cluster-metadata> --backup-dir /var/backups/kafka/topic-id --confirm-topic-id-repair
```

项目侧推荐保留：

```powershell
# bi/bootstrap.ps1
& "$env:AGENTS_HUB_ROOT\skills\share\ops-bootstrap\scripts\bootstrap-ssh.ps1" -OpsRoot $PSScriptRoot @args
```

能力模型 → `references/capability_model.md`；项目配置闭环 → `references/project_ops_contract.md`；开源模式吸收 → `references/open_source_patterns.md`；细节 SOP → `references/workflow.md`；目录分层 → `references/layout_contract.md`；环境安装路线图 → `references/roadmap.md`；触发样例 → `references/trigger_eval.md`；**故障排查案例库索引** → `references/case_library_index.md`（案例全文 → `references/case_library.md`）；**安全操作手册** -> `references/safe_ops_manual.md`；小程序校验 txt → `references/modules/nginx_mp_verify.md`.

## 与其他技能

| 技能 | 何时转交 |
|------|----------|
| `agent-hub-bootstrap` | publish / sync / 挂载本技能 |
| `doc-script-governance` | 运维文档放置与改前备份 |
| `skill-discovery` | 是否该新建同类 skill |
