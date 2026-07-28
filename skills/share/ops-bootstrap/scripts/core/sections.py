from __future__ import annotations

from typing import Any

from core.errors import OpsError


def config_section(config: dict[str, Any], key: str) -> dict[str, Any]:
    value = config.get(key)
    if isinstance(value, dict):
        return value
    return config


def named_configs(config: dict[str, Any], key: str, selected: str = "") -> list[tuple[str, dict[str, Any]]]:
    value = config.get(key)
    if not isinstance(value, dict):
        name = str(config.get("appName") or config.get("name") or config.get("targetName") or "default")
        return [(name, config)]

    if selected:
        selected_config = value.get(selected)
        if not isinstance(selected_config, dict):
            raise OpsError(f"missing {key}.{selected}")
        return [(selected, selected_config)]

    result: list[tuple[str, dict[str, Any]]] = []
    for name, item in value.items():
        if isinstance(item, dict):
            result.append((str(name), item))
    if not result:
        raise OpsError(f"config section `{key}` has no named configs")
    return result
