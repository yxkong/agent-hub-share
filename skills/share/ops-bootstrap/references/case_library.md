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

## CASE-009: 消费 Kafka 历史消息按条件过滤后重推

**日期**: 2026-08-10
**影响**: 生产 bussiness 集群（示例内网：`10.0.0.50:19092`）
**服务**: Kafka（consumer + producer，PLAINTEXT 无 ACL）

### 触发场景

用户要求：从 Kafka topic 消费指定时间范围的历史消息，按业务字段（如 `data.customerId`）过滤后，原样重新推送到同一 topic。典型关键词："消费后重新推送""重推""repush""时间范围消费""按条件过滤重推"。

### 标准 SOP（Agent 必须按此流程执行）

```
┌─────────────────────────────────────────────────────────────┐
│ 阶段一：环境只读探查（不写任何代码，先确认事实）              │
│   ├─ 集群地址、端口、认证方式                                │
│   ├─ topic 分区数、时间戳类型（CreateTime / LogAppendTime）   │
│   ├─ 消息 schema（确认过滤字段路径）                          │
│   ├─ 节点 Python 环境 + pip 可用性                            │
│   └─ 时区换算（北京时间 → epoch ms）                          │
├─────────────────────────────────────────────────────────────┤
│ 阶段二：dry-run 全量扫描（--execute 不加，只统计落清单）       │
│   ├─ 输出：命中条数、分区分布、时间范围覆盖度                  │
│   ├─ 清单落盘 JSONL（customerId + partition + offset + ts）  │
│   └─ 用户 review 清单确认无误后进入下一阶段                   │
├─────────────────────────────────────────────────────────────┤
│ 阶段三：小批量验证（--execute --max-push 10 --rate-per-min 10）│
│   ├─ 推送 10 条，验证 producer 写入正常                       │
│   ├─ 从 topic 末尾消费确认这 10 条已落盘                      │
│   └─ 修正脚本缺陷（清单语义、limit 判断顺序等）               │
├─────────────────────────────────────────────────────────────┤
│ 阶段四：完整推送（--execute --rate-per-min N --resume-from）  │
│   ├─ 断点续推跳过已推送的 (partition, offset)                 │
│   ├─ 限速执行，后台运行并监控进度                              │
│   └─ 推送完成后从 topic 末尾按时间窗口验证全量落盘             │
└─────────────────────────────────────────────────────────────┘
```

### 必须向用户确认的问题

| 问题 | 选项 | 默认 |
|---|---|---|
| 是否限速？ | 每分钟 N 条 / 不限速 | **必须限速**（建议 10 条/分钟起步） |
| 是否分批？ | 每批 N 条 / 一次性全量 | 先小批量 10 条验证 |
| 是否断点续推？ | 从已有清单跳过 / 重新开始 | 续推（避免重复） |
| 清单命名规则 | 每次运行独立清单 / 覆盖 | 独立清单（便于核对） |

### 脚本必备能力

| 参数 | 作用 | 必须？ |
|---|---|---|
| `--start/--end` | 北京时间时间范围 | 是 |
| `--customer-file` | 过滤条件集合文件 | 是 |
| `--execute` | 默认 dry-run；带此参数才推送 | 是 |
| `--max-push N` | 最多推送 N 条（小批量验证） | 推荐 |
| `--rate-per-min N` | 限速 N 条/分钟 | **必须** |
| `--resume-from PATH` | 断点续推，跳过已推送的 (partition, offset) | 推荐 |
| `--out-dir` | 清单输出目录 | 是 |

### 关键设计决策

1. **consumer 隔离**：独立 group（带时间戳唯一名），`offsets_for_times` 定位起始 offset，不 commit，不影响线上消费。
2. **时间窗口**：按 `msg.timestamp`（CreateTime 毫秒）过滤，`ts > end_ms` 即 break，无死循环。
3. **重推不变形**：原样推送（保留 value / key），不修改任何字段。
4. **清单即真相**：推送成功后才写清单，dry-run 记录全部命中。清单不可混入"命中但未推送"的预判。

