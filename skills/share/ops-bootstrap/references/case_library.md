# Ops 排查案例库

> 每个案例包含：**触发场景** → **排查步骤** → **根因** → **解决方案** → **预防措施**。
> 案例必须可公开复用：只写匿名主机、示例 IP、示例路径和脱敏命令，不写真实服务器、真实域名、真实账号、真实密钥名或业务私有表。

---

## CASE-001: 单机数据任务周期性 OOM 导致服务不可用

**日期**: 2026-07-16
**影响**: `<ops-host>`（示例内网：`10.0.0.10`；示例公网：`203.0.113.10`）
**服务**: 数据分析服务、调度任务、本地计算作业

### 触发场景

用户反馈服务器周期性不可用：SSH 连接失败，Web 服务、任务调度或后台进程异常退出。

### 排查步骤

```bash
# 1. 检查服务器是否存活
ssh <ops-host> uptime

# 2. 全局健康检查
powershell -File ./ops-check.ps1

# 3. 查看内存使用
ssh <ops-host> free -h

# 4. 查看 OOM 日志
ssh <ops-host> "dmesg -T | grep -i 'oom\\|kill' | tail -30"
ssh <ops-host> "journalctl -k --since '1 hour ago' | grep -i oom"

# 5. 查看进程内存 Top
ssh <ops-host> "ps aux --sort=-%mem | head -20"

# 6. 检查是否有 Swap
ssh <ops-host> swapon --show

# 7. 检查上次重启时间
ssh <ops-host> "uptime -s || who -b"
```

### 根因分析

| 层次 | 问题 |
|------|------|
| 直接原因 | 本地计算进程和脚本驱动进程同时占用大量内存，峰值超过机器规格 |
| 脚本问题 | 宽表全量读取到 driver 侧，再转成本地 DataFrame，内存被放大 |
| 配置问题 | 小规格服务器无 Swap 或 Swap 过小，没有突发缓冲 |
| 误判原因 | 云监控看到的是 OOM 杀进程后的低谷，不代表峰值没有超限 |

### 解决方案

#### 第一步：配置 Swap

```bash
ssh <ops-host>
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile swap swap defaults 0 0' | sudo tee -a /etc/fstab
```

#### 第二步：优化数据拉取脚本

高内存模式：

```python
df = engine.sql("select * from <wide_table>").to_pandas()
```

低内存模式：

```python
sample_cols = engine.read_table("<wide_table>").columns
use_features = [item for item in features if item in sample_cols]
select_cols = ", ".join(["id", "observe_date"] + use_features)
df = engine.sql(f"select {select_cols} from <wide_table>").to_pandas()
```

结果影响：只读取下游模型或报表实际使用的列，不改变计算口径。

#### 第三步：调整计算参数

规格与推荐 driver memory 对照：

```text
2c4g  -> --driver-memory 1g
2c8g  -> --driver-memory 4g
4c16g -> --driver-memory 8g
```

#### 第四步：升级服务器规格（必要时）

升级后验证：

```bash
ssh <ops-host> "free -h && uptime"
powershell -File ./ops-check.ps1
```

### 性能对比

| 指标 | 优化前 | 优化后 |
|------|--------|--------|
| 数据传输量 | 多张宽表所有列 | 仅实际使用列 |
| Driver 内存峰值 | 高 | 明显降低 |
| OOM 风险 | 高 | 低 |
| 结果准确性 | 基准 | 口径不变 |

### 预防措施

1. 小规格服务器的 Swap 至少覆盖一次短时峰值。
2. 数据拉取脚本禁用 `select *`，先查 schema 再精确 select。
3. 配置内存、磁盘、进程存活告警。
4. OOM 快速诊断命令：

```bash
ssh <ops-host> "dmesg -T | grep -i oom | tail -20"
ssh <ops-host> "uptime -s"
```

---

## CASE-002: SSH 别名无法解析

**日期**: 2026-07-16
**影响**: 本地工作站

### 触发场景

