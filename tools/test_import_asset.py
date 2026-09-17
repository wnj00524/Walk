"""Offline GLB importer tests using generated minimal binary fixtures."""
from __future__ import annotations

import json
from pathlib import Path
import struct
import tempfile
import unittest

from tools.import_asset import AssetImportError, inspect_asset


def make_glb(path: Path, meshes: list[dict] | None = None, dependency_uri: str | None = None, bound_value: float = 1.0) -> None:
    mesh_data = meshes if meshes is not None else [{"primitives": [{"attributes": {"POSITION": 0}, "indices": 1}]}]
    document = {"asset": {"version": "2.0"}, "nodes": [{"mesh": 0}], "meshes": mesh_data, "materials": [{}], "accessors": [{"type": "VEC3", "min": [-1, 0, -1], "max": [bound_value, 2, 1]}, {"type": "SCALAR", "componentType": 5123, "count": 3}]}
    if dependency_uri is not None:
        document["buffers"] = [{"uri": dependency_uri}]
    encoded = json.dumps(document, separators=(",", ":")).encode()
    encoded += b" " * ((4 - len(encoded) % 4) % 4)
    raw = struct.pack("<III", 0x46546C67, 2, 20 + len(encoded)) + struct.pack("<II", len(encoded), 0x4E4F534A) + encoded
    path.write_bytes(raw)


class ImportAssetTests(unittest.TestCase):
    def test_reports_measured_counts_bounds_hash_and_wrapper(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            source = Path(directory) / "fixture.glb"
            make_glb(source)
            report = inspect_asset(source, wrapper_scale=0.5, pivot_y_m=0.25)
            self.assertEqual(report["counts"]["meshes"], 1)
            self.assertEqual(report["counts"]["triangles_from_index_accessors"], 1)
            self.assertEqual(report["bounds_m"]["max"], [1.0, 2.0, 1.0])
            self.assertEqual(report["wrapper_transform"]["scale"], 0.5)
            self.assertFalse(report["blender_dependency"])

    def test_rejects_missing_empty_oversized_and_malformed_inputs(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            with self.assertRaises(AssetImportError):
                inspect_asset(root / "missing.glb")
            empty = root / "empty.glb"
            empty.write_bytes(b"")
            with self.assertRaises(AssetImportError):
                inspect_asset(empty)
            malformed = root / "bad.glb"
            malformed.write_bytes(b"glTF" + b"\0" * 16)
            with self.assertRaises(AssetImportError):
                inspect_asset(malformed)
            oversized = root / "large.glb"
            make_glb(oversized)
            with self.assertRaises(AssetImportError):
                inspect_asset(oversized, max_bytes=10)

    def test_rejects_meshless_and_nonpositive_scale(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            source = Path(directory) / "fixture.glb"
            make_glb(source, meshes=[])
            with self.assertRaises(AssetImportError):
                inspect_asset(source)
            make_glb(source)
            with self.assertRaises(AssetImportError):
                inspect_asset(source, wrapper_scale=0)

    def test_rejects_external_dependencies_and_nonfinite_bounds(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            source = Path(directory) / "fixture.glb"
            make_glb(source, dependency_uri="outside.bin")
            with self.assertRaises(AssetImportError):
                inspect_asset(source)
            make_glb(source, bound_value=float("inf"))
            with self.assertRaises(AssetImportError):
                inspect_asset(source)


if __name__ == "__main__":
    unittest.main()
