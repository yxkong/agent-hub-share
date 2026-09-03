# trigger / eval

## should-trigger

- 「把 bi/wzsy 的 bootstrap 抽到 hub」
- 「新 ECS 按统一方式接 SSH 别名 + 公钥」
- 「ops-bootstrap 这个名字是不是比 ecs-ops-bootstrap 更合适」
- 「ops-check 通用脚本放哪」
- 「bootstrap.ps1 / setup_ssh_key 为什么重复两份」
- 「做成跨平台，底层用 Python，ps1/sh 只做薄封装」
- 「ECS/MySQL/Nginx/JDK/部署的运维能力怎么抽通用层」
- 「references 和 scripts 要按功能区分」
- 「后续要一键安装 uv、Python、JDK、Nginx、Node、MySQL、Redis，需要配置模板」
- 「部署有小规格/大规格/固定配置模板」
- 「需要在线检测」
- 「需要 Redis 查询 / MySQL 查询」
- 「我要连接 xxx，看这里有哪些服务，xxx 包含 IP、端口、账号、密码/RSA」
- 「连接 xxx，然后安装 nginx/redis/mysql/zookeeper/kafka/jdk17」
- 「帮我排查 xxx 上 nginx 的异常日志」
- 「帮我查询 xxx 数据库表结构并和本地代码核验」
- 「帮我查询 xxx 数据库中的数据，确认开发写入」
- 「参考 GitHub 上开源运维工具，把这个 ops 技能做完整」
- 「小程序校验文件下发 / 微信校验 txt 放到业务域名」

## should-not-trigger
- 只改某台机 nginx/mysql 业务配置
- 执行某台机器的安装、重启、删库、证书替换等有状态动作
- 只修改某个项目的 nginx server block、MySQL 用户或 Redis 密码
- 执行 Redis 写命令、MySQL 写命令或清数据
- hub 挂载 / register-project（→ `agent-hub-bootstrap`）
- 写业务 credentials 内容本身

## held-out 样例（创建时）

| 输入 | 期望 |
|------|------|
| 为第三台机建 ops 目录 | 复制 templates + 调 L2，不复制 bi 整份 bootstrap 实现 |
| 只查 bi 服务是否在线 | 调 `ops-check.ps1 -OpsRoot bi` |
| 规划通用环境安装 | 先补 `references/roadmap.md` 与 `templates/provision/`，再实现 `plan/check` |
| 为某项目安装 MySQL 并创建业务库 | 项目 `scripts/` / `provision/`，share 只提供模块契约和 dry-run 编排 |
| 规划部署流程 | 用 `deploy plan` 和 `templates/deploy/`，真实上传/重启留到项目脚本 |
| 查 Redis key 状态 | 用 `query plan` 校验只读 allowlist；Redis 执行仍由项目侧完成 |
| 连接某台服务器 | 用 `connect plan` 解析别名、主机、服务清单；凭据引用留在项目侧 |
| 排查 nginx 502 | 用 `logs plan` 定义 error/access/journalctl 和关联检查；真实读取日志需明确目标 |
| 小程序校验 txt 下发 | 先 `deploy-mp-verify.ps1 -DryRun`，确认 root 与节点后再 apply；不 reload Nginx |
| 核验订单表结构 | 先用 `db plan` 定义 schema/data 检查，再以私有凭据执行 `db run --confirm-readonly`；SQL 保持只读、限行、脱敏并 rollback |
| 查询另一个项目的 MySQL 样例数据 | 使用其 `ops.config.json` 执行 `query plan`，确认后 `query run --confirm-readonly`；不得新建项目专用连库脚本 |
