#!/usr/bin/env python3
"""Deploy local SSH public key to remote server (one-time bootstrap)."""
from __future__ import annotations

import argparse
import sys

try:
    import paramiko
except ImportError:
    print("ERROR: pip install paramiko", file=sys.stderr)
    sys.exit(1)


def main() -> int:
    p = argparse.ArgumentParser(description="Deploy SSH public key to remote server")
    p.add_argument("--host", required=True)
    p.add_argument("--user", default="root")
    p.add_argument("--password", required=True)
    p.add_argument("--pub-key", required=True, help="Path to .pub file")
    args = p.parse_args()

    pub_key = open(args.pub_key, encoding="utf-8").read().strip()
    fingerprint = pub_key.split()[1]

    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    client.connect(args.host, username=args.user, password=args.password, timeout=15)

    cmds = [
        "mkdir -p ~/.ssh && chmod 700 ~/.ssh",
        f"grep -qF '{fingerprint}' ~/.ssh/authorized_keys 2>/dev/null || echo '{pub_key}' >> ~/.ssh/authorized_keys",
        "chmod 600 ~/.ssh/authorized_keys",
    ]
    for cmd in cmds:
        _, stdout, stderr = client.exec_command(cmd, timeout=20)
        err = stderr.read().decode()
        if err.strip():
            print(err, file=sys.stderr)
    client.close()
    print("OK: public key deployed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