### 验证闭环

```bash
# 1. dry-run 产出清单，人工 review 命中条数与时间范围
# 2. 小批量推送后，从 topic 末尾消费验证
python3 -c "
from kafka import KafkaConsumer, TopicPartition
c = KafkaConsumer(bootstrap_servers='<broker>', consumer_timeout_ms=10000)
for p in sorted(c.partitions_for_topic('<topic>')):
    tp = TopicPartition('<topic>', p)
    c.assign([tp]); c.seek_to_end(tp)
    end = c.position(tp)
    c.seek(tp, max(end-50, 0))
    # 检查新时间戳消息中是否包含推送的 customerId
"
# 3. 完整推送后，扩大回读范围（1,500 条/分区），按推送时间窗口过滤验证
```

### 预防措施

1. 重推脚本必须内置 `--execute` 开关，默认 dry-run；禁止无开关直接推送。
2. 生产推送必须限速（`--rate-per-min`），避免瞬时流量冲击下游。
3. 断点续推以 (partition, offset) 为唯一键，确保清单严格等于真实推送。
4. 脚本上传方式：走跳板中转（`scp local → bastion → target`），避免跨跳板 scp 的 ProxyJump 卡住。
5. 推送完成后，将复盘记录写入 `incidents/kafka/`，按模板归档。

### 相关脚本

- 通用重推脚本模板：`htyc/scripts/kafka_repush_pushauth.py`（本项目可复用）

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

---

## CASE-008: Kafka topicId 漂移导致所有 consumer group 无法协调

**日期**: 2026-08-09
**影响**: `<ops-host>`（ZooKeeper 模式单 broker 或小型开发集群）
**服务**: Kafka 3.x / ZooKeeper

### 触发场景

- producer 发送消息并收到 broker ACK，topic 的 log end offset 持续增长。
- consumer 已启动，但 group 一直无 partition assignment、无消费位点。
- `kafka-consumer-groups.sh --describe` 报 `Timed out waiting for a node assignment`。
- 重启应用或 broker 后问题仍存在。

### 排查步骤

```bash
# 1. 先确认 broker、topic leader 和消息写入正常
kafka-topics.sh --bootstrap-server 127.0.0.1:9092 --describe --topic <business-topic>
kafka-run-class.sh kafka.tools.GetOffsetShell --broker-list 127.0.0.1:9092 --topic <business-topic>

# 2. 验证 group coordinator 是否普遍失效
timeout 30 kafka-consumer-groups.sh --bootstrap-server 127.0.0.1:9092 --describe --group <consumer-group>

# 3. 查 broker state-change/server 日志
grep -E 'Topic ID in memory|does not match the topic ID|__consumer_offsets' <kafka-log-dir>/state-change.log

# 4. ZooKeeper 模式：读取集群元数据中的 topic_id
zookeeper-shell.sh 127.0.0.1:2181 get /brokers/topics/__consumer_offsets

# 5. 只读扫描磁盘 partition.metadata；expected 必须来自上一步的集群元数据
python "$AGENTS_HUB_ROOT/skills/share/ops-bootstrap/scripts/ecs_ops.py" kafka topic-id plan \
  --log-dir /var/lib/kafka/logs \
  --topic __consumer_offsets \
  --expected-topic-id <topic-id-from-zookeeper>
```

关键判据：broker 日志中同一 offsets partition 同时出现两个 topicId，且 `plan` 显示 `driftedCount` 等于受影响 partition 数。仅凭 group 超时不能直接修改磁盘。

### 根因分析

