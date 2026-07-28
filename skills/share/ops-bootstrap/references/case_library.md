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
