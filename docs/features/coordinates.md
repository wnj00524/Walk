# Large-distance coordinate probe

This investigation records what the current native terrain setup can prove at
zero, ±100 km, and ±1000 km. It is evidence about a bounded test envelope, not
a claim that every distance is supported.

`WorldPosition` keeps the logical location as signed 256 m cells plus local
metre offsets. The probe also records the native `VoxelGeneratorNoise` height
sample at each test location and the error from a `Vector3` round trip. The
sample helper is diagnostic only; the player must still use native collision.

The candidate handoff tested here is moving the visual origin to zero while
leaving the native generator unchanged. That candidate does not preserve the
same logical terrain sample: the native generator has no exposed world-origin
or coordinate-offset operation in the pinned API. The result therefore blocks
backend acceptance until T011 freezes either an identity-preserving adapter or
an explicit rejection of this backend for large-world use.

Run the bounded probe with:

```text
godot --headless --path game --script res://tests/probes/coordinate_probe.gd
```

Run its graphical scene for visual and collision observations with:

```text
godot --path game --scene res://tests/probes/coordinate_probe.tscn
```
