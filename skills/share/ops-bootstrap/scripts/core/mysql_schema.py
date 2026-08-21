from __future__ import annotations

import json
import re
from dataclasses import asdict, dataclass, field
from typing import Any, Callable, Mapping

from core.errors import OpsError
from core.mysql_readonly import open_mysql_connection, validate_readonly_sql


IDENT_RE = re.compile(r"^[A-Za-z0-9_$-]+$")
DEFAULT_UNQUOTED = re.compile(
    r"^(CURRENT_TIMESTAMP(?:\(\d+\))?|CURRENT_DATE|CURRENT_TIME|NULL|NOW\(\d*\))$",
    re.IGNORECASE,
)
HEADING_ENV_ALIASES = {
    "生产数据库": "prod",
    "生产": "prod",
    "开发数据库": "dev",
    "开发": "dev",
    "测试数据库": "test",
    "测试": "test",
}
FIELD_ALIASES = {
    "链接方式": "connect_mode",
    "连接方式": "connect_mode",
    "链接地址": "host",
    "连接地址": "host",
    "主机": "host",
    "账户": "user",
    "账号": "user",
    "用户": "user",
    "密码": "password",
    "数据库": "database",
    "读写权限": "privilege",
    "权限": "privilege",
    "端口": "port",
    "跳板机": "bastion",
    "跳板机别名": "bastion",
}


@dataclass
class ColumnDef:
    name: str
    column_type: str
    is_nullable: str
    column_default: str | None
    extra: str
    column_comment: str
    character_set_name: str
    collation_name: str
    ordinal_position: int

    def fingerprint(self) -> tuple:
        return (
            self.column_type.lower(),
            self.is_nullable.upper(),
            self.column_default,
            self.extra.lower(),
            self.column_comment,
            self.collation_name.lower(),
        )


@dataclass
class IndexDef:
    name: str
    non_unique: int
    index_type: str
    columns: list[str]
    sub_parts: list[int | None]

    def fingerprint(self) -> tuple:
        return (
            int(self.non_unique),
            self.index_type.upper(),
            tuple(self.columns),
            tuple(self.sub_parts),
        )


@dataclass
class TableDef:
    name: str
    engine: str
    table_collation: str
    table_comment: str
    columns: dict[str, ColumnDef] = field(default_factory=dict)
    indexes: dict[str, IndexDef] = field(default_factory=dict)
    create_sql: str = ""


@dataclass
class SchemaSnapshot:
    env_name: str
    database: str
    tables: dict[str, TableDef] = field(default_factory=dict)

    def to_public_dict(self) -> dict[str, Any]:
        payload = asdict(self)
        payload["tableCount"] = len(self.tables)
        return payload


@dataclass
class SchemaDiff:
    source_env: str
    target_env: str
    source_database: str
    target_database: str
    tables_only_in_source: list[str]
    tables_only_in_target: list[str]
    added_columns: list[dict[str, Any]]
    dropped_columns: list[dict[str, Any]]
    modified_columns: list[dict[str, Any]]
    added_indexes: list[dict[str, Any]]
    dropped_indexes: list[dict[str, Any]]
    modified_indexes: list[dict[str, Any]]
    modified_tables: list[dict[str, Any]]

    @property
    def change_count(self) -> int:
        return (
            len(self.tables_only_in_source)
            + len(self.tables_only_in_target)
            + len(self.added_columns)
            + len(self.dropped_columns)
            + len(self.modified_columns)
            + len(self.added_indexes)
            + len(self.dropped_indexes)
            + len(self.modified_indexes)
            + len(self.modified_tables)
        )


def quote_ident(name: str) -> str:
    if not isinstance(name, str) or not name or "\x00" in name or "`" in name:
        raise OpsError(f"invalid SQL identifier: {name!r}")
    return f"`{name}`"


def quote_string(value: str) -> str:
    return "'" + str(value).replace("\\", "\\\\").replace("'", "\\'") + "'"


def _as_str(value: Any) -> str:
    if value is None:
        return ""
    if isinstance(value, bytes):
        return value.decode("utf-8", errors="replace")
    return str(value)


