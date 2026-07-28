from __future__ import annotations

import re
import subprocess
from pathlib import Path

from core.console import info


DEFAULT_IDENTITY_FILE = "~/.ssh/id_rsa"
DEFAULT_MARKER = "ops-bootstrap"
LEGACY_MARKERS = ("ecs-ops-bootstrap",)


def expand_home_path(value: str) -> Path:
    return Path(value).expanduser()


def ssh_config_path() -> Path:
    return Path.home() / ".ssh" / "config"


def path_for_ssh_config(path: Path) -> str:
    resolved = path.expanduser()
    try:
        home = Path.home().resolve()
        rel = resolved.resolve().relative_to(home)
        return "~/" + rel.as_posix()
    except ValueError:
        return resolved.as_posix()


def remove_legacy_host_block(content: str, host_alias: str) -> str:
    pattern = r"(?ms)^Host\s+" + re.escape(host_alias) + r"\s*\r?\n(?:[ \t].*\r?\n)*"
    return re.sub(pattern, "", content)


def install_ssh_config_block(
    *,
    config_path: Path,
    marker: str,
    host_alias: str,
    host_name: str,
    user: str,
    key_path: Path,
    force: bool,
) -> None:
    begin = f"# BEGIN {marker} ({host_alias})"
    end = f"# END {marker} ({host_alias})"
    block = "\n".join(
        [
            begin,
            f"Host {host_alias}",
            f"    HostName {host_name}",
            f"    User {user}",
            f"    IdentityFile {path_for_ssh_config(key_path)}",
            "    IdentitiesOnly yes",
            end,
        ]
    )

    content = ""
    if config_path.exists():
        content = config_path.read_text(encoding="utf-8")
        managed_markers = (marker, *LEGACY_MARKERS)
        existing_marker = None
        for candidate in managed_markers:
            candidate_begin = f"# BEGIN {candidate} ({host_alias})"
            candidate_end = f"# END {candidate} ({host_alias})"
            block_pattern = re.compile(re.escape(candidate_begin) + r".*?" + re.escape(candidate_end), re.S)
            if block_pattern.search(content):
                existing_marker = candidate
                break
        if existing_marker:
            if not force:
                info("  SSH block exists (use --force to overwrite)", "yellow")
                return
            for candidate in managed_markers:
                candidate_begin = f"# BEGIN {candidate} ({host_alias})"
                candidate_end = f"# END {candidate} ({host_alias})"
                content = re.sub(
                    re.escape(candidate_begin) + r".*?" + re.escape(candidate_end) + r"\s*",
                    "",
                    content,
                    flags=re.S,
                )
        else:
            content = remove_legacy_host_block(content, host_alias)

    if content and not content.endswith("\n"):
        content += "\n"
    content += "\n" + block + "\n"
    config_path.parent.mkdir(parents=True, exist_ok=True)
    config_path.write_text(content, encoding="utf-8", newline="\n")
    info(f"  wrote {config_path} (Host {host_alias})", "green")


def run_command(args: list[str], *, input_text: str | None = None, quiet: bool = False) -> subprocess.CompletedProcess[str]:
    stdout = subprocess.DEVNULL if quiet else None
    stderr = subprocess.DEVNULL if quiet else None
    return subprocess.run(args, input=input_text, text=True, stdout=stdout, stderr=stderr, check=False)


def test_ssh_batch(host_alias: str, *, accept_new: bool = True) -> bool:
    args = ["ssh", "-o", "BatchMode=yes", "-o", "ConnectTimeout=10"]
    if accept_new:
        args.extend(["-o", "StrictHostKeyChecking=accept-new"])
    args.extend([host_alias, "echo OK"])
    return run_command(args, quiet=True).returncode == 0
