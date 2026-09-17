"""Unit tests for the Python game-check wrapper using independent process fixtures."""
from __future__ import annotations

from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

from tools import check_game


class CheckGameTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        (self.root / "docs").mkdir()
        (self.root / "docs" / "toolchain.lock.json").write_text(
            '{"godot":{"binary_version_output":"4.6.2.stable.official.test"}}', encoding="utf-8"
        )

    def tearDown(self) -> None:
        self.temp.cleanup()

    def fake_runner(self, outputs: list[tuple[int, str]]):
        def run(*_args, **_kwargs):
            code, output = outputs.pop(0)
            return subprocess.CompletedProcess([], code, output)
        return run

    def test_success_requires_import_and_real_count(self) -> None:
        runner = self.fake_runner([
            (0, "4.6.2.stable.official.test"),
            (0, "import complete"),
            (0, "Tests: executed=1 passed=1 failed=0\n"),
        ])
        code, report = check_game.check_game("smoke", godot_bin="godot", root=self.root, runner=runner)
        self.assertEqual(code, 0)
        self.assertIn("executed=1", report)

    def test_error_marker_fails_exit_zero_fixture(self) -> None:
        runner = self.fake_runner([
            (0, "4.6.2.stable.official.test"),
            (0, "SCRIPT ERROR: broken import"),
        ])
        code, report = check_game.check_game("smoke", godot_bin="godot", root=self.root, runner=runner)
        self.assertNotEqual(code, 0)
        self.assertIn("import", report.lower())

    def test_timeout_is_nonzero(self) -> None:
        def timeout_runner(*_args, **_kwargs):
            raise subprocess.TimeoutExpired("godot", 1, output="waiting")
        code, report = check_game.check_game("smoke", godot_bin="godot", root=self.root, runner=timeout_runner)
        self.assertNotEqual(code, 0)
        self.assertIn("timed out", report)

    def test_missing_binary_is_nonzero(self) -> None:
        with patch.object(check_game, "_godot_path", return_value=None):
            code, report = check_game.check_game("smoke", root=self.root)
        self.assertNotEqual(code, 0)
        self.assertIn("prerequisite missing", report)

    def test_empty_or_unknown_suite_counts_as_failure(self) -> None:
        runner = self.fake_runner([
            (0, "4.6.2.stable.official.test"),
            (0, "import complete"),
            (1, "Unknown suite: 'other'\nTests: executed=0 passed=0 failed=1"),
        ])
        code, report = check_game.check_game("other", godot_bin="godot", root=self.root, runner=runner)
        self.assertNotEqual(code, 0)
        self.assertIn("Suite", report)


if __name__ == "__main__":
    unittest.main()