运行 `ssh <ops-host>` 或 `ops-check.ps1` 报错：

```text
Could not resolve hostname <ops-host>: Name or service not known
```

### 排查步骤

```bash
# 查 SSH config 是否有对应 Host 块
grep -A5 "Host <ops-host>" ~/.ssh/config

# 检查 hub 环境变量
powershell -Command "Get-ChildItem Env:AGENTS_HUB_ROOT"

# 绕开别名直接测试；使用示例 IP 与示例 key，真实值应来自项目私有配置
ssh -i ~/.ssh/<project_private_key> <user>@203.0.113.10 hostname
```

### 根因

`~/.ssh/config` 中无 `Host <ops-host>` 块，bootstrap 未执行或执行失败。

### 解决方案

```bash
# 方案1：运行 bootstrap（推荐）
powershell -File ./bootstrap-ssh.ps1

# 方案2：手动写 SSH config；真实主机、账号、key 只来自项目私有配置
Host <ops-host>
  HostName 203.0.113.10
  User <user>
  IdentityFile ~/.ssh/<project_private_key>
  ServerAliveInterval 60
```

---

## 如何添加新案例

1. 在文末添加 `## CASE-XXX: 标题` 段落。
2. 填写：日期、影响范围、触发场景、排查命令、根因、解决方案、预防措施。
3. 只使用 `<ops-host>`、`<user>`、`203.0.113.0/24`、`10.0.0.0/8` 这类示例值。
4. 在 `SKILL.md` 的 30 秒决策区按需加入新触发关键词。
5. 若涉及新模板需求，更新 `templates/` 对应目录。

---

## CASE-003: Kafka broker 下线后旧 partition 数据撑满数据盘

**日期**: 2026-07-30
**影响**: `<ops-host>`（示例内网：`10.0.0.20`）
**服务**: Kafka / Kafka Connect（K8s worker 节点）

### 触发场景

监控告警磁盘使用率 100%，应用写入失败。用户在 Kafka 管理后台 recreate 了对应 topic，但磁盘使用率仍为 100%，空间未释放。

### 排查步骤

使用 `scripts/helpers/disk_triage.sh` 进行只读排查（通过跳板机转发到目标机）：

```bash
# 1. 从跳板机登目标机查看磁盘总览
ssh <bastion-host> "ssh <internal-ip> 'df -h'"

# 2. 定位满的挂载点和顶层目录
ssh <bastion-host> "ssh <internal-ip> 'du -sh /data/* 2>/dev/null | sort -rh | head -20'"

# 3. 用通用脚本做结构化排查（推荐）
scp scripts/helpers/disk_triage.sh <bastion-host>:/tmp/
ssh <bastion-host> "scp /tmp/disk_triage.sh <internal-ip>:/tmp/ && ssh <internal-ip> 'bash /tmp/disk_triage.sh /data'"
```

关键发现：
- `/data` 挂载点 100%（295G 用 281G），系统盘正常。
- `/data/kafka-logs-data/` 占 236G，其中 `wk.log.info-0`（114G）和 `wk.log.info-2`（113G）两个 partition 目录最大。
- 每个 partition 目录有 113 个 1GB 的 `.log` segment 文件，最新修改停留在前一天 21:35。
- `meta.properties` 显示 `broker.id=204`，但 `ps aux | grep kafka.Kafka` 无 broker 进程。
- `/proc/*/fd` 检查：无进程持有这些文件句柄。
- `.deleted` 后缀文件：0 个，说明 Kafka log cleaner 未在处理。

### 根因分析

| 层次 | 问题 |
|------|------|
| 直接原因 | 旧 broker 下线后，`kafka-logs-data` 目录遗留 236G 数据未被清理 |
| 为什么 retention 没生效 | `retention.ms`/`retention.bytes` 由 broker 进程的 log cleaner 线程执行；broker 已不在，无人清理 |
| 为什么 recreate 无效 | recreate 只在活跃集群元数据层面重建 topic 定义，不会删除已下线 broker 磁盘上的旧 partition 目录 |
| 为什么没有 .deleted 文件 | `.deleted` 是 broker log cleaner 删除 segment 时的中间态；无 broker 进程则无此机制 |
| 深层原因 | 集群缩容/迁移后未清理下线节点的本地数据盘 |

