from __future__ import annotations

from pathlib import Path

from core.console import info, print_list
from core.io import load_json
from core.sections import config_section


def run_detect_plan(args) -> int:
    config_path = Path(args.config).expanduser().resolve()
    config = config_section(load_json(config_path), "detect")
    checks = config.get("checks") or {}
    info("=== ops-bootstrap online detection plan ===", "cyan")
    info(f"config: {config_path}")
    info(f"name  : {config.get('name', '<detect>')}")
    print_list("systemd", checks.get("systemd"))
    print_list("pm2", checks.get("pm2"))
    print_list("ports", checks.get("ports"))
    http = checks.get("http") or []
    print_list("http", [f"{x.get('name')} {x.get('url')} expect={x.get('expectStatus')}" for x in http])
    print_list("processes", checks.get("processes"))
    print_list("resources", checks.get("resources"))
    logs = checks.get("logs") or []
    print_list("logs", [f"{x.get('path')} tail={x.get('tailLines')} grep={x.get('grep')}" for x in logs])
    info("DETECT_PLAN_READY", "green")
    return 0
