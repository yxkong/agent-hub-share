from __future__ import annotations

import importlib.util
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


SKILL_ROOT = Path(__file__).resolve().parents[1]
SCRIPT_PATH = SKILL_ROOT / "scripts" / "spec_compiler_check.py"


def load_checker():
    spec = importlib.util.spec_from_file_location("spec_compiler_check", SCRIPT_PATH)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"cannot load checker: {SCRIPT_PATH}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


def feature_spec(domain: str = "backend", approval: str = "frozen") -> str:
    return f"""---
title: {domain} Feature Spec
status: canonical
document_type: feature_spec
spec_id: SPEC-sample
version: 1.0.0
approval: {approval}
created: 2026-07-28
updated: 2026-07-28
---

# Feature Spec: {domain}

## 修订记录

| 版本 | 日期 | 修订要点 |
|---|---|---|
| 1.0.0 | 2026-07-28 | 初稿 |

## 1. Fact Pack

| ID | 类型 | 证据等级 | 内容 |
|---|---|---|---|
| FACT-001 | current_code | executed | 已核验当前入口 |

### Assumptions

- 无影响方向的假设。

### Unknowns

- 无阻断项。

### Risks

- 回归风险由自动化测试控制。

## 2. 目标与价值

目标是交付一个可观察、可验证的 {domain} 行为。

## 3. 范围

### In Scope

- 完成主链路。

### Out of Scope

- 不改变无关模块。

## 4. 用户场景

用户触发动作后得到一致结果。

## 5. 需求与业务规则

| ID | 需求 | 事实来源 | 优先级 |
|---|---|---|---|
| REQ-001 | 主链路必须返回结构化结果 | FACT-001 | P0 |

## 6. 契约

请求、响应、状态和权限边界保持一致。

## 7. 非功能与安全

| ID | 类型 | 可量化约束 |
|---|---|---|
| NFR-001 | latency | P95 小于 500ms |
| SEC-001 | authorization | 未授权请求拒绝率 100% |

## 8. 验收标准

| ID | 对应需求 | 可观察结果 |
|---|---|---|
| AC-001 | REQ-001 | 主链路返回结构化结果 |

## 9. TDD / 验证映射

| 验收项 | 可测试行为 | 验证类型 | 证据等级 |
|---|---|---|---|
| AC-001 | 调用主入口 | TDD | runtime |

## 10. 风险与人工确认点

没有需要升级人工的 P0 风险。

## 11. 追踪矩阵

| 需求 | 设计 | 验收 |
|---|---|---|
| REQ-001 | SDD §4 | AC-001 |
| NFR-001 | SDD §7 | AC-001 |
| SEC-001 | SDD §7 | AC-001 |
"""


def sdd(domain: str = "backend", approval: str = "frozen", spec_version: str = "1.0.0") -> str:
    return f"""---
title: {domain} SDD
status: canonical
document_type: sdd
spec_id: SPEC-sample
spec_version: {spec_version}
version: 1.0.0
approval: {approval}
created: 2026-07-28
updated: 2026-07-28
---

# SDD: {domain}

## 修订记录

| 版本 | 日期 | 修订要点 |
|---|---|---|
| 1.0.0 | 2026-07-28 | 初稿 |

## 1. 上游规格

承接 SPEC-sample 1.0.0。

## 2. 设计目标

实现 REQ-001，并满足 NFR-001 与 SEC-001。

## 3. 系统边界

入口、应用编排和基础设施边界明确。

## 4. 方案设计

REQ-001 由单一应用入口编排，DEC-001 约束依赖方向。

## 5. 取舍与 ADR

DEC-001 选择最小依赖方案。

## 6. TDD 映射

AC-001 使用 Red / Green / Refactor 验证。

## 7. 验证与证据

NFR-001 与 SEC-001 使用 runtime 证据验证。

## 8. 交付文档质量门

所有 P0 需求均已追踪。

## 9. 风险与回退

失败时关闭入口并恢复旧版本。
"""


