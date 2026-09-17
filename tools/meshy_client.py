#!/usr/bin/env python3
"""Safely submit, resume, poll, and download named Meshy development jobs.

Purpose: keep paid provider work explicit, resumable, and bounded.
Reads: a C06 request record, an explicitly approved budget, MESHY_API_KEY, and
local receipt files. Writes: JSON receipts and verified local model bytes.
Safe changes: endpoint and request fields must match the pinned provider docs;
limits may be tightened but not removed. Failure never retries an uncertain POST.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import tempfile
import time
from typing import Any, Callable
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen

ROOT = Path(__file__).resolve().parents[1]
API_ROOT = "https://api.meshy.ai/openapi/v2"
MAX_DOWNLOAD_BYTES = 100 * 1024 * 1024
FINAL_STATUSES = {"SUCCEEDED", "FAILED", "EXPIRED"}
Transport = Callable[[str, str, dict[str, Any] | None], tuple[int, dict[str, str], bytes]]


class MeshyError(RuntimeError):
    """A safe, actionable provider-client failure."""


class MeshyHttpError(MeshyError):
    """An HTTP response that cannot be treated as a successful operation."""

    def __init__(self, status: int, body: bytes) -> None:
        super().__init__(f"Meshy request failed with HTTP {status}")
        self.status = status
        self.body = body


def _canonical_hash(record: dict[str, Any]) -> str:
    payload = {"prompt": record.get("prompt"), "config": record.get("config", {})}
    return hashlib.sha256(json.dumps(payload, sort_keys=True, separators=(",", ":")).encode()).hexdigest()


def _default_transport(method: str, url: str, body: dict[str, Any] | None) -> tuple[int, dict[str, str], bytes]:
    encoded = json.dumps(body).encode() if body is not None else None
    request = Request(url, data=encoded, method=method, headers={"Content-Type": "application/json"})
    key = os.environ.get("MESHY_API_KEY")
    if key:
        request.add_header("Authorization", f"Bearer {key}")
    try:
        with urlopen(request, timeout=30) as response:
            return response.status, dict(response.headers), response.read()
    except HTTPError as error:
        return error.code, dict(error.headers), error.read()
    except (TimeoutError, URLError) as error:
        raise TimeoutError("Meshy network operation timed out or was unreachable") from error


class MeshyClient:
    """Provider client with local intent receipts and injectable transport."""

    def __init__(self, receipt_dir: Path, transport: Transport | None = None, sleep: Callable[[float], None] = time.sleep) -> None:
        self.receipt_dir = receipt_dir
        self.transport = transport or _default_transport
        self.sleep = sleep

    def _receipt_path(self, asset_id: str) -> Path:
        if not asset_id or Path(asset_id).name != asset_id:
            raise MeshyError("asset_id must be a simple named request")
        return self.receipt_dir / f"{asset_id}.json"

    def _save(self, asset_id: str, receipt: dict[str, Any]) -> None:
        self.receipt_dir.mkdir(parents=True, exist_ok=True)
        target = self._receipt_path(asset_id)
        with tempfile.NamedTemporaryFile("w", encoding="utf-8", dir=self.receipt_dir, delete=False) as handle:
            json.dump(receipt, handle, indent=2, sort_keys=True)
            handle.write("\n")
            temporary = Path(handle.name)
        os.replace(temporary, target)

    def _load(self, asset_id: str) -> dict[str, Any] | None:
        path = self._receipt_path(asset_id)
        return json.loads(path.read_text(encoding="utf-8")) if path.is_file() else None

    def create_or_resume(self, record: dict[str, Any], budget: dict[str, Any], execute: bool = False) -> dict[str, Any]:
        """Return dry-run/resume/submission state without duplicating a POST."""
        asset_id = record.get("asset_id")
        if not isinstance(asset_id, str):
            raise MeshyError("request record needs a named asset_id")
        request_hash = _canonical_hash(record)
        existing = self._load(asset_id)
        if existing:
            if existing.get("request_hash") != request_hash:
                raise MeshyError(f"receipt for {asset_id} belongs to a different request")
            return existing
        receipt: dict[str, Any] = {"asset_id": asset_id, "request_hash": request_hash, "status": "DRY_RUN"}
        if not execute:
            self._save(asset_id, receipt)
            return receipt
        if os.environ.get("MESHY_API_KEY") is None:
            raise MeshyError("MESHY_API_KEY is required for --execute")
        if budget.get("approved") is not True or asset_id not in budget.get("request_ids", []) or budget.get("max_new_meshy_jobs", 0) < 1:
            raise MeshyError("the named request is not covered by an approved Meshy budget")
        self._save(asset_id, {**receipt, "status": "SUBMISSION_INTENT"})
        body = {"mode": "preview", "prompt": record["prompt"], **record.get("config", {})}
        try:
            status, _, raw = self.transport("POST", f"{API_ROOT}/text-to-3d", body)
        except TimeoutError:
            result = {**receipt, "status": "SUBMISSION_UNKNOWN"}
            self._save(asset_id, result)
            return result
        if status not in {200, 201, 202}:
            raise MeshyHttpError(status, raw)
        response = json.loads(raw)
        task_id = response.get("result") or response.get("id")
        if not isinstance(task_id, str) or not task_id:
            raise MeshyError("Meshy create response did not contain a task ID")
        result = {**receipt, "status": "SUBMITTED", "task_id": task_id}
        self._save(asset_id, result)
        return result

    def poll(self, asset_id: str, attempts: int = 10, interval: float = 1.0) -> dict[str, Any]:
        """Poll a known task a finite number of times and save each state."""
        receipt = self._load(asset_id)
        if not receipt or not receipt.get("task_id"):
            raise MeshyError("no known task ID to resume")
        for attempt in range(attempts):
            try:
                status, _, raw = self.transport("GET", f"{API_ROOT}/text-to-3d/{receipt['task_id']}", None)
            except TimeoutError:
                raise MeshyError("status polling timed out")
            if status != 200:
                raise MeshyHttpError(status, raw)
            task = json.loads(raw)
            state = task.get("status")
            if state in FINAL_STATUSES:
                receipt = {**receipt, "status": state, "task": task}
                self._save(asset_id, receipt)
                return receipt
            if state not in {"PENDING", "IN_PROGRESS"}:
                raise MeshyError("Meshy returned an unknown task status")
            if attempt + 1 < attempts:
                self.sleep(interval)
        raise MeshyError(f"task did not finish within {attempts} polls")

    def download_glb(self, asset_id: str, destination: Path, expected_sha256: str | None = None, max_bytes: int = MAX_DOWNLOAD_BYTES) -> Path:
        """Download only a completed GLB, enforcing size and optional hash."""
        receipt = self._load(asset_id)
        if not receipt or receipt.get("status") != "SUCCEEDED":
            raise MeshyError("a successful task is required before downloading")
        url = receipt.get("task", {}).get("model_urls", {}).get("glb")
        if not isinstance(url, str) or not url.startswith("https://assets.meshy.ai/"):
            raise MeshyError("Meshy response did not provide a trusted HTTPS GLB URL")
        status, headers, content = self.transport("GET", url, None)
        if status != 200:
            raise MeshyHttpError(status, content)
        declared = int(headers.get("Content-Length", len(content)))
        if declared > max_bytes or len(content) > max_bytes:
            raise MeshyError("download exceeds the configured size limit")
        digest = hashlib.sha256(content).hexdigest()
        if expected_sha256 and digest != expected_sha256:
            raise MeshyError("download SHA-256 does not match the expected digest")
        destination.parent.mkdir(parents=True, exist_ok=True)
        with tempfile.NamedTemporaryFile(dir=destination.parent, delete=False) as handle:
            handle.write(content)
            temporary = Path(handle.name)
        os.replace(temporary, destination)
        self._save(asset_id, {**receipt, "status": "DOWNLOADED", "path": str(destination), "sha256": digest})
        return destination


def _load_dotenv() -> None:
    path = ROOT / ".env"
    if not path.is_file() or os.environ.get("MESHY_API_KEY"):
        return
    for line in path.read_text(encoding="utf-8").splitlines():
        if line.startswith("MESHY_API_KEY="):
            os.environ["MESHY_API_KEY"] = line.split("=", 1)[1].strip().strip('"')


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--request", type=Path, required=True)
    parser.add_argument("--budget", type=Path, default=ROOT / "docs" / "asset_budget.example.json")
    parser.add_argument("--receipt-dir", type=Path, default=ROOT / "asset_work" / "meshy_receipts")
    parser.add_argument("--execute", action="store_true", help="allow a named, approved provider submission")
    args = parser.parse_args(argv)
    _load_dotenv()
    record = json.loads(args.request.read_text(encoding="utf-8"))
    budget = json.loads(args.budget.read_text(encoding="utf-8"))
    result = MeshyClient(args.receipt_dir).create_or_resume(record, budget, args.execute)
    print(json.dumps({"asset_id": result["asset_id"], "status": result["status"], "task_id": result.get("task_id")}, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
