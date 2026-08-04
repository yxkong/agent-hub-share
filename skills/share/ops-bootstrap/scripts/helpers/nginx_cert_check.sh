#!/usr/bin/env bash
# nginx_cert_check.sh - Read-only TLS certificate and OCSP health check.
#
# Scenario: SSL errors in nginx error.log, OCSP stapling failures,
# expiring certificates. This script checks certificate validity, OCSP
# responder reachability, and SSL stapling error counts.
#
# Usage:
#   bash nginx_cert_check.sh [--cert-dir /etc/nginx/ssl] [--error-log /var/log/nginx/error.log]
#
# Design principles:
#   - Read-only: never modify, restart, or reload anything.
#   - Portable: POSIX-ish bash, no project-specific paths or credentials.
set -uo pipefail
trap '' PIPE

CERT_DIR="${NGINX_CERT_CHECK_DIR:-/etc/nginx/ssl}"
ERROR_LOG="${NGINX_CERT_CHECK_LOG:-/var/log/nginx/error.log}"

# Override from args
while [ $# -gt 0 ]; do
  case "$1" in
    --cert-dir) CERT_DIR="$2"; shift 2 ;;
    --error-log) ERROR_LOG="$2"; shift 2 ;;
    *) shift ;;
  esac
done

echo "================================================================"
echo "  nginx_cert_check.sh  (read-only)"
echo "  host: $(hostname)  date: $(date '+%Y-%m-%d %H:%M:%S %Z')"
echo "================================================================"
echo

# --- Section 1: OCSP stapling errors in nginx error log ---
echo "=== 1. OCSP stapling errors in error log ==="
if [ -f "$ERROR_LOG" ]; then
  ocsp_count=$(grep -ci "OCSP" "$ERROR_LOG" 2>/dev/null || echo 0)
  echo "  OCSP error lines: $ocsp_count"
  if [ "$ocsp_count" -gt 0 ] 2>/dev/null; then
    echo "--- Sample OCSP errors (last 10) ---"
    grep -i "OCSP" "$ERROR_LOG" 2>/dev/null | tail -10
  fi
else
  echo "  (error log not found: $ERROR_LOG)"
fi
echo

# --- Section 2: SSL stapling config ---
echo "=== 2. SSL stapling configuration ==="
echo "--- Checking for ssl_stapling on in nginx config ---"
if command -v nginx >/dev/null 2>&1; then
  nginx -T 2>/dev/null | grep -A2 "ssl_stapling" | head -30 || echo "  (ssl_stapling not configured)"
else
  echo "  (nginx not installed)"
fi
echo

# --- Section 3: Certificate validity ---
echo "=== 3. Certificate validity (certs in $CERT_DIR) ==="
if [ -d "$CERT_DIR" ]; then
  find "$CERT_DIR" -maxdepth 2 \( -name "*.crt" -o -name "*.pem" -o -name "*.cert" \) 2>/dev/null | while read -r cert; do
    if [ -f "$cert" ]; then
      echo "--- $cert ---"
      openssl x509 -in "$cert" -noout -subject -dates -issuer 2>/dev/null || echo "  (invalid or unreadable cert)"
      echo
    fi
  done
else
  echo "  (cert directory not found: $CERT_DIR)"
  echo "  Searching common paths..."
  find /etc/nginx /etc/ssl -maxdepth 3 \( -name "*.crt" -o -name "*.pem" \) 2>/dev/null | head -20
fi
echo

# --- Section 4: OCSP responder reachability ---
echo "=== 4. OCSP responder reachability test ==="
if [ -d "$CERT_DIR" ]; then
  find "$CERT_DIR" -maxdepth 2 \( -name "*.crt" -o -name "*.pem" -o -name "*.cert" \) 2>/dev/null | head -5 | while read -r cert; do
    if [ -f "$cert" ]; then
      ocsp_url=$(openssl x509 -in "$cert" -noout -ocsp_uri 2>/dev/null)
      if [ -n "$ocsp_url" ]; then
        echo "--- $cert -> $ocsp_url ---"
        curl -s --connect-timeout 5 --max-time 10 "$ocsp_url" -o /dev/null -w "  HTTP %{http_code}  time %{time_total}s\n" 2>/dev/null || echo "  (OCSP responder unreachable)"
      fi
    fi
  done
else
  echo "  (no certs to check)"
fi
echo

# --- Section 5: SSL error summary ---
echo "=== 5. SSL/TLS error summary in error log ==="
if [ -f "$ERROR_LOG" ]; then
  echo "--- SSL/TLS error counts ---"
  grep -iE "SSL|TLS" "$ERROR_LOG" 2>/dev/null | \
    awk '{for(i=1;i<=NF;i++) if($i~/SSL|TLS/){print $i}}' | \
    sort | uniq -c | sort -rn | head -15
  echo
  echo "--- Recent SSL errors (last 10) ---"
  grep -iE "SSL|TLS" "$ERROR_LOG" 2>/dev/null | tail -10
else
  echo "  (error log not found)"
fi
echo

echo "================================================================"
echo "  nginx_cert_check complete"
echo "  Common issues:"
echo "    - ssl_stapling on + no external OCSP responder = error flood"
echo "    - Fix: set ssl_stapling off if server can't reach internet CA"
echo "    - Expiring certs: renew before notAfter date"
echo "    - Self-signed or internal CA: disable OCSP stapling"
echo "================================================================"