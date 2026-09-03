#Requires -Version 5.1
<#
.SYNOPSIS
  将微信/小程序校验 txt 下发到指定环境全部 Nginx 节点的域名静态 root，并做 HTTPS GET 验收。
  ops-bootstrap helper：读项目 <OpsRoot>/ops.config.json 与 conf/nginx/conf.d，不写死业务域名。
#>
param(
    [Parameter(Mandatory = $true)]
    [string]$OpsRoot,
    [Parameter(Mandatory = $true)]
    [string]$LocalFile,
    [Parameter(Mandatory = $true)]
    [string[]]$Domain,
    [switch]$DryRun,
    [switch]$VerifyOnly
)

$ErrorActionPreference = "Stop"
$SshOpts = @("-o", "BatchMode=yes", "-o", "ConnectTimeout=15", "-o", "StrictHostKeyChecking=accept-new")

function Read-Utf8Json([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path)) { throw "missing $Path" }
    return [IO.File]::ReadAllText((Resolve-Path -LiteralPath $Path), [Text.UTF8Encoding]::new($false)) | ConvertFrom-Json
}

function Get-NginxTargets {
    param($OpsConfig)
    $hosts = @()
    foreach ($h in $OpsConfig.connect.hosts) {
        $role = [string]$h.role
        if ($role -eq "nginx" -or $role -eq "egress-nginx" -or $role -eq "test-nginx") {
            $hosts += $h
        }
    }
    if ($hosts.Count -eq 0) { throw "no nginx/test-nginx/egress-nginx hosts in ops.config.json" }
    return $hosts
}

function Resolve-DomainRoot {
    param([string]$ConfD, [string]$HostName)
    if (-not (Test-Path $ConfD)) { throw "missing conf.d: $ConfD" }
    $escaped = [regex]::Escape($HostName)
    $files = Get-ChildItem -Path $ConfD -Recurse -Filter *.conf
    $candidates = @()
    foreach ($f in $files) {
        $text = [IO.File]::ReadAllText($f.FullName)
        if ($text -notmatch ("server_name[^\n]*\b{0}\b" -f $escaped)) { continue }
        $rx = [regex]('(?is)server\s*\{(?:(?!\bserver\s*\{).)*?server_name[^\n]*\b' + $escaped + '\b(?:(?!\bserver\s*\{).)*?root\s+(\S+);')
        foreach ($m in $rx.Matches($text)) {
            $root = $m.Groups[1].Value.Trim().TrimEnd(';')
            $is443 = $m.Value -match 'listen\s+443'
            $candidates += [pscustomobject]@{ File = $f.FullName; Root = $root; PreferSsl = [bool]$is443 }
        }
    }
    if ($candidates.Count -eq 0) {
        throw "cannot resolve root for $HostName under $ConfD (no server_name + root)"
    }
    $ssl = @($candidates | Where-Object PreferSsl)
    if ($ssl.Count -gt 0) { return $ssl[0] }
    return $candidates[0]
}

function Get-LocalBody {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { throw "local file not found: $Path" }
    $name = [IO.Path]::GetFileName($Path)
    if ($name -notmatch '^[A-Za-z0-9._-]+\.txt$') { throw "unsafe filename: $name" }
    $raw = [IO.File]::ReadAllText($Path).Trim([char]0xFEFF).Trim()
    if ([string]::IsNullOrWhiteSpace($raw)) { throw "empty verify file" }
    if ($raw -match '<html|#!/') { throw "refusing non-plaintext verify file" }
    return @{ Name = $name; Body = $raw }
}

function Invoke-Ssh {
    param([string]$Alias, [string]$RemoteCmd)
    & ssh @SshOpts $Alias $RemoteCmd
    if ($LASTEXITCODE -ne 0) { throw "ssh $Alias failed: $RemoteCmd" }
}

function Get-RemoteBody {
    param([string]$Alias, [string]$RemotePath)
    $quoted = $RemotePath.Replace("'", "'\''")
    $out = & ssh @SshOpts $Alias "if test -f '$quoted'; then cat '$quoted'; else echo '__MISSING__'; fi"
    if ($LASTEXITCODE -ne 0) { throw "ssh $Alias cat failed" }
    return ($out | Out-String).Trim()
}

