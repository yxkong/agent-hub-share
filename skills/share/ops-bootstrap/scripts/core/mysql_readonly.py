from __future__ import annotations

import json
import os
import re
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Callable, Mapping, Sequence

from core.errors import OpsError


DEFAULT_ALLOWED_PREFIXES = ("SELECT", "SHOW", "EXPLAIN", "WITH")
DEFAULT_DENIED_PREFIXES = (
    "INSERT",
    "UPDATE",
    "DELETE",
    "REPLACE",
    "DROP",
    "ALTER",
    "CREATE",
    "GRANT",
    "REVOKE",
    "TRUNCATE",
    "CALL",
    "DO",
    "HANDLER",
    "LOAD",
    "LOCK",
    "UNLOCK",
    "SET",
    "USE",
)
SIDE_EFFECT_PATTERNS = (
    r"\bINTO\s+(?:OUTFILE|DUMPFILE)\b",
    r"\bLOAD_FILE\s*\(",
    r"\bGET_LOCK\s*\(",
    r"\bRELEASE_LOCK\s*\(",
    r"\bSLEEP\s*\(",
    r"\bBENCHMARK\s*\(",
    r"\bFOR\s+UPDATE\b",
    r"\bLOCK\s+IN\s+SHARE\s+MODE\b",
)


@dataclass(frozen=True)
class QueryResult:
    columns: list[str]
    rows: list[dict[str, Any]]
    truncated: bool

    @property
    def row_count(self) -> int:
        return len(self.rows)

    def as_dict(self) -> dict[str, Any]:
        return {
            "columns": self.columns,
            "rows": self.rows,
            "rowCount": self.row_count,
            "truncated": self.truncated,
        }


def _mask_literals_and_comments(sql: str) -> str:
    output: list[str] = []
    index = 0
    state = "normal"
    quote = ""
    while index < len(sql):
        char = sql[index]
        next_char = sql[index + 1] if index + 1 < len(sql) else ""
        if state == "normal":
            if char in ("'", '"', "`"):
                state = "quoted"
                quote = char
                output.append(" ")
            elif char == "#":
                state = "line_comment"
                output.append(" ")
            elif char == "-" and next_char == "-":
                state = "line_comment"
                output.extend((" ", " "))
                index += 1
            elif char == "/" and next_char == "*":
                state = "block_comment"
                output.extend((" ", " "))
                index += 1
            else:
                output.append(char)
        elif state == "quoted":
            output.append(" ")
            if char == "\\" and next_char:
                output.append(" ")
                index += 1
            elif char == quote:
                if next_char == quote:
                    output.append(" ")
                    index += 1
                else:
                    state = "normal"
        elif state == "line_comment":
            output.append("\n" if char in "\r\n" else " ")
            if char in "\r\n":
                state = "normal"
        elif state == "block_comment":
            output.append(" ")
            if char == "*" and next_char == "/":
                output.append(" ")
                index += 1
                state = "normal"
        index += 1
    if state in ("quoted", "block_comment"):
        raise OpsError("SQL contains an unterminated quote or comment")
    return "".join(output)


def validate_readonly_sql(
    sql: str,
    allowed_prefixes: Sequence[str] | None = None,
    denied_prefixes: Sequence[str] | None = None,
) -> str:
    if not isinstance(sql, str) or not sql.strip():
        raise OpsError("SQL must not be empty")
    masked = _mask_literals_and_comments(sql).strip()
    semicolons = [index for index, char in enumerate(masked) if char == ";"]
    if len(semicolons) > 1 or (semicolons and masked[semicolons[0] + 1 :].strip()):
        raise OpsError("multiple SQL statements are not allowed")
    normalized = masked.rstrip("; ").upper()
    first = re.match(r"[A-Z]+", normalized)
    if first is None:
        raise OpsError("unable to determine SQL statement type")
    prefix = first.group(0)
    allowed = {str(value).strip().upper() for value in (allowed_prefixes or DEFAULT_ALLOWED_PREFIXES)}
    if prefix not in allowed:
        raise OpsError(f"SQL statement type is not allowed: {prefix}")

    denied = {value.upper() for value in DEFAULT_DENIED_PREFIXES}
    denied.update(str(value).strip().upper() for value in (denied_prefixes or ()) if str(value).strip())
    tokens = set(re.findall(r"\b[A-Z_]+\b", normalized))
    denied_tokens = {value.split()[0] for value in denied if value}
    if prefix == "WITH" and tokens.intersection(denied_tokens):
        blocked = sorted(tokens.intersection(denied_tokens))[0]
        raise OpsError(f"writable CTE or dangerous SQL is not allowed: {blocked}")
    for value in denied:
        if normalized.startswith(value):
            raise OpsError(f"SQL is denied by policy: {value}")
    if ":=" in normalized:
        raise OpsError("SQL user-variable assignment is not allowed")
    for pattern in SIDE_EFFECT_PATTERNS:
        if re.search(pattern, normalized):
            raise OpsError("SQL contains a read-side effect or lock operation")
    return prefix