| 层次 | 问题 |
|------|------|
| 直接原因 | `__consumer_offsets-N/partition.metadata` 中的 `topic_id` 与 ZooKeeper topic 元数据不一致 |
| 为什么 producer 正常 | 普通业务 topic 的 leader 和日志未损坏，Produce API 不依赖 consumer group coordinator |
| 为什么所有 group 失效 | broker 拒绝加载全部或部分 `__consumer_offsets` partition，协调器无法分配 group coordinator |
| 为什么重启无效 | 漂移值持久化在磁盘 metadata 中，重启只会重复触发一致性校验 |

### 解决方案

这是 L2 修改操作：必须先评估停机窗口、确认 ZooKeeper 真源、执行 plan，并获得人工授权。不得删除或重建 `__consumer_offsets`。

```bash
# 1. 停止 broker，并确认进程完全退出
systemctl stop kafka
systemctl is-active kafka
pgrep -af 'kafka.Kafka'

# 2. 备份全部目标 partition.metadata 并原子修复漂移项
python "$AGENTS_HUB_ROOT/skills/share/ops-bootstrap/scripts/ecs_ops.py" kafka topic-id apply \
  --log-dir /var/lib/kafka/logs \
  --topic __consumer_offsets \
  --expected-topic-id <topic-id-from-zookeeper> \
  --backup-dir /var/backups/kafka/topic-id \
  --confirm-topic-id-repair

# 3. 用服务管理器启动，等待 broker 元数据稳定
systemctl start kafka
systemctl is-active kafka

# 4. 验证 offsets leader、group assignment、位点和 lag
kafka-topics.sh --bootstrap-server 127.0.0.1:9092 --describe --topic __consumer_offsets
kafka-consumer-groups.sh --bootstrap-server 127.0.0.1:9092 --describe --group <consumer-group>
```

helper 的安全边界：只匹配精确 `<topic>-<数字>` 目录；默认 `plan`；apply 需显式确认；broker 运行时拒绝修改；先生成 `tar.gz` 备份；同目录临时文件写入并 `os.replace`；修复后再次扫描。

### 验证与回滚

1. broker 日志不再出现 topic ID mismatch，所有 offsets partition 成为 leader/follower。
2. consumer group 能稳定入组并拿到 partition，`CURRENT-OFFSET` 前进、`LAG` 收敛。
3. 业务失败消息应按既有 retry/DLT 策略处理，不得通过跳位点掩盖业务异常。
4. 若 broker 无法启动，保持 broker 停止，使用 apply 输出的归档恢复对应 `partition.metadata`，再复核真源和目标目录。

### 预防措施

1. 迁移 Kafka 数据目录时保持 ZooKeeper 快照与 broker 日志目录成对恢复。
2. 恢复后把 group coordinator 检查加入验收，不只验证端口和 Produce API。
3. `wait_port` 只代表 socket 就绪；topic/group 验证需额外等待 controller metadata 与 offsets 加载完成。
4. KRaft 集群的真源和恢复路径不同，本案例及 helper 不可直接套用。

---

## CASE-010: OpenSearch local/NFS 混合数据节点的容量与高 CPU 排查

**日期**: 2026-08-10
**影响**: K8s 内 OpenSearch 日志集群（示例：5 个 data 节点，local PV + NFS CSI 混合）
**服务**: OpenSearch / K8s / NFS CSI / MinIO operator

### 触发场景

日志写入链路出现 `disk usage exceeded flood-stage watermark`、索引被打上 `read_only_allow_delete`，扩容和解锁后，部分承载 NFS CSI 数据卷的 worker 节点 CPU 仍然偏高。现场容易产生两个误判：

1. 把 NFS CSI 上的在线分片误认为“冷数据在 MinIO 上”。
2. 看到 NAS 节点 CPU 高，就直接归因于 IO 性能问题。

### 只读排查步骤

#### 1. 先确认 OpenSearch 数据节点实际落盘

```bash
kubectl -n <logging-ns> get pod -o wide
kubectl -n <logging-ns> get pvc -o custom-columns=NAME:.metadata.name,SC:.spec.storageClassName,VOLUME:.spec.volumeName,CAP:.status.capacity.storage
```

