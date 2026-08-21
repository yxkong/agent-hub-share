#!/usr/bin/env python3
"""ops-bootstrap CLI router.

Command implementations live under scripts/commands and shared helpers under
scripts/core. Keep this file as a stable thin entrypoint for ps1/sh wrappers.
"""
from __future__ import annotations

import argparse

from commands.bootstrap import run_bootstrap
from commands.connect import run_connect_plan
from commands.db_verify import run_db_execute, run_db_plan
from commands.deploy import run_deploy_plan
from commands.detect import run_detect_plan
from commands.local_port import run_local_free_port
from commands.kafka import run_kafka_topic_id_apply, run_kafka_topic_id_plan
from commands.logs import run_logs_plan
from commands.ops_check import run_ops_check_from_args
from commands.provision import run_provision_plan
from commands.query import run_query_execute, run_query_plan
from core.console import info
from core.errors import OpsError


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Cross-platform ops bootstrap")
    sub = parser.add_subparsers(dest="command", required=True)

    bootstrap = sub.add_parser("bootstrap", help="write SSH alias, deploy key when needed, and run ops-check")
    bootstrap.add_argument("--ops-root", required=True, help="ops directory containing sync.config.json")
    bootstrap.add_argument("--identity-file", default="", help="private key path; defaults to sync.config.json identityFile")
    bootstrap.add_argument("--skip-key-deploy", action="store_true")
    bootstrap.add_argument("--force", action="store_true", help="overwrite managed SSH config blocks")
    bootstrap.add_argument("--skip-ops-check", action="store_true")
    bootstrap.set_defaults(func=run_bootstrap)

    check = sub.add_parser("ops-check", help="run project remote health check through SSH")
    check.add_argument("--ops-root", required=True, help="ops directory containing sync.config.json")
    check.set_defaults(func=run_ops_check_from_args)

    connect = sub.add_parser("connect", help="plan target connection and service inventory")
    connect_sub = connect.add_subparsers(dest="connect_command", required=True)
    connect_plan = connect_sub.add_parser("plan", help="print host aliases, services, and default checks")
    connect_plan.add_argument("--config", required=True, help="target config JSON")
    connect_plan.set_defaults(func=run_connect_plan)

    provision = sub.add_parser("provision", help="plan/check/apply environment provisioning")
    provision_sub = provision.add_subparsers(dest="provision_command", required=True)
    plan = provision_sub.add_parser("plan", help="print online commands and offline artifact requirements")
    plan.add_argument("--ops-root", default="", help="ops directory containing sync.config.json")
    plan.add_argument("--config", default="", help="environment.config.json path; useful for validating templates")
    plan.add_argument("--module", action="append", help="module to include; repeatable")
    plan.add_argument("--mode", choices=("auto", "online", "offline"), default="", help="override networkMode")
    plan.set_defaults(func=run_provision_plan)

    deploy = sub.add_parser("deploy", help="plan deployment with profiles and hooks")
    deploy_sub = deploy.add_subparsers(dest="deploy_command", required=True)
    deploy_plan = deploy_sub.add_parser("plan", help="print deployment steps without remote changes")
    deploy_plan.add_argument("--config", required=True, help="deploy config JSON")
    deploy_plan.add_argument("--name", default="", help="named deploy entry when using project ops.config.json")
    deploy_plan.set_defaults(func=run_deploy_plan)

    detect = sub.add_parser("detect", help="plan online service detection")
    detect_sub = detect.add_subparsers(dest="detect_command", required=True)
    detect_plan = detect_sub.add_parser("plan", help="print online detection checks")
    detect_plan.add_argument("--config", required=True, help="online detection config JSON")
    detect_plan.set_defaults(func=run_detect_plan)

    query = sub.add_parser("query", help="plan read-only data queries")
    query_sub = query.add_subparsers(dest="query_command", required=True)
    query_plan = query_sub.add_parser("plan", help="print query allowlist and limits")
    query_plan.add_argument("--config", required=True, help="query config JSON")
    query_plan.set_defaults(func=run_query_plan)
    query_run = query_sub.add_parser("run", help="execute one guarded MySQL readonly query")
    query_run.add_argument("--config", required=True, help="query config JSON")
    query_sql = query_run.add_mutually_exclusive_group(required=True)
    query_sql.add_argument("--sql", default="", help="one explicit readonly SQL statement")
    query_sql.add_argument("--sql-file", default="", help="UTF-8 file containing one readonly SQL statement")
    query_run.add_argument("--connection", default="", help="named MySQL connection when multiple are configured")
    query_run.add_argument("--max-rows", type=int, default=None, help="lower result cap; cannot exceed config")
    query_run.add_argument("--confirm-readonly", action="store_true", help="confirm plan review and readonly execution")
    query_run.set_defaults(func=run_query_execute)

    logs = sub.add_parser("logs", help="plan service log triage")
    logs_sub = logs.add_subparsers(dest="logs_command", required=True)
    logs_plan = logs_sub.add_parser("plan", help="print log sources, patterns, and correlation checks")
    logs_plan.add_argument("--config", required=True, help="log triage config JSON")
    logs_plan.set_defaults(func=run_logs_plan)

    db = sub.add_parser("db", help="plan database schema and data verification")
    db_sub = db.add_subparsers(dest="db_command", required=True)
    db_plan = db_sub.add_parser("plan", help="print database schema/data verification checks")
    db_plan.add_argument("--config", required=True, help="database verification config JSON")
    db_plan.set_defaults(func=run_db_plan)
    db_run = db_sub.add_parser("run", help="execute configured guarded MySQL readonly checks")
    db_run.add_argument("--config", required=True, help="database verification config JSON")
    db_run.add_argument("--check", action="append", help="check name or group to run; repeatable")
    db_run.add_argument("--confirm-readonly", action="store_true", help="confirm plan review and readonly execution")
    db_run.set_defaults(func=run_db_execute)

    local = sub.add_parser("local", help="local workstation helpers (no remote SSH)")
    local_sub = local.add_subparsers(dest="local_command", required=True)
    free_port = local_sub.add_parser(
        "free-port",
        help="kill leftover listeners on a local TCP port (uvicorn / WinError 10013)",
    )
    free_port.add_argument("--port", type=int, default=9100, help="TCP port (default: 9100)")
    free_port.add_argument(
        "--match",
        default="uvicorn|main:app",
        help="also kill processes whose cmdline matches this regex; empty to disable",
    )
    free_port.add_argument("--dry-run", action="store_true", help="only print candidates")
    free_port.add_argument(
        "--probe",
        action="store_true",
        help="compatibility flag; bind probe always runs after free",
    )
    free_port.add_argument("--retries", type=int, default=3, help="kill/recheck rounds")
    free_port.set_defaults(func=run_local_free_port)

    kafka = sub.add_parser("kafka", help="guarded Kafka broker diagnostics and repair")
    kafka_sub = kafka.add_subparsers(dest="kafka_command", required=True)
    topic_id = kafka_sub.add_parser("topic-id", help="plan or repair partition topic ID drift")
    topic_id_sub = topic_id.add_subparsers(dest="kafka_topic_id_command", required=True)
    topic_id_plan = topic_id_sub.add_parser("plan", help="scan exact topic partitions without changes")
    topic_id_plan.add_argument("--log-dir", required=True, help="Kafka log.dirs path")
    topic_id_plan.add_argument("--topic", default="__consumer_offsets", help="exact Kafka topic name")
    topic_id_plan.add_argument("--expected-topic-id", required=True, help="topic ID from cluster metadata")
    topic_id_plan.set_defaults(func=run_kafka_topic_id_plan)
    topic_id_apply = topic_id_sub.add_parser("apply", help="backup and atomically repair drifted metadata")
    topic_id_apply.add_argument("--log-dir", required=True, help="Kafka log.dirs path")
    topic_id_apply.add_argument("--topic", default="__consumer_offsets", help="exact Kafka topic name")
    topic_id_apply.add_argument("--expected-topic-id", required=True, help="topic ID from cluster metadata")
    topic_id_apply.add_argument("--backup-dir", required=True, help="directory for metadata tar.gz backup")
    topic_id_apply.add_argument(
        "--confirm-topic-id-repair",
        action="store_true",
        help="confirm the broker is stopped and the reviewed plan may be applied",
    )
    topic_id_apply.set_defaults(func=run_kafka_topic_id_apply)

    return parser


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    try:
        return int(args.func(args))
    except OpsError as exc:
        info(str(exc), "red")
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