def _required_env(environ: Mapping[str, str], name: str, label: str) -> str:
    if not name:
        raise OpsError(f"missing credentials.{label}Env")
    value = environ.get(name, "")
    if not value:
        raise OpsError(f"missing required credential environment variable: {name}")
    return value


def resolve_connection_options(
    connection: Mapping[str, Any],
    config_path: Path,
    *,
    environ: Mapping[str, str] | None = None,
) -> dict[str, Any]:
    if any(field in connection for field in ("user", "username", "password", "passwordEnv")):
        raise OpsError("plaintext or legacy credential fields are forbidden; use credentials")
    host = str(connection.get("host") or "").strip()
    database = str(connection.get("database") or "").strip()
    if not host or not database:
        raise OpsError("MySQL connection requires host and database")
    credentials = connection.get("credentials")
    if not isinstance(credentials, Mapping):
        raise OpsError("MySQL connection requires a credentials object")
    credential_type = str(credentials.get("type") or "").strip().lower()
    env = environ if environ is not None else os.environ
    if credential_type == "env":
        username = _required_env(env, str(credentials.get("usernameEnv") or ""), "username")
        password = _required_env(env, str(credentials.get("passwordEnv") or ""), "password")
    elif credential_type == "json-file":
        raw_path = str(credentials.get("path") or "").strip()
        if not raw_path:
            raise OpsError("credentials.path is required for json-file credentials")
        credential_path = Path(raw_path).expanduser()
        if not credential_path.is_absolute():
            credential_path = config_path.resolve().parent / credential_path
        if not credential_path.is_file():
            raise OpsError(f"credential file not found: {credential_path}")
        try:
            payload = json.loads(credential_path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as exc:
            raise OpsError(f"invalid credential JSON file: {credential_path}") from exc
        if not isinstance(payload, dict):
            raise OpsError("credential JSON root must be an object")
        username_field = str(credentials.get("usernameField") or "username")
        password_field = str(credentials.get("passwordField") or "password")
        username = str(payload.get(username_field) or "")
        password = str(payload.get(password_field) or "")
        if not username or not password:
            raise OpsError("credential JSON does not contain the configured username/password fields")
    else:
        raise OpsError("credentials.type must be env or json-file")

    timeout = int(connection.get("timeoutSeconds") or 10)
    if timeout < 1 or timeout > 300:
        raise OpsError("connection timeoutSeconds must be between 1 and 300")
    port = int(connection.get("port") or 3306)
    if port < 1 or port > 65535:
        raise OpsError("MySQL port must be between 1 and 65535")
    return {
        "host": host,
        "port": port,
        "database": database,
        "user": username,
        "password": password,
        "charset": str(connection.get("charset") or "utf8mb4"),
        "timeout_seconds": timeout,
    }


def _sanitize_connection_error(exc: Exception, password: str) -> str:
    message = str(exc)
    if password:
        message = message.replace(password, "***REDACTED***")
    return message


def open_mysql_connection(options: Mapping[str, Any]):
    try:
        import pymysql

        return pymysql.connect(
            host=options["host"],
            port=options["port"],
            database=options["database"],
            user=options["user"],
            password=options["password"],
            charset=options["charset"],
            connect_timeout=options["timeout_seconds"],
            read_timeout=options["timeout_seconds"],
            write_timeout=options["timeout_seconds"],
            autocommit=False,
            cursorclass=pymysql.cursors.SSDictCursor,
        )
    except ImportError:
        try:
            import mysql.connector

            return mysql.connector.connect(
                host=options["host"],
                port=options["port"],
                database=options["database"],
                user=options["user"],
                password=options["password"],
                charset=options["charset"],
                connection_timeout=options["timeout_seconds"],
                autocommit=False,
            )
        except ImportError as exc:
            raise OpsError(
                "MySQL driver unavailable; install PyMySQL or mysql-connector-python in the caller runtime"
            ) from exc
        except Exception as exc:
            message = _sanitize_connection_error(exc, str(options.get("password") or ""))
            raise OpsError(f"MySQL connection failed: {message}") from exc
    except Exception as exc:
        message = _sanitize_connection_error(exc, str(options.get("password") or ""))
        raise OpsError(f"MySQL connection failed: {message}") from exc


def _redact_rows(rows: list[dict[str, Any]], fragments: Sequence[str]) -> list[dict[str, Any]]:
    normalized = [str(value).lower() for value in fragments if str(value).strip()]
    if not normalized:
        return rows
    result: list[dict[str, Any]] = []
    for row in rows:
        result.append(
            {
                key: "***REDACTED***"
                if any(fragment in key.lower() for fragment in normalized)
                else value
                for key, value in row.items()
            }
        )
    return result


def execute_readonly_sql(
    connection,
    sql: str,
    *,
    max_rows: int,
    timeout_seconds: int,
    redact_columns: Sequence[str],
    allowed_prefixes: Sequence[str] | None = None,
    denied_prefixes: Sequence[str] | None = None,
) -> QueryResult:
    validate_readonly_sql(sql, allowed_prefixes, denied_prefixes)
    if max_rows < 1 or max_rows > 10000:
        raise OpsError("max_rows must be between 1 and 10000")
    if timeout_seconds < 1 or timeout_seconds > 300:
        raise OpsError("timeout_seconds must be between 1 and 300")
    cursor = None
    try:
        try:
            cursor = connection.cursor(dictionary=True, buffered=False)
        except TypeError:
            cursor = connection.cursor()
        cursor.execute("START TRANSACTION READ ONLY")
        cursor.execute(f"SET SESSION MAX_EXECUTION_TIME = {int(timeout_seconds * 1000)}")
        cursor.execute(sql)
        description = cursor.description or []
        columns = [str(item[0]) for item in description]
        fetched = list(cursor.fetchmany(max_rows + 1))
        truncated = len(fetched) > max_rows
        fetched = fetched[:max_rows]
        rows: list[dict[str, Any]] = []
        for row in fetched:
            if isinstance(row, Mapping):
                rows.append(dict(row))
            else:
                rows.append(dict(zip(columns, row)))
        return QueryResult(columns, _redact_rows(rows, redact_columns), truncated)
    except OpsError:
        raise
    except Exception as exc:
        raise OpsError(f"readonly SQL execution failed: {exc}") from exc
    finally:
        if cursor is not None:
            try:
                cursor.close()
            except Exception:
                pass
        try:
            connection.rollback()
        except Exception:
            pass


def run_readonly_query(
    connection_options: Mapping[str, Any],
    sql: str,
    *,
    max_rows: int,
    timeout_seconds: int,
    redact_columns: Sequence[str],
    allowed_prefixes: Sequence[str] | None = None,
    denied_prefixes: Sequence[str] | None = None,
    connector: Callable[[Mapping[str, Any]], Any] = open_mysql_connection,
) -> QueryResult:
    connection = connector(connection_options)
    try:
        return execute_readonly_sql(
            connection,
            sql,
            max_rows=max_rows,
            timeout_seconds=timeout_seconds,
            redact_columns=redact_columns,
            allowed_prefixes=allowed_prefixes,
            denied_prefixes=denied_prefixes,
        )
    finally:
        try:
            connection.close()
        except Exception:
            pass
