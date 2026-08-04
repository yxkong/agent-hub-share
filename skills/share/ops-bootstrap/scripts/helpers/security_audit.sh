#!/usr/bin/env bash
# security_audit.sh - Read-only public exposure and malware audit.
#
# Scenario: server compromised (XMRig miner, botnet, etc.) or suspicious
# CPU usage. This script does a read-only audit of public-facing ports,
# running processes, and system state to identify attack vectors.
#
# Usage:
#   bash security_audit.sh [--skip-iptables]
#
# Design principles:
#   - Read-only: never modify, kill, or delete anything.
#   - Portable: POSIX-ish bash, no project-specific paths or credentials.
#   - Bounded: checks common attack vectors, not a full pentest.
set -uo pipefail
trap '' PIPE

SKIP_IPTABLES="${1:-}"

echo "================================================================"
echo "  security_audit.sh  (read-only)"
echo "  host: $(hostname)  date: $(date '+%Y-%m-%d %H:%M:%S %Z')"
echo "================================================================"
echo

# --- Section 1: Public listening ports ---
echo "=== 1. Listening ports on all interfaces (0.0.0.0) ==="
ss -lntp 2>/dev/null | grep "0.0.0.0" | while read -r line; do
  port=$(echo "$line" | awk '{print $4}' | grep -oP ':\K\d+$')
  proc=$(echo "$line" | awk '{print $NF}')
  echo "  $port  $proc"
done
echo
echo "--- Also check ::: (IPv6) ---"
ss -lntp 2>/dev/null | grep ":::" | head -20
echo

# --- Section 2: Suspicious processes ---
echo "=== 2. Suspicious processes (XMRig, miners, crypto, hidden names) ==="
echo "--- CPU top 10 ---"
ps aux --sort=-%cpu | head -11
echo
echo "--- Known miner signatures ---"
ps aux | grep -v grep | grep -iE "xmrig|miner|crypto|kworker_u[0-9]_[0-9]|cpuminer|t-rex|phoenix" || echo "  (none found)"
echo
echo "--- Processes with deleted executables (common malware trick) ---"
find /proc/[0-9]*/exe -type l 2>/dev/null | while read -r link; do
  if [ ! -e "$link" ]; then
    pid=$(echo "$link" | cut -d/ -f3)
    comm=$(cat "/proc/$pid/comm" 2>/dev/null || echo "?")
    name=$(ps -p "$pid" -o args= 2>/dev/null | head -c 150)
    echo "  PID=$pid comm=$comm args=$name"
  fi
done
echo

# --- Section 3: Recent logins and SSH attempts ---
echo "=== 3. Recent logins ==="
last -n 20 2>/dev/null || echo "  (last not available)"
echo
echo "--- Failed SSH attempts (last 50) ---"
grep "Failed password" /var/log/auth.log 2>/dev/null | tail -20 || \
  journalctl -u ssh --no-pager -n 50 2>/dev/null | grep -i "failed" | tail -20 || \
  echo "  (no auth log found)"
echo

# --- Section 4: Cron jobs and startup scripts ---
echo "=== 4. Suspicious cron jobs ==="
for crondir in /etc/cron.d /var/spool/cron/crontabs /etc/cron.daily /etc/cron.hourly; do
  if [ -d "$crondir" ]; then
    echo "--- $crondir ---"
    ls -la "$crondir" 2>/dev/null | head -15
  fi
done
echo
echo "--- User crontabs ---"
for user in $(cut -d: -f1 /etc/passwd 2>/dev/null); do
  crontab -u "$user" -l 2>/dev/null | grep -v "^#" | grep -v "^$" | head -3
done | head -30
echo

# --- Section 5: Unusual services ---
echo "=== 5. Enabled services (non-standard) ==="
systemctl list-unit-files --state=enabled 2>/dev/null | grep -v "^$" | \
  grep -vE "systemd|ssh|nginx|cron|docker|kubelet|containerd|network|dns|syslog|audit|cloud" | head -20
echo

# --- Section 6: Docker containers (if any) ---
echo "=== 6. Docker containers exposing ports ==="
if command -v docker >/dev/null 2>&1; then
  docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Ports}}\t{{.Status}}" 2>/dev/null | head -20
else
  echo "  (docker not installed)"
fi
echo

# --- Section 7: File system anomalies ---
echo "=== 7. Large files in /tmp and /dev/shm ==="
echo "--- /tmp ---"
find /tmp -maxdepth 2 -type f -size +10M -printf '%s\t%p\n' 2>/dev/null | sort -rn | head -10 | \
  awk '{printf "%.1f MB\t%s\n", $1/1024/1024, $2}'
echo "--- /dev/shm ---"
find /dev/shm -maxdepth 2 -type f -size +10M -printf '%s\t%p\n' 2>/dev/null | sort -rn | head -10 | \
  awk '{printf "%.1f MB\t%s\n", $1/1024/1024, $2}'
echo

# --- Section 8: iptables safelist ---
if [ "$SKIP_IPTABLES" != "--skip-iptables" ]; then
  echo "=== 8. iptables INPUT rules (default policy and open ports) ==="
  iptables -L INPUT -n -v --line-numbers 2>/dev/null | head -40 || echo "  (iptables not available)"
  echo
  echo "--- Default policy ---"
  iptables -L INPUT -n 2>/dev/null | grep "Chain INPUT" || true
else
  echo "=== 8. iptables (skipped) ==="
fi
echo

echo "================================================================"
echo "  security_audit complete"
echo "  Red flags to watch:"
echo "    - Unknown services listening on 0.0.0.0 (especially 18080, 8080, etc.)"
echo "    - XMRig/miner processes with high CPU"
echo "    - Processes with deleted executables"
echo "    - Unusual cron jobs or startup scripts"
echo "    - No iptables rules on public-facing services"
echo "  Next: restrict ports to localhost/VPN, kill malicious processes,"
echo "        remove files, and harden firewall rules."
echo "================================================================"