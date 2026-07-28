#!/usr/bin/env python3
"""Validate and export a portable share-skill dependency closure."""

from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
from dataclasses import asdict, dataclass, field
from pathlib import Path
from typing import Iterable


MANIFEST_NAME = "skill-package.json"
PORTABILITY_VALUES = {"standalone", "composed"}
IGNORED_PARTS = {"bak", ".tmp", "__pycache__", ".git", ".pytest_cache"}
TEXT_SUFFIXES = {
    ".md",
    ".json",
    ".yaml",
    ".yml",
    ".py",
    ".ps1",
    ".sh",
    ".txt",
    ".toml",
    ".ini",
    ".cfg",
    ".awk",
}
SCRIPT_SUFFIXES = {".py", ".ps1", ".sh", ".awk"}
HUB_ENV_KEYS = {
    "AGENTS_HUB_ROOT",
    "AGENTS_DEFAULT_PROJECT_ROOT",
    "AGENTS_DEFAULT_PROJECT_KEY",
}
VERSION_RE = re.compile(r"^\d+\.\d+\.\d+$")
SKILL_NAME_RE = re.compile(r"(?m)^name:\s*([a-z0-9][a-z0-9-]*)\s*$")
MARKDOWN_LINK_RE = re.compile(r"\[[^\]]*\]\(([^)]+)\)")
CROSS_SKILL_RE = re.compile(
    r"skills[\\/]+share[\\/]+([a-z0-9][a-z0-9-]*)[\\/]+",
    re.IGNORECASE,
)
EXTERNAL_HUB_SCRIPT_PATTERNS = (
    re.compile(
        r"(?:\.\.[\\/]){2,}(?:scripts|prompts|docs|rules|plugins|dist)",
        re.IGNORECASE,
    ),
    re.compile(
        r"\$?(?:env:)?AGENTS_HUB_ROOT[\\/]+(?:scripts|prompts|docs|rules|plugins|dist)",
        re.IGNORECASE,
    ),
)


@dataclass(frozen=True)
class Violation:
    code: str
    skill: str
    path: str
    message: str


@dataclass
class PackageReport:
    target: str
    skill_root: Path
    skills_root: Path
    members: list[str] = field(default_factory=list)
    member_roots: dict[str, Path] = field(default_factory=dict)
    manifests: dict[str, dict[str, object]] = field(default_factory=dict)
    violations: list[Violation] = field(default_factory=list)
    file_count: int = 0
    smoke_count: int = 0

    @property
    def ok(self) -> bool:
        return not self.violations

    @property
    def codes(self) -> set[str]:
        return {item.code for item in self.violations}

    def to_dict(self) -> dict[str, object]:
        return {
            "ok": self.ok,
            "target": self.target,
            "members": self.members,
            "file_count": self.file_count,
            "smoke_count": self.smoke_count,
            "violations": [asdict(item) for item in self.violations],
        }


def _add(
    report: PackageReport,
    code: str,
    skill: str,
    path: Path | str,
    message: str,
) -> None:
    report.violations.append(
        Violation(code=code, skill=skill, path=str(path), message=message)
    )


def _read_json(path: Path) -> dict[str, object] | None:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError):
        return None
    return value if isinstance(value, dict) else None


def _string_list(
    manifest: dict[str, object],
    field_name: str,
    report: PackageReport,
    skill: str,
    manifest_path: Path,
) -> list[str]:
    value = manifest.get(field_name, [])
    if not isinstance(value, list) or any(
        not isinstance(item, str) or not re.fullmatch(r"[a-z0-9][a-z0-9-]*", item)
        for item in value
    ):
        _add(
            report,
            "INVALID_MANIFEST",
            skill,
            manifest_path,
            f"{field_name} must be an array of skill names",
        )
        return []
    if len(value) != len(set(value)):
        _add(
            report,
            "INVALID_MANIFEST",
            skill,
            manifest_path,
            f"{field_name} contains duplicate names",
        )
    return list(dict.fromkeys(value))


