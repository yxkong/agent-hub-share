#!/usr/bin/env python3
"""释放本机 TCP 端口占用（跨项目本地开发通用 helper）。

典型场景：
- uvicorn 残留导致 WinError 10013 / Address already in use
- Agent 后台拉起的 python 进程未退出，占用开发端口

示例：
  python helpers/free_local_port.py --port 9100
  python helpers/free_local_port.py --port 9100 --match "uvicorn|main:app"
  python helpers/free_local_port.py --port 9100 --dry-run
"""
from __future__ import annotations

import argparse
import os
import re
import socket
import subprocess
import sys
import time
from dataclasses import dataclass
from typing import Iterable, List, Optional, Set


@dataclass(frozen=True)
class Listener:
    pid: int
    cmdline: str = ""


def _run(cmd: List[str]) -> str:
    try:
        completed = subprocess.run(
            cmd,
            check=False,
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
        )
    except FileNotFoundError:
        return ""
    return completed.stdout or ""


def _windows_listeners(port: int) -> List[Listener]:
    out = _run(["netstat", "-ano", "-p", "tcp"])
    pids: Set[int] = set()
    needle = f":{port}"
    for line in out.splitlines():
        text = line.strip()
        if not text or "LISTENING" not in text.upper():
            continue
        parts = text.split()
        if len(parts) < 5:
            continue
        local = parts[1]
        if not (local.endswith(needle) or local.endswith(f"]{needle}")):
            continue
        try:
            pid = int(parts[-1])
        except ValueError:
            continue
        if pid > 0:
            pids.add(pid)
    return [Listener(pid=pid, cmdline=_windows_cmdline(pid)) for pid in sorted(pids)]


def _windows_cmdline(pid: int) -> str:
    ps = (
        f"(Get-CimInstance Win32_Process -Filter \"ProcessId={pid}\")"
        f".CommandLine"
    )
    return _run(["powershell.exe", "-NoProfile", "-Command", ps]).strip()


def _posix_listeners(port: int) -> List[Listener]:
    out = _run(["lsof", "-nP", f"-iTCP:{port}", "-sTCP:LISTEN", "-t"])
    pids: Set[int] = set()
    for token in out.split():
        try:
            pid = int(token.strip())
        except ValueError:
            continue
        if pid > 0:
            pids.add(pid)
    if not pids:
        out = _run(["fuser", f"{port}/tcp"])
        for token in re.split(r"\s+", out.replace(":", " ")):
            try:
                pid = int(token.strip())
            except ValueError:
                continue
            if pid > 0:
                pids.add(pid)
    return [Listener(pid=pid, cmdline=_posix_cmdline(pid)) for pid in sorted(pids)]


def _posix_cmdline(pid: int) -> str:
    try:
        with open(f"/proc/{pid}/cmdline", "rb") as fh:
            raw = fh.read().replace(b"\x00", b" ").decode("utf-8", errors="replace")
            return raw.strip()
    except OSError:
        return _run(["ps", "-p", str(pid), "-o", "args="]).strip()


def list_listeners(port: int) -> List[Listener]:
    if os.name == "nt":
        return _windows_listeners(port)
    return _posix_listeners(port)


def match_process_pids(pattern: str) -> List[Listener]:
    """Find processes whose command line matches regex."""
    regex = re.compile(pattern, re.IGNORECASE)
    found: List[Listener] = []
    if os.name == "nt":
        out = _run(
            [
                "powershell.exe",
                "-NoProfile",
                "-Command",
                (
                    "Get-CimInstance Win32_Process |"
                    " Where-Object { $_.CommandLine } |"
                    " Select-Object ProcessId, CommandLine |"
                    " ForEach-Object { '{0}`t{1}' -f $_.ProcessId, $_.CommandLine }"
                ),
            ]
        )
        for line in out.splitlines():
            if "\t" not in line:
                continue
            pid_s, cmdline = line.split("\t", 1)
            try:
                pid = int(pid_s.strip())
            except ValueError:
                continue
            if pid > 0 and regex.search(cmdline or ""):
                found.append(Listener(pid=pid, cmdline=cmdline.strip()))
    else:
        out = _run(["ps", "-ax", "-o", "pid=,args="])
        for line in out.splitlines():
            text = line.strip()
            if not text:
                continue
            parts = text.split(None, 1)
            if len(parts) < 2:
                continue
            try:
                pid = int(parts[0])
            except ValueError:
                continue
            cmdline = parts[1]
            if pid > 0 and regex.search(cmdline):
                found.append(Listener(pid=pid, cmdline=cmdline))
    by_pid = {item.pid: item for item in found}
    return [by_pid[k] for k in sorted(by_pid)]


