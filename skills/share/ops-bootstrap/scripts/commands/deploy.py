from __future__ import annotations

from pathlib import Path

from core.console import info, print_list
from core.io import load_json
from core.sections import named_configs


def print_one_deploy(config_path: Path, name: str, config: dict) -> None:
    info("=== ops-bootstrap deploy plan ===", "cyan")
    info(f"config : {config_path}#{name}")
    info(f"app    : {config.get('appName', '<app>')}")
    info(f"profile: {config.get('profile', 'fixed')}")
    info(f"strategy: {config.get('strategy', '<strategy>')}")
    artifact = config.get("artifact") or {}
    info("artifact:")
    for key in ("type", "localPath", "remoteReleaseDir", "currentSymlink"):
        if artifact.get(key):
            info(f"  - {key}: {artifact[key]}")
    runtime = config.get("runtime") or {}
    info("runtime:")
    for key in ("serviceManager", "serviceName", "appUser", "workingDirectory", "ecosystemFile"):
        if runtime.get(key):
            info(f"  - {key}: {runtime[key]}")
    print_list("config templates", [f"{x.get('name')} -> {x.get('target')} ({x.get('template')})" for x in config.get("configTemplates", [])])
    hooks = config.get("hooks") or {}
    print_list("pre-check", hooks.get("preCheck"))
    print_list("deploy", hooks.get("deploy"))
    print_list("post-check", hooks.get("postCheck"))
    print_list("rollback", hooks.get("rollback"))


def run_deploy_plan(args) -> int:
    config_path = Path(args.config).expanduser().resolve()
    config = load_json(config_path)
    for name, item in named_configs(config, "deploys", getattr(args, "name", "")):
        print_one_deploy(config_path, name, item)
    info("DEPLOY_PLAN_READY", "green")
    return 0
