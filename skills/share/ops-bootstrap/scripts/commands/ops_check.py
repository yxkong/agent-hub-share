from __future__ import annotations

import subprocess
from pathlib import Path

from core.console import info
from core.io import load_config, resolve_ops_root
from core.ssh import run_command


def run_ops_check(ops_root: Path) -> int:
    config = load_config(ops_root)
    ssh_host = str(config["sshHost"])
    ssh_target = f"{config['remoteUser']}@{config['remoteHost']}"
    remote_path = str(config["remotePath"])
    check_name = str(config.get("opsName") or ops_root.name)
    remote_script_rel = str(config.get("opsCheckScript") or "ops-check.remote.sh")
    remote_script = ops_root / remote_script_rel

    info(f"=== {check_name} ops check ===", "cyan")
    info(f"local : {ops_root}")
    info(f"remote: {ssh_target}:{remote_path}")
    info("")

    info(f"[1/2] SSH alias {ssh_host}", "yellow")
    alias = subprocess.run(
        ["ssh", "-o", "BatchMode=yes", "-o", "ConnectTimeout=10", ssh_host, "echo OK"],
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        check=False,
    )
    if alias.returncode == 0:
        info("  OK", "green")
    else:
        info(f"  FAIL: {alias.stdout.strip()}", "red")
        return 1

    info(f"[2/2] Remote check ({remote_script_rel})", "yellow")
    if not remote_script.exists():
        info(f"  missing {remote_script}", "red")
        info("  copy templates/TEMPLATE_ops-check.remote.sh from ops-bootstrap")
        return 1

    script_text = remote_script.read_text(encoding="utf-8").replace("\r\n", "\n").replace("\r", "\n")
    result = run_command(["ssh", ssh_host, r"sed 's/\r$//' | bash -s"], input_text=script_text)
    if result.returncode != 0:
        info(f"  remote check failed (exit {result.returncode})", "red")
        return result.returncode

    info("")
    info(f"Login: ssh {ssh_host}", "cyan")
    docs = ops_root / "docs" / "server-setup.md"
    if docs.exists():
        info(f"Docs : {docs}")
    return 0


def run_ops_check_from_args(ns) -> int:
    return run_ops_check(resolve_ops_root(ns.ops_root))
