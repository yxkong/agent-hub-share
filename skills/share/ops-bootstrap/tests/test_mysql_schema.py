from __future__ import annotations

import sys
import unittest
from dataclasses import asdict
from pathlib import Path

SKILL_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(SKILL_ROOT / "scripts"))

from core.mysql_schema import (
    ColumnDef,
    IndexDef,
    SchemaSnapshot,
    TableDef,
    diff_schemas,
    format_column_ddl,
    parse_account_markdown,
    render_report,
    render_sql_bundle,
)


def _column(name: str, column_type: str = "varchar(32)", nullable: str = "NO", default: str | None = "", extra: str = "", comment: str = "", position: int = 1) -> ColumnDef:
    return ColumnDef(
        name=name,
        column_type=column_type,
        is_nullable=nullable,
        column_default=default,
        extra=extra,
        column_comment=comment,
        character_set_name="utf8mb4",
        collation_name="utf8mb4_general_ci",
        ordinal_position=position,
    )


class ParseAccountMarkdownTest(unittest.TestCase):
    def test_parses_prod_and_dev_without_exposing_extra_keys(self) -> None:
        text = """
## 生产数据库
- 链接方式：生产跳板机
- 链接地址：prod.example.mysql.rds.aliyuncs.com
- 账户：htyc_rw
- 密码：secret-prod
- 数据库：platform
- 读写权限：只读

## 开发数据库
- 链接方式：本地直连
- 链接地址：dev.example.mysql.rds.aliyuncs.com
- 账户：htyc_rw
- 密码：secret-dev
- 数据库：platform-bak
- 读写权限：只读
"""
        accounts = parse_account_markdown(text)
        self.assertEqual(set(accounts), {"prod", "dev"})
        self.assertEqual(accounts["prod"]["host"], "prod.example.mysql.rds.aliyuncs.com")
        self.assertEqual(accounts["dev"]["database"], "platform-bak")
        self.assertEqual(accounts["prod"]["password"], "secret-prod")

    def test_rejects_missing_password(self) -> None:
        text = """
## 生产数据库
- 链接方式：生产跳板机
- 链接地址：prod.example.com
- 账户：htyc_rw
- 数据库：platform
"""
        with self.assertRaises(Exception):
            parse_account_markdown(text)


class SchemaDiffAndDdlTest(unittest.TestCase):
    def _snapshots(self) -> tuple[SchemaSnapshot, SchemaSnapshot]:
        source = SchemaSnapshot(env_name="prod", database="platform")
        target = SchemaSnapshot(env_name="dev", database="platform-bak")
        source.tables["user"] = TableDef(
            name="user",
            engine="InnoDB",
            table_collation="utf8mb4_general_ci",
            table_comment="user",
            create_sql="CREATE TABLE `user` (\n  `id` bigint NOT NULL,\n  PRIMARY KEY (`id`)\n) ENGINE=InnoDB",
        )
        source.tables["user"].columns["id"] = _column("id", "bigint", extra="auto_increment", position=1)
        source.tables["user"].columns["name"] = _column("name", "varchar(64)", comment="姓名", position=2)
        source.tables["user"].columns["status"] = _column("status", "tinyint", default="0", position=3)
        source.tables["user"].indexes["PRIMARY"] = IndexDef("PRIMARY", 0, "BTREE", ["id"], [None])
        source.tables["user"].indexes["idx_name"] = IndexDef("idx_name", 1, "BTREE", ["name"], [None])

        source.tables["only_prod"] = TableDef(
            name="only_prod",
            engine="InnoDB",
            table_collation="utf8mb4_general_ci",
            table_comment="",
            create_sql="CREATE TABLE `only_prod` (`id` int NOT NULL, PRIMARY KEY (`id`)) ENGINE=InnoDB",
        )
        source.tables["only_prod"].columns["id"] = _column("id", "int", extra="auto_increment")

        target.tables["user"] = TableDef(
            name="user",
            engine="InnoDB",
            table_collation="utf8mb4_general_ci",
            table_comment="user",
        )
        target.tables["user"].columns["id"] = _column("id", "bigint", extra="auto_increment", position=1)
        target.tables["user"].columns["name"] = _column("name", "varchar(32)", comment="姓名", position=2)
        target.tables["user"].columns["legacy"] = _column("legacy", "varchar(8)", position=3)
        target.tables["user"].indexes["PRIMARY"] = IndexDef("PRIMARY", 0, "BTREE", ["id"], [None])

        target.tables["only_dev"] = TableDef(
            name="only_dev",
            engine="InnoDB",
            table_collation="utf8mb4_general_ci",
            table_comment="",
        )
        target.tables["only_dev"].columns["id"] = _column("id", "int")
        return source, target

    def test_diff_classifies_add_drop_modify(self) -> None:
        source, target = self._snapshots()
        diff = diff_schemas(source, target)
        self.assertEqual(diff.tables_only_in_source, ["only_prod"])
        self.assertEqual(diff.tables_only_in_target, ["only_dev"])
        added = {(item["table"], item["column"]) for item in diff.added_columns}
        dropped = {(item["table"], item["column"]) for item in diff.dropped_columns}
        modified = {(item["table"], item["column"]) for item in diff.modified_columns}
        self.assertIn(("user", "status"), added)
        self.assertIn(("user", "legacy"), dropped)
        self.assertIn(("user", "name"), modified)
        self.assertTrue(any(item["index"] == "idx_name" for item in diff.added_indexes))

    def test_sql_bundle_keeps_drop_out_of_safe_file(self) -> None:
        source, target = self._snapshots()
        diff = diff_schemas(source, target)
        bundle = render_sql_bundle(source, target, diff)
        self.assertIn("CREATE TABLE `only_prod`", bundle["safe"])
        self.assertIn("ADD COLUMN `status`", bundle["safe"])
        self.assertIn("ADD INDEX `idx_name`", bundle["safe"])
        self.assertNotIn("DROP COLUMN", bundle["safe"])
        self.assertNotIn("DROP TABLE", bundle["safe"])
        self.assertIn("MODIFY COLUMN `name` varchar(64)", bundle["modify"])
        self.assertIn("DROP TABLE IF EXISTS `only_dev`", bundle["destructive"])
        self.assertIn("DROP COLUMN `legacy`", bundle["destructive"])

    def test_report_does_not_include_passwords(self) -> None:
        source, target = self._snapshots()
        diff = diff_schemas(source, target)
        report = render_report(diff)
        self.assertNotIn("secret", report)
        self.assertNotIn("password", report.lower())
        self.assertIn("changeCount", report)

    def test_format_column_keeps_auto_increment_without_default(self) -> None:
        sql = format_column_ddl(_column("id", "bigint", extra="auto_increment", default=None, nullable="NO"))
        self.assertIn("AUTO_INCREMENT", sql.upper())
        self.assertNotIn("DEFAULT", sql)

    def test_asdict_snapshot_contains_no_credential_fields(self) -> None:
        source, _target = self._snapshots()
        payload = asdict(source)
        self.assertNotIn("password", payload)
        self.assertNotIn("user", payload)


if __name__ == "__main__":
    unittest.main()
