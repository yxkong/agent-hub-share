#!/usr/bin/env bash
# disk_triage.sh - Remote read-only disk usage triage script.
#
# Transferred to a target host and executed via SSH (often through a bastion).
# Produces a structured report of disk usage, top directories, oldest files,
# and open file descriptors holding deleted-but-open space.
#
# Usage:
#   bash disk_triage.sh [TARGET_DIR ...]
#
# When no TARGET_DIR is given, reports all local filesystems and then drills
# into the largest mount points automatically.
#
# Design principles (from ops-bootstrap layout_contract.md):
#   - Read-only: never modify, delete, or restart anything.
#   - Portable: plain POSIX-ish bash, no project-specific paths or credentials.
#   - Bounded: `find` scoped to given dirs with depth limits; avoids full-FS walks
#     on huge containerd/kubelet trees unless explicitly requested.
set -uo pipefail
# Do NOT use set -e: find/sort/head pipelines may raise SIGPIPE when head
# closes early, which is expected and must not abort the whole script.
trap '' PIPE

WARN_PERCENT=${DISK_TRIAGE_WARN_PERCENT:-85}
HEAD_LIMIT=${DISK_TRIAGE_HEAD_LIMIT:-15}
FIND_DAYS=${DISK_TRIAGE_FIND_DAYS:-1}

# Targets passed as args; if empty, auto-detect largest mounts.
if [ $# -gt 0 ]; then
  TARGETS=("$@")
else
  TARGETS=()
fi

echo "================================================================"
echo "  disk_triage.sh  (read-only, warn>=${WARN_PERCENT}%)"
echo "  host: $(hostname)  date: $(date '+%Y-%m-%d %H:%M:%S %Z')"
echo "================================================================"
echo

# --- Section 1: filesystem overview ---
echo "=== 1. Filesystem overview (df -h) ==="
df -h
echo

echo "=== 2. Inode overview (df -i) ==="
df -i
echo

# --- Section 2: auto-detect hot mounts if no targets given ---
if [ ${#TARGETS[@]} -eq 0 ]; then
  echo "=== 3. Auto-detecting mounts >= ${WARN_PERCENT}% usage ==="
  # Parse df output, skip header and tmpfs/overlay pseudo filesystems.
  while read -r line; do
    # shellcheck disable=SC2086
    set -- $line
    fs="$1"
    total="$2"
    used="$3"
    avail="$4"
    pct="$5"
    mount="$6"
    # Strip trailing '%' from pct for integer comparison.
    pct_num="${pct%\%}"
    # Skip pseudo filesystems.
    case "$fs" in
      tmpfs|overlay|shm|devtmpfs|none) continue ;;
    esac
    if [ "$pct_num" -ge "$WARN_PERCENT" ] 2>/dev/null; then
      echo "  WARN: ${mount} at ${pct} (${used}/${total}, avail ${avail})"
      TARGETS+=("$mount")
    fi
  done < <(df -h | tail -n +2)
  if [ ${#TARGETS[@]} -eq 0 ]; then
    echo "  (no mounts above ${WARN_PERCENT}%; nothing to drill into)"
    echo
    echo "=== disk_triage complete ==="
    exit 0
  fi
  echo
fi

# --- Section 3: drill into each target ---
for target in "${TARGETS[@]}"; do
  if [ ! -d "$target" ]; then
    echo "=== ${target}: NOT A DIRECTORY, skipping ==="
    echo
    continue
  fi

  echo "================================================================"
  echo "  Drilling into: ${target}"
  echo "================================================================"

  echo "--- Top-level directories (du -sh, maxdepth=1) ---"
  # Use find+du to avoid crossing mount boundaries into NFS/NAS.
  find "$target" -maxdepth 1 -mindepth 1 -type d -print0 2>/dev/null \
    | xargs -0 -r du -sh 2>/dev/null \
    | sort -rh \
    | head -n "$HEAD_LIMIT"
  echo

  echo "--- Top files by size (find, maxdepth=3) ---"
  find "$target" -maxdepth 3 -type f -printf '%s\t%TY-%Tm-%Td\t%p\n' 2>/dev/null \
    | sort -rn \
    | head -n "$HEAD_LIMIT" \
    | awk -F'\t' '{printf "%.1f MB\t%s\t%s\n", $1/1024/1024, $2, $3}'
  echo

  echo "--- Files older than ${FIND_DAYS}d (potential stale data) ---"
  # Count and sum size of files not modified in FIND_DAYS days.
  old_stats=$(find "$target" -maxdepth 4 -type f -mtime +"$FIND_DAYS" -printf '%s\n' 2>/dev/null \
    | awk '{s+=$1; n++} END{if(n>0) printf "%.1f GB\t%d files", s/1024/1024/1024, n; else print "0 GB\t0 files"}')
  echo "  $old_stats"
  echo

  echo "--- File count by modification day (top 10) ---"
  find "$target" -maxdepth 4 -type f -printf '%TY-%Tm-%Td\t%s\n' 2>/dev/null \
    | awk -F'\t' '{cnt[$1]++; sz[$1]+=$2} END{for(d in cnt) printf "%s\t%d files\t%.1f GB\n", d, cnt[d], sz[d]/1024/1024/1024}' \
    | sort -r \
    | head -n 10
  echo

  echo "--- Deleted-but-open files holding space (lsof) ---"
  # Files deleted from disk but still held open by a process.
  lsof +L1 2>/dev/null | head -n "$HEAD_LIMIT" || echo "  (lsof not available or no deleted-but-open files)"
  echo

  echo "--- Processes with open FDs under ${target} ---"
  # Scan /proc/*/fd for processes holding files under target path.
  # Avoids pipelines that can SIGPIPE; uses direct if/grep per pid.
  fd_found=0
  for pid in $(ls /proc 2>/dev/null | grep -E '^[0-9]+$' | head -n 5000); do
    fd_dir="/proc/$pid/fd"
    [ -d "$fd_dir" ] 2>/dev/null || continue
    # readlink is cheaper than ls -l and avoids permission noise
    matches=$(readlink -f "$fd_dir"/* 2>/dev/null | grep -c "$target" || true)
    if [ "$matches" -gt 0 ]; then
      comm=$(cat "/proc/$pid/comm" 2>/dev/null || echo "?")
      echo "  PID=$pid comm=$comm fds=$matches"
      fd_found=1
    fi
  done
  if [ "$fd_found" -eq 0 ]; then
    echo "  (no process holds open files under this path)"
  fi
  echo
done

echo "================================================================"
echo "  disk_triage complete"
echo "  Next steps:"
echo "    - Verify no process holds files before deleting (section: FDs)."
echo "    - Confirm data is stale (section: old files, modification days)."
echo "    - Delete via project runbook, not this read-only script."
echo "================================================================"
