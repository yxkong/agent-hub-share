# Ops Bootstrap Roadmap

## 目标

把 ECS 日常运维从「SSH 接入 + ops-check」扩展到「环境目标状态 + 安装计划 + 检查 + 可选执行」，覆盖：

- Python / uv
- JDK
- Nginx
- Node.js
- MySQL
- Redis
- ZooKeeper
- Kafka
- 部署编排与回滚
- 在线检测与巡检
- 日志排查
- Redis/MySQL 只读数据查询
- 数据库结构/数据核验

## 非目标

- 不在 share skill 内写真实业务部署脚本。
- 不默认执行远程安装、重启、删库、证书替换等有状态动作。
- 不把项目密码、证书私钥、生产域名、数据库 root 密码写进模板。
- 不把所有组件强行装在一台机器；配置必须允许启用/禁用模块。

## 命令模型

统一收敛为一个 Python CLI：

```bash
python scripts/ecs_ops.py provision plan --ops-root <ops>
python scripts/ecs_ops.py provision check --ops-root <ops>
python scripts/ecs_ops.py provision apply --ops-root <ops> --module python-uv
python scripts/ecs_ops.py connect plan --config templates/connect/TEMPLATE_target.config.json
python scripts/ecs_ops.py deploy plan --config templates/deploy/TEMPLATE_deploy.config.json
python scripts/ecs_ops.py detect plan --config templates/detect/TEMPLATE_online-detection.config.json
python scripts/ecs_ops.py query plan --config templates/query/TEMPLATE_query.config.json
python scripts/ecs_ops.py query run --config <ops>/ops.config.json --sql "SELECT 1" --confirm-readonly
python scripts/ecs_ops.py logs plan --config templates/logs/TEMPLATE_log-triage.config.json
python scripts/ecs_ops.py db plan --config templates/db/TEMPLATE_db-verify.config.json
python scripts/ecs_ops.py db run --config <ops>/ops.config.json --confirm-readonly
```

当前已实现：

```bash
python scripts/ecs_ops.py provision plan --config templates/provision/TEMPLATE_environment.config.json
python scripts/ecs_ops.py provision plan --ops-root <ops>
python scripts/ecs_ops.py provision plan --ops-root <ops> --mode offline --module nginx
python scripts/ecs_ops.py deploy plan --config templates/deploy/TEMPLATE_deploy.config.json
python scripts/ecs_ops.py detect plan --config templates/detect/TEMPLATE_online-detection.config.json
python scripts/ecs_ops.py query plan --config templates/query/TEMPLATE_query.config.json
python scripts/ecs_ops.py query run --config <ops>/ops.config.json --sql "SELECT 1" --confirm-readonly
python scripts/ecs_ops.py connect plan --config templates/connect/TEMPLATE_target.config.json
python scripts/ecs_ops.py logs plan --config templates/logs/TEMPLATE_log-triage.config.json
python scripts/ecs_ops.py db plan --config templates/db/TEMPLATE_db-verify.config.json
python scripts/ecs_ops.py db run --config <ops>/ops.config.json --confirm-readonly
```

阶段要求：

| 命令 | 远程动作 | 输出 |
|------|----------|------|
| `plan` | 无变更 | 将执行的模块、版本、源、服务名、端口、风险 |
| `check` | 只读 | 当前版本、服务状态、端口监听、配置缺口 |
| `apply` | 有状态 | 只执行显式指定模块；必须支持 `--dry-run` |
| `rollback` | 有状态 | 只有模块声明可回滚时提供；必须打印影响范围 |

## 在线 / 离线策略

| 场景 | 行为 |
|------|------|
| 有公网 | 使用各模块 `onlineInstall.commands`，走系统包管理器、官方安装脚本或官方二进制源 |
| 无公网 | 先运行 `provision plan --mode offline`，按 `offlineArtifacts` 准备离线包到 `offlineBundleDir` |
| 不确定 | `networkMode=auto` 时先输出两套信息，由使用者确认网络条件 |

离线准备规则：

- 环境总清单：`templates/provision/TEMPLATE_offline.bundle.json`。
- 模块清单：每个 `templates/provision/modules/TEMPLATE_<component>.json` 的 `offlineArtifacts`。
- apt/rpm 类包必须匹配目标 OS 发行版、版本和 CPU 架构，并携带依赖。
- tarball/binary 类包必须携带 checksum；项目侧 bundle manifest 填 `sha256` 或 `sha256Manifest`。
- 密码、证书私钥、数据库 root 密码不进入离线 bundle 模板，只在项目私有目录保存。

## 模块契约

每个组件模块必须有四层：

| 层 | 内容 |
|----|------|
| config | `templates/provision/modules/TEMPLATE_<component>.json` 字段说明 |
| config-template | `templates/provision/modules/<component>/TEMPLATE_*` 可渲染服务配置 |
| detector | 只读探测：版本、命令路径、服务状态、端口 |
| planner | 根据目标状态生成安装/升级计划 |
| applier | 执行安装或配置变更；默认 dry-run，显式确认后才执行 |

每个模块必须输出四态：

| 状态 | 含义 |
|------|------|
| `ABSENT` | 未安装或不可用 |
| `PRESENT` | 已安装但未完全满足目标状态 |
| `READY` | 满足目标状态和健康检查 |
| `UNKNOWN` | 探测失败或信息不足 |

