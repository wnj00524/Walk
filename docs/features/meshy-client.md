# Resumable Meshy development client

`tools/meshy_client.py` is the guarded development-only path from a named C06
asset request to a local, verified GLB. It reads the request and an explicitly
approved budget, and writes one atomically replaced JSON receipt per asset.
The default command is a no-network dry-run. A real POST requires
`--execute`, a named request in the budget, a positive job allowance, and
`MESHY_API_KEY` from the process environment or the repository `.env` file.

The client uses Meshy API v2: `POST https://api.meshy.ai/openapi/v2/text-to-3d`
with `mode=preview`, then polls `/text-to-3d/<task-id>` and accepts the GLB
from the successful response's `model_urls.glb`. This was checked against the
[official Text to 3D API documentation](https://docs.meshy.ai/en/api/text-to-3d)
on 17 September 2026. The provider task ID is saved immediately; an uncertain
paid POST becomes `SUBMISSION_UNKNOWN` and is never retried automatically.

Offline tests inject fixture responses and cover missing credentials, disabled
budgets, duplicate/resumed requests, pending/success/failure states, HTTP 401,
402 and 429, timeouts, oversized downloads, and hash mismatches. Tests do not
contact Meshy or spend credits. Download size and HTTPS asset-host checks are
deliberately strict. Safe adjustments are request limits and fixture cases;
changing the provider schema requires rechecking the official docs and this
walkthrough.
