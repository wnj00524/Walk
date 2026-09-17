# Repeatable terrain captures

## What the owner can notice

One command produces the same named overview, ground-level, close-ground, and
return-trip views for the fixed seed and camera poses. The output includes the
actual Godot version, display server, renderer, video adapter, recipe, and
camera coordinates so a later comparison can tell what changed.

## How it works, in ordinary language

`game/tests/visual_route.json` is the reviewed route definition. The Godot
capture scene waits for ChunkTerrain collision readiness, positions the camera
from that file, waits for rendered frames, and saves one PNG per pose plus a
JSON report. `tools/run_visual.py` requires a real renderer, rejects missing or
empty files, and keeps the engine log beside the captures. It never declares
the images beautiful; the owner still reviews the captured views.

Later terrain, lighting, material, or asset changes require a fresh capture.

## How it is tested

```text
python tools/run_visual.py --output-dir artifacts/T015_visual_capture
python -m unittest tools/test_run_visual.py
```
