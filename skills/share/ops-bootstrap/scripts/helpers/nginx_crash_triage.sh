#!/usr/bin/env bash
# nginx_crash_triage.sh - Diagnose Nginx crash caused by unattended-upgrades.
#
# Scenario: Nginx suddenly stops working, systemd shows failed, but nobody
# manually touched config. Root cause is often unattended-upgrades updating
# nginx or its dependencies (libc, openssl), then needrestart restarting nginx
# without validating config. This script does read-only triage to confirm.
#
# Usage:
#   bash nginx_crash_triage.sh [--since "2 days ago"]
#
# Design principles:
#   - Read-only: never modify, restart, or reload anything.
#   - Portable: POSIX-ish bash, no project-specific paths or credentials.
#   - Self-contained: works on any Debian/Ubuntu host with nginx installed.
set -uo pipefail
trap '' PIPE

SINCE="${1:-2 days ago}"

echo "================================================================"
echo "  nginx_crash_triage.sh  (read-only)"
echo "  host: $(hostname)  date: $(date '+%Y-%m-%d %H:%M:%S %Z')"
echo "================================================================"
echo

# --- Section 1: Current nginx status ---
echo "=== 1. Nginx status ==="
systemctl is-active nginx 2>/dev/null || echo "  nginx is NOT ACTIVE"
systemctl status nginx --no-pager -l 2>/dev/null | head -20
echo

echo "=== 2. Nginx version (check for unexpected changes) ==="
nginx -v 2>&1 || echo "  nginx binary not found or broken"
echo

echo "=== 3. Nginx config test ==="
nginx -t 2>&1
echo

# --- Section 2: unattended-upgrades log ---
echo "=== 4. unattended-upgrades log (apt auto-update) ==="
if [ -f /var/log/unattended-upgrades/unattended-upgrades.log ]; then
  echo "--- Recent entries (since: $SINCE) ---"
  grep -i "nginx\|libc\|libssl\|openssl\|restart\|needrestart" \
    /var/log/unattended-upgrades/unattended-upgrades.log 2>/dev/null | tail -30
  echo
  echo "--- Summary: packages upgraded in last 7 days ---"
  grep "Packages that were upgraded" \
    /var/log/unattended-upgrades/unattended-upgrades.log 2>/dev/null | tail -10
else
  echo "  (unattended-upgrades log not found)"
fi
echo

# --- Section 3: dpkg history ---
echo "=== 5. dpkg recent nginx/libc updates ==="
if [ -f /var/log/dpkg.log ]; then
  grep -E " install | upgrade | remove " /var/log/dpkg.log 2>/dev/null \
    | grep -iE "nginx|libc6|libssl|openssl" | tail -20
else
  echo "  (dpkg log not found)"
fi
echo

# --- Section 4: systemd journal ---
echo "=== 6. systemd journal (nginx unit, since: $SINCE) ==="
journalctl -u nginx --no-pager --since "$SINCE" 2>/dev/null | tail -40
echo

echo "=== 7. apt-daily-upgrade service status ==="
systemctl status apt-daily-upgrade.service --no-pager -l 2>/dev/null | head -10
systemctl is-active apt-daily-upgrade.timer 2>/dev/null && echo "  apt-daily-upgrade.timer: ACTIVE" || echo "  apt-daily-upgrade.timer: not active"
echo

# --- Section 5: process check ---
echo "=== 8. Old nginx master processes (port conflict risk) ==="
ps aux | grep -E "nginx.*master" | grep -v grep || echo "  (no nginx master process)"
echo "--- Port 80/443 listeners ---"
ss -lntp | grep -E ":80 |:443 " || echo "  (no listeners on 80/443)"
echo

# --- Section 6: configuration check ---
echo "=== 9. Auto-upgrade configuration ==="
if [ -f /etc/apt/apt.conf.d/20auto-upgrades ]; then
  echo "--- /etc/apt/apt.conf.d/20auto-upgrades ---"
  cat /etc/apt/apt.conf.d/20auto-upgrades
else
  echo "  (20auto-upgrades not found)"
fi
echo
if [ -f /etc/apt/apt.conf.d/50unattended-upgrades ]; then
  echo "--- /etc/apt/apt.conf.d/50unattended-upgrades (nginx relevant lines) ---"
  grep -iE "nginx|Unattended-Upgrade::" /etc/apt/apt.conf.d/50unattended-upgrades 2>/dev/null | head -20
fi
echo

echo "================================================================"
echo "  nginx_crash_triage complete"
echo "  Likely causes to check:"
echo "    1. unattended-upgrades upgraded nginx -> config test failed -> crash"
echo "    2. libc/openssl upgrade -> needrestart bounced nginx without testing"
echo "    3. Old master process holding port -> systemd can't start new one"
echo "  Fix: verify nginx -t passes, then systemctl restart nginx"
echo "  Prevent: disable unattended-upgrades for nginx, or pin version"
echo "================================================================"