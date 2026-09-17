# Terrain consistency checks

## What the owner can notice

The same logical place keeps the same height after a return trip or a terrain
regeneration. The two logical paths that meet at a chunk edge also agree
within the recorded 0.01 metre tolerance.

## How it works, in ordinary language

`game/tests/fixtures/terrain_samples.json` stores reviewed reference samples
for seed 42, including a negative cell and both sides of a shared boundary.
`test_terrain_consistency.gd` asks the public `ChunkTerrain.query_surface`
method for those samples. It does not copy the production noise formula. A
changed seed is checked separately so a broken seed mapping cannot pass by
returning a constant landscape.

The fixture is a logic guard, not a promise of identical GPU mesh pixels. The
visual seam and detail-level appearance check remains part of the graphical
review workflow.

## How it is tested

```text
python tools/check_game.py --suite terrain
```
