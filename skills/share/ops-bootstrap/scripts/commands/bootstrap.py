from __future__ import annotations

import re
import sys
from pathlib import Path

from commands.ops_check import run_ops_check
from core.console import info
from core.errors import OpsError
from core.io import load_config, resolve_ops_root
from core.ssh import (
    DEFAULT_IDENTITY_FILE,
    DEFAULT_MARKER,
    expand_home_path,
    install_ssh_config_block,
    run_command,
    ssh_config_path,
    test_ssh_batch,
)


SCRIPT_DIR = Path(__file__).resolve().parents[1]


def read_account_credentials(config: dict, account_file: Path) -> dict[str, str] | None:
    if not account_file.exists():
        return None
    account = {
        "host": str(config.get("remoteHost", "")),
        "user": str(config.get("remoteUser", "")),
        "password": "",
    }
    for line in account_file.read_text(encoding="utf-8").splitlines():
        if match := re.match(r"^\s*ip\s*[:：]\s*(.+?)\s*$", line, re.I):
            account["host"] = match.group(1).strip()
        elif match := re.match(r"^\s*账户\s*[:：]\s*(.+?)\s*$", line):
            account["user"] = match.group(1).strip()
        elif match := re.match(r"^\s*密码\s*[:：]\s*(.+?)\s*$", line):
            account["password"] = match.group(1).strip()
    if not account["password"]:
        return None
    return account


def deploy_public_key(*, config: dict, ops_root: Path, public_key_file: Path) -> None:
    account_name = str(config.get("accountFile") or "account.md")
    account_file = ops_root / account_name
    cred = read_account_credentials(config, account_file)
    if not cred:
        raise OpsError(f"missing or invalid {account_file}")

    setup_script = SCRIPT_DIR / "setup_ssh_key.py"
    result = run_command(
        [
            sys.executable,
            str(setup_script),
            "--host",
            cred["host"],
            "--user",
            cred["user"],
            "--password",
            cred["password"],
            "--pub-key",
            str(public_key_file),
        ]
    )
    if result.returncode != 0:
        raise SystemExit(result.returncode)


def run_bootstrap(args) -> int:
    ops_root = resolve_ops_root(args.ops_root)
    config = load_config(ops_root)
    marker = str(config.get("sshMarker") or DEFAULT_MARKER)
    identity_value = args.identity_file or str(config.get("identityFile") or DEFAULT_IDENTITY_FILE)
    identity_file = expand_home_path(identity_value)
    public_key_file = Path(str(identity_file) + ".pub")

    info("=== ops-bootstrap ===", "cyan")
    info(f"ops   : {ops_root}")
    info(f"remote: {config['remoteUser']}@{config['remoteHost']}:{config['remotePath']}")
    info("")

    info("[1/4] SSH key", "yellow")
    if not identity_file.exists():
        raise OpsError(f"missing private key: {identity_file}\n  copy key or pass --identity-file, then rerun")
    if not public_key_file.exists():
        raise OpsError(f"missing public key: {public_key_file}")
    info(f"  key: {identity_file}", "green")

    info(f"[2/4] SSH alias {config['sshHost']}", "yellow")
    install_ssh_config_block(
        config_path=ssh_config_path(),
        marker=marker,
        host_alias=str(config["sshHost"]),
        host_name=str(config["remoteHost"]),
        user=str(config["remoteUser"]),
        key_path=identity_file,
        force=args.force,
    )
    if config.get("sshHostApp") and config.get("opsAppUser"):
        install_ssh_config_block(
            config_path=ssh_config_path(),
            marker=marker,
            host_alias=str(config["sshHostApp"]),
            host_name=str(config["remoteHost"]),
            user=str(config["opsAppUser"]),
            key_path=identity_file,
            force=args.force,
        )

    info("[3/4] connectivity", "yellow")
    if test_ssh_batch(str(config["sshHost"])):
        info("  key auth OK", "green")
    else:
        info("  key auth failed, deploying public key...", "yellow")
        if args.skip_key_deploy:
            raise OpsError("--skip-key-deploy set; configure authorized_keys manually")
        deploy_public_key(config=config, ops_root=ops_root, public_key_file=public_key_file)
        if not test_ssh_batch(str(config["sshHost"])):
            raise OpsError("still cannot connect after key deploy")
        info("  key deploy OK", "green")

    if args.skip_ops_check:
        info("[4/4] ops-check skipped", "yellow")
    else:
        info("[4/4] remote services", "yellow")
        status = run_ops_check(ops_root)
        if status != 0:
            return status

    info("")
    info("Bootstrap done.", "green")
    info(f"  login: ssh {config['sshHost']}")
    if config.get("sshHostApp"):
        info(f"  login app: ssh {config['sshHostApp']}")
    info("  check: ops-check --ops-root <ops-dir>")
    return 0
