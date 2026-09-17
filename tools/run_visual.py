#!/usr/bin/env python3
"""Run the real-renderer terrain capture route and validate retained outputs.

Purpose: Provide one repeatable GPU/display command for T015's fixed viewpoints.
Reads: GODOT_BIN (optional), the locked Godot version, and game/tests/visual_route.json.
Writes: PNG captures and a JSON report beneath the requested artifacts directory.
Safe changes: Add named route checks; never accept headless or empty output.
Failure: Missing GPU/display, engine errors, timeout, missing images, or missing report returns nonzero.
"""
from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
ROUTE_PATH = ROOT / "game" / "tests" / "visual_route.json"
DEFAULT_OUTPUT = ROOT / "artifacts" / "T015_visual_capture"


def godot_path() -> str | None:
    return os.environ.get("GODOT_BIN", "").strip() or shutil.which("godot")


def validate_capture_outputs(output_dir: Path, route_path: Path = ROUTE_PATH) -> tuple[bool, str]:
    """Require every route image and a non-empty machine-readable report."""
    try:
        route = json.loads(route_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        return False, f"route cannot be read: {exc}"
    report_path = output_dir / "capture_report.json"
    if not report_path.is_file() or report_path.stat().st_size == 0:
        return False, f"capture report is missing or empty: {report_path}"
    try:
        report = json.loads(report_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        return False, f"capture report is invalid: {exc}"
    if report.get("display_server") in (None, "headless"):
        return False, "capture report does not prove a real display"
    for pose in route.get("poses", []):
        image_path = output_dir / f"{pose['name']}.png"
        if not image_path.is_file() or image_path.stat().st_size == 0:
            return False, f"capture image is missing or empty: {image_path}"
    return True, f"validated {len(route.get('poses', []))} captures and report {report_path}"


def run_visual(output_dir: Path = DEFAULT_OUTPUT, binary: str | None = None, timeout: int = 180) -> tuple[int, str]:
    """Run the non-headless Godot scene and validate its retained outputs."""
    executable = binary or godot_path()
    if not executable:
        return 2, "NOT RUN: Godot executable is unavailable"
    output_dir = output_dir.resolve()
    output_dir.mkdir(parents=True, exist_ok=True)
    command = (
        executable, "--path", str(ROOT / "game"),
        "--scene", "res://tests/visual_capture.tscn",
        "--", "--output-dir", str(output_dir),
    )
    try:
        completed = subprocess.run(
            command, cwd=ROOT, text=True, stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT, timeout=timeout, check=False,
        )
    except subprocess.TimeoutExpired:
        return 1, f"ERROR: visual capture timed out after {timeout} seconds"
    log_path = output_dir / "godot_capture.log"
    log_path.write_text("$ " + " ".join(command) + "\n" + (completed.stdout or ""), encoding="utf-8")
    if completed.returncode != 0:
        return 1, f"ERROR: visual capture exited {completed.returncode}; log: {log_path}"
    valid, message = validate_capture_outputs(output_dir)
    if not valid:
        return 1, f"ERROR: {message}; log: {log_path}"
    return 0, f"PASS: {message}; log: {log_path}"


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output-dir", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument("--timeout", type=int, default=180)
    args = parser.parse_args(argv)
    code, message = run_visual(args.output_dir, timeout=args.timeout)
    print(message, file=sys.stderr if code else sys.stdout)
    return code


if __name__ == "__main__":
    raise SystemExit(main())