判据：

- `StorageClass=local`：在线分片落在宿主机本地盘或 local PV。
- `StorageClass=nfs-csi`：在线分片落在 NFS/NAS 挂载卷。
- PVC 声明容量不一定等于真实宿主机空间上限，local PV 还要看宿主机挂载点使用率。

#### 2. 区分在线数据、冷数据和快照仓库

```bash
kubectl -n <logging-ns> exec <opensearch-master-pod> -- \
  curl -ks -u <user>:<pass> https://localhost:9200/_snapshot?pretty

kubectl -n <logging-ns> exec <opensearch-master-pod> -- \
  curl -ks -u <user>:<pass> https://localhost:9200/_cat/plugins?v
```

判据：

- `_snapshot` 返回 `{ }`：没有登记 snapshot repository，不能说冷数据在 MinIO/S3。
- 插件列表没有 `repository-s3`：通常不具备 S3/MinIO 快照仓库能力。
- ISM 只有 `hot -> delete`：代表到期删除，不代表热转冷或归档到对象存储。

#### 3. 判断 CPU 高是否由 IO wait 导致

```bash
top -bn1
iostat -xz 1 2
ps -eo pid,pcpu,pmem,rss,etime,comm,args --sort=-pcpu
```

判据：

- `%wa` 长时间高、进程大量 `D` 状态、设备 await/util 高：优先怀疑 IO/NFS。
- `%us` 长时间高、`%wa` 接近 0：优先按 CPU 计算型过载排查。
- NFS 在线分片可能放大查询、merge、recovery 成本，但不能只凭“NAS 节点 CPU 高”下结论。

#### 4. 把高 CPU PID 映射回 Pod

```bash
tr '\0' ' ' < /proc/<pid>/cmdline
cat /proc/<pid>/cgroup
crictl inspect <container-id>
```

重点识别：

- OpenSearch data 节点是否正在承担 indexing / search / merge / recovery。
- 日志采集器、Kafka Connect、业务 Java 是否与 OpenSearch 混部叠加。
- operator/controller 是否长期空转；若是控制面 Pod，可优先评估低风险重启。

### 根因分析模型

| 现象 | 不要直接推断 | 应该补充的证据 |
|------|--------------|----------------|
| NFS CSI 节点 CPU 高 | NAS IO 慢导致 | `top` 的 `%wa`、`iostat` await/util、进程状态 |
| data 节点挂 NAS | 冷数据在 MinIO | `_snapshot` repository、`repository-s3` 插件、ISM 状态机 |
| PVC 写了 20Gi | 数据只能写 20Gi | 宿主机 `df`、PV 实际路径、local PV 实现 |
| flood-stage 已解除 | 写入一定恢复 | 索引 `read_only_allow_delete` 是否仍为 true |

### 处置顺序

1. **先止写入故障**：扩容或释放触发 flood-stage 的本地盘，再清除索引只读块。
2. **再控保留周期**：核对 ISM policy 的实际 `min_index_age`，不要相信策略名。
3. **再看算力热点**：用 PID -> Pod 映射拆出 OpenSearch、业务 Java、operator/controller 各自占用。
4. **低风险先摘异常控制面**：例如只重启异常空转的 operator Pod，不碰数据 Pod、PVC 或 StatefulSet。
5. **最后做结构性优化**：减少高写入日志在 NFS 在线分片上的占比，或把 NAS 节点定位为低频/冷查询用途。

### 验证闭环

1. OpenSearch health 为 green/yellow 可解释状态，写入索引无 `read_only_allow_delete=true`。
2. 业务日志写入链路恢复，无持续 `TOO_MANY_REQUESTS/12/disk usage exceeded flood-stage watermark`。
3. CPU 归因有证据：高 CPU PID 已映射到 Pod，且 `%us` / `%wa` 判断一致。
4. 控制面重启后，新 Pod Ready，数据面 Pod 仍 Running，节点 CPU/load 有下降或剩余大户明确。

