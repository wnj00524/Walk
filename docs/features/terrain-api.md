# Voxel Tools terrain API

## What the owner can notice

There is not a visible terrain world yet. This task proves that the selected
Windows native add-on can be loaded by Godot and that the classes needed for
later terrain work are present. It does not claim that streaming terrain,
collision meshes, or long-distance rendering are accepted.

## How it works, in ordinary language

Godot loads `game/addons/voxel/voxel.gdextension` during project startup. The
probe asks Godot's native class registry for the exact Voxel Tools 1.7 classes,
constructs them, lists their exposed methods and properties, then performs
small in-memory configuration calls. It configures a noise generator with
`noise`, `height_start`, and `height_range`; configures a graph's SDF clip
threshold; sets a viewer distance and collision requirement; enables collision
generation on a level-of-detail terrain object; and reads the ordinary terrain
statistics diagnostic.

The inspected graph resource exposes `graph_data`, `compile`, and
`generate_block`, but does not expose the assumed `add_node`, `connect_nodes`,
or `set_node_param` methods. Later graph construction must therefore use the
actual graph-data contract established by a focused follow-up task.

## Frozen adapter boundary

T011 freezes the downstream `TerrainService` shape without claiming that the
current probe implements it. The service will expose `configure`,
`update_viewer`, `get_ground_state`, `query_surface`, `get_diagnostics`, and
`shutdown`, using C01 logical positions and the states READY, PENDING,
OUTSIDE_TESTED_SUPPORT, and ERROR. Configuration creates a generation epoch;
old native completions are ignored, and all scene-tree/native-node changes are
performed on the main thread.

The current probe only proves the temporary methods listed in the code guide.
It also proves direct `world_seed` assignment to `FastNoiseLite.seed`, but not a
native generator-origin offset. T010 measured a 6.926433 m sample change after
an origin move without such an offset. As a result, the backend is not accepted
for large-world recentering: a future implementation must return
OUTSIDE_TESTED_SUPPORT beyond its proven local envelope or use a separately
approved alternative spike. T012 remains blocked until continuity, collision,
export, and identity are demonstrated.

The `0.01 m` visual-position and `0.0001 m` diagnostic-height tolerances belong
to the bounded probes only. They are not a promise of bit-identical native
meshes across hardware.

## Foundation gate result

T012 rejected this backend for the product foundation. The pinned Windows
bundle loads and the local probe renders, but there is no accessible Windows
export launch, no completed native mesh/collision evidence from the bounded
headless probe, and no identity-preserving large-world handoff. The candidate
remains recorded for comparison only; `checks.backend_gate` is false and no
dependent terrain implementation may treat this probe as accepted.

## Which files own the behaviour

- `game/addons/voxel/`: the exact pinned Voxel Tools 1.7 GDExtension bundle and
  its licence file. Vendor files are replaced only by re-downloading the same
  locked archive and checking its SHA-256 hash.
- `game/tests/probes/terrain_api_probe.gd`: the offline, non-world API probe.
- `docs/toolchain.lock.json`: the version, checksum, platform test state, and
  probe path.

## Safe settings to change

The probe's viewer distance is a diagnostic value in metres, currently 256 m.
The noise height range is diagnostic only, currently 64 m. These values do not
set game behaviour and can be changed for probing without changing the world
format. Do not add a second terrain generator or per-voxel GDScript loop.

## Failure symptoms and where to look

- A missing class or failed construction is printed by the probe and returns a
  nonzero exit code.
- An unknown method or property is evidence that the locked binary does not
  support the proposed call; update the probe from observed API evidence rather
  than guessing a fallback.
- The headless runtime probe passes on Windows, but the Godot editor-mode
  import command crashes inside the native extension in this environment. The
  editor crash is retained as a blocker for editor verification, not hidden as
  a pass.

## How it is tested

Run:

```text
godot --headless --path game --script res://tests/probes/terrain_api_probe.gd
python tools/project.py validate
python -m unittest discover -s tools -p "test_*.py"
```

The probe is a native-load/API check only. It does not prove generated mesh
quality, collision behaviour in a scene, GPU performance, a Windows export, or
large-world continuity. Those checks belong to later tasks.
