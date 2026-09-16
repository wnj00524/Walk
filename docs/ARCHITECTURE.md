# Architecture: small parts with visible responsibilities

This is the intended layout, not a statement that these files already exist. T001-T012 establish the executable foundation. Only build a module when its task is ready.

## Runtime in ordinary language

The application opens the last saved position. A world-description component identifies the nearby terrain and habitats. The terrain backend creates the nearby ground and a simpler distant view. The scene renderer places approved plants and rocks. The player controller lets the user walk over ready ground. The sound system plays local files. The save system remembers the world identity and location.

## Proposed project tree

```text
game/
  project.godot
  scenes/main.tscn
  src/app/             # Start, stop, settings and error messages.
  src/player/          # Movement and camera; never generates terrain.
  src/world/           # Coordinates, seeds, region recipes and placement data.
  src/terrain/         # The only game module allowed to call Voxel Tools.
  src/presentation/    # Plants, rocks, water appearance, lighting and sound.
  src/persistence/     # Save/load and version checks.
  data/                # Human-readable world and asset definitions.
  assets/              # Approved local runtime assets only.
  tests/               # Focused tests, fixtures and explicit test scenes.
tools/                 # Development commands and later asset-service clients.
asset_work/            # Ignored local raw generations and provider receipts.
artifacts/             # Ignored logs, captures, reports and build outputs.
docs/evidence/         # Small retained verification summaries, not huge binaries.
```

## Boundary rules

World rules produce data and do not create scene nodes. Terrain integration owns terrain generation, mesh/collision readiness and backend-specific sampling. Presentation consumes world data and never invents a second terrain height function. The player uses real collision/readiness, not a guessed floor height. Persistence stores stable identities and versioned logical coordinates, not temporary scene-node paths.

Application glue is typed GDScript. Native plugin operations or programmatically assembled native generator graphs do the heavy terrain work. Do not fill each voxel in nested GDScript loops in the production implementation. Voxel Tools explicitly warns about this performance pattern [S04].

The world recipe and the backend must share one authoritative terrain definition. If plants need a surface height, use the backend's approved sampling path or ready collision. Do not build an approximate GDScript copy that drifts from the rendered terrain. Worker generation must not access the scene tree [S05].

## Keep the first implementation deliberately boring

Use one main scene, ordinary nodes, direct typed methods/signals and explicit ownership. Do not introduce an ECS, dependency-injection framework, a generic plugin framework, a custom job scheduler, an AI orchestrator or a networking layer. A terrain adapter is justified because the dependency is genuinely uncertain; an adapter for every class is not.

Keep configuration in a few versioned JSON files rather than scattered magic numbers. Generated `.tscn` and `.tres` resources must be reproducible from checked-in code/config or checked in as reviewable text with documented ownership. Never require dragging nodes, clicking import settings or painting terrain in an editor to recreate the project.

## Large-world rule

Logical position uses integer horizontal cells plus local offsets, described in CONTRACTS.md. Visual coordinates stay close enough to the active camera for the chosen engine/backend strategy. This does NOT itself solve large-world rendering: T010-T012 must prove terrain samples, detail levels, collision, vegetation and sound maintain the same world identity during recentering or backend handoff.

The logical cell size is not the voxel data-block size, mesh-block size or streaming region size. Keep those names distinct. A shader, graph or plugin may still use limited-precision values internally. Record tested distances and do not claim mathematical infinity.

## First presentation target

One continuous temperate landscape, a single stable lighting condition, safe walking, three habitat variations, local sound and automatic resume. Distant scenery must be the same terrain the user can approach. No fake horizon mountains that disappear or move when approached.

Sources: see docs/SOURCES.md, particularly S03-S06.
