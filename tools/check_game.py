#!/usr/bin/env python3
"""Import the Godot project and run one registered offline game suite.

Purpose: Give contributors one reproducible command for project import and a
real Godot test suite.
Reads: GODOT_BIN (optional), docs/toolchain.lock.json, and game files.
Writes: phase logs beneath artifacts/; no game or source files are changed.
Safe changes: Add narrowly-scoped suite names only when the Godot runner owns
them. Keep version and failure checks strict.
Failure: Missing tools, timeouts, engine errors, empty counts, and nonzero
process exits return a nonzero status with a plain-language explanation.
"""
from __future__ import annotations

import argparse
from dataclasses import dataclass
import json
from pathlib import Path
import os
import re
import shutil
import subprocess
import sys
import time
from typing import Callable, Sequence

ROOT = Path(__file__).resolve().parents[1]
LOCK_PATH = ROOT / "docs" / "toolchain.lock.json"
DEFAULT_TIMEOUT_SECONDS = 30
ERROR_MARKERS = (
    "SCRIPT ERROR",
    "Parse Error",
    "Parser Error",
    "ERROR:",
    "GDScript backtrace",
)
COUNT_PATTERN = re.compile(r"Tests:\s+executed=(\d+)\s+passed=(\d+)\s+failed=(\d+)")
Runner = Callable[..., subprocess.CompletedProcess[str]]


@dataclass(frozen=True)
class PhaseResult:
    """The captured result of one Godot subprocess phase."""

    name: str
    command: tuple[str, ...]
    output: str
    returncode: int
    timed_out: bool = False


def _godot_path(environment: dict[str, str] | None = None) -> str | None:
    """Resolve GODOT_BIN first, then the executable available on PATH."""
    env = os.environ if environment is None else environment
    configured = env.get("GODOT_BIN", "").strip()
    if configured:
        return configured
    return shutil.which("godot")


def _expected_version(lock_path: Path = LOCK_PATH) -> str:
    """Read the exact candidate version string recorded by T001."""
    record = json.loads(lock_path.read_text(encoding="utf-8"))
    return str(record["godot"]["binary_version_output"])


def _run(command: Sequence[str], timeout: int, runner: Runner = subprocess.run) -> PhaseResult:
    """Run a command with captured combined output and an explicit timeout."""
    try:
        completed = runner(
            list(command), cwd=ROOT, text=True, stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT, timeout=timeout, check=False,
        )
        return PhaseResult("process", tuple(command), completed.stdout or "", completed.returncode)
    except subprocess.TimeoutExpired as exc:
        output = exc.stdout or ""
        if isinstance(output, bytes):
            output = output.decode(errors="replace")
        return PhaseResult("process", tuple(command), output, 124, timed_out=True)
    except OSError as exc:
        return PhaseResult("process", tuple(command), str(exc), 127)


def _has_engine_error(output: str) -> bool:
    """Recognize Godot errors that can be printed while returning exit code 0."""
    return any(marker.lower() in output.lower() for marker in ERROR_MARKERS)


def _write_log(result: PhaseResult, directory: Path, suffix: str) -> Path:
    """Retain the exact command output so a reviewer can inspect the result."""
    directory.mkdir(parents=True, exist_ok=True)
    path = directory / f"check_game_{suffix}.log"
    path.write_text(
        "$ " + " ".join(result.command) + "\n" + result.output,
        encoding="utf-8",
    )
    return path


def _failure(result: PhaseResult, phase: str) -> str | None:
    if result.timed_out:
        return f"{phase} timed out after {DEFAULT_TIMEOUT_SECONDS} seconds."
    if result.returncode != 0:
        return f"{phase} failed with exit code {result.returncode}."
    if _has_engine_error(result.output):
        return f"{phase} reported a Godot/script error despite exit code 0."
    return None


def check_game(
    suite: str,
    godot_bin: str | None = None,
    timeout: int = DEFAULT_TIMEOUT_SECONDS,
    root: Path = ROOT,
    runner: Runner = subprocess.run,
) -> tuple[int, str]:
    """Run version, import, and suite phases; return process status and report."""
    binary = godot_bin or _godot_path()
    if not binary:
        return 2, "ERROR: Godot prerequisite missing; set GODOT_BIN or install godot on PATH."
    expected = _expected_version(root / "docs" / "toolchain.lock.json")
    stamp = time.strftime("%Y%m%d-%H%M%S")
    log_dir = root / "artifacts"
    version = _run((binary, "--version"), timeout, runner)
    version_log = _write_log(version, log_dir, f"{stamp}_version")
    problem = _failure(version, "Godot version check")
    if problem:
        return 1, f"ERROR: {problem} Expected {expected}. Log: {version_log}"
    if expected not in version.output:
        return 1, f"ERROR: Godot version mismatch; expected {expected}. Log: {version_log}"

    import_result = _run((binary, "--headless", "--path", str(root / "game"), "--editor", "--quit-after", "2"), timeout, runner)
    import_log = _write_log(import_result, log_dir, f"{stamp}_import")
    problem = _failure(import_result, "Godot project import")
    if problem:
        return 1, f"ERROR: {problem} Log: {import_log}"

    suite_result = _run((binary, "--headless", "--path", str(root / "game"), "--script", "res://tests/run_tests.gd", "--", "--suite", suite), timeout, runner)
    suite_log = _write_log(suite_result, log_dir, f"{stamp}_suite_{suite}")
    problem = _failure(suite_result, f"Suite '{suite}'")
    if problem:
        return 1, f"ERROR: {problem} Log: {suite_log}"
    match = COUNT_PATTERN.search(suite_result.output)
    if not match:
        return 1, f"ERROR: Suite '{suite}' produced no test counts. Log: {suite_log}"
    executed, passed, failed = (int(value) for value in match.groups())
    if executed == 0 or failed:
        return 1, f"ERROR: Suite '{suite}' did not pass: executed={executed} passed={passed} failed={failed}. Log: {suite_log}"
    return 0, f"PASS: suite={suite} executed={executed} passed={passed} failed={failed}; logs: {import_log}, {suite_log}"


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--suite", required=True, help="Registered Godot suite, for example smoke.")
    args = parser.parse_args(argv)
    code, message = check_game(args.suite)
    print(message, file=sys.stderr if code else sys.stdout)
    return code


if __name__ == "__main__":
    raise SystemExit(main())
