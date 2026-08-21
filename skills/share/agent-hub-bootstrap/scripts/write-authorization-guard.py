#!/usr/bin/env python3
"""Codex write-authorization hook and project-local permit state machine."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import shlex
import sys
from pathlib import Path, PurePosixPath
from typing import Any, Iterable


STATE_RELATIVE_PATH = Path(".codex/state/write-authorization/active.json")
STATE_SCHEMA_VERSION = 3
HASH_PATTERN = re.compile(r"sha256:[0-9a-f]{64}")
CONFIRM_PATTERN = re.compile(r"^\s*确认\s+(\S+)\s+(sha256:[0-9a-f]{64})\s*$")
REVOKE_PATTERN = re.compile(r"^\s*撤销\s+(\S+)(?:\s+(sha256:[0-9a-f]{64}))?\s*$")
PATCH_PATH_PATTERN = re.compile(r"^\*\*\* (?:Update|Add|Delete) File: (.+?)\s*$", re.MULTILINE)
PATCH_DELETE_PATTERN = re.compile(r"^\*\*\* Delete File:", re.MULTILINE)

IMPLEMENTATION_TERMS = (
    "修复",
    "实现",
    "修改",
    "优化",
    "重构",
    "新增",
    "创建",
    "更新",
    "同步",
    "安装",
    "配置",
    "落地",
    "处理",
    "fix ",
    "implement ",
    "update ",
    "refactor ",
    "create ",
    "install ",
)
READ_ONLY_INTENT_TERMS = (
    "不要改",
    "不修改",
    "先别改",
    "只读",
    "只分析",
    "仅分析",
    "只评审",
    "仅评审",
)
QUESTION_INTENT_TERMS = ("是否", "了吗", "么？", "吗？", "看下是否", "看看是否")
NEGATED_HIGH_RISK_TERMS = (
    "不要删除",
    "不删除",
    "禁止删除",
    "不要清空",
    "不清空",
    "不要部署到生产",
    "不部署到生产",
    "不要发布到生产",
    "不发布到生产",
    "不触碰生产",
)
HIGH_RISK_TERMS = (
    "生产",
    "线上",
    " prod ",
    "发布到",
    "部署到",
    "删除",
    "清空",
    "drop ",
    "truncate ",
    "rm -rf",
    "密钥",
    "密码",
    "付款",
    "转账",
    "发送邮件",
    "发送消息",
    "提交 pr",
    "创建 pr",
    "push",
)
HUB_SCOPE_TERMS = ("harness", "guard", "hook", "hub", "skill", "技能", "门禁", "规则")
HIGH_RISK_SHELL_PATTERNS = (
    r"\bgit\s+(?:reset|restore|clean|stash|push)\b",
    r"\bgit\s+checkout\s+--",
    r"\brm\s+-[^\n]*r[^\n]*f",
    r"\bremove-item\b[^\n]*(?:-recurse|-force)",
    r"\b(?:del|rmdir)\b[^\n]*(?:/f|/s)",
    r"\b(?:drop|truncate)\s+(?:database|schema|table)\b",
    r"\bgh\s+pr\s+create\b",
    r"\b(?:curl|wget)\b[^\n]*(?:-x\s*(?:post|put|patch|delete)|--method\s+(?:post|put|patch|delete))",
)

READ_ONLY_PREFIXES = (
    "git status",
    "git diff",
    "git log",
    "git show",
    "git branch --show-current",
    "git rev-parse",
    "rg ",
    "rg --files",
    "get-content ",
    "select-string ",
    "test-path ",
    "get-item ",
    "get-childitem ",
    "get-child-item ",
    "resolve-path ",
    "pwd",
    "ls",
    "dir",
)


class AuthorizationError(ValueError):
    pass


def _state_path(cwd: str | Path) -> Path:
    return Path(cwd).resolve() / STATE_RELATIVE_PATH


def _normalize_relative_path(value: str) -> str:
    raw = value.strip().strip('"\'').replace("\\", "/")
    path = PurePosixPath(raw)
    if not raw or path.is_absolute() or re.match(r"^[A-Za-z]:", raw) or ".." in path.parts:
        raise AuthorizationError(f"写入路径必须是项目内精确相对路径: {value}")
    normalized = path.as_posix()
    if normalized in {".", ""} or any(ch in normalized for ch in "*?[]"):
        raise AuthorizationError(f"写入范围禁止目录、通配符或空路径: {value}")
    return normalized


def _ensure_within_workspace(cwd: str | Path, relative_path: str) -> None:
    root = Path(cwd).resolve()
    target = (root / Path(relative_path)).resolve()
    try:
        target.relative_to(root)
    except ValueError as exc:
        raise AuthorizationError(f"写入路径解析后越出项目: {relative_path}") from exc


def _validate_hash(design_hash: str) -> str:
    value = design_hash.strip().lower()
    if not HASH_PATTERN.fullmatch(value):
        raise AuthorizationError("design_hash 必须是 sha256:<64位小写十六进制>")
    return value


def _write_state(cwd: str | Path, state: dict[str, Any]) -> dict[str, Any]:
    target = _state_path(cwd)
    target.parent.mkdir(parents=True, exist_ok=True)
    temporary = target.with_suffix(".tmp")
    temporary.write_text(
        json.dumps(state, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
        newline="\n",
    )
    os.replace(temporary, target)
    return state


def load_state(cwd: str | Path) -> dict[str, Any]:
    target = _state_path(cwd)
    if not target.exists():
        return {"schema_version": STATE_SCHEMA_VERSION, "state": "DISCOVERY"}
    try:
        value = json.loads(target.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise AuthorizationError(f"授权状态不可读，按未授权处理: {exc}") from exc
    if not isinstance(value, dict) or not isinstance(value.get("state"), str):
        raise AuthorizationError("授权状态格式无效，按未授权处理")
    if int(value.get("schema_version", 1)) < 2:
        value.pop("quality_gate", None)
    value["schema_version"] = STATE_SCHEMA_VERSION
    return value


def _prompt_requests_implementation(prompt: str) -> bool:
    normalized = " ".join(prompt.strip().lower().split())
    if not normalized or any(term in normalized for term in READ_ONLY_INTENT_TERMS):
        return False
    if normalized.endswith(("了吗", "了吗？", "了吗?", "吗", "吗？", "吗?", "么", "么？", "么?")):
        return False
    if any(term in normalized for term in ("看下是否", "看看是否", "检查是否")):
        return False
    return any(term in normalized for term in IMPLEMENTATION_TERMS)


def _prompt_requires_high_risk_confirmation(prompt: str) -> bool:
    normalized = f" {prompt.strip().lower()} "
    for term in NEGATED_HIGH_RISK_TERMS:
        normalized = normalized.replace(term, "")
    return any(term in normalized for term in HIGH_RISK_TERMS)


def _normalize_scope_root(value: str | Path) -> str:
    root = Path(value).resolve()
    if not root.is_absolute():
        raise AuthorizationError(f"授权根目录必须是绝对路径: {value}")
    return str(root)


def _scope_roots_for_prompt(cwd: str | Path, prompt: str) -> list[str]:
    roots = {_normalize_scope_root(cwd)}
    normalized = prompt.lower()
    hub_root = os.environ.get("AGENTS_HUB_ROOT", "").strip()
    if hub_root and any(term in normalized for term in HUB_SCOPE_TERMS):
        roots.add(_normalize_scope_root(hub_root))
    return sorted(roots)


def authorize_goal(
    *,
    cwd: str | Path,
    prompt: str,
    turn_id: str,
    session_id: str,
    scope_roots: Iterable[str | Path] | None = None,
    task_id: str | None = None,
) -> dict[str, Any]:
    goal = prompt.strip()
    if not _prompt_requests_implementation(goal):
        raise AuthorizationError("当前消息不是明确实施请求，未生成目标授权")
    if _prompt_requires_high_risk_confirmation(goal):
        raise AuthorizationError("请求包含生产、外部、删除或敏感操作，必须先做高风险确认")
    prompt_hash = hashlib.sha256(goal.encode("utf-8")).hexdigest()
    roots = sorted({_normalize_scope_root(item) for item in (scope_roots or _scope_roots_for_prompt(cwd, goal))})
    state = {
        "schema_version": STATE_SCHEMA_VERSION,
        "state": "GOAL_AUTHORIZED",
        "task_id": task_id or f"goal-{prompt_hash[:16]}",
        "goal": goal,
        "scope_roots": roots,
        "authorization": {
            "turn_id": turn_id or "unknown",
            "session_id": session_id or "unknown",
            "prompt_sha256": f"sha256:{prompt_hash}",
        },
    }
    return _write_state(cwd, state)


def adopt_confirmed_goal(
    *,
    cwd: str | Path,
    goal: str,
    scope_roots: Iterable[str | Path],
    confirmed_task_id: str | None = None,
    confirmed_design_hash: str | None = None,
) -> dict[str, Any]:
    state = load_state(cwd)
    confirmation = state.get("confirmation")
    if state.get("state") == "REVIEWED_AWAITING_CONFIRMATION":
        normalized_hash = _validate_hash(confirmed_design_hash or "")
        if state.get("task_id") != confirmed_task_id or state.get("design_hash") != normalized_hash:
            raise AuthorizationError("迁移凭证与待确认 task_id/design_hash 不匹配")
        confirmation_prompt = f"确认 {confirmed_task_id} {normalized_hash}"
        confirmation = {
            "turn_id": "user-confirm",
            "session_id": "cursor",
            "prompt_sha256": "sha256:"
            + hashlib.sha256(confirmation_prompt.encode("utf-8")).hexdigest(),
        }
    elif state.get("state") != "WRITE_PERMITTED" or not confirmation:
        raise AuthorizationError("只有已确认或携带匹配确认凭证的旧许可证可以迁移")
    roots = {_normalize_scope_root(cwd)}
    hub_root = os.environ.get("AGENTS_HUB_ROOT", "").strip()
    for item in scope_roots:
        normalized = _normalize_scope_root(item)
        if normalized != _normalize_scope_root(cwd) and (
            not hub_root or normalized != _normalize_scope_root(hub_root)
        ):
            raise AuthorizationError(f"迁移只允许当前 workspace 或已登记 AGENTS_HUB_ROOT: {item}")
        roots.add(normalized)
    state = {
        "schema_version": STATE_SCHEMA_VERSION,
        "state": "GOAL_AUTHORIZED",
        "task_id": state.get("task_id"),
        "goal": goal.strip() or state.get("goal", ""),
        "scope_roots": sorted(roots),
        "authorization": dict(confirmation),
        "migrated_from_design_hash": state.get("design_hash"),
    }
    return _write_state(cwd, state)


def propose(
    *,
    cwd: str | Path,
    task_id: str,
    design_hash: str,
    allowed_paths: Iterable[str],
    validation_commands: Iterable[str],
    goal: str,
    design_source: str,
) -> dict[str, Any]:
    task = task_id.strip()
    if not task or any(char.isspace() for char in task):
        raise AuthorizationError("task_id 必须是无空白的稳定标识")
    paths = sorted({_normalize_relative_path(item) for item in allowed_paths})
    for path in paths:
        _ensure_within_workspace(cwd, path)
    if not paths:
        raise AuthorizationError("至少声明一个精确写入文件")
    commands = [item.strip() for item in validation_commands if item.strip()]
    if not commands:
        raise AuthorizationError("至少声明一条验收命令")
    source = design_source.strip()
    if not source:
        raise AuthorizationError("design_source 不能为空")
    state = {
        "schema_version": STATE_SCHEMA_VERSION,
        "state": "REVIEWED_AWAITING_CONFIRMATION",
        "task_id": task,
        "goal": goal.strip(),
        "design_source": source,
        "design_hash": _validate_hash(design_hash),
        "review_status": "PASS",
        "allowed_paths": paths,
        "validation_commands": commands,
    }
    return _write_state(cwd, state)


def confirm(
    *,
    cwd: str | Path,
    task_id: str,
    design_hash: str,
    turn_id: str,
    session_id: str,
    prompt: str,
) -> dict[str, Any]:
    state = load_state(cwd)
    normalized_hash = _validate_hash(design_hash)
    if state.get("state") != "REVIEWED_AWAITING_CONFIRMATION":
        raise AuthorizationError(f"当前状态不能确认: {state.get('state')}")
    if state.get("task_id") != task_id or state.get("design_hash") != normalized_hash:
        raise AuthorizationError("确认凭证与当前 task_id/design_hash 不匹配")
    state["state"] = "WRITE_PERMITTED"
    state["confirmation"] = {
        "turn_id": turn_id or "unknown",
        "session_id": session_id or "unknown",
        "prompt_sha256": "sha256:" + hashlib.sha256(prompt.encode("utf-8")).hexdigest(),
    }
    return _write_state(cwd, state)


def revoke(*, cwd: str | Path, task_id: str | None = None, design_hash: str | None = None) -> dict[str, Any]:
    state = load_state(cwd)
    if task_id and state.get("task_id") != task_id:
        raise AuthorizationError("撤销凭证与当前 task_id 不匹配")
    if design_hash and state.get("design_hash") != _validate_hash(design_hash):
        raise AuthorizationError("撤销凭证与当前 design_hash 不匹配")
    state["state"] = "REVOKED"
    state.pop("confirmation", None)
    return _write_state(cwd, state)


def _command_from_input(tool_input: Any) -> str:
    if isinstance(tool_input, str):
        return tool_input.strip()
    if not isinstance(tool_input, dict):
        return ""
    for key in ("command", "cmd", "patch", "input"):
        value = tool_input.get(key)
        if isinstance(value, str):
            return value.strip()
    return ""


def _is_read_only_command(command: str) -> bool:
    compact = " ".join(command.strip().split()).lower()
    unquoted = _unquoted_shell_text(compact)
    if not compact or any(token in unquoted for token in (";", "&&", "||", "|", ">", "`", "$(")):
        return False
    return any(compact == prefix.rstrip() or compact.startswith(prefix) for prefix in READ_ONLY_PREFIXES)


def _unquoted_shell_text(command: str) -> str:
    """Return shell syntax outside single/double quoted literals."""
    result: list[str] = []
    quote: str | None = None
    escaped = False
    for char in command:
        if escaped:
            result.append(" " if quote else char)
            escaped = False
            continue
        if char == "\\" and quote == '"':
            result.append(" ")
            escaped = True
            continue
        if quote:
            result.append(" ")
            if char == quote:
                quote = None
            continue
        if char in {"'", '"'}:
            quote = char
            result.append(" ")
            continue
        result.append(char)
    return command if quote else "".join(result)


def _is_guard_control_command(command: str) -> bool:
    lowered = " ".join(command.split()).lower()
    return bool(
        re.search(
            r"write-authorization-guard\.py[\"']?\s+(?:propose|status|verify|revoke|adopt-goal)(?:\s|$)",
            lowered,
        )
    )


def _is_high_risk_shell_command(command: str) -> bool:
    normalized = " ".join(command.strip().lower().split())
    return any(re.search(pattern, normalized) for pattern in HIGH_RISK_SHELL_PATTERNS)


def _resolve_patch_target(value: str, cwd: str | Path) -> Path:
    raw = value.strip().strip('"\'')
    candidate = Path(raw)
    if not candidate.is_absolute():
        if ".." in PurePosixPath(raw.replace("\\", "/")).parts:
            raise AuthorizationError(f"补丁路径禁止父目录穿越: {value}")
        candidate = Path(cwd).resolve() / candidate
    return candidate.resolve()


def _patch_targets(command: str, cwd: str | Path) -> list[Path]:
    paths: list[Path] = []
    for match in PATCH_PATH_PATTERN.findall(command):
        paths.append(_resolve_patch_target(match, cwd))
    return paths


def _target_in_scope(target: Path, scope_roots: Iterable[str]) -> bool:
    for value in scope_roots:
        try:
            target.relative_to(Path(value).resolve())
            return True
        except ValueError:
            continue
    return False


def _handle_functions_exec(source: str, state: dict[str, Any], cwd: str | Path) -> dict[str, str]:
    tool_calls = re.findall(r"tools\.([A-Za-z0-9_]+)\s*\(", source)
    if not tool_calls:
        return _deny(state, "functions.exec 未解析到受控工具调用")
    safe_nested_tools = {
        "read_mcp_resource",
        "list_mcp_resources",
        "list_mcp_resource_templates",
        "view_image",
        "web__run",
        "get_goal",
    }
    for nested_name in tool_calls:
        if nested_name in safe_nested_tools:
            continue
        if nested_name == "apply_patch":
            decoded_source = source.replace("\\r", "\r").replace("\\n", "\n")
            result = _handle_pre_tool(
                {"tool_name": "apply_patch", "tool_input": decoded_source, "cwd": str(cwd)}, state
            )
        elif nested_name == "exec_command":
            command_match = re.search(
                r"(?:cmd|command)\s*:\s*\"((?:\\.|[^\"])*)\"", source
            )
            if not command_match:
                return _deny(state, "functions.exec 中的 Shell 命令无法精确解析")
            try:
                nested_command = json.loads('"' + command_match.group(1) + '"')
            except json.JSONDecodeError:
                return _deny(state, "functions.exec 中的 Shell 命令转义无效")
            result = _handle_pre_tool(
                {"tool_name": "exec_command", "tool_input": {"cmd": nested_command}, "cwd": str(cwd)}, state
            )
        else:
            return _deny(state, f"functions.exec 包含未分类工具: {nested_name}")
        if result["decision"] == "deny":
            return result
    return _permit_result(state, "functions.exec 内部调用均通过授权检查")


def _permit_result(state: dict[str, Any], reason: str) -> dict[str, str]:
    return {"decision": "allow", "reason": f"{reason}; state={state.get('state', 'DISCOVERY')}"}


def _deny(state: dict[str, Any], reason: str) -> dict[str, str]:
    return {"decision": "deny", "reason": f"{reason}; state={state.get('state', 'DISCOVERY')}"}


def _validate_permit_state(state: dict[str, Any], session_id: str | None = None) -> str | None:
    if state.get("state") != "WRITE_PERMITTED":
        return f"无有效写入许可证: {state.get('state', 'DISCOVERY')}"
    required = (
        "task_id",
        "goal",
        "design_source",
        "design_hash",
        "allowed_paths",
        "validation_commands",
        "confirmation",
    )
    missing = [key for key in required if not state.get(key)]
    if missing:
        return f"写入许可证字段缺失: {', '.join(missing)}"
    confirmation = state["confirmation"]
    if not all(confirmation.get(key) for key in ("turn_id", "session_id", "prompt_sha256")):
        return "写入许可证确认凭证不完整"
    if session_id and confirmation["session_id"] != session_id:
        return "写入许可证属于另一 session，必须重新确认"
    return None


def _validate_goal_state(state: dict[str, Any], session_id: str | None = None) -> str | None:
    if state.get("state") == "WRITE_PERMITTED":
        return _validate_permit_state(state, session_id)
    if state.get("state") != "GOAL_AUTHORIZED":
        return f"无有效目标授权: {state.get('state', 'DISCOVERY')}"
    required = ("task_id", "goal", "scope_roots", "authorization")
    missing = [key for key in required if not state.get(key)]
    if missing:
        return f"目标授权字段缺失: {', '.join(missing)}"
    authorization = state["authorization"]
    if not all(authorization.get(key) for key in ("turn_id", "session_id", "prompt_sha256")):
        return "目标授权凭证不完整"
    if session_id and authorization["session_id"] != session_id:
        return "目标授权属于另一 session，需要重新提出明确实施请求"
    return None


def _handle_pre_tool(event: dict[str, Any], state: dict[str, Any]) -> dict[str, str]:
    tool_name = str(event.get("tool_name", ""))
    lowered_name = tool_name.lower()
    command = _command_from_input(event.get("tool_input"))

    if lowered_name in {"functions.exec", "function.exec"}:
        return _handle_functions_exec(command, state, event.get("cwd") or os.getcwd())

    if lowered_name in {"apply_patch", "applypatch"}:
        permit_error = _validate_goal_state(state, str(event.get("session_id", "")))
        if permit_error:
            return _deny(state, permit_error)
        if state.get("state") == "GOAL_AUTHORIZED" and PATCH_DELETE_PATTERN.search(command):
            return _deny(state, "删除文件属于高风险动作，必须单独确认")
        try:
            paths = _patch_targets(command, event.get("cwd") or os.getcwd())
        except AuthorizationError as exc:
            return _deny(state, str(exc))
        if not paths:
            return _deny(state, "无法从补丁解析精确写入文件")
        if state.get("state") == "WRITE_PERMITTED":
            allowed = {
                (Path(event.get("cwd") or os.getcwd()).resolve() / path).resolve()
                for path in state.get("allowed_paths", [])
            }
            outside = [str(path) for path in paths if path not in allowed]
            if outside:
                return _deny(state, f"补丁超出旧许可证白名单: {', '.join(outside)}")
            return _permit_result(state, "补丁文件均在旧许可证白名单")
        outside = [str(path) for path in paths if not _target_in_scope(path, state.get("scope_roots", []))]
        if outside:
            return _deny(state, f"补丁超出目标授权根目录: {', '.join(outside)}")
        return _permit_result(state, "补丁文件位于目标授权根目录")

    if lowered_name in {"bash", "exec_command", "shell", "powershell"}:
        if _is_read_only_command(command):
            return _permit_result(state, "只读命令")
        if _is_guard_control_command(command):
            return _permit_result(state, "授权状态机控制命令")
        if _is_high_risk_shell_command(command):
            return _deny(state, "高风险 Shell 动作必须单独确认")
        permit_error = _validate_goal_state(state, str(event.get("session_id", "")))
        if not permit_error:
            if state.get("state") == "WRITE_PERMITTED" and command not in state.get("validation_commands", []):
                return _deny(state, "旧许可证 Shell 仅允许已声明验收命令")
            return _permit_result(state, "当前任务已有目标授权")
        return _deny(state, "Shell 仅允许只读命令、授权控制命令，或在目标授权后执行")

    read_only_tools = {
        "read_mcp_resource",
        "list_mcp_resources",
        "list_mcp_resource_templates",
        "view_image",
        "web__run",
        "get_goal",
    }
    coordination_tools = {"update_plan", "request_user_input"}
    if lowered_name in read_only_tools | coordination_tools:
        return _permit_result(state, "非写入工具")
    return _deny(state, f"未分类工具默认拒绝: {tool_name or '<empty>'}")


def handle_hook(event: dict[str, Any]) -> dict[str, str]:
    cwd = event.get("cwd") or os.getcwd()
    try:
        state = load_state(cwd)
        hook_name = event.get("hook_event_name")
        if hook_name == "PreToolUse":
            return _handle_pre_tool(event, state)
        if hook_name == "UserPromptSubmit":
            prompt = str(event.get("prompt", ""))
            confirmation = CONFIRM_PATTERN.fullmatch(prompt)
            if confirmation:
                confirm(
                    cwd=cwd,
                    task_id=confirmation.group(1),
                    design_hash=confirmation.group(2),
                    turn_id=str(event.get("turn_id", "unknown")),
                    session_id=str(event.get("session_id", "unknown")),
                    prompt=prompt,
                )
                return {"decision": "allow", "reason": "写入许可证已签发"}
            revocation = REVOKE_PATTERN.fullmatch(prompt)
            if revocation:
                revoke(cwd=cwd, task_id=revocation.group(1), design_hash=revocation.group(2))
                return {"decision": "allow", "reason": "写入许可证已撤销"}
            if _prompt_requests_implementation(prompt):
                if _prompt_requires_high_risk_confirmation(prompt):
                    _write_state(
                        cwd,
                        {
                            "schema_version": STATE_SCHEMA_VERSION,
                            "state": "HIGH_RISK_AWAITING_CONFIRMATION",
                            "previous_task_id": state.get("task_id"),
                            "pending_goal_sha256": "sha256:"
                            + hashlib.sha256(prompt.encode("utf-8")).hexdigest(),
                        },
                    )
                    return {
                        "decision": "allow",
                        "reason": "检测到高风险实施请求；保持当前状态并要求单独确认",
                    }
                authorize_goal(
                    cwd=cwd,
                    prompt=prompt,
                    turn_id=str(event.get("turn_id", "unknown")),
                    session_id=str(event.get("session_id", "unknown")),
                )
                return {"decision": "allow", "reason": "明确实施请求已生成目标授权"}
            return {"decision": "allow", "reason": f"未改变授权状态; state={state.get('state')}"}
        if hook_name == "SessionStart":
            if state.get("state") == "WRITE_PERMITTED":
                permit_error = _validate_permit_state(state, str(event.get("session_id", "")))
                if permit_error:
                    state["state"] = "REVIEWED_AWAITING_CONFIRMATION"
                    state.pop("confirmation", None)
                    _write_state(cwd, state)
            elif state.get("state") == "GOAL_AUTHORIZED":
                permit_error = _validate_goal_state(state, str(event.get("session_id", "")))
                if permit_error:
                    state = {
                        "schema_version": STATE_SCHEMA_VERSION,
                        "state": "DISCOVERY",
                        "previous_task_id": state.get("task_id"),
                        "reason": "session_changed",
                    }
                    _write_state(cwd, state)
            return {
                "decision": "allow",
                "reason": (
                    f"写入授权状态: {state.get('state')}; task_id={state.get('task_id', 'N/A')}; "
                    f"goal={state.get('goal', 'N/A')}"
                ),
            }
        return _deny(state, f"未知 Hook 事件: {hook_name}")
    except AuthorizationError as exc:
        return {"decision": "deny", "reason": str(exc)}


def _hook_output(event: dict[str, Any], result: dict[str, str]) -> dict[str, Any]:
    hook_name = str(event.get("hook_event_name", ""))
    if hook_name == "PreToolUse":
        return {
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "permissionDecision": "allow" if result["decision"] == "allow" else "deny",
                "permissionDecisionReason": result["reason"],
            }
        }
    return {
        "hookSpecificOutput": {
            "hookEventName": hook_name,
            "additionalContext": result["reason"],
        }
    }


def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="action")
    proposal = subparsers.add_parser("propose")
    proposal.add_argument("--task-id", required=True)
    proposal.add_argument("--design-hash", required=True)
    proposal.add_argument("--allow-path", action="append", required=True)
    proposal.add_argument("--validation-command", action="append", required=True)
    proposal.add_argument("--goal", required=True)
    proposal.add_argument("--design-source", required=True)
    subparsers.add_parser("status")
    revoke_parser = subparsers.add_parser("revoke")
    revoke_parser.add_argument("--task-id")
    revoke_parser.add_argument("--design-hash")
    verify_parser = subparsers.add_parser("verify")
    verify_parser.add_argument("--path", action="append", default=[])
    adopt_parser = subparsers.add_parser("adopt-goal")
    adopt_parser.add_argument("--goal", required=True)
    adopt_parser.add_argument("--scope-root", action="append", default=[])
    adopt_parser.add_argument("--confirmed-task-id")
    adopt_parser.add_argument("--confirmed-design-hash")
    return parser


def _run_cli(args: argparse.Namespace, cwd: Path) -> int:
    if args.action == "propose":
        state = propose(
            cwd=cwd,
            task_id=args.task_id,
            design_hash=args.design_hash,
            allowed_paths=args.allow_path,
            validation_commands=args.validation_command,
            goal=args.goal,
            design_source=args.design_source,
        )
    elif args.action == "revoke":
        state = revoke(cwd=cwd, task_id=args.task_id, design_hash=args.design_hash)
    elif args.action == "adopt-goal":
        state = adopt_confirmed_goal(
            cwd=cwd,
            goal=args.goal,
            scope_roots=args.scope_root,
            confirmed_task_id=args.confirmed_task_id,
            confirmed_design_hash=args.confirmed_design_hash,
        )
    elif args.action == "verify":
        state = load_state(cwd)
        permit_error = _validate_goal_state(state)
        if permit_error:
            raise AuthorizationError(permit_error)
        requested = [_resolve_patch_target(item, cwd) for item in args.path]
        if state.get("state") == "WRITE_PERMITTED":
            allowed = {(cwd / item).resolve() for item in state.get("allowed_paths", [])}
            outside = [str(item) for item in requested if item not in allowed]
        else:
            outside = [str(item) for item in requested if not _target_in_scope(item, state.get("scope_roots", []))]
        if outside:
            raise AuthorizationError(f"路径超出目标授权范围: {', '.join(sorted(outside))}")
    else:
        state = load_state(cwd)
    print(json.dumps(state, ensure_ascii=False, indent=2))
    return 0


def main() -> int:
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")
    if hasattr(sys.stderr, "reconfigure"):
        sys.stderr.reconfigure(encoding="utf-8")
    if len(sys.argv) > 1:
        try:
            return _run_cli(_build_parser().parse_args(), Path.cwd())
        except AuthorizationError as exc:
            print(str(exc), file=sys.stderr)
            return 2
    try:
        event = json.load(sys.stdin)
        result = handle_hook(event)
        print(json.dumps(_hook_output(event, result), ensure_ascii=False))
        return 0
    except Exception as exc:  # Hook must fail closed on malformed input.
        print(
            json.dumps(
                {
                    "hookSpecificOutput": {
                        "hookEventName": "PreToolUse",
                        "permissionDecision": "deny",
                        "permissionDecisionReason": f"授权 Hook 异常，按拒绝处理: {exc}",
                    }
                },
                ensure_ascii=False,
            )
        )
        return 0


if __name__ == "__main__":
    raise SystemExit(main())
