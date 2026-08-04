# 安全运维操作手册（Safe Ops Manual）

> 本手册是 ops-bootstrap 技能的强制操作规范。所有使用本技能进行服务器运维操作的人员和 Agent 必须遵守。
> 核心原则：**先备份再修改，先确认再删除，除非明确要求不能删除。**

---

## 一、操作分级

| 级别 | 说明 | 审批要求 | 示例 |
|------|------|----------|------|
| L0 只读 | 不改变任何状态的探测 | 无需审批 | `df -h`、`systemctl status`、`cat`、`ls`、`grep` |
| L1 可逆变更 | 可回滚的配置修改 | 备份后执行 | 修改 Nginx conf、调整 retention、改 systemd unit |
| L2 不可逆操作 | 删除文件、删除数据、重启服务 | **人工确认 + 备份** | `rm`、`journalctl --vacuum`、`systemctl restart` |
| L3 高危操作 | 影响数据完整性或服务可用性 | **人工明确指令 + 双重确认** | 删库、删 PVC、格式化磁盘、`dd`、`mkfs` |

---

## 二、备份规则（修改前必须备份）

### 2.1 配置文件修改

**规则**：修改任何配置文件前，必须先备份原文件。

```bash
# 标准备份方式（带时间戳）
cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak.$(date +%Y%m%d%H%M%S)

# 项目内配置修改
cp conf.d/site.conf conf.d/site.conf.bak.$(date +%Y%m%d%H%M%S)
```

**备份命名规范**：`<原文件名>.bak.<YYYYMMDDHHMMSS>`

**保留策略**：备份文件保留至少 7 天，重要配置保留 30 天。

### 2.2 批量配置修改

修改多个文件时，先打包备份整个目录：

```bash
# 打包备份 conf.d 目录
tar -czf /tmp/nginx-conf.d.bak.$(date +%Y%m%d%H%M%S).tar.gz -C /etc/nginx conf.d
```

### 2.3 数据库变更

任何 DDL 操作前必须备份相关表：

```bash
# MySQL 表备份
mysqldump -u root -p <database> <table> > /tmp/<table>.bak.$(date +%Y%m%d%H%M%S).sql
```

### 2.4 systemd unit 修改

```bash
cp /etc/systemd/system/kafka@.service /etc/systemd/system/kafka@.service.bak.$(date +%Y%m%d%H%M%S)
systemctl daemon-reload
```

---

## 三、删除规则（删除前必须确认）

### 3.1 铁律

1. **除非用户明确要求"删除"，否则不执行任何删除操作。**
2. **删除前必须先备份**（即使确认要删）。
3. **删除前必须向用户确认**，列出将要删除的内容和影响。
4. **禁止使用 `rm -rf /`、`rm -rf /*`、`rm -rf ~`** 等通配根目录的命令。
5. **禁止使用 `find ... -delete`** 而不先 `find ... -print` 预览。

### 3.2 删除确认流程

```
步骤 1：预览将要删除的内容
  find /path/to/cleanup -type f -name "*.log" -mtime +7 -print

步骤 2：备份（如果内容有价值）
  tar -czf /tmp/cleanup.bak.$(date +%Y%m%d%H%M%S).tar.gz <files...>

步骤 3：向用户展示清单并请求确认
  "将要删除以下 N 个文件，共 XXG，是否确认？"

步骤 4：用户确认后执行删除
  find /path/to/cleanup -type f -name "*.log" -mtime +7 -delete
```

### 3.3 安全删除替代方案

优先使用「移动到临时目录」代替直接删除：

```bash
# 创建临时目录
mkdir -p /tmp/trash/$(date +%Y%m%d)

# 移动而非删除
mv /var/log/old-app.log /tmp/trash/$(date +%Y%m%d)/

# 确认无影响后再清理（至少 24 小时后）
rm -rf /tmp/trash/$(date -d yesterday +%Y%m%d)/
```

### 3.4 Kafka 数据清理

Kafka topic 数据清理**不直接删文件**，通过调整 retention 实现：

```bash
# 先查看当前配置
kafka-configs.sh --bootstrap-server <broker> --describe --topic <topic>

# 调整 retention（可逆操作）
kafka-configs.sh --bootstrap-server <broker> --alter --topic <topic> \
  --add-config retention.ms=259200000

# 等待自动清理后验证
kafka-log-dirs.sh --bootstrap-server <broker> --describe | grep <topic>
```

---

## 四、服务操作规则

### 4.1 重启服务

```bash
# 重启前检查当前状态
systemctl status <service>

# 重启
systemctl restart <service>

# 重启后验证
systemctl status <service>
# 如果是网络服务，验证端口
ss -lntp | grep <port>
```

### 4.2 Kafka 服务特殊注意

`kafka@.service` 为 `Type=oneshot` + `RemainAfterExit=yes`，**不能只看 `systemctl is-active`**：

```bash
# 错误：只看 is-active
systemctl is-active kafka@kafka-logs  # 可能显示 active 但进程已死

# 正确：检查端口 + 进程
ss -lntp | grep 29092
ps aux | grep kafka.Kafka
```

### 4.3 Nginx 操作

**核心原则：以目标机器配置为准，修改前必须先同步。**

```bash
# 修改前必须先从服务器同步到本地缓存
# prod: sync-control (prod -> control hub) + pull-local (hub -> laptop)
# egress: pull (egress -> jump hub) + pull-local (hub -> laptop)
# test: pull-local (test server -> laptop)

# 修改配置后先测试语法
nginx -t

# 平滑重载（不影响连接）
nginx -s reload

# 只有在 reload 失败时才 restart
systemctl restart nginx
```