def parse_account_markdown(text: str) -> dict[str, dict[str, str]]:
    if not isinstance(text, str) or not text.strip():
        raise OpsError("database account markdown is empty")
    accounts: dict[str, dict[str, str]] = {}
    current_heading = ""
    current: dict[str, str] = {}

    def flush() -> None:
        nonlocal current_heading, current
        if not current_heading:
            current = {}
            return
        env = HEADING_ENV_ALIASES.get(current_heading, "")
        if not env:
            env = re.sub(r"数据库$", "", current_heading).strip().lower()
            env = re.sub(r"[^a-z0-9_-]+", "-", env).strip("-") or current_heading
        required = ("host", "user", "password", "database")
        missing = [key for key in required if not str(current.get(key) or "").strip()]
        if missing:
            raise OpsError(f"account '{current_heading}' missing fields: {', '.join(missing)}")
        if env in accounts:
            raise OpsError(f"duplicate database env key: {env}")
        accounts[env] = dict(current)
        accounts[env]["title"] = current_heading
        current_heading = ""
        current = {}

    for raw_line in text.splitlines():
        line = raw_line.strip()
        if not line or line.startswith("<!--"):
            continue
        heading = re.match(r"^##\s+(.+)$", line)
        if heading:
            flush()
            current_heading = heading.group(1).strip()
            current = {}
            continue
        item = re.match(r"^[-*]\s*([^：:]+)[：:]\s*(.*)$", line)
        if item and current_heading:
            raw_key = item.group(1).strip()
            value = item.group(2).strip()
            key = FIELD_ALIASES.get(raw_key, raw_key)
            current[key] = value
    flush()
    if not accounts:
        raise OpsError("no database accounts parsed from markdown")
    return accounts


def resolve_connect_mode(account: Mapping[str, str]) -> str:
    mode = str(account.get("connect_mode") or "")
    if any(token in mode for token in ("跳板", "bastion", "jump")):
        return "jump"
    if any(token in mode for token in ("直连", "本地", "direct")):
        return "direct"
    raise OpsError(f"unable to resolve connect mode from: {mode or '<empty>'}")


def _fetch_all(cursor, sql: str) -> list[dict[str, Any]]:
    validate_readonly_sql(sql)
    cursor.execute(sql)
    rows = cursor.fetchall() or []
    result: list[dict[str, Any]] = []
    for row in rows:
        if isinstance(row, Mapping):
            result.append({str(key): value for key, value in row.items()})
        else:
            raise OpsError("schema dump expected dict rows")
    return result


def _cursor(connection):
    try:
        return connection.cursor(dictionary=True, buffered=True)
    except TypeError:
        return connection.cursor()


def open_schema_connection(options: Mapping[str, Any]):
    try:
        import pymysql

        return pymysql.connect(
            host=options["host"],
            port=options["port"],
            database=options["database"],
            user=options["user"],
            password=options["password"],
            charset=options.get("charset") or "utf8mb4",
            connect_timeout=int(options.get("timeout_seconds") or 60),
            read_timeout=int(options.get("timeout_seconds") or 60),
            write_timeout=int(options.get("timeout_seconds") or 60),
            autocommit=True,
            cursorclass=pymysql.cursors.DictCursor,
        )
    except ImportError:
        return open_mysql_connection(options)
    except Exception as exc:
        message = str(exc)
        password = str(options.get("password") or "")
        if password:
            message = message.replace(password, "***REDACTED***")
        raise OpsError(f"MySQL connection failed: {message}") from exc


def _chunks(values: list[str], size: int) -> list[list[str]]:
    return [values[index : index + size] for index in range(0, len(values), size)]


