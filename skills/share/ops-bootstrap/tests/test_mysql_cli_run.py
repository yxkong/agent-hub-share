from __future__ import annotations

import argparse
import io
import json
import os
import sys
import tempfile
import unittest
from contextlib import redirect_stdout
from pathlib import Path
from unittest.mock import patch


SKILL_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(SKILL_ROOT / "scripts"))

from commands.db_verify import expectation_passes, run_db_execute
from commands.query import run_query_execute, run_query_plan
from core.errors import OpsError
from core.mysql_readonly import QueryResult
from ecs_ops import build_parser


class CliParserContractTest(unittest.TestCase):
    def test_exposes_query_and_db_run_commands(self) -> None:
        parser = build_parser()

        query_args = parser.parse_args(
            [
                "query",
                "run",
                "--config",
                "ops.config.json",
                "--sql",
                "SELECT 1",
                "--confirm-readonly",
            ]
        )
        db_args = parser.parse_args(
            ["db", "run", "--config", "ops.config.json", "--confirm-readonly"]
        )

        self.assertEqual("query", query_args.command)
        self.assertEqual("run", query_args.query_command)
        self.assertEqual("db", db_args.command)
        self.assertEqual("run", db_args.db_command)


class QueryRunContractTest(unittest.TestCase):
    def test_plan_reports_credential_reference_type_without_secret_values(self) -> None:
        template = SKILL_ROOT / "templates" / "query" / "TEMPLATE_query.config.json"
        output = io.StringIO()
        with redirect_stdout(output):
            exit_code = run_query_plan(argparse.Namespace(config=str(template)))

        rendered = output.getvalue()
        self.assertEqual(0, exit_code)
        self.assertIn("auth=env", rendered)
        self.assertNotIn("OPS_MYSQL_PASSWORD=", rendered)

    def test_executes_configured_readonly_query_without_printing_credentials(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            config_path = Path(temp_dir) / "ops.config.json"
            config_path.write_text(
                json.dumps(
                    {
                        "query": {
                            "defaultMode": "readonly",
                            "mysql": {
                                "enabled": True,
                                "connection": {
                                    "host": "127.0.0.1",
                                    "database": "app",
                                    "credentials": {
                                        "type": "env",
                                        "usernameEnv": "OPS_CLI_DB_USER",
                                        "passwordEnv": "OPS_CLI_DB_PASSWORD",
                                    },
                                },
                                "allowedPrefixes": ["SELECT", "SHOW", "EXPLAIN", "WITH"],
                                "deniedPrefixes": ["UPDATE", "DELETE"],
                                "redactColumns": ["password"],
                                "limits": {"maxRows": 10, "timeoutSeconds": 5},
                            },
                        }
                    }
                ),
                encoding="utf-8",
            )
            args = argparse.Namespace(
                config=str(config_path),
                sql="SELECT id FROM users",
                sql_file="",
                connection="",
                max_rows=None,
                confirm_readonly=True,
            )
            output = io.StringIO()
            result = QueryResult(["id"], [{"id": 1}], False)
            with patch.dict(
                os.environ,
                {"OPS_CLI_DB_USER": "reader", "OPS_CLI_DB_PASSWORD": "never-print-me"},
            ), patch("commands.query.run_readonly_query", return_value=result), redirect_stdout(output):
                exit_code = run_query_execute(args)

            rendered = output.getvalue()
            self.assertEqual(0, exit_code)
            self.assertIn('"rowCount": 1', rendered)
            self.assertNotIn("never-print-me", rendered)

    def test_requires_explicit_readonly_confirmation(self) -> None:
        args = argparse.Namespace(confirm_readonly=False)
        with self.assertRaises(OpsError):
            run_query_execute(args)


class DbExpectationContractTest(unittest.TestCase):
    def test_evaluates_supported_expectations(self) -> None:
        populated = QueryResult(["id"], [{"id": 1}], False)
        empty = QueryResult(["id"], [], False)

        self.assertTrue(expectation_passes("rows-present", populated))
        self.assertTrue(expectation_passes("rows-empty", empty))
        self.assertTrue(expectation_passes("no-error", empty))
        with self.assertRaises(OpsError):
            expectation_passes("unknown", empty)

    def test_db_run_executes_schema_and_data_checks_through_shared_executor(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            config_path = Path(temp_dir) / "ops.config.json"
            config_path.write_text(
                json.dumps(
                    {
                        "dbVerify": {
                            "mode": "readonly",
                            "connection": {
                                "type": "mysql",
                                "host": "127.0.0.1",
                                "database": "app",
                                "credentials": {
                                    "type": "env",
                                    "usernameEnv": "OPS_DB_RUN_USER",
                                    "passwordEnv": "OPS_DB_RUN_PASSWORD",
                                },
                            },
                            "schemaChecks": [
                                {"table": "users", "queries": ["SHOW COLUMNS FROM users"]}
                            ],
                            "dataChecks": [
                                {
                                    "name": "users-present",
                                    "sql": "SELECT id FROM users LIMIT 1",
                                    "expect": "rows-present",
                                }
                            ],
                            "safety": {
                                "allowedPrefixes": ["SELECT", "SHOW"],
                                "limits": {"maxRows": 10, "timeoutSeconds": 5},
                                "redactColumns": ["password"],
                            },
                        }
                    }
                ),
                encoding="utf-8",
            )
            args = argparse.Namespace(
                config=str(config_path),
                check=None,
                confirm_readonly=True,
            )
            result = QueryResult(["id"], [{"id": 1}], False)
            output = io.StringIO()
            with patch.dict(
                os.environ,
                {"OPS_DB_RUN_USER": "reader", "OPS_DB_RUN_PASSWORD": "never-print-me"},
            ), patch("commands.db_verify.run_readonly_query", return_value=result) as executor, redirect_stdout(output):
                exit_code = run_db_execute(args)

            self.assertEqual(0, exit_code)
            self.assertEqual(2, executor.call_count)
            self.assertIn('"check": "schema:users:1"', output.getvalue())
            self.assertIn('"check": "users-present"', output.getvalue())
            self.assertNotIn("never-print-me", output.getvalue())


if __name__ == "__main__":
    unittest.main()
