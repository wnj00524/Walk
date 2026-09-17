# Script-Defined Streamed Ground Probe

The probe scene configures a seeded native smooth terrain with
`VoxelLodTerrain`, `VoxelGeneratorNoise`, `VoxelMesherTransvoxel`, and a
`VoxelViewer` attached to the camera. Collision generation is enabled.

`TerrainService` reports `PENDING` until native work completes; it never
supplies a guessed height. `streamed_ground.gd` waits up to 600 frames, records
backend settings and statistics, walks checkpoints at 0, 48, 96, 48, and 0
metres, and checks the return position. This is a technical probe, not a
finished landscape: it has no foliage, water, biomes, or save data.

The pinned API exposes timing and dropped-work diagnostics, but not exact
resident mesh or collision counts. Settings are recorded in
`game/data/terrain_probe.json`.

Run the headless probe with:

```text
godot --headless --path game --script res://tests/probes/streamed_ground.gd
```

Run the graphical scene with:

```text
godot --path game --scene res://tests/probes/streamed_ground.tscn
```
