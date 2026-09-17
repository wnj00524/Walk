"""Test visual wrapper validation without launching Godot."""
from __future__ import annotations

import json
from pathlib import Path
import tempfile
import unittest

from tools import run_visual


class VisualWrapperTests(unittest.TestCase):
    def test_missing_report_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            valid, message = run_visual.validate_capture_outputs(Path(directory))
        self.assertFalse(valid)
        self.assertIn("report", message)

    def test_headless_report_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory)
            route = {"poses": [{"name": "overview"}]}
            route_path = output / "route.json"
            route_path.write_text(json.dumps(route), encoding="utf-8")
            (output / "capture_report.json").write_text(json.dumps({"display_server": "headless"}), encoding="utf-8")
            (output / "overview.png").write_bytes(b"png")
            valid, message = run_visual.validate_capture_outputs(output, route_path)
        self.assertFalse(valid)
        self.assertIn("real display", message)

    def test_complete_route_is_accepted(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory)
            route = {"poses": [{"name": "overview"}, {"name": "return_trip"}]}
            route_path = output / "route.json"
            route_path.write_text(json.dumps(route), encoding="utf-8")
            (output / "capture_report.json").write_text(json.dumps({"display_server": "windows"}), encoding="utf-8")
            for pose in route["poses"]:
                (output / f"{pose['name']}.png").write_bytes(b"png")
            valid, message = run_visual.validate_capture_outputs(output, route_path)
        self.assertTrue(valid, message)


if __name__ == "__main__":
    unittest.main()
