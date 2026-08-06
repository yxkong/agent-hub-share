from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from core.console import info, print_list
from core.errors import OpsError
from core.io import load_json
from core.mysql_readonly import (
    QueryResult,
    resolve_connection_options,
    run_readonly_query,
    validate_readonly_sql,
)
from core.sections import config_section


def _auth_reference(connection: dict[str, Any]) -> str:
    credentials = connection.get("credentials")
    if isinstance(credentials, dict):
        return str(credentials.get("type") or "missing")
    return str(connection.get("authSource") or "missing")


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
        f"{connection.get('type')}://{connection.get('host')}:{connection.get('port')}/{connection.get('database')} "
        f"auth={_auth_reference(connection)}"
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


def expectation_passes(expectation: str, result: QueryResult) -> bool:
    normalized = str(expectation or "no-error").strip().lower()
    if normalized == "no-error":
        return True
    if normalized == "rows-present":
        return result.row_count > 0
    if normalized == "rows-empty":
        return result.row_count == 0
    raise OpsError(f"unsupported DB check expectation: {expectation}")


def _configured_checks(config: dict[str, Any]) -> list[dict[str, Any]]:
    checks: list[dict[str, Any]] = []
    for schema_check in config.get("schemaChecks") or []:
        if not isinstance(schema_check, dict):
            continue
        table = str(schema_check.get("table") or "schema")
        for index, sql in enumerate(schema_check.get("queries") or [], start=1):
            checks.append(
                {
                    "name": f"schema:{table}:{index}",
                    "group": table,
                    "sql": sql,
                    "expect": "no-error",
                    "maxRows": schema_check.get("maxRows"),
                }
            )
    for data_check in config.get("dataChecks") or []:
        if not isinstance(data_check, dict):
            continue
        checks.append(
            {
                "name": str(data_check.get("name") or "data-check"),
                "group": str(data_check.get("name") or "data-check"),
                "sql": data_check.get("sql"),
                "expect": data_check.get("expect") or "no-error",
                "maxRows": data_check.get("maxRows"),
            }
        )
    return checks


def run_db_execute(args) -> int:
    if not getattr(args, "confirm_readonly", False):
        raise OpsError("db run requires --confirm-readonly after reviewing db plan")
    config_path = Path(args.config).expanduser().resolve()
    config = config_section(load_json(config_path), "dbVerify")
    if str(config.get("mode") or "readonly").lower() != "readonly":
        raise OpsError("db run only supports mode=readonly")
    connection = config.get("connection")
    if not isinstance(connection, dict) or str(connection.get("type") or "mysql").lower() != "mysql":
        raise OpsError("dbVerify.connection.type must be mysql")
    safety = config.get("safety") or {}
    allowed = safety.get("allowedPrefixes")
    denied = safety.get("deniedPrefixes")
    limits = safety.get("limits") or {}
    configured_max_rows = int(limits.get("maxRows") or 100)
    timeout_seconds = int(limits.get("timeoutSeconds") or connection.get("timeoutSeconds") or 10)
    selected = set(getattr(args, "check", None) or [])
    checks = _configured_checks(config)
    if selected:
        checks = [check for check in checks if check["name"] in selected or check["group"] in selected]
    if not checks:
        raise OpsError("no DB checks selected or configured")
    options = resolve_connection_options(connection, config_path)
    failed = False
    for check in checks:
        sql = str(check.get("sql") or "")
        validate_readonly_sql(sql, allowed, denied)
        check_max_rows = min(int(check.get("maxRows") or configured_max_rows), configured_max_rows)
        result = run_readonly_query(
            options,
            sql,
            max_rows=check_max_rows,
            timeout_seconds=timeout_seconds,
            redact_columns=safety.get("redactColumns") or [],
            allowed_prefixes=allowed,
            denied_prefixes=denied,
        )
        passed = expectation_passes(str(check.get("expect") or "no-error"), result)
        failed = failed or not passed
        payload = {
            "status": "pass" if passed else "fail",
            "mode": "readonly",
            "check": check["name"],
            "expect": check["expect"],
            **result.as_dict(),
        }
        info(json.dumps(payload, ensure_ascii=False, default=str))
    return 1 if failed else 0
