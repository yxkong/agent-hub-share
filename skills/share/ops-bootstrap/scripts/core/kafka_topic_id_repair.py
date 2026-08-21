from __future__ import annotations

import os
import re
import tarfile
import tempfile
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Callable

from core.errors import OpsError


_TOPIC_PATTERN = re.compile(r"[A-Za-z0-9._-]+")
_TOPIC_ID_PATTERN = re.compile(r"[A-Za-z0-9_-]{22}")


@dataclass(frozen=True)
class PartitionTopicId:
    partition: int
    metadata_path: Path
    current_topic_id: str


@dataclass(frozen=True)
class TopicIdRepairPlan:
    log_dir: Path
    topic: str
    expected_topic_id: str
    partitions: tuple[PartitionTopicId, ...]
    drifted: tuple[PartitionTopicId, ...]

    @property
    def partition_count(self) -> int:
        return len(self.partitions)

    @property
    def drifted_count(self) -> int:
        return len(self.drifted)

    @property
    def current_topic_ids(self) -> tuple[str, ...]:
        return tuple(sorted({item.current_topic_id for item in self.drifted}))

    def to_dict(self) -> dict[str, object]:
        return {
            "action": "plan",
            "logDir": str(self.log_dir),
            "topic": self.topic,
            "expectedTopicId": self.expected_topic_id,
            "partitionCount": self.partition_count,
            "driftedCount": self.drifted_count,
            "currentTopicIds": list(self.current_topic_ids),
            "driftedPartitions": [item.partition for item in self.drifted],
        }


@dataclass(frozen=True)
class TopicIdRepairResult:
    topic: str
    expected_topic_id: str
    updated_count: int
    backup_path: Path | None

    def to_dict(self) -> dict[str, object]:
        return {
            "action": "apply",
            "topic": self.topic,
            "expectedTopicId": self.expected_topic_id,
            "updatedCount": self.updated_count,
            "backupPath": str(self.backup_path) if self.backup_path else None,
        }


def _validate_inputs(log_dir: Path, topic: str, expected_topic_id: str) -> Path:
    if not _TOPIC_PATTERN.fullmatch(topic) or topic in {".", ".."}:
        raise OpsError(f"invalid Kafka topic name: {topic!r}")
    if not _TOPIC_ID_PATTERN.fullmatch(expected_topic_id):
        raise OpsError("expected topic ID must be a 22-character Kafka UUID")
    resolved_log_dir = log_dir.expanduser().resolve()
    if not resolved_log_dir.is_dir():
        raise OpsError(f"Kafka log directory does not exist: {resolved_log_dir}")
    return resolved_log_dir


def _read_topic_id(metadata_path: Path) -> str:
    try:
        lines = metadata_path.read_text(encoding="utf-8").splitlines()
    except OSError as exc:
        raise OpsError(f"cannot read Kafka partition metadata: {metadata_path}: {exc}") from exc
    values = [line.split(":", 1)[1].strip() for line in lines if line.startswith("topic_id:")]
    if len(values) != 1 or not _TOPIC_ID_PATTERN.fullmatch(values[0]):
        raise OpsError(f"invalid topic_id entry in {metadata_path}")
    return values[0]


def build_repair_plan(log_dir: Path | str, topic: str, expected_topic_id: str) -> TopicIdRepairPlan:
    resolved_log_dir = _validate_inputs(Path(log_dir), topic, expected_topic_id)
    partition_pattern = re.compile(rf"{re.escape(topic)}-(\d+)")
    partitions: list[PartitionTopicId] = []
    for candidate in resolved_log_dir.iterdir():
        match = partition_pattern.fullmatch(candidate.name)
        if not match or not candidate.is_dir():
            continue
        metadata_path = candidate / "partition.metadata"
        if not metadata_path.is_file():
            raise OpsError(f"missing Kafka partition metadata: {metadata_path}")
        partitions.append(
            PartitionTopicId(
                partition=int(match.group(1)),
                metadata_path=metadata_path,
                current_topic_id=_read_topic_id(metadata_path),
            )
        )
    partitions.sort(key=lambda item: item.partition)
    if not partitions:
        raise OpsError(f"no partitions found for Kafka topic {topic!r} under {resolved_log_dir}")
    drifted = tuple(item for item in partitions if item.current_topic_id != expected_topic_id)
    return TopicIdRepairPlan(
        log_dir=resolved_log_dir,
        topic=topic,
        expected_topic_id=expected_topic_id,
        partitions=tuple(partitions),
        drifted=drifted,
    )