def dump_schema(
    options: Mapping[str, Any],
    *,
    env_name: str,
    table_filter: set[str] | None = None,
    include_create_sql: bool = True,
    connector: Callable[[Mapping[str, Any]], Any] = open_schema_connection,
) -> SchemaSnapshot:
    database = str(options.get("database") or "").strip()
    if not IDENT_RE.match(database):
        raise OpsError(f"unsafe database name: {database}")
    connection = connector(options)
    cursor = None
    try:
        cursor = _cursor(connection)
        schema_sql = quote_string(database)
        table_rows = _fetch_all(
            cursor,
            "SELECT TABLE_NAME, ENGINE, TABLE_COLLATION, TABLE_COMMENT "
            "FROM information_schema.TABLES "
            f"WHERE TABLE_SCHEMA = {schema_sql} AND TABLE_TYPE = 'BASE TABLE' "
            "ORDER BY TABLE_NAME",
        )
        snapshot = SchemaSnapshot(env_name=env_name, database=database)
        for row in table_rows:
            name = _as_str(row.get("TABLE_NAME"))
            if table_filter and name not in table_filter:
                continue
            snapshot.tables[name] = TableDef(
                name=name,
                engine=_as_str(row.get("ENGINE")),
                table_collation=_as_str(row.get("TABLE_COLLATION")),
                table_comment=_as_str(row.get("TABLE_COMMENT")),
            )
        table_names = list(snapshot.tables)
        column_rows: list[dict[str, Any]] = []
        index_rows: list[dict[str, Any]] = []
        for chunk in _chunks(table_names, 40):
            in_list = ", ".join(quote_string(name) for name in chunk)
            column_rows.extend(
                _fetch_all(
                    cursor,
                    "SELECT TABLE_NAME, COLUMN_NAME, COLUMN_TYPE, IS_NULLABLE, COLUMN_DEFAULT, "
                    "EXTRA, COLUMN_COMMENT, CHARACTER_SET_NAME, COLLATION_NAME, ORDINAL_POSITION "
                    "FROM information_schema.COLUMNS "
                    f"WHERE TABLE_SCHEMA = {schema_sql} AND TABLE_NAME IN ({in_list}) "
                    "ORDER BY TABLE_NAME, ORDINAL_POSITION",
                )
            )
            index_rows.extend(
                _fetch_all(
                    cursor,
                    "SELECT TABLE_NAME, INDEX_NAME, NON_UNIQUE, SEQ_IN_INDEX, COLUMN_NAME, "
                    "INDEX_TYPE, SUB_PART "
                    "FROM information_schema.STATISTICS "
                    f"WHERE TABLE_SCHEMA = {schema_sql} AND TABLE_NAME IN ({in_list}) "
                    "ORDER BY TABLE_NAME, INDEX_NAME, SEQ_IN_INDEX",
                )
            )
        for row in column_rows:
            table_name = _as_str(row.get("TABLE_NAME"))
            table = snapshot.tables.get(table_name)
            if table is None:
                continue
            column_name = _as_str(row.get("COLUMN_NAME"))
            table.columns[column_name] = ColumnDef(
                name=column_name,
                column_type=_as_str(row.get("COLUMN_TYPE")),
                is_nullable=_as_str(row.get("IS_NULLABLE") or "YES"),
                column_default=None if row.get("COLUMN_DEFAULT") is None else _as_str(row.get("COLUMN_DEFAULT")),
                extra=_as_str(row.get("EXTRA")),
                column_comment=_as_str(row.get("COLUMN_COMMENT")),
                character_set_name=_as_str(row.get("CHARACTER_SET_NAME")),
                collation_name=_as_str(row.get("COLLATION_NAME")),
                ordinal_position=int(row.get("ORDINAL_POSITION") or 0),
            )
        grouped: dict[tuple[str, str], IndexDef] = {}
        for row in index_rows:
            table_name = _as_str(row.get("TABLE_NAME"))
            if table_name not in snapshot.tables:
                continue
            index_name = _as_str(row.get("INDEX_NAME"))
            key = (table_name, index_name)
            item = grouped.get(key)
            if item is None:
                item = IndexDef(
                    name=index_name,
                    non_unique=int(row.get("NON_UNIQUE") or 0),
                    index_type=_as_str(row.get("INDEX_TYPE") or "BTREE"),
                    columns=[],
                    sub_parts=[],
                )
                grouped[key] = item
            item.columns.append(_as_str(row.get("COLUMN_NAME")))
            sub_part = row.get("SUB_PART")
            item.sub_parts.append(None if sub_part is None else int(sub_part))
        for (table_name, index_name), index in grouped.items():
            snapshot.tables[table_name].indexes[index_name] = index
        if include_create_sql:
            _load_create_sql(cursor, snapshot)
        return snapshot
    except OpsError:
        raise
    except Exception as exc:
        raise OpsError(f"schema dump failed for {env_name}: {exc}") from exc
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
        try:
            connection.close()
        except Exception:
            pass