def kill_pids(pids: Iterable[int], *, dry_run: bool = False) -> List[int]:
    killed: List[int] = []
    for pid in sorted(set(int(p) for p in pids if int(p) > 0)):
        if dry_run:
            print(f"[dry-run] would kill pid={pid}", flush=True)
            killed.append(pid)
            continue
        if os.name == "nt":
            completed = subprocess.run(
                ["taskkill", "/F", "/T", "/PID", str(pid)],
                check=False,
                capture_output=True,
                text=True,
                encoding="utf-8",
                errors="replace",
            )
            ok = completed.returncode == 0
            detail = (completed.stdout or completed.stderr or "").strip()
        else:
            try:
                try:
                    os.killpg(pid, 9)
                except OSError:
                    os.kill(pid, 9)
                ok = True
                detail = "SIGKILL"
            except OSError as exc:
                ok = False
                detail = str(exc)
        if ok:
            print(f"killed pid={pid} {detail}".rstrip(), flush=True)
            killed.append(pid)
        else:
            print(f"fail pid={pid}: {detail}", file=sys.stderr, flush=True)
    return killed


def probe_bind(port: int, host: str = "0.0.0.0") -> bool:
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    try:
        # 与 uvicorn/常见服务器一致；可覆盖 Windows 幽灵 LISTEN（PID 已死）
        sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        sock.bind((host, port))
        print(f"BIND_OK {host}:{port}", flush=True)
        return True
    except OSError as exc:
        print(f"BIND_FAIL {host}:{port} -> {exc}", file=sys.stderr, flush=True)
        return False
    finally:
        sock.close()


def pid_alive(pid: int) -> bool:
    if pid <= 0:
        return False
    if os.name == "nt":
        completed = subprocess.run(
            ["tasklist", "/FI", f"PID eq {pid}", "/NH"],
            check=False,
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
        )
        out = (completed.stdout or "").strip()
        return bool(out) and str(pid) in out and "No tasks" not in out and "没有" not in out
    try:
        os.kill(pid, 0)
        return True
    except OSError:
        return False


def free_port(
    port: int,
    *,
    match: Optional[str] = None,
    dry_run: bool = False,
    retries: int = 3,
) -> int:
    last_targets: dict[int, Listener] = {}
    for attempt in range(1, max(1, retries) + 1):
        listeners = list_listeners(port)
        live_listeners = [item for item in listeners if pid_alive(item.pid)]
        for item in listeners:
            if not pid_alive(item.pid):
                print(f"ignore stale LISTEN pid={item.pid} (process gone)", flush=True)

        targets = {item.pid: item for item in live_listeners}
        if match:
            for item in match_process_pids(match):
                if pid_alive(item.pid):
                    targets[item.pid] = item

        last_targets = targets
        if not targets:
            break

        print(f"port {port}: candidates (attempt {attempt}/{retries})", flush=True)
        for item in targets.values():
            cmd = item.cmdline or "(cmdline unavailable)"
            print(f"  pid={item.pid}  {cmd}", flush=True)
        kill_pids(targets.keys(), dry_run=dry_run)
        if dry_run:
            break
        time.sleep(0.8)

    live_left = [] if dry_run else [x for x in list_listeners(port) if pid_alive(x.pid)]
    if live_left:
        print("WARN: still LISTEN:", file=sys.stderr, flush=True)
        for item in live_left:
            print(f"  pid={item.pid}  {item.cmdline}", file=sys.stderr, flush=True)
        probe_bind(port)
        return 1

    if not last_targets:
        print(f"port {port}: no live LISTEN / matched process", flush=True)

    if dry_run:
        print(f"OK: dry-run done for port {port}", flush=True)
        return 0

    if probe_bind(port):
        print(f"OK: port {port} is free", flush=True)
        return 0
    return 1


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Free a local TCP port occupied by leftover listeners (uvicorn etc.)."
    )
    parser.add_argument("--port", type=int, default=9100, help="TCP port (default: 9100)")
    parser.add_argument(
        "--match",
        default="uvicorn|main:app",
        help="Also kill processes whose cmdline matches this regex; empty to disable",
    )
    parser.add_argument("--dry-run", action="store_true", help="Only print candidates")
    parser.add_argument(
        "--probe",
        action="store_true",
        help="Compatibility flag; bind probe always runs after free",
    )
    parser.add_argument("--retries", type=int, default=3, help="Kill/recheck rounds")
    return parser


def main(argv: Optional[List[str]] = None) -> int:
    args = build_parser().parse_args(argv)
    match = (args.match or "").strip() or None
    return free_port(
        args.port,
        match=match,
        dry_run=args.dry_run,
        retries=args.retries,
    )


if __name__ == "__main__":
    raise SystemExit(main())
