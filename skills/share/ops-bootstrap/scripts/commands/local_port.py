from __future__ import annotations

from helpers.free_local_port import free_port


def run_local_free_port(args) -> int:
    match = (getattr(args, "match", "") or "").strip() or None
    return free_port(
        int(args.port),
        match=match,
        dry_run=bool(getattr(args, "dry_run", False)),
        retries=int(getattr(args, "retries", 3) or 3),
    )