def _parse_create_sql(row: Mapping[str, Any]) -> str:
    create_sql = ""
    for key, value in row.items():
        if str(key).lower().replace(" ", "") in {"createtable", "createview"}:
            create_sql = _as_str(value)
            break
    if not create_sql and row:
        create_sql = _as_str(list(row.values())[-1])
    return _strip_auto_increment(create_sql)


def _load_create_sql(cursor, snapshot: SchemaSnapshot, table_names: list[str] | None = None) -> None:
    names = table_names if table_names is not None else list(snapshot.tables)
    for table_name in names:
        table = snapshot.tables.get(table_name)
        if table is None:
            continue
        create_rows = _fetch_all(cursor, f"SHOW CREATE TABLE {quote_ident(table_name)}")
        if create_rows:
            table.create_sql = _parse_create_sql(create_rows[0])


def fill_create_sql(
    snapshot: SchemaSnapshot,
    options: Mapping[str, Any],
    table_names: list[str],
    *,
    connector: Callable[[Mapping[str, Any]], Any] = open_schema_connection,
) -> None:
    if not table_names:
        return
    connection = connector(options)
    cursor = None
    try:
        cursor = _cursor(connection)
        _load_create_sql(cursor, snapshot, table_names)
    except OpsError:
        raise
    except Exception as exc:
        raise OpsError(f"SHOW CREATE TABLE failed for {snapshot.env_name}: {exc}") from exc
    finally:
        if cursor is not None:
            try:
                cursor.close()
            except Exception:
                pass
        try:
            connection.close()
        except Exception:
            pass


def _strip_auto_increment(create_sql: str) -> str:
    return re.sub(r"\sAUTO_INCREMENT=\d+", "", create_sql, flags=re.IGNORECASE)


def diff_schemas(source: SchemaSnapshot, target: SchemaSnapshot) -> SchemaDiff:
    source_tables = set(source.tables)
    target_tables = set(target.tables)
    only_source = sorted(source_tables - target_tables)
    only_target = sorted(target_tables - source_tables)
    added_columns: list[dict[str, Any]] = []
    dropped_columns: list[dict[str, Any]] = []
    modified_columns: list[dict[str, Any]] = []
    added_indexes: list[dict[str, Any]] = []
    dropped_indexes: list[dict[str, Any]] = []
    modified_indexes: list[dict[str, Any]] = []
    modified_tables: list[dict[str, Any]] = []

    for table_name in sorted(source_tables & target_tables):
        src_table = source.tables[table_name]
        dst_table = target.tables[table_name]
        table_changes: dict[str, Any] = {}
        if src_table.engine != dst_table.engine:
            table_changes["engine"] = {"source": src_table.engine, "target": dst_table.engine}
        if src_table.table_comment != dst_table.table_comment:
            table_changes["comment"] = {"source": src_table.table_comment, "target": dst_table.table_comment}
        if src_table.table_collation != dst_table.table_collation:
            table_changes["collation"] = {
                "source": src_table.table_collation,
                "target": dst_table.table_collation,
            }
        if table_changes:
            modified_tables.append({"table": table_name, "changes": table_changes})

        src_cols = set(src_table.columns)
        dst_cols = set(dst_table.columns)
        for column_name in sorted(src_cols - dst_cols):
            added_columns.append(
                {"table": table_name, "column": column_name, "source": asdict(src_table.columns[column_name])}
            )
        for column_name in sorted(dst_cols - src_cols):
            dropped_columns.append(
                {"table": table_name, "column": column_name, "target": asdict(dst_table.columns[column_name])}
            )
        for column_name in sorted(src_cols & dst_cols):
            src_col = src_table.columns[column_name]
            dst_col = dst_table.columns[column_name]
            if src_col.fingerprint() != dst_col.fingerprint():
                modified_columns.append(
                    {
                        "table": table_name,
                        "column": column_name,
                        "source": asdict(src_col),
                        "target": asdict(dst_col),
                    }
                )

        src_idx = set(src_table.indexes)
        dst_idx = set(dst_table.indexes)
        for index_name in sorted(src_idx - dst_idx):
            added_indexes.append(
                {"table": table_name, "index": index_name, "source": asdict(src_table.indexes[index_name])}
            )
        for index_name in sorted(dst_idx - src_idx):
            dropped_indexes.append(
                {"table": table_name, "index": index_name, "target": asdict(dst_table.indexes[index_name])}
            )
        for index_name in sorted(src_idx & dst_idx):
            src_index = src_table.indexes[index_name]
            dst_index = dst_table.indexes[index_name]
            if src_index.fingerprint() != dst_index.fingerprint():
                modified_indexes.append(
                    {
                        "table": table_name,
                        "index": index_name,
                        "source": asdict(src_index),
                        "target": asdict(dst_index),
                    }
                )

    return SchemaDiff(
        source_env=source.env_name,
        target_env=target.env_name,
        source_database=source.database,
        target_database=target.database,
        tables_only_in_source=only_source,
        tables_only_in_target=only_target,
        added_columns=added_columns,
        dropped_columns=dropped_columns,
        modified_columns=modified_columns,
        added_indexes=added_indexes,
        dropped_indexes=dropped_indexes,
        modified_indexes=modified_indexes,
        modified_tables=modified_tables,
    )


