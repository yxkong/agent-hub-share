# Case Library 索引

> **用途**：Agent 检索案例时先读本文件（小上下文），找到目标案例后按行号精确读取 `case_library.md`。
> **读取方式**：`Read(path="case_library.md", offset=<起始行>, limit=<建议读取>)`。

---

## 案例全景（按编号排序）

| 编号 | 标题 | 日期 | 领域 | 行范围 | 建议读取 |
|------|------|------|------|--------|----------|
| CASE-001 | 单机数据任务周期性 OOM 导致服务不可用 | 2026-07-16 | 内存/OS | 8-126 | `offset=8, limit=119` |
| CASE-002 | SSH 别名无法解析 | 2026-07-16 | SSH/连接 | 127-182 | `offset=127, limit=56` |
| CASE-003 | Kafka broker 下线后旧 partition 数据撑满数据盘 | 2026-07-30 | Kafka/磁盘 | 281-366 | `offset=281, limit=86` |
| CASE-004 | unattended-upgrades 自动升级导致 Nginx 崩溃 | 2026-07-30 | Nginx/OS | 367-434 | `offset=367, limit=68` |
| CASE-005 | 公网暴露服务无认证导致挖矿入侵 | 2026-07-29 | 安全/入侵 | 435-518 | `offset=435, limit=84` |
| CASE-006 | OCSP Stapling 错误刷屏 | 2026-07-30 | Nginx/SSL | 519-582 | `offset=519, limit=64` |
| CASE-007 | Nginx 配置漂移 | 2026-07-21 | Nginx/配置 | 583-666 | `offset=583, limit=84` |
| CASE-008 | Kafka topicId 漂移导致所有 consumer group 无法协调 | 2026-08-09 | Kafka/协调 | 667-756 | `offset=667, limit=90` |
| CASE-009 | 消费 Kafka 历史消息按条件过滤后重推 | 2026-08-10 | Kafka/运维 | 183-280 | `offset=183, limit=98` |
| CASE-010 | OpenSearch local/NFS 混合数据节点的容量与高 CPU 排查 | 2026-08-10 | OpenSearch/存储/CPU | 759-861 | `offset=759, limit=103` |
| CASE-011 | Java 容器线程触达 kubelet podPidsLimit 后被探针重启 | 2026-08-17 | Java/K8s | 865-970 | `offset=865, limit=106` |

## 按领域检索

| 领域 | 案例 |
|------|------|
| 内存/OS | CASE-001, CASE-011 |
| SSH/连接 | CASE-002 |
| Kafka | CASE-003, CASE-008, CASE-009 |
| OpenSearch | CASE-010 |
| Nginx | CASE-004, CASE-006, CASE-007 |
| 安全/入侵 | CASE-005 |
| 磁盘 | CASE-003, CASE-010 |
| CPU | CASE-005, CASE-010 |
| 存储/NFS | CASE-010 |
| 配置漂移 | CASE-007 |
| Java/K8s | CASE-011 |

## 与项目 incidents 的关系

- 项目事件档案写在各运维包 `incidents/`（htyc 见 `../../incidents/`）。
- 本索引只收录**跨事件可复用**案例；先有 incident，再提炼 CASE。
- 提炼门槛：通用场景可检索、输入输出清楚、验收判据可执行。详见项目 `docs/layout.md`。

## 按关键词检索

| 关键词 | 命中案例 |
|--------|----------|
| OOM / Swap / 内存不足 / 进程被杀 | CASE-001 |
| SSH / 别名 / hostname / 连接失败 | CASE-002 |
| Kafka 磁盘满 / 孤儿 partition / topic 删除后空间未释放 | CASE-003 |
| Nginx 崩溃 / 自动升级 / unattended-upgrades | CASE-004 |
| CPU 飙高 / 挖矿 / 入侵 / 公网暴露 | CASE-005 |
| OCSP / SSL 错误刷屏 / 证书 | CASE-006 |
| Nginx 配置不一致 / 多节点 / diff | CASE-007 |
| Kafka topicId 漂移 / consumer group 超时 / 不消费 | CASE-008 |
| Kafka 重推 / repush / 历史消息重放 / 时间范围消费 | CASE-009 |
| OpenSearch flood-stage / read_only_allow_delete / local PV / NFS CSI / NAS / MinIO 冷数据 / iowait / operator 高 CPU | CASE-010 |
| native thread / podPidsLimit / pids.max / exit 143 / Attempt:1 / http-nio / Tomcat 线程膨胀 | CASE-011 |

## Section 结构

多数故障排查案例包含以下标准 section（可用于精准定位）：

- `### 触发场景` — 什么现象触发排查
- `### 排查步骤` — 逐条命令和检查项
- `### 根因分析` / `### 根因` — 根因表格或结论
- `### 解决方案` — 分步修复（含 `#### 第N步` 子标题）
- `### 预防措施` — 避免再次发生的措施

额外 section（部分案例有）：
- `#### 性能对比`（CASE-001, CASE-003）
- `### 验证与回滚`（CASE-008）
- `### 标准 SOP`（CASE-009）
- `### 必须向用户确认的问题`（CASE-009）
- `### 脚本必备能力`（CASE-009）
- `### 关键设计决策`（CASE-009）
- `### 验证闭环`（CASE-009）
- `### 相关脚本`（CASE-009）
- `### 根因分析模型`（CASE-010, CASE-011）
- `### 处置顺序`（CASE-010）
- `### 线程预算`（CASE-011）
- `### 流量溯源`（CASE-011）

注意：CASE-009 是 SOP 型案例，不是传统故障排查案例；正文顺序目前不是严格按编号排序，以本索引为准。

## 命中策略

1. 用户描述明确命中关键词时：只读取对应 CASE，不加载全文。
2. 用户描述不明确时：先读本索引，按领域和关键词二次判断。
3. 涉及修改、删除、重启、生产执行时：同时读取 `safe_ops_manual.md`，并先确认风险与回退。
4. Kafka 类问题优先在 CASE-003、CASE-008、CASE-009 中判断：磁盘满看 CASE-003，consumer group 不协调看 CASE-008，历史消息重推看 CASE-009。
5. Java 容器重启 / native thread / 多副本同秒 SIGTERM：先读 CASE-011，不要先加 `-Xmx` 或改全集群 `podPidsLimit`。

## Agent 使用规范

```
# 场景：用户说"磁盘满了，帮我排查"
# 1. 读本索引，命中 CASE-003
# 2. Read(path="case_library.md", offset=281, limit=86)  — 只读取 CASE-003
# 3. 按案例步骤执行排查
```