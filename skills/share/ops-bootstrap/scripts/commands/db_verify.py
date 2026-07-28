from __future__ import annotations

from pathlib import Path

from core.console import info, print_list
from core.io import load_json
from core.sections import config_section


def run_db_plan(args) -> int:
    config_path = Path(args.config).expanduser().resolve()
    config = config_section(load_json(config_path), "dbVerify")
    connection = config.get("connection") or {}
    info("=== ops-bootstrap db verify plan ===", "cyan")
    info(f"config : {config_path}")
    info(f"target : {config.get('targetName', '<target>')}")
    info(f"mode   : {config.get('mode', 'readonly')}")
    info(
        "connection: "
        f"{connection.get('type')}://{connection.get('host')}:{connection.get('port')}/{connection.get('database')}"
    )
    local_code = config.get("localCode") or {}
    info(f"local code root: {local_code.get('root', '.')}")
    print_list("include", local_code.get("include"))
    schema_checks = config.get("schemaChecks") or []
    info("  schema checks:")
    for check in schema_checks:
        info(f"    - table={check.get('table')} expectedColumnsFromCode={check.get('expectedColumnsFromCode')}")
        print_list("queries", check.get("queries"), indent="      ")
    data_checks = config.get("dataChecks") or []
    info("  data checks:")
    for check in data_checks:
        info(f"    - {check.get('name')} expect={check.get('expect')} maxRows={check.get('maxRows')}")
        info(f"      sql: {check.get('sql')}")
    safety = config.get("safety") or {}
    print_list("allowed prefixes", safety.get("allowedPrefixes"))
    print_list("redact columns", safety.get("redactColumns"))
    info("DB_VERIFY_PLAN_READY readonly=true", "green")
    return 0
