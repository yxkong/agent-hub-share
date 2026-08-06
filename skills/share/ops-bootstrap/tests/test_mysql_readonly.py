from __future__ import annotations

import json
import os
import sys
import tempfile
import unittest
from pathlib import Path


SKILL_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(SKILL_ROOT / "scripts"))

from core.errors import OpsError
from core.mysql_readonly import (
    QueryResult,
    execute_readonly_sql,
    resolve_connection_options,
    validate_readonly_sql,
)


class FakeCursor:
    def __init__(self) -> None:
        self.executed: list[tuple[str, object]] = []
        self.description = [("id",), ("password_hash",), ("name",)]
        self.closed = False

    def execute(self, sql: str, params=None) -> None:
        self.executed.append((sql, params))

    def fetchmany(self, size: int):
        return [
            {"id": 1, "password_hash": "secret-a", "name": "alpha"},
            {"id": 2, "password_hash": "secret-b", "name": "beta"},
            {"id": 3, "password_hash": "secret-c", "name": "gamma"},
        ][:size]

    def close(self) -> None:
        self.closed = True


class FakeConnection:
    def __init__(self) -> None:
        self.cursor_instance = FakeCursor()
        self.rollback_count = 0

    def cursor(self, **_kwargs):
        return self.cursor_instance

    def rollback(self) -> None:
        self.rollback_count += 1


class ReadonlySqlValidationTest(unittest.TestCase):
    def test_allows_select_show_explain_and_readonly_cte(self) -> None:
        for sql in (
            "SELECT * FROM users",
            "SHOW COLUMNS FROM users",
            "EXPLAIN SELECT * FROM users",
            "WITH recent AS (SELECT id FROM users) SELECT * FROM recent",
        ):
            self.assertTrue(validate_readonly_sql(sql))

    def test_rejects_write_cte_multi_statement_and_file_side_effects(self) -> None:
        blocked = (
            "UPDATE users SET status = 0",
            "WITH ids AS (SELECT id FROM users) DELETE FROM users WHERE id IN (SELECT id FROM ids)",
            "SELECT 1; DROP TABLE users",
            "SELECT * FROM users INTO OUTFILE '/tmp/users.csv'",
            "SELECT @value := 1",
        )
        for sql in blocked:
            with self.subTest(sql=sql), self.assertRaises(OpsError):
                validate_readonly_sql(sql)

    def test_project_denylist_cannot_weaken_builtin_safety(self) -> None:
        with self.assertRaises(OpsError):
            validate_readonly_sql(
                "WITH ids AS (SELECT id FROM users) UPDATE users SET status = 0",
                denied_prefixes=["DELETE"],
            )


class CredentialResolutionTest(unittest.TestCase):
    def test_resolves_credentials_from_environment_without_plaintext_config(self) -> None:
        options = resolve_connection_options(
            {
                "host": "127.0.0.1",
                "port": 3306,
                "database": "app",
                "credentials": {
                    "type": "env",
                    "usernameEnv": "OPS_TEST_DB_USER",
                    "passwordEnv": "OPS_TEST_DB_PASSWORD",
                },
            },
            Path("ops.config.json"),
            environ={"OPS_TEST_DB_USER": "readonly", "OPS_TEST_DB_PASSWORD": "hidden"},
        )

        self.assertEqual("readonly", options["user"])
        self.assertEqual("hidden", options["password"])

    def test_resolves_credentials_from_private_json_relative_to_config(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            config_path = root / "ops.config.json"
            secret_path = root / ".private" / "db.json"
            secret_path.parent.mkdir()
            secret_path.write_text(
                json.dumps({"username": "reader", "password": "private"}),
                encoding="utf-8",
            )

            options = resolve_connection_options(
                {
                    "host": "db.internal",
                    "database": "app",
                    "credentials": {"type": "json-file", "path": ".private/db.json"},
                },
                config_path,
            )

            self.assertEqual("reader", options["user"])
            self.assertEqual("private", options["password"])

    def test_rejects_plaintext_password_in_shared_config(self) -> None:
        with self.assertRaises(OpsError):
            resolve_connection_options(
                {"host": "db.internal", "database": "app", "password": "do-not-store"},
                Path("ops.config.json"),
            )

    def test_rejects_non_object_credential_json(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            secret_path = root / "db.json"
            secret_path.write_text("[]", encoding="utf-8")
            with self.assertRaises(OpsError):
                resolve_connection_options(
                    {
                        "host": "db.internal",
                        "database": "app",
                        "credentials": {"type": "json-file", "path": str(secret_path)},
                    },
                    root / "ops.config.json",
                )

    def test_rejects_invalid_port(self) -> None:
        with self.assertRaises(OpsError):
            resolve_connection_options(
                {
                    "host": "db.internal",
                    "port": 70000,
                    "database": "app",
                    "credentials": {
                        "type": "env",
                        "usernameEnv": "OPS_TEST_DB_USER",
                        "passwordEnv": "OPS_TEST_DB_PASSWORD",
                    },
                },
                Path("ops.config.json"),
                environ={"OPS_TEST_DB_USER": "reader", "OPS_TEST_DB_PASSWORD": "hidden"},
            )


class ReadonlyExecutionTest(unittest.TestCase):
    def test_limits_redacts_and_always_rolls_back(self) -> None:
        connection = FakeConnection()

        result = execute_readonly_sql(
            connection,
            "SELECT id, password_hash, name FROM users",
            max_rows=2,
            timeout_seconds=3,
            redact_columns=["password", "token"],
        )

        self.assertIsInstance(result, QueryResult)
        self.assertEqual(2, len(result.rows))
        self.assertTrue(result.truncated)
        self.assertEqual("***REDACTED***", result.rows[0]["password_hash"])
        self.assertEqual(1, connection.rollback_count)
        self.assertTrue(connection.cursor_instance.closed)
        self.assertEqual("START TRANSACTION READ ONLY", connection.cursor_instance.executed[0][0])


if __name__ == "__main__":
    unittest.main()