def _load_manifest(
    skill_root: Path,
    report: PackageReport,
    expected_name: str,
) -> dict[str, object] | None:
    manifest_path = skill_root / MANIFEST_NAME
    if not manifest_path.is_file():
        _add(
            report,
            "MISSING_MANIFEST",
            expected_name,
            manifest_path,
            f"missing {MANIFEST_NAME}",
        )
        return None
    manifest = _read_json(manifest_path)
    if manifest is None:
        _add(
            report,
            "INVALID_MANIFEST",
            expected_name,
            manifest_path,
            "manifest must be a UTF-8 JSON object",
        )
        return None
    if manifest.get("schema_version") != 1:
        _add(
            report,
            "INVALID_MANIFEST",
            expected_name,
            manifest_path,
            "schema_version must be 1",
        )
    name = manifest.get("name")
    if name != expected_name:
        _add(
            report,
            "NAME_MISMATCH",
            expected_name,
            manifest_path,
            f"manifest name must match directory name: {expected_name}",
        )
    version = manifest.get("version")
    if not isinstance(version, str) or not VERSION_RE.fullmatch(version):
        _add(
            report,
            "INVALID_MANIFEST",
            expected_name,
            manifest_path,
            "version must use numeric major.minor.patch",
        )
    portability = manifest.get("portability")
    if portability not in PORTABILITY_VALUES:
        _add(
            report,
            "INVALID_MANIFEST",
            expected_name,
            manifest_path,
            "portability must be standalone or composed",
        )
    requires = _string_list(
        manifest, "requires", report, expected_name, manifest_path
    )
    optional = _string_list(
        manifest, "optional_skills", report, expected_name, manifest_path
    )
    if set(requires) & set(optional):
        _add(
            report,
            "INVALID_MANIFEST",
            expected_name,
            manifest_path,
            "a skill cannot be both required and optional",
        )
    if portability == "standalone" and requires:
        _add(
            report,
            "INVALID_MANIFEST",
            expected_name,
            manifest_path,
            "standalone package cannot declare required skills",
        )
    runtime = manifest.get("runtime", {})
    if not isinstance(runtime, dict) or any(
        not isinstance(key, str) or not isinstance(value, str)
        for key, value in runtime.items()
    ):
        _add(
            report,
            "INVALID_MANIFEST",
            expected_name,
            manifest_path,
            "runtime must be an object of string constraints",
        )
    smoke = manifest.get("smoke", [])
    if not isinstance(smoke, list):
        _add(
            report,
            "INVALID_MANIFEST",
            expected_name,
            manifest_path,
            "smoke must be an array",
        )
    skill_md = skill_root / "SKILL.md"
    if not skill_md.is_file():
        _add(report, "MISSING_SKILL", expected_name, skill_md, "missing SKILL.md")
    else:
        match = SKILL_NAME_RE.search(skill_md.read_text(encoding="utf-8"))
        if not match or match.group(1) != expected_name:
            _add(
                report,
                "NAME_MISMATCH",
                expected_name,
                skill_md,
                "SKILL.md name must match package name",
            )
    return manifest


def _active_files(skill_root: Path) -> Iterable[Path]:
    for path in skill_root.rglob("*"):
        relative = path.relative_to(skill_root)
        if any(part in IGNORED_PARTS for part in relative.parts):
            continue
        if path.is_file() or path.is_symlink():
            yield path


def _is_within(path: Path, root: Path) -> bool:
    try:
        path.resolve().relative_to(root.resolve())
        return True
    except (OSError, ValueError):
        return False


def _scan_member(
    name: str,
    root: Path,
    manifest: dict[str, object],
    report: PackageReport,
) -> None:
    required = set(item for item in manifest.get("requires", []) if isinstance(item, str))
    optional = set(
        item for item in manifest.get("optional_skills", []) if isinstance(item, str)
    )
    allowed_names = required | optional | {name}
    for path in _active_files(root):
        report.file_count += 1
        if path.is_symlink() and not _is_within(path, root):
            _add(
                report,
                "EXTERNAL_SYMLINK",
                name,
                path,
                "symlink or junction target escapes the skill root",
            )
            continue
        if path.suffix.lower() not in TEXT_SUFFIXES:
            continue
        try:
            text = path.read_text(encoding="utf-8")
        except (OSError, UnicodeError):
            _add(
                report,
                "INVALID_TEXT",
                name,
                path,
                "active text asset must be readable as UTF-8",
            )
            continue
        if path.suffix.lower() in SCRIPT_SUFFIXES:
            for pattern in EXTERNAL_HUB_SCRIPT_PATTERNS:
                if pattern.search(text):
                    _add(
                        report,
                        "EXTERNAL_HUB_PATH",
                        name,
                        path,
                        "script accesses a Hub-root asset outside the skill package",
                    )
                    break
        for referenced_name in CROSS_SKILL_RE.findall(text):
            if referenced_name.lower() not in allowed_names:
                _add(
                    report,
                    "UNDECLARED_SKILL_PATH",
                    name,
                    path,
                    f"physical path references undeclared skill: {referenced_name}",
                )
        if path.suffix.lower() == ".md":
            for raw_link in MARKDOWN_LINK_RE.findall(text):
                link = raw_link.strip().strip("<>")
                if (
                    not link
                    or link.startswith(("#", "http://", "https://", "mailto:"))
                    or "$" in link
                    or "<" in link
                ):
                    continue
                file_part = link.split("#", 1)[0]
                if not file_part or Path(file_part).is_absolute():
                    continue
                resolved = (path.parent / file_part).resolve()
                if not _is_within(resolved, root):
                    _add(
                        report,
                        "EXTERNAL_MARKDOWN_LINK",
                        name,
                        path,
                        f"relative Markdown link escapes skill root: {link}",
                    )
                elif not resolved.exists():
                    _add(
                        report,
                        "MISSING_INTERNAL_ASSET",
                        name,
                        path,
                        f"relative Markdown link target does not exist: {link}",
                    )


