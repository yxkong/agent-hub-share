from __future__ import annotations

from pathlib import Path
from typing import Any

from core.console import info
from core.errors import OpsError
from core.io import load_config, load_json, resolve_ops_root
from core.sections import config_section


def resolve_provision_config(args) -> Path:
    if args.config:
        return Path(args.config).expanduser().resolve()
    if not args.ops_root:
        raise OpsError("provision plan needs --ops-root or --config")
    ops_root = resolve_ops_root(args.ops_root)
    config = load_config(ops_root)
    rel = str(config.get("environmentConfig") or "provision/environment.config.json")
    path = (ops_root / rel).resolve()
    if not path.exists():
        raise OpsError(
            f"missing provision config: {path}\n"
            "  copy templates/provision/TEMPLATE_environment.config.json to <ops>/provision/environment.config.json"
        )
    return path


def resolve_module_config(env_path: Path, module_name: str, module_ref: dict[str, Any]) -> Path:
    raw = str(module_ref.get("config") or f"modules/{module_name}.json")
    candidate = Path(raw).expanduser()
    if not candidate.is_absolute():
        candidate = env_path.parent / candidate
    if candidate.exists():
        return candidate.resolve()

    template_name = f"TEMPLATE_{module_name}.json"
    fallback = candidate.parent / template_name
    if fallback.exists():
        return fallback.resolve()
    raise OpsError(f"missing module config for {module_name}: {candidate}")


def load_module_config(env_path: Path, module_name: str, module_ref: dict[str, Any]) -> tuple[str, dict[str, Any]]:
    inline = module_ref.get("inlineConfig")
    if isinstance(inline, dict):
        return f"<inline:{module_name}>", inline
    module_path = resolve_module_config(env_path, module_name, module_ref)
    return str(module_path), load_json(module_path)


def get_module_target_summary(module_config: dict[str, Any]) -> str:
    parts: list[str] = []
    for key in ("pythonVersion", "uvVersion", "majorVersion", "version", "distribution", "installMethod", "serviceName"):
        value = module_config.get(key)
        if value not in (None, "", []):
            parts.append(f"{key}={value}")
    return ", ".join(parts) if parts else "no explicit target fields"


def run_provision_plan(args) -> int:
    env_path = resolve_provision_config(args)
    env_config = config_section(load_json(env_path), "provision")
    mode = args.mode or str(env_config.get("networkMode") or "auto")
    offline_dir = str(env_config.get("offlineBundleDir") or "provision/offline")
    modules = env_config.get("modules") or {}
    if not isinstance(modules, dict):
        raise OpsError("environment config field `modules` must be object")

    selected = set(args.module or [])
    info("=== ops-bootstrap provision plan ===", "cyan")
    info(f"config : {env_path}")
    info(f"target : {env_config.get('osFamily', 'unknown')} {env_config.get('architecture', 'unknown')}")
    info(f"network: {mode}")
    info(f"offline bundle dir: {offline_dir}")
    info("")

    planned = 0
    offline_count = 0
    for module_name, module_ref in modules.items():
        if selected and module_name not in selected:
            continue
        if not isinstance(module_ref, dict):
            raise OpsError(f"module entry must be object: {module_name}")
        if not selected and not module_ref.get("enabled", False):
            continue
        module_path, module_config = load_module_config(env_path, module_name, module_ref)
        planned += 1

        info(f"[{module_name}]", "yellow")
        info(f"  config: {module_path}")
        info(f"  target: {get_module_target_summary(module_config)}")

        templates = module_config.get("configTemplates") or []
        if templates:
            info("  config templates:")
            for template in templates:
                validate = template.get("validate") or "not declared"
                info(
                    "    - "
                    f"{template.get('name', '<name>')}: {template.get('template', '<template>')} "
                    f"-> {template.get('target', '<target>')} "
                    f"profileAware={template.get('profileAware', False)} validate={validate}"
                )

        commands = (module_config.get("onlineInstall") or {}).get("commands") or []
        info("  online install:")
        if commands:
            for command in commands:
                info(f"    - {command}")
        else:
            info("    - not declared")

        artifacts = module_config.get("offlineArtifacts") or []
        info("  offline preparation:")
        if artifacts:
            for artifact in artifacts:
                offline_count += 1
                required = "required" if artifact.get("required", False) else "optional"
                target = artifact.get("targetFile") or artifact.get("targetDir") or "<target>"
                info(f"    - {artifact.get('id', '<id>')} ({artifact.get('type', 'artifact')}, {required}) -> {offline_dir}/{target}")
                hint = artifact.get("prepareHint")
                if hint:
                    info(f"      {hint}")
        else:
            info("    - not declared")

        checks = (module_config.get("healthCheck") or {}).get("commands") or []
        if checks:
            info("  health check:")
            for command in checks:
                info(f"    - {command}")
        info("")

    if planned == 0:
        info("No enabled modules matched the selection.", "yellow")
        return 1

    info(f"PLAN_READY modules={planned} offline_artifacts={offline_count}", "green")
    info("Next: prepare offline artifacts when networkMode=offline, then run check/apply after those commands are implemented.")
    return 0
