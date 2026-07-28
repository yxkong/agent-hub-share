from __future__ import annotations

from pathlib import Path

from core.console import info, print_list
from core.io import load_json
from core.sections import config_section


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
            info(f"  connection: {connection.get('host')}:{connection.get('port')} db={connection.get('db')} auth={connection.get('authSource')}")
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
                f"auth={connection.get('authSource')}"
            )
        connections = mysql.get("connections") or []
        if connections:
            print_list(
                "connections",
                [f"{x.get('name')} database={x.get('database')} auth={x.get('authSource')}" for x in connections],
            )
        print_list("allowed prefixes", mysql.get("allowedPrefixes"))
        print_list("denied prefixes", mysql.get("deniedPrefixes"))
        print_list("limits", mysql.get("limits"))
    info("QUERY_PLAN_READY readonly=true", "green")
    return 0
