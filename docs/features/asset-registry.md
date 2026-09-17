# Offline asset request registry

## What the owner can notice

The project can list a rock, tree, and ground-cover request without pretending
that any model exists or contacting Meshy. The shipped approved catalogue is
empty until a real asset has passed technical and visual review.

## How it works, in ordinary language

`tools/asset_registry.py` validates C06 records, including stable IDs,
request dimensions, lifecycle state, prompt/config hashes, confined local
paths, and approved-file presence. It also checks that an enabled budget names
requests and a positive job limit. The example budget remains disabled with
zero jobs.

`asset_requests/initial.json` contains request-only examples. Their source and
derivative paths are deliberately empty. `game/data/asset_catalogue.json` is a
JSON list reserved for approved local runtime assets; no test fixture can enter
it implicitly.

## Safe settings to change

Use the validator before any future provider client. Keep request IDs stable,
recompute hashes when prompt/config changes, and never treat an API key as
spend approval. Provider calls belong to later tasks.

## How it is tested

```text
python tools/asset_registry.py
python -m unittest tools/test_asset_registry.py
```
