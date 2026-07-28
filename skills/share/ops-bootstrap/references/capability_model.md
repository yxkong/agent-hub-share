# Ops Bootstrap Capability Model

## 运维能力面

| 能力 | 目标 | 默认边界 |
|------|------|----------|
| Access | SSH alias、公钥、账号上下文 | 不保存私钥和密码 |
| Inventory | 目标名、IP/端口、服务清单、别名映射 | share 只放脱敏模板，真实资产在项目侧 |
| Provision | Python/uv/JDK/Nginx/Node/MySQL/Redis/ZooKeeper/Kafka 安装规划 | 先 plan/check，apply 必须显式确认 |
| Deploy | 上传、渲染配置、切换版本、重启、回滚 | 项目脚本执行真实业务动作，share 只管编排契约 |
| Config Profiles | small/large/fixed 多档参数 | 只提供变量值，不替代服务配置模板 |
| Service Configs | Nginx/Redis/MySQL/JDK/JVM/systemd 配置模板 | 模板脱敏，凭据和域名在项目侧填 |
| Online Detect | 进程、端口、HTTP、systemd、日志、磁盘内存；本机开发端口释放 | 默认只读；`local free-port` 仅杀本机占用进程 |
| Log Triage | Nginx/服务日志源、异常 pattern、journalctl、关联检查 | 默认只读，不直接改配置 |
| Data Query | Redis/MySQL 等只读查询 | 默认 allowlist，禁止写命令 |
| DB Verify | 表结构、字段、索引、样例数据与本地代码核验 | 默认只读，限制行数和脱敏字段 |
| Backup/Rollback | 变更前备份、版本回退 | destructive 动作单独确认 |
| Audit | 权限、端口暴露、证书、服务状态 | 只读巡检和报告 |

## 典型场景

| 场景 | 输入 | skill 行为 | 模板/入口 |
|------|------|------------|-----------|
| 连接 `xxx` 并查看有哪些服务 | `xxx` 含 IP、端口、账号、RSA 状态、服务名 | 解析 target/alias/host/service/defaultChecks，输出连接和检查计划 | `connect plan` + `templates/connect/` |
| 在 `xxx` 安装基础服务 | 指定或默认 nginx/redis/mysql/zookeeper/kafka/jdk17 等 | 读取模块模板，按在线/离线模式输出安装命令、离线包清单、端口和健康检查 | `provision plan` + `templates/provision/` |
| 排查 `xxx` 上 Nginx 异常日志 | 服务名、时间窗口、可读日志路径 | 定位 access/error/journalctl 来源，匹配异常 pattern，关联端口、`nginx -t`、systemd 状态 | `logs plan` + `templates/logs/` |
| 查询 DB 结构/数据并核验本地代码 | 数据库连接引用、本地代码目录、目标表/SQL | 只读生成 schema/data 检查计划，限制 SQL 前缀、行数和脱敏列 | `db plan` + `templates/db/` |
| 排查本机开发端口占用 / WinError 10013 | 端口号、可选 cmdline 匹配 | 结束存活监听进程并 bind 探测；忽略 Windows 幽灵 LISTEN | `local free-port` + `scripts/free-local-port.ps1|.sh` |

## 部署能力

部署不是单一脚本，必须拆为：

1. `pre-check`：确认主机、磁盘、端口、依赖、当前版本。
2. `render-config`：按 profile 渲染配置。
3. `upload`：上传 artifact 到 release 目录。
4. `switch`：更新 symlink 或 systemd env。
5. `restart`：重启指定服务。
6. `post-check`：HTTP/端口/日志/业务健康检查。
7. `rollback`：回到上一个 release。

部署模板必须声明 profile：

| profile | 适用 | 示例 |
|---------|------|------|
| `small` | 低规格单机、内存小、并发低 | 小 worker、低连接数、小 buffer |
| `large` | 高规格、并发高、独立数据盘 | 高连接数、大 buffer、更多连接池 |
| `fixed` | 服务配置不随机器规格变化 | JDK 路径、systemd 单元结构、固定端口 |

## 配置模板关系

`profiles` 只给档位参数，不能代替服务配置。服务启动必须同时具备：

| 服务 | 模板 | 说明 |
|------|------|------|
| Nginx | `templates/provision/modules/nginx/TEMPLATE_nginx.conf`、`TEMPLATE_site.reverse-proxy.conf` | HTTP/域名/反代/静态资源/TLS 引用在这里表达 |
| Redis | `templates/provision/modules/redis/TEMPLATE_redis.conf` | 默认本机或 VPC 访问，不走 Nginx 反向代理，不默认配置域名 |
| MySQL | `templates/provision/modules/mysql/TEMPLATE_mysqld.cnf` | 默认本机或 VPC 访问，不走 Nginx 反向代理，不默认配置域名 |
| JDK | `templates/provision/modules/jdk/TEMPLATE_java.sh` | 只配置 JDK 环境，不代表某个应用启动参数 |
| Java App | `templates/deploy/TEMPLATE_java-app.jvm.options`、`TEMPLATE_systemd.service` | JVM 堆、GC、GC log、OOM 行为、systemd 启动在部署层表达 |

## 数据查询能力

查询能力默认只读：

| 类型 | 允许 | 禁止 |
|------|------|------|
| Redis | `GET`、`HGETALL`、`TTL`、`TYPE`、`INFO`、`DBSIZE`、`SCAN` | `SET`、`DEL`、`FLUSH*`、`CONFIG SET`、`EVAL` |
| MySQL | `SELECT`、`SHOW`、`EXPLAIN`、只读 `information_schema` | `INSERT`、`UPDATE`、`DELETE`、`DDL`、权限变更 |

项目侧可以扩展 allowlist，但不能把写命令设为默认。

## 模板分层

| 模板目录 | 内容 |
|----------|------|
| `templates/provision/` | 环境安装和服务目标状态 |
| `templates/connect/` | 目标资产、IP/名称映射、服务清单 |
| `templates/deploy/` | 部署流程、artifact、profile 选择 |
| `templates/detect/` | 在线检测、巡检、健康检查 |
| `templates/logs/` | 日志排查源、pattern、关联检查 |
| `templates/query/` | Redis/MySQL 等只读查询策略 |
| `templates/db/` | 数据库结构和数据核验策略 |
| `templates/profiles/` | small/large/fixed 通用档位 |

## 项目落地原则

项目侧配置是通用 skill 的实例化，不是第二套实现：

- `connect/` 描述目标和服务清单。
- `provision/` 描述这台机器应该具备哪些基础环境；没有本机服务就不要启用。
- `deploy/` 描述当前服务如何发布、重启、回滚。
- `detect/` 描述日常只读健康检查。
- `logs/` 描述故障排查时读取哪些日志和 pattern。
- `query/` / `db/` 只做只读数据验证，凭据只引用项目私有文件。