def kafka_broker_is_running() -> bool:
    proc_root = Path("/proc")
    if os.name != "posix" or not proc_root.is_dir():
        raise OpsError("Kafka broker process guard requires a POSIX /proc filesystem")
    for proc_dir in proc_root.iterdir():
        if not proc_dir.name.isdigit():
            continue
        try:
            cmdline = (proc_dir / "cmdline").read_bytes().replace(b"\0", b" ").decode("utf-8", "ignore")
        except (OSError, PermissionError):
            continue
        if "kafka.Kafka" in cmdline:
            return True
    return False


def _create_backup(plan: TopicIdRepairPlan, backup_root: Path, now: datetime) -> Path:
    resolved_backup_root = backup_root.expanduser().resolve()
    resolved_backup_root.mkdir(parents=True, exist_ok=True)
    timestamp = now.astimezone(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    final_path = resolved_backup_root / f"{plan.topic}-partition-metadata-{timestamp}.tar.gz"
    if final_path.exists():
        raise OpsError(f"backup already exists, refusing overwrite: {final_path}")
    temp_path = final_path.with_suffix(final_path.suffix + ".tmp")
    try:
        with tarfile.open(temp_path, "w:gz") as archive:
            for item in plan.partitions:
                archive.add(
                    item.metadata_path,
                    arcname=f"{plan.topic}-{item.partition}/partition.metadata",
                    recursive=False,
                )
        os.replace(temp_path, final_path)
    except (OSError, tarfile.TarError) as exc:
        try:
            temp_path.unlink(missing_ok=True)
        except OSError:
            pass
        raise OpsError(f"failed to create Kafka metadata backup: {exc}") from exc
    return final_path


def _replace_topic_id(metadata_path: Path, expected_topic_id: str) -> None:
    original = metadata_path.read_text(encoding="utf-8")
    updated, count = re.subn(
        r"(?m)^topic_id:\s*[A-Za-z0-9_-]{22}\s*$",
        f"topic_id: {expected_topic_id}",
        original,
    )
    if count != 1:
        raise OpsError(f"invalid topic_id entry in {metadata_path}")
    stat = metadata_path.stat()
    temp_file = tempfile.NamedTemporaryFile(
        mode="w",
        encoding="utf-8",
        newline="",
        dir=metadata_path.parent,
        prefix=f".{metadata_path.name}.",
        suffix=".tmp",
        delete=False,
    )
    temp_path = Path(temp_file.name)
    try:
        with temp_file:
            temp_file.write(updated)
            temp_file.flush()
            os.fsync(temp_file.fileno())
        os.chmod(temp_path, stat.st_mode)
        if os.name == "posix":
            os.chown(temp_path, stat.st_uid, stat.st_gid)
        os.replace(temp_path, metadata_path)
    except OSError as exc:
        try:
            temp_path.unlink(missing_ok=True)
        except OSError:
            pass
        raise OpsError(f"failed to update Kafka partition metadata {metadata_path}: {exc}") from exc


def repair_topic_id_drift(
    log_dir: Path | str,
    topic: str,
    expected_topic_id: str,
    *,
    backup_root: Path | str,
    confirmed: bool,
    broker_running: Callable[[], bool] = kafka_broker_is_running,
    now: Callable[[], datetime] = lambda: datetime.now(timezone.utc),
) -> TopicIdRepairResult:
    plan = build_repair_plan(log_dir, topic, expected_topic_id)
    if not plan.drifted:
        return TopicIdRepairResult(topic, expected_topic_id, 0, None)
    if not confirmed:
        raise OpsError("apply requires --confirm-topic-id-repair after reviewing the plan")
    if broker_running():
        raise OpsError("Kafka broker is running; stop it before applying topic ID repair")

    backup_path = _create_backup(plan, Path(backup_root), now())
    for item in plan.drifted:
        _replace_topic_id(item.metadata_path, expected_topic_id)

    verification = build_repair_plan(plan.log_dir, topic, expected_topic_id)
    if verification.drifted:
        raise OpsError(
            f"Kafka topic ID repair verification failed for partitions: "
            f"{[item.partition for item in verification.drifted]}"
        )
    return TopicIdRepairResult(topic, expected_topic_id, len(plan.drifted), backup_path)
