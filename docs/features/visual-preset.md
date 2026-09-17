# Consistent terrain materials and daylight

## What the owner can notice

Terrain, rocks, and vegetation are lit by the same fixed temperate daylight
palette. The ground is a restrained woodland green rather than an over-bright
test colour, while distant views retain a light atmospheric veil.

## How it works, in ordinary language

`visual_preset.json` is the single reviewed source for terrain colour,
roughness, UV repeat scale, ambient light, sun intensity, shadows, and fog.
`EnvironmentSetup` validates those values before constructing Godot's standard
material, world environment, and directional sun. `ChunkTerrain` loads the
preset during configuration, applies the material to every generated chunk,
and adds the shared daylight objects. Invalid values stop configuration rather
than silently choosing a different look.

The texture scale is a dimensionless UV repeat count on the generated terrain
mesh. Light and ambient energy are bounded multipliers; fog density is a
bounded atmospheric value. Fog is intentionally light so it cannot conceal
terrain seams, weak landforms, or poor ground contact.

## Which files own the behaviour

- `game/data/visual_preset.json` — reviewed palette and safe numeric controls.
- `game/src/presentation/environment_setup.gd` — validation and Godot visual objects.
- `game/src/terrain/chunk_terrain.gd` — applies the preset to streamed chunks.
- `game/tests/test_visual_preset.gd` — invalid-value and object-construction checks.

## Safe settings to change

Keep texture scale between 0.1 and 64 UV repeats, roughness between 0 and 1,
light intensity between 0.1 and 4, ambient energy between 0 and 2, and fog
density between 0 and 0.1. Prefer small changes followed by the fixed capture
route; do not use heavy fog or bloom to hide a terrain defect.

## Failure symptoms and where to look

An `ERROR` during terrain configuration points to a malformed preset or an
out-of-range value. A flat or overly bright view means the preset or material
needs review. Missing objects in a capture should first be checked in
`capture_report.json` and the terrain readiness log; this feature does not add
fallback geometry.

## How it is tested

```text
python tools/check_game.py --suite visual_preset
python tools/check_game.py --suite terrain
python tools/check_game.py --suite placement
python tools/check_game.py --suite vegetation
python tools/run_visual.py --output-dir artifacts/T023_visual_capture --timeout 180
```

The suite proves schema/range behavior and construction, while the Windows
capture route proves the real renderer can produce the fixed PNG views. Owner
beauty acceptance of the complete procedural slice remains T024.