function Publish-File {
    param([string]$Alias, [string]$RemotePath, [string]$LocalPath, [string]$Body, [switch]$PlanOnly)
    $dir = ($RemotePath -replace '/[^/]+$', '')
    $existing = Get-RemoteBody -Alias $Alias -RemotePath $RemotePath
    if ($existing -eq $Body) {
        Write-Host "SKIP $Alias $RemotePath (identical)" -ForegroundColor DarkGray
        return "skip"
    }
    if ($PlanOnly) {
        if ($existing -eq "__MISSING__") { Write-Host "PLAN write $Alias $RemotePath" -ForegroundColor Yellow }
        else { Write-Host "PLAN backup+overwrite $Alias $RemotePath" -ForegroundColor Yellow }
        return "plan"
    }
    Invoke-Ssh $Alias "mkdir -p '$dir'"
    if ($existing -ne "__MISSING__") {
        Invoke-Ssh $Alias "cp '$RemotePath' '$RemotePath.bak.`$(date +%Y%m%d%H%M%S)'"
    }
    & scp @SshOpts $LocalPath "${Alias}:${RemotePath}"
    if ($LASTEXITCODE -ne 0) { throw "scp to $Alias failed" }
    Invoke-Ssh $Alias "chmod 644 '$RemotePath'"
    $after = Get-RemoteBody -Alias $Alias -RemotePath $RemotePath
    if ($after -ne $Body) { throw "remote content mismatch after scp: $Alias $RemotePath" }
    Write-Host "WROTE $Alias $RemotePath" -ForegroundColor Green
    return "wrote"
}

function Test-PublicUrl {
    param([string]$HostName, [string]$FileName, [string]$Body)
    $url = "https://$HostName/$FileName"
    $curl = if (Get-Command curl.exe -ErrorAction SilentlyContinue) { "curl.exe" } else { "curl" }
    $tmp = [IO.Path]::GetTempFileName()
    try {
        & $curl -sS -f --max-time 20 -o $tmp $url
        if ($LASTEXITCODE -ne 0) { throw "GET failed $url" }
        $got = [IO.File]::ReadAllText($tmp).Trim([char]0xFEFF).Trim()
        if ($got -ne $Body) { throw "body mismatch $url got=[$got] want=[$Body]" }
        Write-Host "OK $url" -ForegroundColor Green
    }
    finally {
        Remove-Item $tmp -ErrorAction SilentlyContinue
    }
}

$opsRootResolved = (Resolve-Path -LiteralPath $OpsRoot).Path
$opsConfig = Read-Utf8Json (Join-Path $opsRootResolved "ops.config.json")
$syncPath = Join-Path $opsRootResolved "sync.config.json"
$envName = if (Test-Path -LiteralPath $syncPath) { [string](Read-Utf8Json $syncPath).opsName } else { Split-Path $opsRootResolved -Leaf }

$local = Get-LocalBody -Path $LocalFile
$absLocal = (Resolve-Path -LiteralPath $LocalFile).Path
$domains = @($Domain | ForEach-Object { $_.Trim() } | Where-Object { $_ })
$targets = Get-NginxTargets -OpsConfig $opsConfig
$confD = Join-Path $opsRootResolved "conf\nginx\conf.d"

Write-Host "env=$envName file=$($local.Name) dryRun=$DryRun verifyOnly=$VerifyOnly"
foreach ($d in $domains) {
    $resolved = Resolve-DomainRoot -ConfD $confD -HostName $d
    $remotePath = ($resolved.Root.TrimEnd('/') + '/' + $local.Name)
    Write-Host "domain=$d root=$($resolved.Root) conf=$($resolved.File)"
    if (-not $VerifyOnly) {
        foreach ($h in $targets) {
            Publish-File -Alias ([string]$h.sshHost) -RemotePath $remotePath -LocalPath $absLocal -Body $local.Body -PlanOnly:$DryRun | Out-Null
        }
    }
    if ($DryRun) { continue }
    Test-PublicUrl -HostName $d -FileName $local.Name -Body $local.Body
}

if ($DryRun) { Write-Host "dry-run done; rerun without -DryRun to apply" }