## 部署 / 检测 / 查询

| 能力 | 当前入口 | 模板 |
|------|----------|------|
| 部署计划 | `deploy plan` | `templates/deploy/TEMPLATE_deploy.config.json` |
| 配置档位 | plan 引用 | `templates/profiles/TEMPLATE_small.profile.json` / `TEMPLATE_large.profile.json` / `TEMPLATE_fixed.profile.json` |
| 在线检测 | `detect plan` | `templates/detect/TEMPLATE_online-detection.config.json` |
| 数据查询 | MySQL `query plan` → `query run --confirm-readonly`；Redis plan | `templates/query/TEMPLATE_query.config.json` |
| 连接资产 | `connect plan` | `templates/connect/TEMPLATE_target.config.json` |
| 日志排查 | `logs plan` | `templates/logs/TEMPLATE_log-triage.config.json` |
| DB 核验 | `db plan` → `db run --confirm-readonly` | `templates/db/TEMPLATE_db-verify.config.json` |

MySQL 执行默认只读，Redis 仍只提供 plan；禁止把写命令纳入 share 默认 allowlist 或执行器。

## 组件规划

| 阶段 | 模块 | P0 检查 | P1 安装/配置 |
|------|------|---------|--------------|
| P0 | `python-uv` | `python3 --version`、`uv --version`、pip/venv 可用性 | 安装 uv、创建 venv、配置 pip/uv index |
| P0 | `jdk` | `java -version`、`javac -version`、`JAVA_HOME`、systemd 服务依赖 | 安装指定 LTS JDK、设置 profile |
| P0 | `nginx` | `nginx -v`、`nginx -t`、80/443 监听、systemd 状态 | 安装 nginx、渲染站点模板、reload |
| P1 | `node` | `node -v`、`npm -v`、包管理器、pm2 | 安装 Node LTS、启用 corepack/pm2 |
| P1 | `mysql` | `mysql --version`、systemd、端口、数据目录、只读连接探测 | 安装 MySQL、初始化配置、创建库用户 |
| P1 | `redis` | `redis-server --version`、systemd、端口、配置路径 | 安装 Redis、绑定地址、持久化策略 |
| P1 | `zookeeper` | `zkServer.sh status`、systemd、2181/2888/3888 端口 | 安装 ZooKeeper、设置 dataDir/myid、集群配置 |
| P1 | `kafka` | `kafka-topics.sh --version`、systemd、9092/9093 端口 | 安装 Kafka、KRaft/集群配置、broker listener |

## 配置总入口

项目侧建议使用：

```text
<ops>/provision/environment.config.json
<ops>/provision/modules/<component>.json
```

`environment.config.json` 只声明 OS、包管理器、全局源策略、启用模块和配置文件路径。组件细节进入 `modules/*.json`。

## Nginx 优化方向

Nginx 模板不只描述“是否安装”，还要描述目标优化状态：

- 基础 worker、连接数、gzip、日志格式、上传大小、超时。
- TLS 协议、HSTS、OCSP stapling、证书路径引用。
- 反向代理 headers、WebSocket、buffer、连接超时。
- 静态资源缓存、前端 history fallback、健康检查 URL。
- `nginx -t` 和 reload 命令必须先进入 plan，再进入 apply。

## 服务配置模板要求

- `profiles` 只保存档位参数，例如连接数、buffer、内存、JVM heap；不能替代服务配置文件。
- Redis/MySQL 这类非 HTTP 服务默认不需要 Nginx 反向代理和域名；默认绑定 `127.0.0.1` 或 VPC 地址。
- Redis/MySQL 如需远程访问，项目侧必须显式声明安全组/VPN/TLS/ACL/账号策略。
- Java 应用启动参数属于 deploy 层，不属于 JDK 安装层；JDK 只负责 `JAVA_HOME` 和命令可用。
- JVM 模板必须包含 heap、GC、GC log、OOM 退出、heap dump、编码和时区。

## 安全门

- `apply` 前必须展示计划、目标 host、模块、版本、端口、服务名、会写入的路径。
- MySQL/Redis 密码只能来自项目私有文件、环境变量或交互输入。
- Nginx 证书 key 只允许引用项目私有路径。
- 默认不开放公网端口；端口暴露必须在配置里显式声明。
- 任何 destructive 动作必须单独命令和单独确认，不跟 install 混跑。

## 迭代顺序

1. 固化 layout contract、roadmap、配置模板。
2. 实现 `provision plan`，输出在线命令和离线包清单。DONE
3. 实现 `provision check`，只读远程状态。
4. 实现 `python-uv` 和 `jdk` 的 dry-run apply。
5. 加入 `nginx` 模板渲染和 `nginx -t` 验证。
6. 加入 `node` / `mysql` / `redis`，每个模块先 check，再 apply；Redis/MySQL 配置模板已补齐。
7. 引入项目级 deploy hook：pre-check、upload、restart、post-check、rollback。PLAN DONE
8. 实现在线 detection 的远程只读执行。
9. 实现 Redis/MySQL 查询的只读执行与审计日志。
10. 实现日志排查的远程只读读取和脱敏摘要。
11. 实现 DB schema/data 核验与本地代码扫描的只读闭环。
