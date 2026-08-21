#!/usr/bin/env python3
"""Destructive command guard - cross-platform hook core.

Reads JSON on stdin, matches against destructive command patterns,
outputs deny/allow JSON on stdout.

Supported input formats (auto-detect):
  - Cursor:        {"command": "git stash"}
  - Claude Code:   {"tool_name": "Bash", "tool_input": {"command": "git stash"}}
  - Codex CLI:     {"tool_name": "Bash", "tool_input": {"command": "git stash"}}
  - Gemini CLI:    {"tool": "run_shell_command", "args": {"command": "git stash"}}

Output (stdout):
  - Allow:  {"permission":"allow"} (Cursor) / {"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow"}} (Claude/Codex)
  - Deny:   corresponding deny JSON

Exit codes:
  - 0: allow
  - 2: deny (block)
"""

from __future__ import annotations

import json
import re
import sys
from typing import Any


# --- Destructive command patterns ---

# git restore / reset / clean
_PAT_GIT_DESTRUCTIVE = re.compile(
    r'(^|\s)git\s+(restore|reset|clean)(\s|$)'
)
# git stash (all subcommands)
_PAT_GIT_STASH = re.compile(
    r'(^|\s)git\s+stash(\s|$)'
)
# git checkout -- <path> (discard working tree; NOT branch checkout)
_PAT_GIT_CHECKOUT_DASH = re.compile(
    r'(^|\s)git\s+checkout\s+--(\s|$)'
)
# Remove-Item / del / rm / rmdir / rd / unlink  (ALL file deletion, not just recursive/force)
_PAT_FILE_DELETE = re.compile(
    r'(^|\s)(remove-item|del|rm|rmdir|rd|unlink)(\s|$)'
)


def _extract_command(raw: str) -> str:
    """Extract the shell command string from various hook input formats."""
    if not raw or not raw.strip():
        return ""
    try:
        obj: dict[str, Any] = json.loads(raw)
    except (json.JSONDecodeError, ValueError):
        return raw.strip()

    # Cursor: {"command": "..."}
    cmd = obj.get("command")
    if isinstance(cmd, str) and cmd.strip():
        return cmd.strip()

    # Claude Code / Codex: {"tool_input": {"command": "..."}}
    tool_input = obj.get("tool_input")
    if isinstance(tool_input, dict):
        cmd = tool_input.get("command")
        if isinstance(cmd, str) and cmd.strip():
            return cmd.strip()

    # Gemini CLI: {"args": {"command": "..."}}
    args = obj.get("args")
    if isinstance(args, dict):
        cmd = args.get("command")
        if isinstance(cmd, str) and cmd.strip():
            return cmd.strip()

    return ""


def _is_destructive(command: str) -> tuple[bool, str]:
    """Check if command is destructive. Returns (is_destructive, reason)."""
    if not command:
        return False, ""

    norm = re.sub(r'\s+', ' ', command).strip().lower()

    # git restore / reset / clean
    m = _PAT_GIT_DESTRUCTIVE.search(norm)
    if m:
        return True, f"git {m.group(2)} is a destructive git operation"

    # git stash
    if _PAT_GIT_STASH.search(norm):
        return True, "git stash can hide or discard working-tree state"

    # git checkout --
    if _PAT_GIT_CHECKOUT_DASH.search(norm):
        return True, "git checkout -- discards working tree changes"

    # file deletion (ALL deletion commands, not just recursive/force)
    if _PAT_FILE_DELETE.search(norm):
        return True, "file deletion command detected"

    return False, ""


def _detect_platform(raw: str) -> str:
    """Detect which platform's hook format the input uses."""
    if not raw or not raw.strip():
        return "cursor"
    try:
        obj = json.loads(raw)
    except (json.JSONDecodeError, ValueError):
        return "cursor"

    if "tool_name" in obj or "tool_input" in obj:
        return "claude"  # Claude Code / Codex share format
    if "tool" in obj and "args" in obj:
        return "gemini"
    return "cursor"


def _build_allow(platform: str) -> str:
    if platform in ("claude", "codex"):
        return json.dumps({
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "permissionDecision": "allow",
            }
        })
    if platform == "gemini":
        return json.dumps({"decision": "allow"})
    return json.dumps({"permission": "allow"})


def _build_deny(platform: str, reason: str) -> str:
    user_msg = f"BLOCKED: {reason}. Confirm with the user before executing."
    agent_msg = (
        f"Hook blocked: {reason}. "
        "List path/command/impact and get explicit user confirmation first."
    )

    if platform in ("claude", "codex"):
        return json.dumps({
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "permissionDecision": "deny",
                "permissionDecisionReason": user_msg,
            }
        })
    if platform == "gemini":
        return json.dumps({"decision": "block", "reason": user_msg})
    return json.dumps({
        "permission": "deny",
        "user_message": user_msg,
        "agent_message": agent_msg,
    })


def main() -> int:
    raw = ""
    try:
        raw = sys.stdin.read()
    except Exception:
        # If stdin read fails, allow (fail-open on I/O, fail-closed is config-level)
        sys.stdout.write(_build_allow("cursor"))
        return 0

    if not raw.strip():
        sys.stdout.write(_build_allow("cursor"))
        return 0

    platform = _detect_platform(raw)
    command = _extract_command(raw)

    if not command:
        sys.stdout.write(_build_allow(platform))
        return 0

    is_dest, reason = _is_destructive(command)
    if is_dest:
        sys.stdout.write(_build_deny(platform, reason))
        # Log to stderr for audit
        print(f"[GUARD] BLOCKED: {reason} | command={command[:200]}", file=sys.stderr)
        return 2

    sys.stdout.write(_build_allow(platform))
    return 0


if __name__ == "__main__":
    sys.exit(main())