### 解决方案

#### 第一步：确认安全（只读检查）

```bash
# 确认无 Kafka broker 进程
ssh <ops-host> "ps aux | grep 'kafka.Kafka' | grep -v grep"
# 确认无进程持有目标文件句柄
ssh <ops-host> "for pid in \$(ls /proc | grep -E '^[0-9]+\$'); do ls -l /proc/\$pid/fd 2>/dev/null | grep 'wk.log.info' && echo PID=\$pid; done"
# 确认目录是旧 partition（修改时间停留在过去，无新写入）
ssh <ops-host> "find /data/kafka-logs-data/wk.log.info-0 -name '*.log' -printf '%TY-%Tm-%Td %TH:%TM\n' | sort | tail -1"
```

#### 第二步：删除孤儿 partition 目录

```bash
ssh <ops-host> "rm -rf /data/kafka-logs-data/wk.log.info-0"
ssh <ops-host> "rm -rf /data/kafka-logs-data/wk.log.info-2"
ssh <ops-host> "df -h /data"
```

> 注意：`rm -rf` 前必须确认（1）无 broker 进程，（2）无进程持有文件句柄，（3）目录确实无新写入。
> Kafka Connect 的 `kafka-connect-data` 目录不要直接删，它是活跃 Connect 进程的 internal topic，需通过 Connect REST API 处理。

### 性能对比

| 指标 | 清理前 | 清理后 |
|------|--------|--------|
| 磁盘使用率 | 100%（281G/295G） | 17%（48G/295G） |
| 可用空间 | 0 | 233G |
| kafka-logs-data | 236G | 2.3G |

### 预防措施

1. **集群缩容 SOP**：下线 broker 前必须 `du -sh` 检查数据盘，确认数据已迁移后再清理本地 `kafka-logs-data`。
2. **磁盘告警**：`diskUsageWarnPercent` 设为 80%（detect 模板已支持），提前发现。
3. **定期巡检**：对下线节点跑 `disk_triage.sh` 确认无残留大目录。
4. **区分 broker vs connect**：`kafka-logs-data` 是 broker 数据目录，`kafka-connect-data` 是 Connect 内部存储；前者随 broker 下线可清，后者是活跃数据不可直接删。
5. **通用排查脚本**：`scripts/helpers/disk_triage.sh` 可复用于任何磁盘满场景，自动探测高使用率挂载点并输出顶层目录、大文件、旧文件、FD 占用。

---

## CASE-004: unattended-upgrades 自动升级导致 Nginx 崩溃

**日期**: 2026-07-30
**影响**: `<ops-host>`（示例内网：`10.0.0.30`），两台 Nginx egress 节点
**服务**: Nginx

### 触发场景

Nginx 突然无法访问，`systemctl status nginx` 显示 failed。无人工操作，无配置变更。重启后暂时恢复，但可能再次崩溃。

### 排查步骤

```bash
# 1. 使用通用脚本做只读诊断
bash scripts/helpers/nginx_crash_triage.sh --since "2 days ago"

# 2. 手动检查关键日志
ssh <ops-host> "systemctl status nginx --no-pager -l"
ssh <ops-host> "grep -i 'nginx\|libc\|libssl' /var/log/unattended-upgrades/unattended-upgrades.log | tail -30"
ssh <ops-host> "grep -E ' install | upgrade ' /var/log/dpkg.log | grep -iE 'nginx|libc6|libssl' | tail -20"
ssh <ops-host> "journalctl -u nginx --no-pager --since '2 days ago' | tail -40"
```

### 根因分析

