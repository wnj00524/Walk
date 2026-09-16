# Contracts: agreements an implementation agent must not improvise

These are application contracts, not claims about third-party method names. T008-T012 resolve the adapter's exact native API against the pinned dependency. Change a cross-module agreement only through a coordinator task and update its tests first.

## C01 - Units and coordinates

One world unit is one metre. +Y is up. Horizontal location uses `cell_x`, `cell_z` as signed 64-bit integers, with `local_x_m`, `local_z_m` in [0, 256). Vertical height `y_m` is a finite number. Store yaw/pitch in radians. Logical cells are 256 m wide; they are independent of plugin chunk sizes.

A location crossing the west/south origin must use mathematical floor, not truncation towards zero. Example: x = -0.25 m becomes cell_x = -1, local_x_m = 255.75. x = 256 becomes cell_x = 1, local_x_m = 0. Do not repeatedly reconstruct a huge global floating-point Vector3 for rendering. `fixtures/coordinate_vectors.json` provides independent examples.

Persistence serialises large cell integers as decimal strings to avoid precision loss in JSON consumers. Validate string syntax and signed-64-bit range before conversion. Initial vertical range is a recorded terrain configuration, not an unlimited promise. The tested exploration envelope is evidence, not a fabricated world boundary.

## C02 - World identity and deterministic choices

World identity contains schema_version, generator_version, content_version and world_seed. Initial proposed values are 1, "g1", "c1", and a canonical unsigned decimal seed string in range 0..2147483647. World generation is independent of time, frame rate, loading order and global random state.

For application-level asset choices, use this exact ASCII byte payload, without spaces or a newline:

```text
endless-nature|g1|<seed>|<channel>|<cell_x>|<cell_z>|<slot>
```

Channel is a non-empty lowercase ASCII identifier using letters, digits or underscores. Cell coordinates use canonical decimal form; slot is a non-negative decimal integer. Hash with SHA-256, interpret the first four digest bytes as an unsigned big-endian integer, and divide by 4294967296 for a value in [0, 1). Do not substitute the runtime's built-in string hash. `fixtures/seed_vectors.json` freezes test examples independently of the future game code.

This controls application-level discrete choices, not the plugin's noise internals. The terrain graph's seed mapping and numerical tolerance must be separately pinned and tested in T009-T014. Promise repeatability for supported pinned versions, not bit-identical floating-point meshes on every possible device. A generator/content update must not silently replace an existing world's landscape.

## C03 - Terrain boundary (design contract)

`TerrainService` is the only owner of backend APIs. It must support: configure a world identity and recipe; receive the viewer's logical position; expose ground-readiness near a location; report safe surface information; expose diagnostic counters; and shut down cleanly. Exact method signatures and event names are written by T008-T012 before downstream tasks are made READY.

A surface query distinguishes READY, PENDING and OUTSIDE_TESTED_SUPPORT/ERROR. PENDING is not height zero. Include a normal and height only when valid. Spawn/movement must not enter terrain without ready collision. Scene-tree changes occur on the main thread. A background completion from an old world or generation epoch must be discarded.

The backend owns streaming and its configured budgets. Do not layer an unrelated competing chunk scheduler over it. Application vegetation residency may have its own bounded spatial batches, but derives coverage from the same viewer position.

## C04 - Placement records

A plant/rock record has stable_id, asset_id, logical position, yaw_rad, scale and habitat_id. The generating cell owns records with horizontal positions in its half-open bounds: minimum included, maximum excluded. Features spanning boundaries use canonical owner IDs and explicit neighbour context. This prevents duplicates and missing strips.

The same seed/cell/channel produces the same ordered placement records, regardless of load order. Sorting uses stable IDs. Scale is finite and positive; approved species ranges live in configuration. Rejected, missing or unreviewed assets are never silently replaced in a release.

## C05 - Save envelope

```json
{
  "schema_version": 1,
  "generator_version": "g1",
  "content_version": "c1",
  "world_seed": "42",
  "position": {"cell_x": "-1", "cell_z": "0", "local_x_m": 255.75, "local_z_m": 12.0, "y_m": 18.5},
  "view": {"yaw_rad": 0.0, "pitch_rad": 0.0}
}
```

Write via a temporary file and a tested replace/backup operation. Invalid or unsupported saves must show a readable explanation and preserve the original. No silent re-seeding. Resolve collision safely before placing a loaded player. A bounded generated-data cache is disposable and is not the save. Never delete a user's save as part of cache eviction.

## C06 - Asset lifecycle and spending

An asset request records a stable asset_id, provider, prompt/config hash, requested dimensions, local source/derivative paths, content hashes, provider task ID when known, technical review and visual/audio review. It moves through REQUESTED, SUBMITTED, DOWNLOADED, TECHNICAL_PASS, APPROVED or REJECTED. An ambiguous paid submission is SUBMISSION_UNKNOWN and requires reconciliation, not automatic resubmission.

The local approved manifest contains only approved runtime files and provenance, never credentials or expiring download URLs. Test fixtures are visibly marked and cannot enter release exports. Only an explicit local batch budget enables paid requests. A task may be technically complete with mocked tests, but the real-asset proof remains blocked until its own authorised run passes.

## C07 - Evidence

Each task report contains base/final commit references when available, environment, exact commands, exit codes, test counts, observed result, unverified items, and retained evidence location/hash. Missing evidence is NOT RUN, never PASS. Documentation validation is not runtime validation. Manual aesthetic approval records who reviewed which build and what they accepted.
