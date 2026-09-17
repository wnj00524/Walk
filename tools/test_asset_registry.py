"""Test C06 asset validation without network access or provider credentials."""
from __future__ import annotations

import copy
import json
from pathlib import Path
import tempfile
import unittest

from tools import asset_registry


ROOT = Path(__file__).resolve().parents[1]


class AssetRegistryTests(unittest.TestCase):
    def setUp(self) -> None:
        self.requests = json.loads((ROOT / "asset_requests" / "initial.json").read_text(encoding="utf-8"))

    def test_examples_validate_and_catalogue_is_empty(self) -> None:
        self.assertEqual(asset_registry.validate_requests(self.requests, ROOT), [])
        self.assertEqual(asset_registry.validate_catalogue([], ROOT), [])

    def test_duplicate_ids_are_rejected(self) -> None:
        errors = asset_registry.validate_requests(self.requests + [copy.deepcopy(self.requests[0])], ROOT)
        self.assertTrue(any("duplicate asset_id" in error for error in errors))

    def test_approved_record_requires_existing_confined_file(self) -> None:
        record = copy.deepcopy(self.requests[0])
        record["status"] = "APPROVED"
        record["source_path"] = "game/assets/rock.glb"
        errors = asset_registry.validate_record(record, ROOT, ROOT / "game" / "assets")
        self.assertTrue(any("approved source_path is missing" in error for error in errors))

    def test_traversal_path_is_rejected(self) -> None:
        record = copy.deepcopy(self.requests[0])
        record["source_path"] = "../private.glb"
        errors = asset_registry.validate_record(record, ROOT)
        self.assertTrue(any("escapes" in error for error in errors))

    def test_bad_state_and_hash_are_rejected(self) -> None:
        record = copy.deepcopy(self.requests[0])
        record["status"] = "READY"
        record["prompt_hash"] = "0" * 64
        errors = asset_registry.validate_record(record, ROOT)
        self.assertTrue(any("invalid lifecycle state" in error for error in errors))
        self.assertTrue(any("prompt_hash does not match" in error for error in errors))

    def test_enabled_budget_needs_named_limits(self) -> None:
        budget = {"schema_version": 1, "approved": True, "request_ids": [], "max_new_meshy_jobs": 0, "max_new_elevenlabs_requests": 0}
        errors = asset_registry.validate_budget(budget, {self.requests[0]["asset_id"]})
        self.assertTrue(any("enabled budget" in error for error in errors))

    def test_example_budget_authorizes_zero_jobs(self) -> None:
        budget = json.loads((ROOT / "docs" / "asset_budget.example.json").read_text(encoding="utf-8"))
        self.assertEqual(asset_registry.validate_budget(budget, set()), [])


if __name__ == "__main__":
    unittest.main()
