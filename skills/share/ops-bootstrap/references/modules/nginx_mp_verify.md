# Nginx 小程序/微信校验 txt 下发

归属 Deploy / Nginx helper。不单独建 skill。

## 何时用

用户要把微信或小程序业务域名校验 `*.txt` 放到对应站点根，使 `GET /<filename>` 返回校验体。

## 执行入口

`scripts/helpers/deploy_mp_verify.ps1`

必须先 `-DryRun`，确认每域名 `root` 与全部 nginx 角色主机后再去掉该开关。`-VerifyOnly` 只做 HTTPS GET。

项目侧可薄封装转发（只传 `-OpsRoot`）：

```powershell
& <ops-bootstrap>\scripts\helpers\deploy_mp_verify.ps1 -OpsRoot $PSScriptRoot\.. -LocalFile <txt> -Domain a.example,b.example -DryRun
```

本仓库：`prod/scripts/deploy-mp-verify.ps1`、`test/scripts/deploy-mp-verify.ps1`。

## 行为契约

1. 主机来自 `<OpsRoot>/ops.config.json` 的 `role=nginx|test-nginx|egress-nginx`（含与跳板同机）。
2. `root` 来自 `<OpsRoot>/conf/nginx/conf.d`：匹配 `server_name` 整词，优先 `listen 443` 块内（含 `location /` 上的）`root`。
3. 远端 `$root/<文件名>`。一致则 SKIP；缺失则写入；不同则 `.bak.<时间戳>` 后覆盖。禁止 `rm`。
4. apply 后 `https://<host>/<file>` 正文与源文件 trim 后一致。
5. 不为静态 txt 执行 `nginx reload`。
6. 文件名 `^[A-Za-z0-9._-]+\.txt$`；拒绝空文件、HTML、shebang。

## 禁止

- 手拼 scp、沿用其它域名历史路径
- 把文件放到子应用 `alias`（如 `/market/`）冒充站点根
- `location /` 仅 `proxy_pass`、无 `try_files $uri` 且无 `root` 时强行下发（脚本应失败）
- 在本文件或 templates 写入项目业务域名清单（路径以 conf 解析为准）

## 失败

| 现象 | 动作 |
|------|------|
| cannot resolve root | `nginx.ps1 pull-local` 后再解析；仍失败则该域名不在本 helper 范围 |
| ssh 失败 | 走本技能 bootstrap / 别名 |
| GET 失败但远端有文件 | 查 HTTP 301、漏节点、root 解析错 |
