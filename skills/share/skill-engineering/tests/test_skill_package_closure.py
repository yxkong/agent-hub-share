from __future__ import annotations

import importlib.util
import json
import sys
import tempfile
import unittest
from pathlib import Path


SKILL_ENGINEERING_ROOT = Path(__file__).resolve().parents[1]
SCRIPT_PATH = SKILL_ENGINEERING_ROOT / "scripts" / "skill_package_closure.py"


def load_checker():
    spec = importlib.util.spec_from_file_location("skill_package_closure", SCRIPT_PATH)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"cannot load checker: {SCRIPT_PATH}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


def write_skill(
    skills_root: Path,
    name: str,
    *,
    requires: list[str] | None = None,
    optional: list[str] | None = None,
    smoke: list[dict[str, object]] | None = None,
    extra_files: dict[str, str] | None = None,
) -> Path:
    root = skills_root / name
    root.mkdir(parents=True)
    (root / "SKILL.md").write_text(
        f"---\nname: {name}\ndescription: fixture\n---\n\n# {name}\n",
        encoding="utf-8",
        newline="\n",
    )
    manifest = {
        "schema_version": 1,
        "name": name,
        "version": "1.0.0",
        "portability": "composed" if requires else "standalone",
        "requires": requires or [],
        "optional_skills": optional or [],
        "runtime": {"python": "3"},
        "smoke": smoke or [],
    }
    (root / "skill-package.json").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
        newline="\n",
    )
    for relative, content in (extra_files or {}).items():
        path = root / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content, encoding="utf-8", newline="\n")
    return root


class SkillPackageClosureTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.checker = load_checker()

    def test_missing_manifest_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            skills_root = Path(temp_dir) / "skills"
            root = skills_root / "target"
            root.mkdir(parents=True)
            (root / "SKILL.md").write_text(
                "---\nname: target\ndescription: fixture\n---\n",
                encoding="utf-8",
            )
            report = self.checker.validate_package(root, skills_root)
            self.assertIn("MISSING_MANIFEST", report.codes)

    def test_required_dependency_is_exported_in_closure(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            base = Path(temp_dir)
            skills_root = base / "skills"
            write_skill(skills_root, "foundation")
            target = write_skill(skills_root, "target", requires=["foundation"])

            report = self.checker.validate_package(target, skills_root)
            self.assertTrue(report.ok, report.to_dict())
            self.assertEqual(["foundation", "target"], report.members)

            export_root = base / "export"
            lock = self.checker.export_package(report, export_root)
            self.assertTrue((export_root / "skills" / "target" / "SKILL.md").is_file())
            self.assertTrue((export_root / "skills" / "foundation" / "SKILL.md").is_file())
            self.assertEqual(["foundation", "target"], lock["members"])

    def test_missing_required_dependency_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            skills_root = Path(temp_dir) / "skills"
            target = write_skill(skills_root, "target", requires=["missing"])
            report = self.checker.validate_package(target, skills_root)
            self.assertIn("MISSING_DEPENDENCY", report.codes)

    def test_dependency_cycle_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            skills_root = Path(temp_dir) / "skills"
            first = write_skill(skills_root, "first", requires=["second"])
            write_skill(skills_root, "second", requires=["first"])
            report = self.checker.validate_package(first, skills_root)
            self.assertIn("DEPENDENCY_CYCLE", report.codes)

    def test_optional_dependency_may_be_absent(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            skills_root = Path(temp_dir) / "skills"
            target = write_skill(skills_root, "target", optional=["optional-helper"])
            report = self.checker.validate_package(target, skills_root)
            self.assertTrue(report.ok, report.to_dict())
            self.assertEqual(["target"], report.members)

    def test_script_hub_escape_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            skills_root = Path(temp_dir) / "skills"
            target = write_skill(
                skills_root,
                "target",
                extra_files={
                    "scripts/check.sh": (
                        'HUB_SCRIPTS_DIR=$(cd "$SKILL_SCRIPT_DIR/../../../../scripts" && pwd)\n'
                    )
                },
            )
            report = self.checker.validate_package(target, skills_root)
            self.assertIn("EXTERNAL_HUB_PATH", report.codes)

    def test_undeclared_cross_skill_path_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            skills_root = Path(temp_dir) / "skills"
            target = write_skill(
                skills_root,
                "target",
                extra_files={
                    "references/workflow.md": (
                        "调用 `skills/share/other-skill/scripts/run.py` 完成执行。\n"
                    )
                },
            )
            report = self.checker.validate_package(target, skills_root)
            self.assertIn("UNDECLARED_SKILL_PATH", report.codes)

    def test_missing_internal_markdown_asset_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            skills_root = Path(temp_dir) / "skills"
            target = write_skill(
                skills_root,
                "target",
                extra_files={
                    "references/workflow.md": (
                        "执行前读取 [缺失契约](missing-contract.md)。\n"
                    )
                },
            )
            report = self.checker.validate_package(target, skills_root)
            self.assertIn("MISSING_INTERNAL_ASSET", report.codes)

    def test_smoke_runs_in_isolated_copy_without_hub_environment(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            skills_root = Path(temp_dir) / "skills"
            target = write_skill(
                skills_root,
                "target",
                smoke=[
                    {
                        "command": ["{python}", "scripts/smoke.py"],
                        "expect_exit": 0,
                        "expect_output": "ISOLATED_SMOKE=ok",
                    }
                ],
                extra_files={
                    "scripts/smoke.py": (
                        "import os\n"
                        "if os.environ.get('AGENTS_HUB_ROOT'):\n"
                        "    raise SystemExit(1)\n"
                        "print('ISOLATED_SMOKE=ok')\n"
                    )
                },
            )
            report = self.checker.validate_package(
                target,
                skills_root,
                run_smoke=True,
                extra_env={"AGENTS_HUB_ROOT": "must-be-removed"},
            )
            self.assertTrue(report.ok, report.to_dict())
            self.assertEqual(1, report.smoke_count)


if __name__ == "__main__":
    unittest.main()