| 层次 | 问题 |
|------|------|
| 直接原因 | `apt-daily-upgrade.service` 自动升级了 nginx 或依赖库（libc/openssl），`needrestart` 重启 nginx 时配置测试失败 |
| 为什么重启失败 | 升级后的 nginx 二进制与旧配置不兼容，或 DNS 解析失败导致配置测试不通过 |
| 为什么自动升级 | 默认安装的 Ubuntu 启用了 `unattended-upgrades`，`Unattended-Upgrade::Automatic-Reboot` 未配置但 needrestart 仍会重启服务 |
| 深层原因 | 缺乏对自动升级的监控和控制，生产环境应禁用或限制自动升级范围 |

### 解决方案

#### 第一步：恢复服务

```bash
ssh <ops-host> "nginx -t && systemctl restart nginx"
```

如果配置测试失败，先修复配置再重启。

#### 第二步：禁用自动升级（推荐）

```bash
ssh <ops-host>
# 完全禁用
sudo apt-get remove -y unattended-upgrades
# 或仅禁用 nginx 相关的自动升级
echo 'Unattended-Upgrade::Package-Blacklist {"nginx";"nginx-common";"libnginx-.*";};' \
  | sudo tee /etc/apt/apt.conf.d/51unattended-upgrades-nginx
```

#### 第三步：验证

```bash
ssh <ops-host> "systemctl is-active apt-daily-upgrade.timer"
ssh <ops-host> "nginx -v; systemctl is-active nginx"
```

### 预防措施

1. 使用 `scripts/helpers/nginx_crash_triage.sh` 定期巡检，检查 `apt-daily-upgrade` 状态和 nginx 版本是否变化。
2. 生产环境禁止 `unattended-upgrades`，或至少 blacklist nginx 及相关依赖。
3. 在 `ops-check.remote.sh` 中增加 `apt-daily-upgrade` 状态检查和 `nginx -v` 版本监控。

---

## CASE-005: 公网暴露服务无认证导致挖矿入侵

**日期**: 2026-07-29
**影响**: `<ops-host>`（示例公网：`203.0.113.50`）
**服务**: kafka-ui (Docker)、WireGuard VPN

### 触发场景

CPU 使用率 200%，WireGuard VPN 丢包严重（39 万包），但用户未主动运行任何任务。`top` 显示 `kworker_u8_0` 进程占用大量 CPU。

### 排查步骤

```bash
# 1. 使用通用安全审计脚本
bash scripts/helpers/security_audit.sh

# 2. 手动检查
ssh <ops-host> "ps aux --sort=-%cpu | head -20"
ssh <ops-host> "ss -lntp | grep '0.0.0.0'"
ssh <ops-host> "find /proc/*/exe -type l ! -exec test -e {} \; -print"  # 进程可执行文件已删除
ssh <ops-host> "ls -la /tmp/.cache/ /tmp/kworker_u8_*"
ssh <ops-host> "docker ps --format '{{.Names}} {{.Image}} {{.Ports}}'"
```

关键发现：
- `kworker_u8_0` 进程伪装系统名，实际是 XMRig 挖矿程序
- `/tmp/.cache/` 和 `/tmp/kworker_u8_*/` 包含 xmrig 二进制和配置文件
- kafka-ui v0.7.2 暴露在 `0.0.0.0:18080`，无认证
- 挖矿进程以 `_apt` 用户运行，提权路径尚未确认

### 根因分析

| 层次 | 问题 |
|------|------|
| 直接原因 | kafka-ui v0.7.2 存在 RCE 漏洞，暴露在公网且无认证 |
| 入侵路径 | 公网 → kafka-ui 18080 → RCE 漏洞 → 以 `_apt` 用户执行 → 释放 xmrig |
| 为什么没发现 | 无安全审计脚本，无端口暴露监控，kafka-ui 无认证机制 |
| 深层原因 | 测试环境缺乏安全基线，服务默认暴露所有接口 |

### 解决方案

#### 第一步：清理恶意进程和文件

