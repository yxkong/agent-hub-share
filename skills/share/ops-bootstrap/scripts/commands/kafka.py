from __future__ import annotations

import json
from pathlib import Path

from core.console import info
from core.kafka_topic_id_repair import build_repair_plan, repair_topic_id_drift


def run_kafka_topic_id_plan(args) -> int:
    plan = build_repair_plan(Path(args.log_dir), args.topic, args.expected_topic_id)
    info(json.dumps(plan.to_dict(), ensure_ascii=False))
    return 0


def run_kafka_topic_id_apply(args) -> int:
    result = repair_topic_id_drift(
        Path(args.log_dir),
        args.topic,
        args.expected_topic_id,
        backup_root=Path(args.backup_dir),
        confirmed=bool(args.confirm_topic_id_repair),
    )
    info(json.dumps(result.to_dict(), ensure_ascii=False))
    return 0