def _format_default(column: ColumnDef) -> str:
    extra = column.extra.upper()
    if "AUTO_INCREMENT" in extra:
        return ""
    if column.column_default is None:
        if column.is_nullable.upper() == "YES":
            return "DEFAULT NULL"
        return ""
    raw = column.column_default
    if DEFAULT_UNQUOTED.match(raw) or raw.startswith("("):
        return f"DEFAULT {raw}"
    if re.match(r"^-?\d+(\.\d+)?$", raw) and re.search(
        r"int|decimal|float|double|numeric|bit", column.column_type, re.IGNORECASE
    ):
        return f"DEFAULT {raw}"
    return f"DEFAULT {quote_string(raw)}"


def format_column_ddl(column: ColumnDef) -> str:
    parts = [quote_ident(column.name), column.column_type]
    if column.is_nullable.upper() == "NO":
        parts.append("NOT NULL")
    else:
        parts.append("NULL")
    default_sql = _format_default(column)
    if default_sql:
        parts.append(default_sql)
    extra = re.sub(r"DEFAULT_GENERATED", "", column.extra, flags=re.IGNORECASE).strip()
    if extra:
        parts.append(extra)
    if column.column_comment:
        parts.append("COMMENT " + quote_string(column.column_comment))
    return " ".join(parts)


def _previous_column(table: TableDef, column_name: str) -> str | None:
    ordered = sorted(table.columns.values(), key=lambda item: item.ordinal_position)
    names = [item.name for item in ordered]
    try:
        index = names.index(column_name)
    except ValueError:
        return None
    if index <= 0:
        return None
    return names[index - 1]


def _format_index_columns(index: IndexDef) -> str:
    chunks: list[str] = []
    for name, sub_part in zip(index.columns, index.sub_parts):
        chunk = quote_ident(name)
        if sub_part:
            chunk += f"({int(sub_part)})"
        chunks.append(chunk)
    return ", ".join(chunks)


def format_add_index(table_name: str, index: IndexDef) -> str:
    columns = _format_index_columns(index)
    table_sql = quote_ident(table_name)
    if index.name == "PRIMARY":
        return f"ALTER TABLE {table_sql} ADD PRIMARY KEY ({columns});"
    kind = "UNIQUE INDEX" if int(index.non_unique) == 0 else "INDEX"
    using = ""
    if index.index_type and index.index_type.upper() not in {"", "BTREE"}:
        using = f" USING {index.index_type}"
    return f"ALTER TABLE {table_sql} ADD {kind} {quote_ident(index.name)} ({columns}){using};"


