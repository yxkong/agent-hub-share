# Project Ops Config Contract

把 `ops-bootstrap` 落到具体项目时，项目目录只保存配置、凭据引用、远程检查和业务 runbook，不复制 share 脚本实现。

默认形态是单文件：

```text
<ops>/
  sync.config.json
  ops.config.json
  account.md
  credentials.md
  ops-check.remote.sh
  bootstrap.ps1
  ops-check.ps1
  docs/
```

`ops.config.json` 包含 `connect`、`provision`、`deploys`、`detect`、`logs`、`query`、`dbVerify`。只有配置超过可读范围或项目有明确多人维护边界时，才拆成子目录文件。

## 必备配置

| 目录 | 何时需要 | 内容 |
|------|----------|------|
| `connect` | 总是需要 | 主机、SSH alias、IP/名称映射、服务清单 |
| `provision` | 需要安装或校验基础环境 | OS、网络模式、启用模块、组件目标状态和配置模板引用 |
| `deploys` | 需要发版/重启/回滚 | artifact、进程管理器、hook、配置模板、回滚命令 |
| `detect` | 需要日常巡检 | systemd、PM2、端口、HTTP、资源、日志尾部检查 |
| `logs` | 需要排障 | Nginx、应用、systemd、PM2、业务日志路径和异常 pattern |
| `query` | 需要开发/验收查数据 | Redis/MySQL 只读 allowlist、连接引用、行数限制 |
| `dbVerify` | 需要核验 schema/data | 目标库、只读 SQL、代码扫描范围、脱敏列 |

## 拓扑优先

- 先读项目文档、`sync.config.json`、`connect/target.config.json` 和现有 runbook。
- 项目机器没有本机 MySQL/Redis 时，`provision/modules/mysql.json` 和 `redis.json` 必须保持 `enabled=false`。
- 外部 RDS、AnalyticDB、Redis Cloud 等只进入 `query/`、`db/` 或项目凭据引用，不进入本机安装计划。
- HTTP 服务才考虑 Nginx 域名/反代；MySQL/Redis 默认 local/VPC，不默认域名和反代。
- PM2、systemd、Docker、Supervisor 等进程管理器必须在 `deploy/*.config.json` 和 `detect/*.config.json` 中明确。
- 模板文件必须优先引用 `skill:templates/...`，项目侧只写变量值；项目真实运行配置可以留在项目，但不要命名为模板。

## 安全边界

- 不在 share 或项目模板里写真实密码、私钥、JWT secret、数据库 root 密码。
- 项目私有 `credentials.md` 可以保存凭据，但必须被同步排除。
- query/db 默认只读；凭据通过环境变量或被同步排除的项目私有 JSON 引用；配置中禁止明文 password。
- MySQL `run` 必须先执行对应 `plan`，再显式传 `--confirm-readonly`；写数据、删数据、建库建用户不由本技能执行。
- 项目提供的 MySQL 账号必须是服务端只读最小权限账号；不得因为客户端已有 allowlist 就复用写账号。
- `ops-check.remote.sh` 只做只读探测，不做安装、重启、reload。

## 验收

项目侧配置落地后至少运行：

```bash
python <hub>/skills/share/ops-bootstrap/scripts/ecs_ops.py connect plan --config <ops>/ops.config.json
python <hub>/skills/share/ops-bootstrap/scripts/ecs_ops.py provision plan --config <ops>/ops.config.json
python <hub>/skills/share/ops-bootstrap/scripts/ecs_ops.py deploy plan --config <ops>/ops.config.json
python <hub>/skills/share/ops-bootstrap/scripts/ecs_ops.py detect plan --config <ops>/ops.config.json
python <hub>/skills/share/ops-bootstrap/scripts/ecs_ops.py logs plan --config <ops>/ops.config.json
python <hub>/skills/share/ops-bootstrap/scripts/ecs_ops.py query plan --config <ops>/ops.config.json
python <hub>/skills/share/ops-bootstrap/scripts/ecs_ops.py query run --config <ops>/ops.config.json --sql "SELECT 1" --confirm-readonly
python <hub>/skills/share/ops-bootstrap/scripts/ecs_ops.py db plan --config <ops>/ops.config.json
python <hub>/skills/share/ops-bootstrap/scripts/ecs_ops.py db run --config <ops>/ops.config.json --confirm-readonly
```