```bash
ssh <ops-host>
# 杀进程
pkill -f xmrig; pkill -f kworker_u8
# 清文件
rm -rf /tmp/.cache/ /tmp/kworker_u8_*
# 清理 Docker 容器内残留
docker exec <container-id> rm -rf /tmp/.cache/ /tmp/kworker_u8_*
```

#### 第二步：加固防火墙

```bash
ssh <ops-host>
# 限制 kafka-ui 18080 仅本地 + VPN 子网
iptables -I INPUT -p tcp --dport 18080 -s 127.0.0.1 -j ACCEPT
iptables -I INPUT -p tcp --dport 18080 -s 10.8.0.0/24 -j ACCEPT
iptables -A INPUT -p tcp --dport 18080 -j DROP
# 持久化
iptables-save > /etc/iptables.rules
```

#### 第三步：加固 Docker 容器

```bash
ssh <ops-host>
# 停止 kafka-ui 容器
docker stop kafka-ui
# 修改 restart policy 为 no（不再自动拉起）
docker update --restart=no kafka-ui
```

### 预防措施

1. 使用 `scripts/helpers/security_audit.sh` 定期巡检，检查所有 `0.0.0.0` 监听端口。
2. 所有公网暴露服务必须有认证（kafka-ui、Grafana、Jenkins 等）。
3. kafka-ui 升级到最新版本（v0.7.2 存在已知漏洞）。
4. 在 `ops-check.remote.sh` 中增加端口监听检查、CPU 使用率监控、可疑进程扫描。

---

## CASE-006: OCSP Stapling 错误刷屏

**日期**: 2026-07-30
**影响**: `<ops-host>`（示例内网：`10.0.0.40`），3 台生产 Nginx
**服务**: Nginx

### 触发场景

Nginx 错误日志中 OCSP 相关错误每天 700+ 条，污染 error.log 且增加 SSL 握手延迟。

### 排查步骤

```bash
# 1. 使用通用脚本
bash scripts/helpers/nginx_cert_check.sh

# 2. 手动检查
ssh <ops-host> "grep -c OCSP /var/log/nginx/error.log"
ssh <ops-host> "nginx -T 2>/dev/null | grep -A2 'ssl_stapling'"
ssh <ops-host> "openssl x509 -in /etc/nginx/ssl/server.crt -noout -ocsp_uri"
ssh <ops-host> "curl -s --connect-timeout 5 <ocsp-url> -o /dev/null -w '%{http_code}'"
```

关键发现：
- `ssl_stapling on` 配置在所有 3 台 Nginx 上启用
- 证书的 OCSP responder URL 指向外部 CA（如 `http://ocsp.digicert.com`）
- 生产机在内网，无法访问外网 CA 的 OCSP responder
- 每台每天产生 ~700 条 OCSP 错误日志

### 根因分析

| 层次 | 问题 |
|------|------|
| 直接原因 | `ssl_stapling on` 启用了 OCSP 装订，但服务器无法访问外网 OCSP responder |
| 为什么无影响 | OCSP 装订失败不影响 SSL 握手（Nginx 会退回到不装订模式），但会产生大量错误日志 |
| 为什么被启用 | 配置模板默认启用了 `ssl_stapling on`，未考虑内网环境 |
| 深层原因 | 缺乏对 SSL 配置的环境差异化管理 |

### 解决方案

#### 第一步：关闭 OCSP 装订

```bash
ssh <ops-host>
# 在 nginx.conf 的 http 块中
sed -i 's/ssl_stapling on/ssl_stapling off/' /etc/nginx/nginx.conf
nginx -t && systemctl reload nginx
```

#### 第二步：验证

```bash
ssh <ops-host> "grep -c OCSP /var/log/nginx/error.log"
ssh <ops-host> "nginx -T 2>/dev/null | grep ssl_stapling"
```

### 预防措施

