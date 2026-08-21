from __future__ import annotations

import sys
import tarfile
import tempfile
import unittest
from datetime import datetime, timezone
from pathlib import Path


SKILL_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(SKILL_ROOT / "scripts"))

from core.errors import OpsError
from core.kafka_topic_id_repair import build_repair_plan, repair_topic_id_drift
from ecs_ops import build_parser


EXPECTED_TOPIC_ID = "xrXVBj0mTkWj-vYR9QUvHA"
STALE_TOPIC_ID = "c6CAfblUQ4yJfmWRjXF9AA"


def write_partition_metadata(log_dir: Path, topic: str, partition: int, topic_id: str) -> Path:
    metadata_path = log_dir / f"{topic}-{partition}" / "partition.metadata"
    metadata_path.parent.mkdir(parents=True)
    metadata_path.write_text(f"version: 0\ntopic_id: {topic_id}\n", encoding="utf-8")
    return metadata_path


class KafkaTopicIdRepairTest(unittest.TestCase):
    def test_cli_exposes_plan_and_guarded_apply(self) -> None:
        parser = build_parser()
        plan = parser.parse_args(
            [
                "kafka",
                "topic-id",
                "plan",
                "--log-dir",
                "/var/lib/kafka/logs",
                "--expected-topic-id",
                EXPECTED_TOPIC_ID,
            ]
        )
        apply = parser.parse_args(
            [
                "kafka",
                "topic-id",
                "apply",
                "--log-dir",
                "/var/lib/kafka/logs",
                "--expected-topic-id",
                EXPECTED_TOPIC_ID,
                "--backup-dir",
                "/var/backups/kafka",
                "--confirm-topic-id-repair",
            ]
        )

        self.assertEqual("run_kafka_topic_id_plan", plan.func.__name__)
        self.assertEqual("run_kafka_topic_id_apply", apply.func.__name__)
        self.assertTrue(apply.confirm_topic_id_repair)

    def test_plan_only_scans_exact_topic_partitions_and_reports_drift(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            log_dir = Path(temp_dir)
            write_partition_metadata(log_dir, "__consumer_offsets", 0, STALE_TOPIC_ID)
            write_partition_metadata(log_dir, "__consumer_offsets", 1, EXPECTED_TOPIC_ID)
            write_partition_metadata(log_dir, "__consumer_offsets_backup", 0, STALE_TOPIC_ID)

            plan = build_repair_plan(log_dir, "__consumer_offsets", EXPECTED_TOPIC_ID)

            self.assertEqual(2, plan.partition_count)
            self.assertEqual(1, plan.drifted_count)
            self.assertEqual((STALE_TOPIC_ID,), plan.current_topic_ids)
            self.assertEqual((0,), tuple(item.partition for item in plan.drifted))

    def test_apply_requires_explicit_confirmation(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            log_dir = root / "logs"
            write_partition_metadata(log_dir, "__consumer_offsets", 0, STALE_TOPIC_ID)

            with self.assertRaisesRegex(OpsError, "confirm"):
                repair_topic_id_drift(
                    log_dir,
                    "__consumer_offsets",
                    EXPECTED_TOPIC_ID,
                    backup_root=root / "backups",
                    confirmed=False,
                    broker_running=lambda: False,
                )

    def test_apply_refuses_while_kafka_broker_is_running(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            log_dir = root / "logs"
            write_partition_metadata(log_dir, "__consumer_offsets", 0, STALE_TOPIC_ID)

            with self.assertRaisesRegex(OpsError, "running"):
                repair_topic_id_drift(
                    log_dir,
                    "__consumer_offsets",
                    EXPECTED_TOPIC_ID,
                    backup_root=root / "backups",
                    confirmed=True,
                    broker_running=lambda: True,
                )

    def test_apply_backs_up_every_metadata_file_then_updates_drifted_partitions(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            log_dir = root / "logs"
            first = write_partition_metadata(log_dir, "__consumer_offsets", 0, STALE_TOPIC_ID)
            second = write_partition_metadata(log_dir, "__consumer_offsets", 1, STALE_TOPIC_ID)

            result = repair_topic_id_drift(
                log_dir,
                "__consumer_offsets",
                EXPECTED_TOPIC_ID,
                backup_root=root / "backups",
                confirmed=True,
                broker_running=lambda: False,
                now=lambda: datetime(2026, 8, 9, 7, 0, 0, tzinfo=timezone.utc),
            )

            self.assertEqual(2, result.updated_count)
            self.assertTrue(result.backup_path.is_file())
            self.assertIn(f"topic_id: {EXPECTED_TOPIC_ID}", first.read_text(encoding="utf-8"))
            self.assertIn(f"topic_id: {EXPECTED_TOPIC_ID}", second.read_text(encoding="utf-8"))
            with tarfile.open(result.backup_path, "r:gz") as archive:
                names = sorted(archive.getnames())
                self.assertEqual(
                    [
                        "__consumer_offsets-0/partition.metadata",
                        "__consumer_offsets-1/partition.metadata",
                    ],
                    names,
                )
                archived = archive.extractfile(names[0])
                self.assertIsNotNone(archived)
                assert archived is not None
                self.assertIn(STALE_TOPIC_ID, archived.read().decode("utf-8"))

    def test_apply_is_noop_when_all_partitions_match(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            log_dir = root / "logs"
            write_partition_metadata(log_dir, "__consumer_offsets", 0, EXPECTED_TOPIC_ID)

            result = repair_topic_id_drift(
                log_dir,
                "__consumer_offsets",
                EXPECTED_TOPIC_ID,
                backup_root=root / "backups",
                confirmed=True,
                broker_running=lambda: False,
            )

            self.assertEqual(0, result.updated_count)
            self.assertIsNone(result.backup_path)
            self.assertFalse((root / "backups").exists())


if __name__ == "__main__":
    unittest.main()
