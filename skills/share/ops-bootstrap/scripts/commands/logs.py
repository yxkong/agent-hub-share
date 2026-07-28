from __future__ import annotations

from pathlib import Path

from core.console import info, print_list
from core.io import load_json
from core.sections import config_section


def run_logs_plan(args) -> int:
    config_path = Path(args.config).expanduser().resolve()
    config = config_section(load_json(config_path), "logs")
    info("=== ops-bootstrap log triage plan ===", "cyan")
    info(f"config : {config_path}")
    info(f"target : {config.get('targetName', '<target>')}")
    info(f"service: {config.get('service', '<service>')}")
    window = config.get("timeWindow") or {}
    info(f"window : {window.get('since', '<since>')} -> {window.get('until', '<until>')}")
    sources = config.get("sources") or []
    info("  sources:")
    for source in sources:
        if source.get("type") == "file":
            info(f"    - file {source.get('path')} tail={source.get('tailLines')}")
            print_list("patterns", source.get("patterns"), indent="      ")
        elif source.get("type") == "journalctl":
            info(f"    - journalctl unit={source.get('unit')} since={source.get('since')} lines={source.get('lines')}")
    print_list("correlate", config.get("correlate"))
    print_list("output", config.get("output"))
    info("LOG_TRIAGE_PLAN_READY readonly=true", "green")
    return 0