def _resolve_graph(
    target_root: Path,
    skills_root: Path,
    report: PackageReport,
) -> None:
    visited: set[str] = set()
    visiting: list[str] = []

    def visit(name: str, root: Path) -> None:
        if name in visited:
            return
        if name in visiting:
            cycle = " -> ".join(visiting + [name])
            _add(
                report,
                "DEPENDENCY_CYCLE",
                name,
                root,
                f"required dependency cycle: {cycle}",
            )
            return
        visiting.append(name)
        manifest = _load_manifest(root, report, name)
        if manifest is not None:
            report.member_roots[name] = root
            report.manifests[name] = manifest
            for dependency in _string_list(
                manifest, "requires", report, name, root / MANIFEST_NAME
            ):
                dependency_root = skills_root / dependency
                if not dependency_root.is_dir():
                    _add(
                        report,
                        "MISSING_DEPENDENCY",
                        name,
                        dependency_root,
                        f"required skill not found: {dependency}",
                    )
                    continue
                visit(dependency, dependency_root)
        visiting.pop()
        visited.add(name)
        report.members.append(name)

    visit(target_root.name, target_root)


def _copy_members(report: PackageReport, destination: Path) -> None:
    skills_destination = destination / "skills"
    skills_destination.mkdir(parents=True, exist_ok=True)

    def ignore(_directory: str, names: list[str]) -> set[str]:
        return {name for name in names if name in IGNORED_PARTS}

    for name in report.members:
        source = report.member_roots.get(name)
        if source is None:
            continue
        shutil.copytree(
            source,
            skills_destination / name,
            ignore=ignore,
            symlinks=False,
        )


def _run_smoke(
    report: PackageReport,
    *,
    extra_env: dict[str, str] | None = None,
) -> None:
    if report.violations:
        return
    with tempfile.TemporaryDirectory(prefix="skill-package-") as temp_dir:
        isolated_root = Path(temp_dir)
        _copy_members(report, isolated_root)
        env = os.environ.copy()
        if extra_env:
            env.update(extra_env)
        for key in HUB_ENV_KEYS:
            env.pop(key, None)
        for name in report.members:
            manifest = report.manifests[name]
            smoke_items = manifest.get("smoke", [])
            if not isinstance(smoke_items, list):
                continue
            cwd = isolated_root / "skills" / name
            for index, item in enumerate(smoke_items):
                if not isinstance(item, dict):
                    _add(
                        report,
                        "INVALID_SMOKE",
                        name,
                        cwd / MANIFEST_NAME,
                        f"smoke[{index}] must be an object",
                    )
                    continue
                command = item.get("command")
                expected_exit = item.get("expect_exit", 0)
                expected_output = item.get("expect_output", "")
                if (
                    not isinstance(command, list)
                    or not command
                    or any(not isinstance(part, str) for part in command)
                    or not isinstance(expected_exit, int)
                    or not isinstance(expected_output, str)
                ):
                    _add(
                        report,
                        "INVALID_SMOKE",
                        name,
                        cwd / MANIFEST_NAME,
                        f"smoke[{index}] has invalid command or expectations",
                    )
                    continue
                resolved_command = [
                    sys.executable if part == "{python}" else part for part in command
                ]
                try:
                    result = subprocess.run(
                        resolved_command,
                        cwd=cwd,
                        env=env,
                        capture_output=True,
                        encoding="utf-8",
                        errors="replace",
                        timeout=60,
                        check=False,
                    )
                except (OSError, subprocess.TimeoutExpired) as exc:
                    _add(
                        report,
                        "SMOKE_EXECUTION_ERROR",
                        name,
                        cwd,
                        f"smoke[{index}] could not run: {exc}",
                    )
                    continue
                report.smoke_count += 1
                combined = result.stdout + result.stderr
                if result.returncode != expected_exit:
                    _add(
                        report,
                        "SMOKE_EXIT_MISMATCH",
                        name,
                        cwd,
                        f"smoke[{index}] exit={result.returncode}, expected={expected_exit}",
                    )
                if expected_output and expected_output not in combined:
                    _add(
                        report,
                        "SMOKE_OUTPUT_MISSING",
                        name,
                        cwd,
                        f"smoke[{index}] missing output: {expected_output}",
                    )