### 预防措施

1. OpenSearch 数据节点混用 local/NFS 时，容量告警必须按**宿主机本地盘余量**和**节点角色**分别看，不只看集群平均。
2. 日志保留策略以实际 ISM policy 为准；策略名带 `4d`、`short` 等字样不能作为事实。
3. 若要使用 MinIO/S3 做快照或冷归档，必须显式配置 repository、插件和恢复演练；否则不要把 MinIO 当作默认冷数据层。
4. 8C worker 上避免叠放 OpenSearch data、重业务 Java、Kafka Connect/Amoro optimizer、长期高 CPU operator。
5. 对 operator/controller 设置合理 CPU request/limit，并把长期高 CPU 控制面纳入巡检。

---

## CASE-011: Java 容器线程触达 kubelet podPidsLimit 后被探针重启

**日期**: 2026-08-17
**影响**: K8s 中的 Java 服务 Pod（示例：3 副本，cgroup `pids.max=1000`）
**服务**: Java / Tomcat / kubelet / 入口 Nginx

### 触发场景

同一 Deployment 多个副本在晚高峰前后约 1 分钟内全部重启。表象像节点 OOM、apt 升级或有人点了平台重启。日志里可能出现：

- `java.lang.OutOfMemoryError: unable to create new native thread`
- kubelet `PreStop hook failed` 随后 SIGTERM，容器 `exit 143`
- `/actuator/health` readiness/liveness timeout
- Tomcat 线程名 `http-nio-<port>-exec-N` 的 N 快速升高

### 排查步骤

```bash
# 1. 先拆「发版/点击重启」vs「kubelet 杀容器」
kubectl get deploy,rs,pod -n <ns> -l app=<app> -o wide
kubectl get deploy <deploy> -n <ns> -o jsonpath='{.spec.template.metadata.annotations}'
# restartedAt 变化 = 平台滚动（新 Pod Attempt:0）
# 同一 Pod UID 的 Attempt:1/2 + exit 143 = kubelet 停容器

# 2. 看停机前 60~90 秒，不要只看 PreStop
journalctl -u kubelet --since '<t-10m>' --until '<t+5m>' | grep -v 'Unable to retrieve pull secret'
journalctl -u containerd --since '<t-10m>' --until '<t+5m>' | grep <container-name>

# 3. native thread OOM：查 cgroup 线程配额，不要先加 -Xmx
grep podPidsLimit /var/lib/kubelet/config.yaml
cat /sys/fs/cgroup/kubepods.slice/.../pids.max
cat /sys/fs/cgroup/kubepods.slice/.../pids.current
ls /proc/<java-pid>/task | wc -l
# 线程名分布
for t in /proc/<java-pid>/task/*/comm; do cat "$t"; done | sort | uniq -c | sort -nr | head

# 4. 排除节点级事故
dmesg -T | grep -i 'oom\|kill' | tail
systemctl is-enabled apt-daily-upgrade.timer
free -h
```

判据：

- 堆 RSS 远低于 `-Xmx`，但 `pids.current` 贴近 `pids.max`：这是线程配额，不是 Java 堆 OOM。
- 多副本同时重启但 RS / 镜像 / `restartedAt` 不变：共享流量模型 + 相同线程基线即可同秒触顶。
- `PreStop hook failed` 只能说明停机钩子非 0；要看钩子里业务步骤是否已成功（例如注册中心 DOWN 已 200）。

### 根因分析模型

