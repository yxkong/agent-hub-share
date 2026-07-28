from __future__ import annotations

from pathlib import Path

from core.console import info, print_list
from core.io import load_json
from core.sections import config_section


def run_connect_plan(args) -> int:
    config_path = Path(args.config).expanduser().resolve()
    config = config_section(load_json(config_path), "connect")
    info("=== ops-bootstrap connect plan ===", "cyan")
    info(f"config : {config_path}")
    info(f"target : {config.get('targetName', '<target>')}")
    print_list("aliases", config.get("aliases"))
    hosts = config.get("hosts") or []
    info("  hosts:")
    for host in hosts:
        info(
            "    - "
            f"{host.get('name')} ip={host.get('ip')} sshHost={host.get('sshHost')} "
            f"user={host.get('sshUser')} rsaConfigured={host.get('rsaConfigured')}"
        )
    services = config.get("services") or []
    info("  services:")
    for service in services:
        info(
            "    - "
            f"{service.get('name')} {service.get('protocol')}://{service.get('host')}:{service.get('port')} "
            f"systemd={service.get('systemd')}"
        )
    print_list("default checks", config.get("defaultChecks"))
    info("CONNECT_PLAN_READY", "green")
    return 0
