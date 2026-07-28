#!/usr/bin/env bash
# Remote health probes for one ECS. Piped via: ssh <alias> 'bash -s'
set +e
echo '--- host ---'
hostname; uptime
echo '--- disk/mem ---'
df -h / | tail -1
free -h | head -2
echo '--- customize below ---'
# systemctl is-active nginx
# curl -s -o /dev/null -w 'HTTP %{http_code}\n' http://127.0.0.1/
