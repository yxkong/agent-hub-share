# Ops Bootstrap — Workflow

## 实现分层

| 层 | 文件 | 职责 |
|----|------|------|
| Python core | `scripts/ecs_ops.py` | 读取 `sync.config.json`、写 SSH config block、调用 `ssh`、执行远程 `ops-check.remote.sh` |
| Future core modules | `scripts/core/`、`scripts/modules/`、`scripts/helpers/` | 后续承接 provision plan/check/apply，分区规则见 `layout_contract.md` |
| Key deploy helper | `scripts/setup_ssh_key.py` | 仅在密码部署公钥时使用 `paramiko` |
| Windows wrapper | `scripts/bootstrap-ssh.ps1`、`scripts/ops-check.ps1` | 定位 Python，兼容 PowerShell 参数，转发到 core |
| macOS/Linux wrapper | `scripts/bootstrap-ssh.sh`、`scripts/ops-check.sh` | 定位 Python，转发到 core |
| 项目薄封装 | `<ops>/bootstrap.ps1`、`<ops>/ops-check.ps1` 或 `.sh` | 只传入 `OpsRoot` / `--ops-root` |

规则：

- 通用逻辑只放 `ecs_ops.py`，不要在 `ps1/sh` 中复制配置解析或 SSH 处理。
- 新增功能按 `layout_contract.md` 分区；根脚本保持兼容入口，不继续堆业务逻辑。
- `ops-check` 只做只读探测；安装、部署、重启等有状态动作留在项目 `scripts/` 或显式 runbook。
- 日常检查不依赖 `paramiko`；只有 key auth 失败且需要密码部署公钥时才需要 `paramiko`。

## Discovery 结论（创建依据）

| 候选 | 匹配 | 说明 |
|------|------|------|
| `agent-hub-bootstrap` | none | hub 挂载，不覆盖服务器 SSH 和运维启动包 |
| `ops-mcp-dev` | none | MCP 服务开发，非本机运维包 |
| 本地 share 其它 skill | none | 无 SSH bootstrap 同类 |

结论：通用运维启动包使用 `skills/share/ops-bootstrap`；历史名 `ecs-ops-bootstrap` 只作为旧引用迁移来源。

## 新机器 / 新电脑

1. 复制项目 ops 目录（或从 `templates/` 脚手架）
2. 填 `sync.config.json`、`account.md`（仅首次）
3. 写 `ops-check.remote.sh`（项目相关检查）
4. 按 `references/project_ops_contract.md` 落 `connect/provision/deploy/detect/logs/query/db` 中适用的项目配置
5. 如需一键环境安装，复制 `templates/provision/` 到项目 `<ops>/provision/` 并按目标机器改脱敏配置
5. 运行：

```powershell
& "$env:AGENTS_HUB_ROOT\skills\share\ops-bootstrap\scripts\bootstrap-ssh.ps1" -OpsRoot <ops-dir>
```

```bash
bash "$AGENTS_HUB_ROOT/skills/share/ops-bootstrap/scripts/bootstrap-ssh.sh" --ops-root <ops-dir>
```

## sync.config.json 字段

| 字段 | 必填 | 说明 |
|------|------|------|
| `sshHost` | 是 | 本机 SSH 别名，如 `<ops-host>` |
| `remoteHost` | 是 | IP / 域名 |
| `remoteUser` | 是 | 通常 `root` |
| `remotePath` | 是 | 远程业务根路径（展示用） |
| `identityFile` | 否 | 默认 `~/.ssh/id_rsa`；项目私有 key 在项目配置中覆盖 |
| `accountFile` | 否 | 默认 `account.md` |
| `sshHostApp` / `opsAppUser` | 否 | 第二别名（如 appuser） |
| `opsCheckScript` | 否 | 默认 `ops-check.remote.sh` |
| `opsName` | 否 | 检查标题，默认目录名 |
| `sshMarker` | 否 | SSH config 块标记，默认 `ops-bootstrap`；脚本兼容旧 marker `ecs-ops-bootstrap` |
| `environmentConfig` | 否 | 环境安装总配置，建议 `provision/environment.config.json` |

## ops-check.remote.sh

在**远程** bash 执行的检查脚本，由本机 `ops-check.ps1` 通过 `ssh host 'bash -s'` 注入。
只写 `echo` / `systemctl` / `curl` / `pm2` 等只读探测，避免破坏性命令。

## 项目薄封装约定

```powershell
# <ops>/bootstrap.ps1
param([switch]$Force, [switch]$SkipKeyDeploy, [string]$IdentityFile = "")
& "$env:AGENTS_HUB_ROOT\skills\share\ops-bootstrap\scripts\bootstrap-ssh.ps1" `
  -OpsRoot $PSScriptRoot -IdentityFile $IdentityFile -Force:$Force -SkipKeyDeploy:$SkipKeyDeploy

# <ops>/ops-check.ps1
& "$env:AGENTS_HUB_ROOT\skills\share\ops-bootstrap\scripts\ops-check.ps1" -OpsRoot $PSScriptRoot
```

项目可删除本地 `scripts/setup_ssh_key.py` 副本。

macOS/Linux 项目侧可保留：

```bash
#!/usr/bin/env bash
set -euo pipefail
bash "$AGENTS_HUB_ROOT/skills/share/ops-bootstrap/scripts/ops-check.sh" --ops-root "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
```

## 能力边界：ECS / MySQL / Nginx / JDK / 部署

| 能力 | share skill 放什么 | 项目目录放什么 |
|------|--------------------|----------------|
| ECS 接入 | SSH alias、公钥部署、连通性检查 | IP、用户、业务路径、账号说明 |
| MySQL | 只读检查模板和执行编排 | 连接方式、库名、慢查询/连接数等项目脚本 |
| Nginx | 只读检查模板和执行编排 | 域名、证书路径、站点配置、reload runbook |
| JDK | 只读版本/服务检查模板 | 具体 JDK 版本、systemd/启动参数 |
| 部署 | 通用前置检查、后置健康检查、hook 约定 | 构建产物、上传路径、服务重启、回滚脚本 |

默认不要把 MySQL/Nginx/JDK 的写操作或业务部署脚本放进 share。share 只固化「怎么调用、怎么检查、怎么分层」，项目脚本负责「对哪台机器做什么」。

## 一键环境安装规划入口

环境安装不直接塞进 `ops-check.remote.sh`。后续走独立 provision 流程：

1. `templates/provision/TEMPLATE_environment.config.json` 定义启用模块。
2. `templates/provision/modules/TEMPLATE_<component>.json` 定义组件目标状态。
3. `references/roadmap.md` 定义 `plan/check/apply/rollback` 命令模型。
4. 项目复制模板到 `<ops>/provision/` 后只改项目私有配置。

组件配置模板当前覆盖：

- `python-uv`
- `jdk`
- `nginx`
- `node`
- `mysql`
- `redis`
- `zookeeper`
- `kafka`

执行顺序必须是 `plan` → `check` → `apply --module <name>`，不得默认全量安装。

## 小程序 / 微信校验 txt

走 Nginx helper，不新建独立 skill。SOP：`references/modules/nginx_mp_verify.md`。

```powershell
# 本仓库
.\prod\scripts\deploy-mp-verify.ps1 -LocalFile <txt> -Domain a.example,b.example -DryRun
.\prod\scripts\deploy-mp-verify.ps1 -LocalFile <txt> -Domain a.example,b.example
```