| 现象 | 不要直接推断 | 应该补充的证据 |
|------|--------------|----------------|
| `unable to create new native thread` | 堆内存不够，先加 `-Xmx` | `pids.current` / `pids.max`、线程名分布 |
| 三副本同秒重启 | 节点 apt / 内核 OOM | `restartedAt`、RS、dmesg、timer 状态 |
| `PreStop hook failed` | 停机脚本是根因 | 钩子内部是否已成功；随后是否仍 SIGTERM |
| 收了 Tomcat max 仍见 http-nio 上涨 | 应用又泄漏线程 | 高峰是否回落；backup/Kafka 池是否跟着涨 |
| 内部服务 QPS 暴增 | 自己的消费者/定时任务 | 调用方 Pod IP → 入口 Nginx 源 IP + UA |

### 线程预算（2C 容器、pids.max=1000 的经验值）

| 项 | 危险基线 | 更稳妥 |
|---|---|---|
| Tomcat `threads.max` | 1000（峰值可直接打满 pids） | 与 CPU 匹配，例如 120–250 |
| Kafka `listener.concurrency` × listener 数 | 全局 5，再叠加 Micrometer scheduler | 默认 2，热点单独覆盖；可关 per-consumer Micrometer |
| 异步池 core=max 且常驻 | 闲时已占几百 | core 小、max 弹性、`allowCoreThreadTimeOut` |
| 闲时 pids.current / max | ≥70% | 闲时 <40%，峰值仍留 >400 余量 |

### 流量溯源（http-nio 独涨时）

1. 应用 HTTP 访问日志或 OpenSearch `Http trace log` 按 path、按分钟聚合，对比基线窗口与高峰窗口。
2. 把调用方集群内 IP 反查成 Pod / Service；若是 BFF/渠道网关，继续查该服务的渠道 URL 或 adaptor。
3. 到入口 Nginx access_log 用同一时间窗 + 路径关键字取源 IP 和 User-Agent。
4. 消费者日志量很低时，不要先查 Kafka 重放。

示例入口行（脱敏）：

```text
203.0.113.80 - - [17/Aug/2026:17:56:19 +0800] "POST /openApi/api/<channel>/getQuota HTTP/1.1" 200 1304 "-" "Apache-HttpClient/4.5.12"
```

### 解决方案

1. **先保活**：限制 Tomcat max / accept-count / max-connections，避免峰值线程顶满 `pids.max`。
2. **再降基线**：Kafka concurrency、异步池 core、关掉无用的 per-consumer metrics 线程。
3. **不要先改全集群 `podPidsLimit`**：会掩盖膨胀，大 Tomcat 池仍可能把小 CPU 配额打满。
4. **高峰仍涨但不重启**：用流量溯源找渠道/对端并发，而不是继续加线程上限。
5. **探针**：存活/就绪不要在线程耗尽时还依赖同一 HTTP 池的重检查；超时过短会把卡顿放大成重启。

### 验证闭环

1. 启动 10 分钟后 `pids.current` 明显低于改前基线（例如从 ~750 降到 ~300）。
2. `http-nio` 线程数封顶在配置的 `threads.max` 附近，且高峰后回落。
3. 连续一个业务高峰窗口无 `unable to create new native thread`、无同 Pod `Attempt+1` / exit 143。
4. 若高峰 `http-nio` 仍接近 max：已拿到 path、调用方服务、入口源 IP，并能区分「正常业务」与「对端突发轮询」。

### 预防措施

1. Java 服务上线前把 Tomcat / 线程池 / Kafka concurrency 纳入与 `podPidsLimit` 对照的预算，而不是沿用默认 1000。
2. 巡检看 `pids.current` 和 `http-nio-exec-N` 高水位，不要只看堆内存和重启次数。
3. 渠道额度/状态查询类接口要对对端明确并发与间隔；入口 Nginx 保留可检索的 access_log。
4. 停机脚本不要把非关键 IO（例如写不存在的 start.log）变成 PreStop 失败，以免掩盖真正停机原因。

### 相关档案

- 事件档案写在各运维包 `incidents/`（htyc：`20260813-java-native-thread-oom-podpidslimit`、`20260817-java-peak-thread-kubelet-restart`）。
