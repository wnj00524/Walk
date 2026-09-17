# GLB import and technical review

## What the walker notices

Nothing is added to the walk automatically. A candidate is measured and
reviewed first, so malformed geometry cannot quietly become a floating,
oversized, or empty runtime asset.

## How it works, in ordinary language

`tools/import_asset.py` reads the binary GLB header and its glTF JSON metadata,
then reports actual node, mesh, material, primitive, triangle-accessor, bounds,
byte-size, and SHA-256 values. It records scale and vertical pivot as a wrapper
transform; source bytes remain unchanged. `inspect_asset.gd` is a labelled
Godot fixture for checking that an imported scene really contains
`MeshInstance3D` nodes. Neither path invokes Blender or reads a `.blend` file.

## Which files own the behaviour

- `tools/import_asset.py`: offline validation and JSON report.
- `tools/test_import_asset.py`: malformed, empty, missing, oversized, meshless,
  and wrapper-setting tests using local binary fixtures.
- `game/tests/tools/asset_review.tscn` and `inspect_asset.gd`: Godot import
  fixture, not a runtime catalogue or beauty claim.

## Safe settings to change

The default maximum candidate size is 100 MB. Wrapper scale must be positive;
`pivot_y_m` is metres and may be adjusted after a measured asset review.
Collision is intentionally not generated or assumed here; T019 owns asset
approval.

## Failure symptoms and where to look

Import errors identify the header, JSON, mesh, size, or bounds input that was
rejected. A successful Python report does not prove visual quality. A Godot
fixture failure means the actual engine import or mesh hierarchy needs review.

## How it is tested

Run `python -m unittest tools/test_import_asset.py` for offline checks. The
fixture is explicitly not evidence of a real generated asset; T019 supplies
the representative Meshy batch and owner visual decision.