def adr(domain: str = "backend", decision_status: str = "accepted") -> str:
    return f"""---
title: {domain} ADR
status: canonical
document_type: adr
spec_id: SPEC-sample
spec_version: 1.0.0
version: 1.0.0
decision_status: {decision_status}
created: 2026-07-28
updated: 2026-07-28
---

# ADR: {domain}

## 修订记录

| 版本 | 日期 | 修订要点 |
|---|---|---|
| 1.0.0 | 2026-07-28 | 初稿 |

## 状态

DEC-001 已形成明确决策。

## 背景

REQ-001 存在两个可行实现。

## 约束

必须遵守 SEC-001。

## 备选方案

比较直接调用与应用编排两种方案。

## 决策

DEC-001 选择应用编排。

## 决策原因

边界稳定且易于验证。

## 影响范围

影响应用入口，不改变数据契约。

## 回滚方案

关闭新入口并恢复旧实现。

## 后续验证

使用 AC-001 验证。
"""


def task_contract(domain: str = "backend", approval: str = "frozen") -> str:
    return f"""---
title: {domain} Task Contract
status: canonical
document_type: task_contract
spec_id: SPEC-sample
spec_version: 1.0.0
version: 1.0.0
approval: {approval}
created: 2026-07-28
updated: 2026-07-28
---

# Task Contract: {domain}

## 修订记录

| 版本 | 日期 | 修订要点 |
|---|---|---|
| 1.0.0 | 2026-07-28 | 初稿 |

## 任务目标

TASK-001 实现 REQ-001。

## 路由

backend。

## 输入

SPEC-sample、SDD 和 DEC-001。

## 范围

### 只允许改

- 应用入口和相邻测试。

### 禁止改

- 无关模块和共享契约。

### 越界处理

发现越界立即停止。

## 契约

保持请求、响应、权限和状态一致。

## Project Contract

本任务不触发跨项目契约。

## 验收标准

TASK-001 覆盖 AC-001。

## TDD 执行判定

AC-001 使用 TDD，先 Red 再 Green。

## 主链证据矩阵

AC-001 的证据等级为 runtime。

## 回退方式

关闭新入口并恢复旧实现。

## 完成状态

允许 DONE / DONE_WITH_CONCERNS / NEEDS_CONTEXT / BLOCKED。
"""


class SpecCompilerCheckTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.checker = load_checker()

    def write_bundle(self, root: Path, domain: str = "backend") -> dict[str, Path]:
        docs = {
            "spec": feature_spec(domain),
            "sdd": sdd(domain),
            "adr": adr(domain),
            "task_contract": task_contract(domain),
        }
        paths: dict[str, Path] = {}
        for name, body in docs.items():
            path = root / f"{name}.md"
            path.write_text(body, encoding="utf-8", newline="\n")
            paths[name] = path
        return paths

    def test_three_held_out_bundles_are_implementation_ready(self) -> None:
        for domain in ("backend", "fullstack", "security"):
            with self.subTest(domain=domain), tempfile.TemporaryDirectory() as temp_dir:
                report = self.checker.validate_bundle(
                    self.write_bundle(Path(temp_dir), domain),
                    mode="implementation-ready",
                )
                self.assertTrue(report.ok, report.to_dict())

    def test_empty_required_section_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            paths = self.write_bundle(Path(temp_dir))
            body = paths["spec"].read_text(encoding="utf-8")
            body = body.replace(
                "## 2. 目标与价值\n\n目标是交付一个可观察、可验证的 backend 行为。",
                "## 2. 目标与价值\n",
            )
            paths["spec"].write_text(body, encoding="utf-8", newline="\n")
            report = self.checker.validate_bundle(paths, mode="document")
            self.assertIn("EMPTY_SECTION", report.codes)

    def test_placeholder_is_rejected_in_document_mode(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            paths = self.write_bundle(Path(temp_dir))
            body = paths["spec"].read_text(encoding="utf-8")
            paths["spec"].write_text(
                body.replace("Feature Spec: backend", "Feature Spec: <标题>"),
                encoding="utf-8",
                newline="\n",
            )
            report = self.checker.validate_bundle(paths, mode="document")
            self.assertIn("PLACEHOLDER", report.codes)

    def test_review_spec_is_not_implementation_ready(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            paths = self.write_bundle(Path(temp_dir))
            paths["spec"].write_text(
                feature_spec(approval="review"),
                encoding="utf-8",
                newline="\n",
            )
            report = self.checker.validate_bundle(paths, mode="implementation-ready")
            self.assertIn("NOT_FROZEN", report.codes)

    def test_spec_version_drift_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            paths = self.write_bundle(Path(temp_dir))
            paths["sdd"].write_text(
                sdd(spec_version="0.9.0"),
                encoding="utf-8",
                newline="\n",
            )
            report = self.checker.validate_bundle(paths, mode="document")
            self.assertIn("SPEC_VERSION_MISMATCH", report.codes)

    def test_proposed_adr_is_not_implementation_ready(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            paths = self.write_bundle(Path(temp_dir))
            paths["adr"].write_text(
                adr(decision_status="proposed"),
                encoding="utf-8",
                newline="\n",
            )
            report = self.checker.validate_bundle(paths, mode="implementation-ready")
            self.assertIn("ADR_NOT_ACCEPTED", report.codes)

    def test_missing_sdd_trace_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            paths = self.write_bundle(Path(temp_dir))
            body = paths["sdd"].read_text(encoding="utf-8")
            paths["sdd"].write_text(
                body.replace("REQ-001", "需求一"),
                encoding="utf-8",
                newline="\n",
            )
            report = self.checker.validate_bundle(paths, mode="document")
            self.assertIn("TRACE_SPEC_TO_SDD", report.codes)

    def test_templates_pass_template_mode(self) -> None:
        paths = {
            "spec": SKILL_ROOT / "templates" / "TEMPLATE_FEATURE_SPEC.md",
            "sdd": SKILL_ROOT / "templates" / "TEMPLATE_SDD.md",
            "adr": SKILL_ROOT / "templates" / "TEMPLATE_ADR.md",
            "task_contract": SKILL_ROOT / "templates" / "TEMPLATE_TASK_CONTRACT.md",
        }
        report = self.checker.validate_bundle(paths, mode="template")
        self.assertTrue(report.ok, report.to_dict())

    def test_cli_ready_mode_does_not_load_default_brainstorm(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            paths = self.write_bundle(root)
            result = self.checker.main(
                [
                    "--hub-root",
                    str(SKILL_ROOT.parents[2]),
                    "--mode",
                    "implementation-ready",
                    "--spec",
                    str(paths["spec"]),
                    "--sdd",
                    str(paths["sdd"]),
                    "--adr",
                    str(paths["adr"]),
                    "--task-contract",
                    str(paths["task_contract"]),
                    "--json-output",
                    str(root / "report.json"),
                ]
            )
            self.assertEqual(0, result)
            self.assertTrue((root / "report.json").is_file())

    def test_explicit_brainstorm_is_still_validated(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            paths = self.write_bundle(root)
            brainstorm = root / "brainstorm.md"
            brainstorm.write_text(
                "---\nstatus: in_progress\n---\n\n# Brainstorm\n",
                encoding="utf-8",
                newline="\n",
            )
            paths["brainstorm"] = brainstorm
            report = self.checker.validate_bundle(
                paths,
                mode="implementation-ready",
            )
            self.assertIn("BRAINSTORM_CONTRACT", report.codes)
            self.assertIn("BRAINSTORM_NOT_CLOSED", report.codes)

    @unittest.skipUnless(shutil.which("pwsh"), "pwsh is not available")
    def test_powershell_wrapper_supports_template_mode(self) -> None:
        command = [
            "pwsh",
            "-NoProfile",
            "-File",
            str(SKILL_ROOT / "scripts" / "check-spec-sdd-structure.ps1"),
            "-HubRoot",
            str(SKILL_ROOT.parents[2]),
            "-Mode",
            "template",
        ]
        result = subprocess.run(
            command,
            capture_output=True,
            encoding="utf-8",
            errors="replace",
            check=False,
        )
        self.assertEqual(0, result.returncode, result.stdout + result.stderr)
        self.assertIn("SPEC_SDD_STRUCTURE=ok", result.stdout)


if __name__ == "__main__":
    unittest.main()