def format_drop_index(table_name: str, index_name: str) -> str:
    table_sql = quote_ident(table_name)
    if index_name == "PRIMARY":
        return f"ALTER TABLE {table_sql} DROP PRIMARY KEY;"
    return f"ALTER TABLE {table_sql} DROP INDEX {quote_ident(index_name)};"


def _sql_header(kind: str, diff: SchemaDiff) -> list[str]:
    return [
        f"-- {kind} schema sync SQL",
        f"-- source : {diff.source_env}/{diff.source_database}",
        f"-- target : {diff.target_env}/{diff.target_database}",
        "-- generated by db_schema_diff; review before applying on TARGET",
        "-- this file is NOT executed by the tool",
        "",
    ]


def render_sql_bundle(source: SchemaSnapshot, target: SchemaSnapshot, diff: SchemaDiff) -> dict[str, str]:
    safe: list[str] = _sql_header("additive", diff)
    modify: list[str] = _sql_header("modify", diff)
    destructive: list[str] = _sql_header("destructive", diff)
    destructive.append("-- WARNING: may drop tables/columns/indexes and cause data loss")
    destructive.append("")

    for table_name in diff.tables_only_in_source:
        create_sql = source.tables[table_name].create_sql.strip()
        if not create_sql:
            safe.append(f"-- missing SHOW CREATE TABLE for {quote_ident(table_name)}")
            continue
        if not create_sql.endswith(";"):
            create_sql += ";"
        safe.append(create_sql)
        safe.append("")

    for table_name in diff.tables_only_in_target:
        destructive.append(f"DROP TABLE IF EXISTS {quote_ident(table_name)};")

    for item in diff.added_columns:
        table_name = item["table"]
        column = source.tables[table_name].columns[item["column"]]
        clause = f"ALTER TABLE {quote_ident(table_name)} ADD COLUMN {format_column_ddl(column)}"
        previous = _previous_column(source.tables[table_name], column.name)
        if previous:
            clause += f" AFTER {quote_ident(previous)}"
        safe.append(clause + ";")

    for item in diff.dropped_columns:
        destructive.append(
            f"ALTER TABLE {quote_ident(item['table'])} DROP COLUMN {quote_ident(item['column'])};"
        )

    for item in diff.modified_columns:
        table_name = item["table"]
        column = source.tables[table_name].columns[item["column"]]
        modify.append(
            f"ALTER TABLE {quote_ident(table_name)} MODIFY COLUMN {format_column_ddl(column)};"
        )

    for item in diff.modified_tables:
        table_name = item["table"]
        changes = item["changes"]
        table_sql = quote_ident(table_name)
        if "engine" in changes:
            modify.append(f"ALTER TABLE {table_sql} ENGINE={changes['engine']['source']};")
        if "comment" in changes:
            modify.append(f"ALTER TABLE {table_sql} COMMENT={quote_string(changes['comment']['source'])};")
        if "collation" in changes:
            modify.append(
                f"-- collation differs on {table_sql}: "
                f"{changes['collation']['target']} -> {changes['collation']['source']}; skipped CONVERT"
            )

    for item in diff.added_indexes:
        if item["table"] in diff.tables_only_in_source:
            continue
        safe.append(format_add_index(item["table"], source.tables[item["table"]].indexes[item["index"]]))

    for item in diff.dropped_indexes:
        if item["table"] in diff.tables_only_in_target:
            continue
        destructive.append(format_drop_index(item["table"], item["index"]))

    for item in diff.modified_indexes:
        table_name = item["table"]
        index_name = item["index"]
        modify.append(format_drop_index(table_name, index_name))
        modify.append(format_add_index(table_name, source.tables[table_name].indexes[index_name]))

    def _join(lines: list[str]) -> str:
        body = [line for line in lines if line is not None]
        if all(line.startswith("--") or line == "" for line in body):
            body.append("-- no statements")
        if not body[-1].endswith("\n"):
            return "\n".join(body).rstrip() + "\n"
        return "\n".join(body)

    return {
        "safe": _join(safe),
        "modify": _join(modify),
        "destructive": _join(destructive),
    }


