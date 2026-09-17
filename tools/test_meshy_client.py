"""Offline contract tests for the guarded Meshy client."""
from __future__ import annotations

import hashlib
import json
from pathlib import Path
import tempfile
import unittest

from tools.meshy_client import MeshyClient, MeshyError, MeshyHttpError

ROOT = Path(__file__).resolve().parents[1]
FIXTURES = json.loads((ROOT / "tools" / "fixtures" / "meshy_responses.json").read_text(encoding="utf-8"))


class FixtureTransport:
    def __init__(self, *responses: str) -> None:
        self.responses = list(responses)
        self.calls: list[tuple[str, str]] = []

    def __call__(self, method: str, url: str, body: dict | None) -> tuple[int, dict[str, str], bytes]:
        self.calls.append((method, url))
        name = self.responses.pop(0)
        if name == "download":
            item = FIXTURES[name]
            return item["status"], item["headers"], item["body_utf8"].encode()
        item = FIXTURES["errors"][name] if name in {"401", "402", "429"} else FIXTURES[name]
        return item["status"], {}, json.dumps(item["body"]).encode()


class MeshyClientTests(unittest.TestCase):
    def setUp(self) -> None:
        self.record = {"asset_id": "oak_tree", "prompt": "a temperate oak tree", "config": {"art_style": "realistic"}}
        self.budget = {"approved": True, "request_ids": ["oak_tree"], "max_new_meshy_jobs": 1}

    def client(self, transport: FixtureTransport) -> tuple[MeshyClient, Path]:
        directory = Path(tempfile.mkdtemp())
        return MeshyClient(directory, transport, sleep=lambda _: None), directory

    def test_dry_run_needs_no_key_or_network(self) -> None:
        transport = FixtureTransport()
        client, _ = self.client(transport)
        result = client.create_or_resume(self.record, {"approved": False}, execute=False)
        self.assertEqual(result["status"], "DRY_RUN")
        self.assertEqual(transport.calls, [])

    def test_execute_requires_key_and_approved_budget(self) -> None:
        import os
        client, _ = self.client(FixtureTransport("create"))
        with self.assertRaises(MeshyError):
            client.create_or_resume(self.record, self.budget, execute=True)
        os.environ["MESHY_API_KEY"] = "test-only"
        with self.assertRaises(MeshyError):
            client.create_or_resume(self.record, {"approved": False}, execute=True)
        os.environ.pop("MESHY_API_KEY", None)

    def test_duplicate_request_reuses_receipt_without_post(self) -> None:
        import os
        os.environ["MESHY_API_KEY"] = "test-only"
        transport = FixtureTransport("create")
        client, _ = self.client(transport)
        first = client.create_or_resume(self.record, self.budget, execute=True)
        second = client.create_or_resume(self.record, self.budget, execute=True)
        self.assertEqual(first, second)
        self.assertEqual([method for method, _ in transport.calls], ["POST"])
        os.environ.pop("MESHY_API_KEY", None)

    def test_poll_pending_then_success_and_failure(self) -> None:
        import os
        os.environ["MESHY_API_KEY"] = "test-only"
        transport = FixtureTransport("create", "pending", "success")
        client, _ = self.client(transport)
        client.create_or_resume(self.record, self.budget, execute=True)
        self.assertEqual(client.poll("oak_tree", attempts=2, interval=0)["status"], "SUCCEEDED")
        failure_transport = FixtureTransport("create", "failure")
        failure_client, _ = self.client(failure_transport)
        failure_client.create_or_resume(self.record, self.budget, execute=True)
        self.assertEqual(failure_client.poll("oak_tree")["status"], "FAILED")
        os.environ.pop("MESHY_API_KEY", None)

    def test_http_errors_are_explicit(self) -> None:
        import os
        os.environ["MESHY_API_KEY"] = "test-only"
        for code in ("401", "402", "429"):
            client, _ = self.client(FixtureTransport(code))
            with self.assertRaises(MeshyHttpError) as caught:
                client.create_or_resume(self.record, self.budget, execute=True)
            self.assertEqual(caught.exception.status, int(code))
        os.environ.pop("MESHY_API_KEY", None)

    def test_timeout_marks_submission_unknown_and_never_retries(self) -> None:
        import os
        os.environ["MESHY_API_KEY"] = "test-only"
        calls = 0
        def timeout(method: str, url: str, body: dict | None) -> tuple[int, dict[str, str], bytes]:
            nonlocal calls
            calls += 1
            raise TimeoutError()
        client, _ = self.client(timeout)  # type: ignore[arg-type]
        self.assertEqual(client.create_or_resume(self.record, self.budget, execute=True)["status"], "SUBMISSION_UNKNOWN")
        self.assertEqual(client.create_or_resume(self.record, self.budget, execute=True)["status"], "SUBMISSION_UNKNOWN")
        self.assertEqual(calls, 1)
        os.environ.pop("MESHY_API_KEY", None)

    def test_resume_known_task_and_verify_download_size_and_hash(self) -> None:
        import os
        os.environ["MESHY_API_KEY"] = "test-only"
        digest = hashlib.sha256(b"GLB!").hexdigest()
        transport = FixtureTransport("create", "success", "download")
        client, directory = self.client(transport)
        client.create_or_resume(self.record, self.budget, execute=True)
        client.poll("oak_tree")
        output = directory / "oak.glb"
        self.assertEqual(client.download_glb("oak_tree", output, digest), output)
        self.assertEqual(output.read_bytes(), b"GLB!")

        corrupt_transport = FixtureTransport("create", "success", "download")
        corrupt_client, corrupt_dir = self.client(corrupt_transport)
        corrupt_client.create_or_resume(self.record, self.budget, execute=True)
        corrupt_client.poll("oak_tree")
        with self.assertRaises(MeshyError):
            corrupt_client.download_glb("oak_tree", corrupt_dir / "bad.glb", "0" * 64)

        large_transport = FixtureTransport("create", "success", "download")
        large_client, large_dir = self.client(large_transport)
        large_client.create_or_resume(self.record, self.budget, execute=True)
        large_client.poll("oak_tree")
        with self.assertRaises(MeshyError):
            large_client.download_glb("oak_tree", large_dir / "large.glb", max_bytes=3)
        os.environ.pop("MESHY_API_KEY", None)


if __name__ == "__main__":
    unittest.main()