**同步校验机制**：nginx.ps1 的写操作（push / push-host / deploy-file / sync-up / add-http / add-https）执行前会检查 `conf/.last-sync` 时间戳，超过 30 分钟未同步将被拒绝，强制要求先执行 `sync-control` 或 `pull-local`。

```bash
# 被拒绝时的提示示例：
# push 被拒绝：本地缓存已过期（上次同步于 45 分钟前，超过 30 分钟）。
# Nginx 操作以目标机器配置为准，修改前必须重新同步：
#   .\scripts\nginx.ps1 sync-control   # prod -> control hub
#   .\scripts\nginx.ps1 pull-local     # control hub -> laptop cache
```

---

## 五、Agent 行为约束

### 5.1 必须遵守

1. **任何 L2 级别操作（删除、重启）前，必须向用户列出操作清单并等待确认。**
2. **任何修改操作前，必须先执行备份。**
3. **除非用户明确说"删除"，不得使用 `rm` 命令。**
4. **清理磁盘时，优先建议可逆方案（retention 调整、移动到 trash），而非直接删除。**
5. **执行任何有状态变更前，先运行 `plan` 或 `--dry-run`。**

### 5.2 禁止行为

1. **禁止**在未经确认的情况下执行 `rm -rf`。
2. **禁止**删除数据库、PVC、持久化卷。
3. **禁止**直接删除 Kafka 数据目录中的 `.log` 文件。
4. **禁止**在生产环境执行未经 `nginx -t` 验证的配置重载。
5. **禁止**跳过备份直接修改配置文件。
6. **禁止**使用通配符删除（`rm /path/*`），必须明确指定文件。
7. **禁止**在未执行 `sync-control`/`pull-local` 同步的情况下，执行 Nginx 的 `push`/`deploy-file`/`add-http`/`add-https` 等写操作（脚本会强制校验）。

### 5.3 确认话术模板

当需要执行 L2/L3 操作时，使用以下格式请求确认：

```
⚠️ 待执行操作清单（L2 级别）：

1. 操作：清理 7 天前的 journal 日志
   主机：172.20.1.229 (k8s-worker-01)
   命令：journalctl --vacuum-time=7d
   预计影响：释放约 3G 磁盘空间
   可逆性：不可逆（日志删除后无法恢复）
   风险：低

2. 操作：压缩 wk.log.info 保留期至 3 天
   主机：kafka-logs 集群
   命令：kafka-configs.sh --alter --topic wk.log.info --add-config retention.ms=259200000
   预计影响：3 天前的日志数据将被清理
   可逆性：可逆（可改回原 retention）
   风险：低

是否确认执行？（yes/no）
```

---

## 六、故障排查安全规则

### 6.1 日志排查

- 只读取日志，不修改、不删除日志文件
- 大日志文件用 `tail -n 1000` 或 `journalctl --since` 限制范围
- 不使用 `>` 重定向覆盖日志文件

### 6.2 进程排查

- 只用 `ps`、`top`、`htop` 查看，不随意 `kill`
- `kill` 进程前必须确认进程归属和影响
- 优先 `kill -TERM`（优雅终止），避免 `kill -9`

### 6.3 磁盘排查

- 只用 `df`、`du`、`ls` 查看
- 清理操作必须走第三章的删除确认流程
- 排查时避免在 NFS 挂载点上执行 `find`（可能卡住），用 `timeout` 包裹

```bash
# 安全的磁盘排查
timeout 30 du -sh /data/* 2>/dev/null | sort -rh | head -20
```

---

## 七、凭证安全规则

1. **密码不进项目目录**：项目目录内不存放任何明文密码。
2. **密钥优先**：所有操作通过 SSH 密钥认证完成。拿到密钥即可直连跳板机，跳板机免密操作所有内网节点。
3. **项目内只留映射**：项目内 `account.md` 只记录 IP、SSH 别名和密钥路径，不记密码。
4. **`.gitignore`**：确保 `account.md`、`credentials.md`、`*.key`、`*.pem` 在 `.gitignore` 中。
5. **禁止**在脚本中硬编码密码。

---

## 八、操作记录

所有 L2 级别以上的操作，必须记录到项目的 `incidents/` 目录：

1. 每次操作创建一个 `.md` 文件，命名格式：`YYYYMMDD-<brief-description>.md`
2. 记录内容：时间、主机、操作内容、执行人、结果
3. 更新 `incidents/index.json` 索引

---

## 九、快速参考

### 安全操作检查清单

- [ ] 这是只读操作吗？（L0 -> 直接执行）
- [ ] 如果是修改，已备份原文件吗？（L1 -> 备份后执行）
- [ ] 如果是删除，用户明确要求了吗？（L2 -> 确认 + 备份）
- [ ] 如果是高危操作，有回滚方案吗？（L3 -> 双重确认 + 回滚方案）
- [ ] 操作记录已写入 incidents/ 吗？

### 常用安全命令速查

```bash
# 备份配置
cp <file> <file>.bak.$(date +%Y%m%d%H%M%S)

# 安全查看大日志
tail -n 1000 <logfile>
journalctl --since "1 hour ago" | tail -100

# 安全排查磁盘
timeout 30 du -sh /data/* 2>/dev/null | sort -rh | head -20

# Nginx 配置验证
nginx -t

# Kafka 保留期调整（可逆）
kafka-configs.sh --bootstrap-server <broker> --alter --topic <topic> --add-config retention.ms=<ms>

# journal 清理
journalctl --vacuum-time=7d
journalctl --vacuum-size=1G
```
