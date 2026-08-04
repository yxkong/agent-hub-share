#!/usr/bin/env bash
# nginx_drift_check.sh - Compare Nginx config across multiple hosts.
#
# Scenario: Multiple Nginx nodes serving the same traffic, but config
# files have drifted (whitespace, different edits, missing updates).
# This script compares config file checksums across hosts.
#
# Usage:
#   bash nginx_drift_check.sh <host1> <host2> [host3 ...]
#
# Hosts should be SSH-reachable (BatchMode). The script compares
# /etc/nginx/conf.d/*.conf and /etc/nginx/nginx.conf across all hosts.
#
# Design principles:
#   - Read-only: never modify, sync, or push config.
#   - Portable: POSIX-ish bash, no project-specific paths or credentials.
set -uo pipefail
trap '' PIPE

if [ $# -lt 2 ]; then
  echo "Usage: bash nginx_drift_check.sh <host1> <host2> [host3 ...]"
  echo "  Hosts should be SSH-accessible with BatchMode."
  exit 1
fi

HOSTS=("$@")
NGINX_DIR="${NGINX_DRIFT_DIR:-/etc/nginx}"
CONF_DIR="${NGINX_DRIFT_CONF_DIR:-$NGINX_DIR/conf.d}"

echo "================================================================"
echo "  nginx_drift_check.sh  (read-only)"
echo "  date: $(date '+%Y-%m-%d %H:%M:%S %Z')"
echo "  hosts: ${HOSTS[*]}"
echo "  config: ${CONF_DIR}"
echo "================================================================"
echo

# --- Section 1: Host reachability ---
echo "=== 1. Host reachability ==="
for host in "${HOSTS[@]}"; do
  if ssh -o BatchMode=yes -o ConnectTimeout=5 "$host" "hostname" 2>/dev/null; then
    echo "  $host: OK"
  else
    echo "  $host: UNREACHABLE"
  fi
done
echo

# --- Section 2: Nginx version comparison ---
echo "=== 2. Nginx versions ==="
for host in "${HOSTS[@]}"; do
  ver=$(ssh -o BatchMode=yes -o ConnectTimeout=5 "$host" "nginx -v 2>&1" 2>/dev/null || echo "ERROR")
  echo "  $host: $ver"
done
echo

# --- Section 3: nginx.conf checksum ---
echo "=== 3. nginx.conf checksum ==="
for host in "${HOSTS[@]}"; do
  sum=$(ssh -o BatchMode=yes -o ConnectTimeout=5 "$host" "md5sum $NGINX_DIR/nginx.conf 2>/dev/null | cut -d' ' -f1" 2>/dev/null || echo "N/A")
  echo "  $host: $sum"
done
echo

# --- Section 4: config file count ---
echo "=== 4. Config file count (conf.d) ==="
for host in "${HOSTS[@]}"; do
  count=$(ssh -o BatchMode=yes -o ConnectTimeout=5 "$host" "find $CONF_DIR -name '*.conf' -type f 2>/dev/null | wc -l" 2>/dev/null || echo "N/A")
  echo "  $host: $count files"
done
echo

# --- Section 5: file list comparison ---
echo "=== 5. File list comparison ==="
declare -A all_files
for host in "${HOSTS[@]}"; do
  files=$(ssh -o BatchMode=yes -o ConnectTimeout=5 "$host" "find $CONF_DIR -name '*.conf' -type f -printf '%P\n' 2>/dev/null | sort" 2>/dev/null)
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    all_files["$f"]=1
  done <<< "$files"
done

echo "--- Files present on some but not all hosts ---"
for f in $(printf "%s\n" "${!all_files[@]}" | sort); do
  present=()
  missing=()
  for host in "${HOSTS[@]}"; do
    if ssh -o BatchMode=yes -o ConnectTimeout=5 "$host" "test -f $CONF_DIR/$f" 2>/dev/null; then
      present+=("$host")
    else
      missing+=("$host")
    fi
  done
  if [ ${#missing[@]} -gt 0 ] && [ ${#missing[@]} -lt ${#HOSTS[@]} ]; then
    echo "  PARTIAL: $f"
    echo "    present: ${present[*]}"
    echo "    missing: ${missing[*]}"
  fi
done
echo

# --- Section 6: content diff for common files ---
echo "=== 6. Content checksum comparison (files with mismatches) ==="
drift_count=0
for f in $(printf "%s\n" "${!all_files[@]}" | sort); do
  declare -A sums=()
  for host in "${HOSTS[@]}"; do
    sum=$(ssh -o BatchMode=yes -o ConnectTimeout=5 "$host" "md5sum $CONF_DIR/$f 2>/dev/null | cut -d' ' -f1" 2>/dev/null || echo "N/A")
    sums["$host"]="$sum"
  done
  unique=$(printf "%s\n" "${sums[@]}" | sort -u | wc -l)
  if [ "$unique" -gt 1 ]; then
    drift_count=$((drift_count + 1))
    echo "  DRIFT: $f"
    for host in "${HOSTS[@]}"; do
      echo "    $host: ${sums[$host]}"
    done
    echo
  fi
done

if [ "$drift_count" -eq 0 ]; then
  echo "  (all files match across hosts)"
fi
echo

# --- Section 7: recent config changes ---
echo "=== 7. Recent config modifications (last 7 days) ==="
for host in "${HOSTS[@]}"; do
  echo "--- $host ---"
  ssh -o BatchMode=yes -o ConnectTimeout=5 "$host" \
    "find $CONF_DIR -name '*.conf' -type f -mtime -7 -printf '%TY-%Tm-%Td %TH:%TM %p\n' 2>/dev/null | sort -r" 2>/dev/null | head -15
  echo
done

echo "================================================================"
echo "  nginx_drift_check complete"
echo "  Drift files found: $drift_count"
echo "  Next steps:"
echo "    - Align: choose canonical host, diff, and sync"
echo "    - Prevent: always edit on control hub, push to nodes"
echo "    - Run regularly: schedule this script as a cron job"
echo "================================================================"