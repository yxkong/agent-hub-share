#!/usr/bin/env python3
"""Deterministic validator for the ai-development-governance Spec Compiler."""

from __future__ import annotations

import argparse
import json
import re
import sys
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Iterable, Mapping


MODES = ("template", "document", "implementation-ready")
COMMON_METADATA = (
    "title",
    "status",
    "document_type",
    "version",
    "created",
    "updated",
)
DOCUMENT_METADATA = {
    "spec": COMMON_METADATA + ("spec_id", "approval"),
    "sdd": COMMON_METADATA + ("spec_id", "spec_version", "approval"),
    "adr": COMMON_METADATA + ("spec_id", "spec_version", "decision_status"),
    "task_contract": COMMON_METADATA + ("spec_id", "spec_version", "approval"),
}
REQUIRED_SECTIONS = {
    "spec": (
        "修订记录",
        "1. Fact Pack",
        "2. 目标与价值",
        "3. 范围",
        "4. 用户场景",
        "5. 需求与业务规则",
        "6. 契约",
        "7. 非功能与安全",
        "8. 验收标准",
        "9. TDD / 验证映射",
        "10. 风险与人工确认点",
        "11. 追踪矩阵",
    ),
    "sdd": (
        "修订记录",
        "1. 上游规格",
        "2. 设计目标",
        "3. 系统边界",
        "4. 方案设计",
        "5. 取舍与 ADR",
        "6. TDD 映射",
        "7. 验证与证据",
        "8. 交付文档质量门",
        "9. 风险与回退",
    ),
    "adr": (
        "修订记录",
        "状态",
        "背景",
        "约束",
        "备选方案",
        "决策",
        "决策原因",
        "影响范围",
        "回滚方案",
        "后续验证",
    ),
    "task_contract": (
        "修订记录",
        "任务目标",
        "路由",
        "输入",
        "范围",
        "契约",
        "Project Contract",
        "验收标准",
        "TDD 执行判定",
        "主链证据矩阵",
        "回退方式",
        "完成状态",
    ),
}
PLACEHOLDER_RE = re.compile(r"<[^>\n]+>|\b(?:TODO|TBD|FIXME)\b", re.IGNORECASE)
TRACE_ID_RE = re.compile(r"\b(?:FACT|REQ|NFR|SEC|AC|DEC|TASK|TEST|EVAL)-\d{3}\b")
OPEN_ITEM_RE = re.compile(r"\bOPEN-\d{3}\b|\|\s*open\s*\|", re.IGNORECASE)
HEADING_RE = re.compile(r"^##\s+(.+?)\s*$", re.MULTILINE)


@dataclass(frozen=True)
class Violation:
    code: str
    document: str
    message: str


@dataclass
class ValidationReport:
    mode: str
    checked: int
    violations: list[Violation]

    @property
    def ok(self) -> bool:
        return not self.violations

    @property
    def codes(self) -> set[str]:
        return {item.code for item in self.violations}

    def to_dict(self) -> dict[str, object]:
        return {
            "ok": self.ok,
            "mode": self.mode,
            "checked": self.checked,
            "violations": [asdict(item) for item in self.violations],
        }


@dataclass(frozen=True)
class ParsedDocument:
    name: str
    path: Path
    body: str
    metadata: dict[str, str]
    sections: dict[str, str]
    trace_ids: set[str]


def parse_front_matter(body: str) -> tuple[dict[str, str], str]:
    lines = body.splitlines()
    if not lines or lines[0].strip() != "---":
        return {}, body
    try:
        closing = next(index for index in range(1, len(lines)) if lines[index].strip() == "---")
    except StopIteration:
        return {}, body
    metadata: dict[str, str] = {}
    for line in lines[1:closing]:
        match = re.match(r"^([A-Za-z][A-Za-z0-9_-]*):\s*(.*?)\s*$", line)
        if match:
            metadata[match.group(1)] = match.group(2).strip().strip("\"'")
    return metadata, "\n".join(lines[closing + 1 :])


def parse_sections(markdown: str) -> dict[str, str]:
    matches = list(HEADING_RE.finditer(markdown))
    sections: dict[str, str] = {}
    for index, match in enumerate(matches):
        start = match.end()
        end = matches[index + 1].start() if index + 1 < len(matches) else len(markdown)
        sections[match.group(1).strip()] = markdown[start:end].strip()
    return sections


def parse_document(name: str, path: Path) -> ParsedDocument:
    body = path.read_text(encoding="utf-8")
    metadata, markdown = parse_front_matter(body)
    return ParsedDocument(
        name=name,
        path=path,
        body=body,
        metadata=metadata,
        sections=parse_sections(markdown),
        trace_ids=set(TRACE_ID_RE.findall(markdown)),
    )


def add(
    violations: list[Violation],
    code: str,
    document: str,
    message: str,
) -> None:
    violations.append(Violation(code=code, document=document, message=message))