def validate_package(
    skill_root: Path,
    skills_root: Path,
    *,
    run_smoke: bool = False,
    extra_env: dict[str, str] | None = None,
) -> PackageReport:
    resolved_skill = skill_root.resolve()
    resolved_skills = skills_root.resolve()
    report = PackageReport(
        target=resolved_skill.name,
        skill_root=resolved_skill,
        skills_root=resolved_skills,
    )
    if not resolved_skill.is_dir():
        _add(
            report,
            "MISSING_SKILL_ROOT",
            resolved_skill.name,
            resolved_skill,
            "skill root does not exist",
        )
        return report
    if not _is_within(resolved_skill, resolved_skills):
        _add(
            report,
            "SKILL_ROOT_OUTSIDE",
            resolved_skill.name,
            resolved_skill,
            "skill root must be located under skills root",
        )
        return report
    _resolve_graph(resolved_skill, resolved_skills, report)
    for name in report.members:
        root = report.member_roots.get(name)
        manifest = report.manifests.get(name)
        if root is not None and manifest is not None:
            _scan_member(name, root, manifest, report)
    if run_smoke:
        _run_smoke(report, extra_env=extra_env)
    return report


def export_package(report: PackageReport, export_root: Path) -> dict[str, object]:
    if not report.ok:
        raise ValueError("cannot export an invalid package")
    destination = export_root.resolve()
    if destination.exists() and any(destination.iterdir()):
        raise ValueError(f"export directory must be empty: {destination}")
    destination.mkdir(parents=True, exist_ok=True)
    _copy_members(report, destination)
    lock = {
        "schema_version": 1,
        "target": report.target,
        "members": report.members,
        "versions": {
            name: report.manifests[name]["version"] for name in report.members
        },
        "file_count": report.file_count,
    }
    (destination / "skill-package-lock.json").write_text(
        json.dumps(lock, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
        newline="\n",
    )
    return lock


def _print_report(report: PackageReport) -> None:
    for item in report.violations:
        print(
            "SKILL_PACKAGE_VIOLATION="
            f"code={item.code} skill={item.skill} path={item.path} message={item.message}"
        )
    status = "ok" if report.ok else "fail"
    print(
        "SKILL_PACKAGE_CLOSURE="
        f"{status} target={report.target} members={len(report.members)} "
        f"files={report.file_count} smoke={report.smoke_count}"
    )


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--skill-root", default="")
    parser.add_argument("--skills-root", required=True)
    parser.add_argument("--all-manifests", action="store_true")
    parser.add_argument("--run-smoke", action="store_true")
    parser.add_argument("--export-dir", default="")
    parser.add_argument("--json-output", default="")
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    skills_root = Path(args.skills_root).resolve()
    if args.all_manifests:
        roots = sorted(
            path.parent
            for path in skills_root.glob(f"*/{MANIFEST_NAME}")
            if path.is_file()
        )
        if args.export_dir:
            raise SystemExit("--export-dir cannot be used with --all-manifests")
    else:
        if not args.skill_root:
            raise SystemExit("--skill-root is required unless --all-manifests is set")
        roots = [Path(args.skill_root).resolve()]
    reports = [
        validate_package(root, skills_root, run_smoke=args.run_smoke)
        for root in roots
    ]
    for report in reports:
        _print_report(report)
    if args.export_dir and reports and reports[0].ok:
        lock = export_package(reports[0], Path(args.export_dir))
        print(
            f"SKILL_PACKAGE_EXPORT=ok target={lock['target']} "
            f"members={len(lock['members'])}"
        )
    if args.json_output:
        output = Path(args.json_output)
        output.parent.mkdir(parents=True, exist_ok=True)
        output.write_text(
            json.dumps(
                {"ok": all(report.ok for report in reports),
                 "reports": [report.to_dict() for report in reports]},
                ensure_ascii=False,
                indent=2,
            )
            + "\n",
            encoding="utf-8",
            newline="\n",
        )
    if not reports:
        print("SKILL_PACKAGE_CLOSURE=skip reason=no-manifests")
        return 0
    return 0 if all(report.ok for report in reports) else 1


if __name__ == "__main__":
    raise SystemExit(main())
