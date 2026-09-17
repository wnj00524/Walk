#!/usr/bin/env python3
"""Validate a local GLB and write a factual technical report.

Purpose: make candidate asset review reproducible without Blender.
Reads: one GLB file and optional scale/pivot settings. Writes: a JSON report;
the source bytes are never modified. Safe changes: review limits and wrapper
transform defaults. Failure: malformed, empty, oversized, unsafe or incomplete
GLBs fail before an asset can enter the runtime catalogue.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import math
from pathlib import Path
import struct
from typing import Any

MAX_GLB_BYTES = 100 * 1024 * 1024
GLB_MAGIC = 0x46546C67


class AssetImportError(ValueError):
    """A candidate cannot be safely reviewed or imported."""


def _read_glb(path: Path, max_bytes: int = MAX_GLB_BYTES) -> tuple[dict[str, Any], bytes]:
    if path.suffix.lower() != ".glb" or not path.is_file():
        raise AssetImportError("input must be an existing .glb file")
    if path.stat().st_size > max_bytes:
        raise AssetImportError("GLB exceeds the configured size limit")
    raw = path.read_bytes()
    if len(raw) < 20:
        raise AssetImportError("GLB header is incomplete")
    magic, version, total_length = struct.unpack_from("<III", raw)
    if magic != GLB_MAGIC or version != 2 or total_length != len(raw):
        raise AssetImportError("GLB header is invalid or length does not match")
    chunk_length, chunk_type = struct.unpack_from("<II", raw, 12)
    if chunk_type != 0x4E4F534A or 20 + chunk_length > len(raw):
        raise AssetImportError("GLB must begin with a JSON chunk")
    try:
        document = json.loads(raw[20:20 + chunk_length].decode("utf-8").rstrip(" \t\r\n\0"))
    except (UnicodeDecodeError, json.JSONDecodeError) as error:
        raise AssetImportError("GLB JSON chunk is not valid UTF-8 JSON") from error
    if not isinstance(document, dict) or not isinstance(document.get("asset"), dict) or document["asset"].get("version") != "2.0":
        raise AssetImportError("GLB does not declare glTF 2.0 asset metadata")
    return document, raw


def inspect_asset(path: Path, max_bytes: int = MAX_GLB_BYTES, wrapper_scale: float = 1.0, pivot_y_m: float = 0.0) -> dict[str, Any]:
    """Return measured glTF counts, bounds, and a documented wrapper transform."""
    if wrapper_scale <= 0:
        raise AssetImportError("wrapper scale must be positive")
    document, raw = _read_glb(path, max_bytes)
    meshes = document.get("meshes", [])
    nodes = document.get("nodes", [])
    materials = document.get("materials", [])
    accessors = document.get("accessors", [])
    if not isinstance(meshes, list) or not meshes:
        raise AssetImportError("GLB contains no meshes")
    primitive_count = sum(len(mesh.get("primitives", [])) for mesh in meshes if isinstance(mesh, dict))
    for collection_name in ("buffers", "images"):
        for dependency in document.get(collection_name, []):
            if isinstance(dependency, dict) and dependency.get("uri"):
                raise AssetImportError(f"GLB has an external {collection_name[:-1]} dependency")
    triangle_count = 0
    bounds: list[float] = []
    for accessor in accessors:
        if not isinstance(accessor, dict):
            continue
        if accessor.get("type") == "VEC3" and accessor.get("min") and accessor.get("max"):
            bounds.extend([float(value) for value in accessor["min"]])
            bounds.extend([float(value) for value in accessor["max"]])
    for mesh in meshes:
        for primitive in mesh.get("primitives", []) if isinstance(mesh, dict) else []:
            index_accessor = primitive.get("indices") if isinstance(primitive, dict) else None
            if isinstance(index_accessor, int) and 0 <= index_accessor < len(accessors):
                accessor = accessors[index_accessor]
                if isinstance(accessor, dict) and accessor.get("type") == "SCALAR":
                    triangle_count += int(accessor.get("count", 0)) // 3
    if primitive_count < 1 or not nodes:
        raise AssetImportError("GLB contains no usable primitives or nodes")
    if bounds and not all(math.isfinite(value) for value in bounds):
        raise AssetImportError("GLB bounds contain a non-finite value")
    measured_min = [min(bounds[index::3]) for index in range(3)] if bounds else None
    measured_max = [max(bounds[index::3]) for index in range(3)] if bounds else None
    return {
        "schema_version": 1,
        "source": {"path": str(path), "bytes": len(raw), "sha256": hashlib.sha256(raw).hexdigest()},
        "counts": {"nodes": len(nodes), "meshes": len(meshes), "materials": len(materials), "primitives": primitive_count, "triangles_from_index_accessors": triangle_count},
        "bounds_m": {"min": measured_min, "max": measured_max},
        "wrapper_transform": {"scale": wrapper_scale, "pivot_y_m": pivot_y_m, "collision_policy": "review separately; no generated collision assumed"},
        "blender_dependency": False,
    }


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("input", type=Path)
    parser.add_argument("--report", type=Path, required=True)
    parser.add_argument("--scale", type=float, default=1.0)
    parser.add_argument("--pivot-y-m", type=float, default=0.0)
    args = parser.parse_args(argv)
    report = inspect_asset(args.input, wrapper_scale=args.scale, pivot_y_m=args.pivot_y_m)
    args.report.parent.mkdir(parents=True, exist_ok=True)
    args.report.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"PASS: inspected {args.input.name}; meshes={report['counts']['meshes']} triangles={report['counts']['triangles_from_index_accessors']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