def render_report(diff: SchemaDiff) -> str:
    lines = [
        f"# Schema diff `{diff.source_env}` → `{diff.target_env}`",
        "",
        f"- source: `{diff.source_env}` / `{diff.source_database}`",
        f"- target: `{diff.target_env}` / `{diff.target_database}`",
        f"- changeCount: `{diff.change_count}`",
        "",
        "SQL is generated to make **target** look like **source**. The tool never executes DDL.",
        "",
        "## Summary",
        "",
        f"| kind | count |",
        f"|---|---|",
        f"| tables only in source (CREATE on target) | {len(diff.tables_only_in_source)} |",
        f"| tables only in target (DROP on target) | {len(diff.tables_only_in_target)} |",
        f"| columns to ADD | {len(diff.added_columns)} |",
        f"| columns to DROP | {len(diff.dropped_columns)} |",
        f"| columns to MODIFY | {len(diff.modified_columns)} |",
        f"| indexes to ADD | {len(diff.added_indexes)} |",
        f"| indexes to DROP | {len(diff.dropped_indexes)} |",
        f"| indexes to rebuild | {len(diff.modified_indexes)} |",
        f"| table meta changes | {len(diff.modified_tables)} |",
        "",
    ]

    def _section(title: str, rows: list[str]) -> None:
        lines.append(f"## {title}")
        lines.append("")
        if not rows:
            lines.append("- none")
        else:
            lines.extend(f"- `{row}`" for row in rows)
        lines.append("")

    _section("Tables only in source", diff.tables_only_in_source)
    _section("Tables only in target", diff.tables_only_in_target)

    lines.append("## Column changes")
    lines.append("")
    if not (diff.added_columns or diff.dropped_columns or diff.modified_columns):
        lines.append("- none")
        lines.append("")
    else:
        for item in diff.added_columns:
            src = item["source"]
            lines.append(
                f"- ADD `{item['table']}`.`{item['column']}` {src['column_type']} "
                f"nullable={src['is_nullable']}"
            )
        for item in diff.dropped_columns:
            lines.append(f"- DROP `{item['table']}`.`{item['column']}`")
        for item in diff.modified_columns:
            src = item["source"]
            dst = item["target"]
            lines.append(
                f"- MODIFY `{item['table']}`.`{item['column']}` "
                f"{dst['column_type']} -> {src['column_type']}"
            )
        lines.append("")

    lines.append("## Index changes")
    lines.append("")
    if not (diff.added_indexes or diff.dropped_indexes or diff.modified_indexes):
        lines.append("- none")
        lines.append("")
    else:
        for item in diff.added_indexes:
            src = item["source"]
            lines.append(
                f"- ADD `{item['table']}`.`{item['index']}` columns={','.join(src['columns'])}"
            )
        for item in diff.dropped_indexes:
            lines.append(f"- DROP `{item['table']}`.`{item['index']}`")
        for item in diff.modified_indexes:
            lines.append(f"- REBUILD `{item['table']}`.`{item['index']}`")
        lines.append("")

    lines.append("## Table meta")
    lines.append("")
    if not diff.modified_tables:
        lines.append("- none")
        lines.append("")
    else:
        for item in diff.modified_tables:
            lines.append(f"- `{item['table']}` {json.dumps(item['changes'], ensure_ascii=False)}")
        lines.append("")
    return "\n".join(lines)


def diff_to_public_dict(diff: SchemaDiff) -> dict[str, Any]:
    return {
        "sourceEnv": diff.source_env,
        "targetEnv": diff.target_env,
        "sourceDatabase": diff.source_database,
        "targetDatabase": diff.target_database,
        "changeCount": diff.change_count,
        "tablesOnlyInSource": diff.tables_only_in_source,
        "tablesOnlyInTarget": diff.tables_only_in_target,
        "addedColumns": diff.added_columns,
        "droppedColumns": diff.dropped_columns,
        "modifiedColumns": diff.modified_columns,
        "addedIndexes": diff.added_indexes,
        "droppedIndexes": diff.dropped_indexes,
        "modifiedIndexes": diff.modified_indexes,
        "modifiedTables": diff.modified_tables,
    }
