from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from core.console import info, print_list
from core.errors import OpsError
from core.io import load_json
from core.mysql_readonly import (
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


def run_query_plan(args) -> int:
    config_path = Path(args.config).expanduser().resolve()
    config = config_section(load_json(config_path), "query")
    info("=== ops-bootstrap data query plan ===", "cyan")
    info(f"config: {config_path}")
    info(f"defaultMode: {config.get('defaultMode', 'readonly')}")
    redis = config.get("redis") or {}
    if redis.get("enabled"):
        info("[redis]", "yellow")
        connection = redis.get("connection") or {}
        if connection:
            info(f"  connection: {connection.get('host')}:{connection.get('port')} db={connection.get('db')} auth={_auth_reference(connection)}")
        print_list("allowed", redis.get("allowedCommands"))
        print_list("denied", redis.get("deniedCommands"))
        print_list("limits", redis.get("limits"))
        print_list("examples", redis.get("examples"))
    elif redis.get("reason"):
        info(f"[redis] disabled: {redis.get('reason')}", "yellow")
    mysql = config.get("mysql") or {}
    if mysql.get("enabled"):
        info("[mysql]", "yellow")
        connection = mysql.get("connection") or {}
        if connection:
            info(
                "  connection: "
                f"{connection.get('host')}:{connection.get('port')}/{connection.get('database')} "
                f"auth={_auth_reference(connection)}"
            )
        connections = mysql.get("connections") or []
        if connections:
            print_list(
                "connections",
                [f"{x.get('name')} database={x.get('database')} auth={_auth_reference(x)}" for x in connections],
            )
        print_list("allowed prefixes", mysql.get("allowedPrefixes"))
        print_list("denied prefixes", mysql.get("deniedPrefixes"))
        print_list("limits", mysql.get("limits"))
    info("QUERY_PLAN_READY readonly=true", "green")
    return 0


def _select_connection(mysql: dict[str, Any], selected: str) -> tuple[str, dict[str, Any]]:
    connections = mysql.get("connections")
    if isinstance(connections, list) and connections:
        candidates = {
            str(item.get("name") or ""): item
            for item in connections
            if isinstance(item, dict) and item.get("name")
        }
        if selected:
            if selected not in candidates:
                raise OpsError(f"missing MySQL connection: {selected}")
            return selected, candidates[selected]
        if len(candidates) != 1:
            raise OpsError("multiple MySQL connections configured; pass --connection")
        return next(iter(candidates.items()))
    connection = mysql.get("connection")
    if not isinstance(connection, dict):
        raise OpsError("missing query.mysql.connection")
    name = str(connection.get("name") or selected or "default")
    if selected and connection.get("name") and selected != connection.get("name"):
        raise OpsError(f"missing MySQL connection: {selected}")
    return name, connection


def _read_sql(args) -> str:
    if getattr(args, "sql", ""):
        return str(args.sql)
    sql_path = Path(str(getattr(args, "sql_file", ""))).expanduser().resolve()
    if not sql_path.is_file():
        raise OpsError(f"SQL file not found: {sql_path}")
    return sql_path.read_text(encoding="utf-8")


def run_query_execute(args) -> int:
    if not getattr(args, "confirm_readonly", False):
        raise OpsError("query run requires --confirm-readonly after reviewing query plan")
    config_path = Path(args.config).expanduser().resolve()
    config = config_section(load_json(config_path), "query")
    if str(config.get("defaultMode") or "readonly").lower() != "readonly":
        raise OpsError("query run only supports defaultMode=readonly")
    mysql = config.get("mysql") or {}
    if not isinstance(mysql, dict) or not mysql.get("enabled"):
        raise OpsError("query.mysql must be enabled")
    connection_name, connection = _select_connection(mysql, str(getattr(args, "connection", "") or ""))
    limits = mysql.get("limits") or {}
    configured_max_rows = int(limits.get("maxRows") or limits.get("defaultLimit") or 100)
    requested_max_rows = getattr(args, "max_rows", None)
    max_rows = int(requested_max_rows or configured_max_rows)
    if max_rows > configured_max_rows:
        raise OpsError(f"--max-rows cannot exceed configured limit {configured_max_rows}")
    timeout_seconds = int(limits.get("timeoutSeconds") or connection.get("timeoutSeconds") or 10)
    allowed = mysql.get("allowedPrefixes")
    denied = mysql.get("deniedPrefixes")
    sql = _read_sql(args)
    validate_readonly_sql(sql, allowed, denied)
    options = resolve_connection_options(connection, config_path)
    result = run_readonly_query(
        options,
        sql,
        max_rows=max_rows,
        timeout_seconds=timeout_seconds,
        redact_columns=mysql.get("redactColumns") or [],
        allowed_prefixes=allowed,
        denied_prefixes=denied,
    )
    payload = {
        "status": "ok",
        "mode": "readonly",
        "connection": connection_name,
        **result.as_dict(),
    }
    info(json.dumps(payload, ensure_ascii=False, default=str))
    return 0
