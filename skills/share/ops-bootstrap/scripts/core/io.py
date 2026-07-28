from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from core.errors import OpsError


def load_json(path: Path) -> dict[str, Any]:
    if not path.exists():
        raise OpsError(f"file not found: {path}")
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        raise OpsError(f"invalid JSON: {path}: {exc}") from exc
    if not isinstance(data, dict):
        raise OpsError(f"JSON root must be object: {path}")
    return data


def load_config(ops_root: Path) -> dict[str, Any]:
    config_path = ops_root / "sync.config.json"
    config = load_json(config_path)
    for field in ("sshHost", "remoteUser", "remoteHost", "remotePath"):
        if not config.get(field):
            raise OpsError(f"missing required sync.config.json field: {field}")
    return config


def resolve_ops_root(value: str) -> Path:
    path = Path(value).expanduser().resolve()
    if not path.exists():
        raise OpsError(f"ops root does not exist: {path}")
    return path