def validate_metadata(
    document: ParsedDocument,
    mode: str,
    violations: list[Violation],
) -> None:
    required = DOCUMENT_METADATA.get(document.name, ())
    for field in required:
        if not document.metadata.get(field):
            add(
                violations,
                "MISSING_METADATA",
                document.name,
                f"missing metadata field: {field}",
            )
    if mode == "template":
        return
    status = document.metadata.get("status")
    if status not in {"in_progress", "canonical", "superseded", "blocked"}:
        add(violations, "INVALID_STATUS", document.name, f"invalid status: {status or '<empty>'}")
    if document.name in {"spec", "sdd", "task_contract"}:
        approval = document.metadata.get("approval")
        if approval not in {"draft", "review", "frozen"}:
            add(
                violations,
                "INVALID_APPROVAL",
                document.name,
                f"invalid approval: {approval or '<empty>'}",
            )
    if document.name == "adr":
        decision_status = document.metadata.get("decision_status")
        if decision_status not in {"proposed", "accepted", "superseded"}:
            add(
                violations,
                "INVALID_DECISION_STATUS",
                document.name,
                f"invalid decision_status: {decision_status or '<empty>'}",
            )


def validate_sections(
    document: ParsedDocument,
    mode: str,
    violations: list[Violation],
) -> None:
    for heading in REQUIRED_SECTIONS.get(document.name, ()):
        if heading not in document.sections:
            add(
                violations,
                "MISSING_SECTION",
                document.name,
                f"missing section: {heading}",
            )
        elif mode != "template" and not meaningful_content(document.sections[heading]):
            add(
                violations,
                "EMPTY_SECTION",
                document.name,
                f"empty section: {heading}",
            )
    if mode != "template":
        placeholder = PLACEHOLDER_RE.search(document.body)
        if placeholder:
            add(
                violations,
                "PLACEHOLDER",
                document.name,
                f"unresolved placeholder: {placeholder.group(0)}",
            )


def meaningful_content(content: str) -> bool:
    for line in content.splitlines():
        stripped = line.strip()
        if not stripped:
            continue
        if stripped.startswith("|") and set(stripped.replace("|", "").replace("-", "").strip()) == set():
            continue
        if stripped in {"-", "*", "—"}:
            continue
        return True
    return False


def ids_with_prefix(document: ParsedDocument, prefix: str) -> set[str]:
    marker = f"{prefix}-"
    return {item for item in document.trace_ids if item.startswith(marker)}


def require_ids(
    document: ParsedDocument,
    prefixes: Iterable[str],
    violations: list[Violation],
) -> None:
    for prefix in prefixes:
        if not ids_with_prefix(document, prefix):
            add(
                violations,
                "MISSING_TRACE_ID",
                document.name,
                f"missing {prefix}-NNN identifier",
            )


def validate_traceability(
    documents: Mapping[str, ParsedDocument],
    mode: str,
    violations: list[Violation],
) -> None:
    if mode == "template":
        return
    spec = documents.get("spec")
    sdd = documents.get("sdd")
    task = documents.get("task_contract")
    adr = documents.get("adr")
    if not spec:
        return
    require_ids(spec, ("FACT", "REQ", "NFR", "SEC", "AC"), violations)
    requirement_ids = set().union(
        ids_with_prefix(spec, "REQ"),
        ids_with_prefix(spec, "NFR"),
        ids_with_prefix(spec, "SEC"),
    )
    for requirement_id in sorted(requirement_ids):
        if spec.body.count(requirement_id) < 2:
            add(
                violations,
                "TRACE_MATRIX_MISSING",
                "spec",
                f"{requirement_id} is not mapped in the Spec trace matrix",
            )
    if sdd:
        missing = sorted((requirement_ids | ids_with_prefix(spec, "AC")) - sdd.trace_ids)
        for trace_id in missing:
            add(
                violations,
                "TRACE_SPEC_TO_SDD",
                "sdd",
                f"missing upstream trace id: {trace_id}",
            )
    if task:
        require_ids(task, ("TASK",), violations)
        for acceptance_id in sorted(ids_with_prefix(spec, "AC") - task.trace_ids):
            add(
                violations,
                "TRACE_SPEC_TO_TASK",
                "task_contract",
                f"missing acceptance trace id: {acceptance_id}",
            )
    if adr:
        require_ids(adr, ("DEC",), violations)
        if sdd:
            for decision_id in sorted(ids_with_prefix(adr, "DEC") - sdd.trace_ids):
                add(
                    violations,
                    "TRACE_ADR_TO_SDD",
                    "sdd",
                    f"missing ADR decision trace id: {decision_id}",
                )


