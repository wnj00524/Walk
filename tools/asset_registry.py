#!/usr/bin/env python3
"""Validate offline C06 asset requests, approvals, paths, and budgets.

Purpose: Catch unsafe or incomplete asset records before any provider call.
Reads: JSON request/catalogue/budget files and local paths named by approved records.
Writes: Nothing; validation is read-only and never contacts a provider.
Safe changes: Extend schema checks only with a documented C06 change.
Failure: Duplicate IDs, bad hashes/states, unsafe paths, missing approved files, or unsafe budgets fail clearly.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import re
import sys
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
STATES = {"REQUESTED", "SUBMITTED", "SUBMISSION_UNKNOWN", "DOWNLOADED", "TECHNICAL_PASS", "APPROVED", "REJECTED"}
ASSET_ID = re.compile(r"^[a-z][a-z0-9_]{2,63}$")
HASH = re.compile(r"^[0-9a-f]{64}$")
REQUIRED_RECORD_FIELDS = {"asset_id", "provider", "status", "prompt", "config", "prompt_hash", "config_hash", "requested_dimensions"}


def _read(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def _error(message: str) -> list[str]:
    return [message]


def _hash_prompt(prompt: str) -> str:
    return hashlib.sha256(prompt.encode("utf-8")).hexdigest()


def _hash_config(config: dict[str, Any]) -> str:
    canonical = json.dumps(config, sort_keys=True, separators=(",", ":"), ensure_ascii=True)
    return hashlib.sha256(canonical.encode("utf-8")).hexdigest()


def _confined_path(value: str, root: Path) -> Path | None:
    candidate = (root / value).resolve() if not Path(value).is_absolute() else Path(value).resolve()
    try:
        candidate.relative_to(root.resolve())
    except ValueError:
        return None
    return candidate


def validate_record(record: dict[str, Any], root: Path = ROOT, approved_root: Path | None = None) -> list[str]:
    """Validate one C06 record and require local files once it is approved."""
    errors: list[str] = []
    missing = REQUIRED_RECORD_FIELDS - record.keys()
    if missing:
        errors.append(f"{record.get('asset_id', '<unknown>')}: missing fields {sorted(missing)}")
        return errors
    asset_id = record["asset_id"]
    if not isinstance(asset_id, str) or not ASSET_ID.fullmatch(asset_id):
        errors.append(f"{asset_id}: asset_id must be a stable lowercase identifier")
    status = record["status"]
    if status not in STATES:
        errors.append(f"{asset_id}: invalid lifecycle state {status}")
    if record["provider"] not in {"meshy", "local_cc0"}:
        errors.append(f"{asset_id}: unsupported provider")
    prompt = record["prompt"]
    config = record["config"]
    if not isinstance(prompt, str) or not prompt.strip():
        errors.append(f"{asset_id}: prompt must be non-empty text")
    if not isinstance(config, dict):
        errors.append(f"{asset_id}: config must be an object")
    else:
        expected_config_hash = _hash_config(config)
        if record["config_hash"] != expected_config_hash:
            errors.append(f"{asset_id}: config_hash does not match config")
    if isinstance(prompt, str) and record["prompt_hash"] != _hash_prompt(prompt):
        errors.append(f"{asset_id}: prompt_hash does not match prompt")
    if not isinstance(record["prompt_hash"], str) or not HASH.fullmatch(record["prompt_hash"]):
        errors.append(f"{asset_id}: prompt_hash must be a SHA-256 hex digest")
    if not isinstance(record["config_hash"], str) or not HASH.fullmatch(record["config_hash"]):
        errors.append(f"{asset_id}: config_hash must be a SHA-256 hex digest")
    dimensions = record["requested_dimensions"]
    if not isinstance(dimensions, dict) or set(dimensions) != {"width_px", "height_px", "format"}:
        errors.append(f"{asset_id}: requested_dimensions must name width_px, height_px, and format")
    elif not all(isinstance(dimensions[key], int) and dimensions[key] > 0 for key in ("width_px", "height_px")):
        errors.append(f"{asset_id}: requested pixel dimensions must be positive integers")
    elif dimensions["format"] != "glb":
        errors.append(f"{asset_id}: requested format must be glb")
    for field in ("source_path", "derivative_path"):
        value = record.get(field)
        if value is not None:
            if not isinstance(value, str) or _confined_path(value, approved_root or root) is None:
                errors.append(f"{asset_id}: {field} escapes the permitted local root")
            elif status == "APPROVED" and not _confined_path(value, approved_root or root).is_file():
                errors.append(f"{asset_id}: approved {field} is missing")
    if status == "APPROVED" and not any(record.get(field) for field in ("source_path", "derivative_path")):
        errors.append(f"{asset_id}: approved record needs a local source or derivative path")
    if status in {"DOWNLOADED", "TECHNICAL_PASS"} and not any(record.get(field) for field in ("source_path", "derivative_path")):
        errors.append(f"{asset_id}: {status} record needs a local path")
    return errors


def validate_requests(records: list[dict[str, Any]], root: Path = ROOT) -> list[str]:
    errors: list[str] = []
    seen: set[str] = set()
    for record in records:
        asset_id = record.get("asset_id")
        if asset_id in seen:
            errors.append(f"duplicate asset_id: {asset_id}")
        seen.add(asset_id)
        errors.extend(validate_record(record, root))
    return errors


def validate_catalogue(records: list[dict[str, Any]], root: Path = ROOT) -> list[str]:
    errors: list[str] = []
    seen: set[str] = set()
    approved_root = root / "game" / "assets"
    for record in records:
        asset_id = record.get("asset_id")
        if asset_id in seen:
            errors.append(f"duplicate asset_id: {asset_id}")
        seen.add(asset_id)
        errors.extend(validate_record(record, root, approved_root))
    for record in records:
        if record.get("status") != "APPROVED":
            errors.append(f"catalogue record {record.get('asset_id')} must be APPROVED")
    return errors


def validate_budget(budget: dict[str, Any], request_ids: set[str]) -> list[str]:
    errors: list[str] = []
    if budget.get("schema_version") != 1:
        errors.append("budget schema_version must be 1")
    approved = budget.get("approved", False)
    ids = budget.get("request_ids", [])
    if not isinstance(ids, list) or any(not isinstance(item, str) for item in ids):
        errors.append("budget request_ids must be a list of names")
    else:
        unknown = set(ids) - request_ids
        if unknown:
            errors.append(f"budget names unknown requests: {sorted(unknown)}")
    mesh_jobs = budget.get("max_new_meshy_jobs", 0)
    sound_requests = budget.get("max_new_elevenlabs_requests", 0)
    if approved and (not ids or not isinstance(mesh_jobs, int) or mesh_jobs < 1):
        errors.append("enabled budget needs named requests and a positive Meshy job limit")
    if not approved and (mesh_jobs != 0 or sound_requests != 0):
        errors.append("disabled budget cannot authorize new jobs or requests")
    return errors


def validate_files(request_path: Path, catalogue_path: Path, budget_path: Path, root: Path = ROOT) -> list[str]:
    requests = _read(request_path)
    catalogue = _read(catalogue_path)
    budget = _read(budget_path)
    if not isinstance(requests, list):
        return _error("request registry must be a JSON list")
    if not isinstance(catalogue, list):
        return _error("approved catalogue must be a JSON list")
    errors = validate_requests(requests, root)
    errors.extend(validate_catalogue(catalogue, root))
    errors.extend(validate_budget(budget, {record.get("asset_id") for record in requests}))
    return errors


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--requests", type=Path, default=ROOT / "asset_requests" / "initial.json")
    parser.add_argument("--catalogue", type=Path, default=ROOT / "game" / "data" / "asset_catalogue.json")
    parser.add_argument("--budget", type=Path, default=ROOT / "docs" / "asset_budget.example.json")
    args = parser.parse_args(argv)
    errors = validate_files(args.requests, args.catalogue, args.budget)
    if errors:
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)
        return 1
    print(f"PASS: asset requests/catalogue/budget validated; requests={len(_read(args.requests))}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
