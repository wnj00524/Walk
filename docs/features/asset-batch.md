# Representative asset batch

## What the walker notices

No new asset is visible in the runtime walk yet. Three generated candidates
were reviewed and marked REVISE because the captures show untextured white
materials; the runtime catalogue remains empty.

## How it works, in ordinary language

The named local budget allowed one rock, one tree, and one fern request. Each
provider task was submitted once, resumed by its saved ID, downloaded over the
guarded client, and measured by the GLB inspector. Candidates live in ignored
review storage, not the exported catalogue.

## Which files own the behaviour

`asset_requests/initial.json` names the batch; `asset_budget.local.json` is the
ignored local authorization; `asset_work/` holds receipts, candidates, and
reports; `game/data/asset_catalogue.json` is intentionally empty.

## Safe settings to change

Only the finite named budget and request prompts may change before a new
review. Do not copy candidates into `game/assets/` or catalogue them without
the fixed visual review.

## Failure symptoms and where to look

Missing receipts indicate a submission workflow problem. A failed GLB report
indicates a technical rejection. Renderer diagnostics or poor close/mid/far
views require review rather than silently approving the model.

## How it is tested

Use `python tools/asset_registry.py` and `python tools/import_asset.py` for
offline validation. T019 records REVISE for all three candidates and does not
promote them; any future regeneration must use the same review path.