def validate_bundle_metadata(
    documents: Mapping[str, ParsedDocument],
    mode: str,
    violations: list[Violation],
) -> None:
    if mode == "template":
        return
    spec = documents.get("spec")
    if not spec:
        return
    spec_id = spec.metadata.get("spec_id")
    spec_version = spec.metadata.get("version")
    for name, document in documents.items():
        if name == "spec" or name == "brainstorm":
            continue
        if document.metadata.get("spec_id") != spec_id:
            add(
                violations,
                "SPEC_ID_MISMATCH",
                name,
                f"expected spec_id {spec_id}, got {document.metadata.get('spec_id')}",
            )
        if document.metadata.get("spec_version") != spec_version:
            add(
                violations,
                "SPEC_VERSION_MISMATCH",
                name,
                f"expected spec_version {spec_version}, got {document.metadata.get('spec_version')}",
            )
    if mode != "implementation-ready":
        return
    for name in ("spec", "sdd", "task_contract"):
        document = documents.get(name)
        if not document:
            continue
        if document.metadata.get("status") != "canonical" or document.metadata.get("approval") != "frozen":
            add(
                violations,
                "NOT_FROZEN",
                name,
                "implementation-ready requires status=canonical and approval=frozen",
            )
        if OPEN_ITEM_RE.search(document.body):
            add(
                violations,
                "OPEN_ITEM",
                name,
                "implementation-ready document contains an open item",
            )
    adr = documents.get("adr")
    if adr and (
        adr.metadata.get("status") != "canonical"
        or adr.metadata.get("decision_status") != "accepted"
    ):
        add(
            violations,
            "ADR_NOT_ACCEPTED",
            "adr",
            "implementation-ready requires status=canonical and decision_status=accepted",
        )


def validate_brainstorm(
    path: Path,
    mode: str,
    violations: list[Violation],
) -> None:
    body = path.read_text(encoding="utf-8")
    required = (
        "## 1. 触发与目标",
        "## 2. 反迎合自检",
        "fact",
        "assumption",
        "unknown",
        "risk",
        "## 3. 方案选项",
        "## 6. 回灌计划",
        "Feature Spec",
        "Task Contract",
        "## 7. 关闭条件",
    )
    for token in required:
        if token not in body:
            add(violations, "BRAINSTORM_CONTRACT", "brainstorm", f"missing token: {token}")
    if mode == "implementation-ready" and "status: in_progress" in body:
        add(
            violations,
            "BRAINSTORM_NOT_CLOSED",
            "brainstorm",
            "implementation-ready requires brainstorm status done/superseded/blocked",
        )


def validate_bundle(
    paths: Mapping[str, Path | str],
    mode: str = "template",
) -> ValidationReport:
    if mode not in MODES:
        raise ValueError(f"mode must be one of: {', '.join(MODES)}")
    violations: list[Violation] = []
    documents: dict[str, ParsedDocument] = {}
    for name, raw_path in paths.items():
        path = Path(raw_path)
        if not path.is_file():
            add(violations, "MISSING_FILE", name, f"missing file: {path}")
            continue
        if name == "brainstorm":
            validate_brainstorm(path, mode, violations)
            continue
        document = parse_document(name, path)
        documents[name] = document
        validate_metadata(document, mode, violations)
        validate_sections(document, mode, violations)
    for required in ("spec", "sdd", "task_contract"):
        if required not in paths:
            add(violations, "MISSING_DOCUMENT", required, f"missing document input: {required}")
    validate_bundle_metadata(documents, mode, violations)
    validate_traceability(documents, mode, violations)
    return ValidationReport(mode=mode, checked=len(paths), violations=violations)


def resolve_defaults() -> dict[str, Path]:
    governance = Path(__file__).resolve().parents[1]
    return {
        "spec": governance / "templates" / "TEMPLATE_FEATURE_SPEC.md",
        "sdd": governance / "templates" / "TEMPLATE_SDD.md",
        "adr": governance / "templates" / "TEMPLATE_ADR.md",
        "task_contract": governance / "templates" / "TEMPLATE_TASK_CONTRACT.md",
    }


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--hub-root", default="")
    parser.add_argument("--brainstorm", default="")
    parser.add_argument("--spec", default="")
    parser.add_argument("--sdd", default="")
    parser.add_argument("--adr", default="")
    parser.add_argument("--task-contract", default="")
    parser.add_argument("--mode", choices=MODES, default="template")
    parser.add_argument("--json-output", default="")
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    paths = resolve_defaults()
    overrides = {
        "brainstorm": args.brainstorm,
        "spec": args.spec,
        "sdd": args.sdd,
        "adr": args.adr,
        "task_contract": args.task_contract,
    }
    for name, value in overrides.items():
        if value:
            paths[name] = Path(value).resolve()
    report = validate_bundle(paths, mode=args.mode)
    for violation in report.violations:
        print(
            "SPEC_COMPILER_VIOLATION="
            f"code={violation.code} document={violation.document} message={violation.message}"
        )
    if args.json_output:
        output_path = Path(args.json_output)
        output_path.parent.mkdir(parents=True, exist_ok=True)
        output_path.write_text(
            json.dumps(report.to_dict(), ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
            newline="\n",
        )
    status = "ok" if report.ok else "fail"
    print(f"SPEC_SDD_STRUCTURE={status} checked={report.checked} mode={report.mode}")
    return 0 if report.ok else 1


if __name__ == "__main__":
    sys.exit(main())