1. 使用 `scripts/helpers/nginx_cert_check.sh` 定期检查 OCSP 错误计数和证书有效期。
2. 内网环境默认关闭 `ssl_stapling`，仅在能访问外网 CA 的环境启用。
3. 在 `detect` 模板的 `logs` 段中增加 `OCSP` 监控 pattern。

---

## CASE-007: Nginx 配置漂移

**日期**: 2026-07-21
**影响**: `<ops-host>`（3 台生产 Nginx 节点：`10.0.0.41/42/43`）
**服务**: Nginx

### 触发场景

多台 Nginx 节点配置不一致，部分域名在某台机器上行为异常。`diff` 发现相同文件在三台机器上内容不同。

### 排查步骤

```bash
# 1. 使用通用脚本
bash scripts/helpers/nginx_drift_check.sh <host1> <host2> <host3>

# 2. 手动比较
ssh <host1> "md5sum /etc/nginx/nginx.conf /etc/nginx/conf.d/*.conf | sort" > /tmp/h1.txt
ssh <host2> "md5sum /etc/nginx/nginx.conf /etc/nginx/conf.d/*.conf | sort" > /tmp/h2.txt
ssh <host3> "md5sum /etc/nginx/nginx.conf /etc/nginx/conf.d/*.conf | sort" > /tmp/h3.txt
diff /tmp/h1.txt /tmp/h2.txt
diff /tmp/h1.txt /tmp/h3.txt
```

关键发现：
- 3 个文件内容不一致（`app-api.haitongyun.cc.conf`、`upstreams-namespace.conf`、`manageplus.haitongyun.cc.conf`）
- 差异主要是空白字符（不同编辑器导致），但 `upstreams-namespace.conf` 有实质性差异

### 根因分析

| 层次 | 问题 |
|------|------|
| 直接原因 | 多人直接在生产机上编辑 Nginx 配置，未同步到其他节点 |
| 为什么不一致 | 缺乏统一的配置管理入口和中控同步机制 |
| 为什么没及时发现 | 无定期检查配置漂移的脚本或告警 |
| 深层原因 | 运维流程缺失：应在中控机编辑，统一 push 到所有节点 |

### 解决方案

#### 第一步：建立中控镜像模式

```bash
# 在中控机上
ssh <control-host>
mkdir -p /root/nginx-mirror/active /root/nginx-mirror/hosts

# 从生产机拉取当前配置到中控
rsync -av <host1>:/etc/nginx/ /root/nginx-mirror/hosts/<host1>/
rsync -av <host2>:/etc/nginx/ /root/nginx-mirror/hosts/<host2>/
rsync -av <host3>:/etc/nginx/ /root/nginx-mirror/hosts/<host3>/

# 选择权威机作为 active 来源
rsync -av /root/nginx-mirror/hosts/<canonical-host>/ /root/nginx-mirror/active/
```

#### 第二步：对齐配置

```bash
# 以 canonical 节点为准，diff 其他节点
diff -r /root/nginx-mirror/hosts/<host1>/ /root/nginx-mirror/hosts/<host2>/ | grep -v "whitespace\|blank\|Only in"
# 修复实质性差异后，push 到所有节点
rsync -av --dry-run /root/nginx-mirror/active/ <host1>:/etc/nginx/
```

#### 第三步：建立同步流程

```bash
# 中控 → 生产（dry-run 先看）
rsync -avn --delete /root/nginx-mirror/active/ <host>:/etc/nginx/
# 确认后执行
rsync -av --delete /root/nginx-mirror/active/ <host>:/etc/nginx/
ssh <host> "nginx -t && systemctl reload nginx"
```

### 预防措施

1. 使用 `scripts/helpers/nginx_drift_check.sh` 定期检查所有节点配置一致性。
2. 建立中控镜像模式：所有变更在中控机编辑，统一 push 到所有节点。
3. 多人协作约定：Git 对齐人，中控对齐机器；禁改生产 `/etc/nginx`。
4. push 必须带 `--dry-run` 或 `-Force` 标志，防止误操作。
5. 在 `ops-check.remote.sh` 中增加配置漂移检查。
