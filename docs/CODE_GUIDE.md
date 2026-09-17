# What each implemented part does

This index describes only code actually included now. Intended game modules are described separately in ARCHITECTURE.md.

| File | Ordinary-language purpose | Safe adjustments | Checks |
| --- | --- | --- | --- |
| tools/project.py | Checks the plan/task records and prints a small assignment for one agent | Brief byte limit, with care; do not weaken dependency checks | `python -m unittest discover -s tools -p "test_*.py"` |
| tools/test_project.py | Tests the helper itself using temporary copies and intentionally bad records | Add new failure examples; do not delete inconvenient assertions | Same command |
| tools/check_game.py | Checks the pinned Godot version, imports the project, then runs one real registered game suite and saves phase logs | Keep the version/error/count checks strict; suite names must also exist in the Godot runner | `python tools/check_game.py --suite smoke` |
| tools/test_check_game.py | Tests wrapper failure and success handling with independent fake subprocess results | Add explicit failure fixtures; do not use production output to define expectations | `python -m unittest tools/test_check_game.py` |
| fixtures/seed_vectors.json | Fixed examples of seed-based choices for future game tests | Do not regenerate to hide an implementation mismatch | T007 consumes these in Godot |
| fixtures/coordinate_vectors.json | Fixed examples of positive/negative map positions | Add independent examples without changing existing expectations | T006 consumes these in Godot |
| docs/toolchain.lock.json | Pinned toolchain candidate versions, download URLs, and SHA-256 hashes | Candidate versions require matching checksums; see [docs/features/setup.md](features/setup.md) | `python tools/project.py validate` |
| game/project.godot | Tells Godot which scene starts and sets the prototype window and renderer | Development window size; keep the main-scene path stable | `godot --headless --path game --editor --quit` |
| game/src/player/walker.gd | Moves the first-person body, applies mouse look, and releases/re-captures the cursor safely | Speed, sensitivity, and pitch limits in metres/second and degrees | `python tools/check_game.py --suite player` plus graphical walk/look check |
| game/scenes/player.tscn | Defines the player's collision capsule and eye-height camera | Capsule and camera dimensions, with visual review | Loaded by the player suite and prototype scene |
| game/tests/test_player.gd | Tests comfort bounds and physics-step-independent movement | Add independent cases for changed comfort contracts | `python tools/check_game.py --suite player` |
| game/scenes/main.tscn | Shows the labelled test floor, daylight, start marker, and controls for T005 | Fixture dimensions and instructional text only | Launch with `godot --path game` and perform the graphical check |
| game/src/app/main.gd | Turns a window-close request into an orderly application exit | Add startup behaviour only in its assigned task | Launch, close the window, and confirm exit code 0 |
| game/tests/run_tests.gd | Runs named offline Godot suites and reports honest counts and exit codes | Add focused registered suites; keep smoke and failure semantics stable | `godot --headless --path game --script res://tests/run_tests.gd -- --suite smoke` |
| game/tests/test_smoke.gd | Checks that the current main scene exists for the passing smoke suite | Add independent foundation assertions | Selected by the smoke suite; headless only |
| game/tests/test_harness_failure.gd | Supplies an opt-in known failure to prove failures reach the process exit code | Keep intentionally broken and out of normal suites | `godot --headless --path game --script res://tests/run_tests.gd -- --self-test failure` |
| game/src/world/world_position.gd | Keeps signed 256-metre logical cells and finite local metre offsets separate from renderer coordinates | Cell width and contract validation only | `python tools/check_game.py --suite coordinates` |
| game/tests/test_world_position.gd | Reads frozen coordinate examples and checks boundaries and invalid input | Add independent cases without deriving expectations from production code | `python tools/check_game.py --suite coordinates` |
| game/src/world/world_choices.gd | Turns a canonical world identity, cell, channel, and slot into a repeatable SHA-256 choice value | C02 payload fields, validation limits, and digest interpretation | `python tools/check_game.py --suite deterministic` |
| game/tests/test_world_choices.gd | Compares deterministic choices with frozen seed vectors and checks order independence and rejection | Add independent vectors and invalid cases; do not generate expected values from production code | `python tools/check_game.py --suite deterministic` |
| game/src/persistence/world_save.gd | Validates and atomically reads/writes the C05 world identity, logical position, and view envelope | Schema/version fields and decimal-string cell rules; preserve invalid originals | `python tools/check_game.py --suite save` |
| game/tests/test_world_save.gd | Checks save round-trips, negative/large cells, unsupported versions, and corrupt-file preservation | Add independent malformed fixtures; never weaken preservation assertions | `python tools/check_game.py --suite save` |
| game/tests/test_terrain_consistency.gd | Compares accepted terrain samples with pinned values, shared boundaries, repeat generation, and changed-seed behavior | Add independently reviewed fixture rows and tolerances; do not duplicate the noise function | `python tools/check_game.py --suite terrain` |
| game/tests/fixtures/terrain_samples.json | Stores the reviewed seed-42 surface values used to detect terrain drift and edge discontinuity | Coordinates, seed, recipe values, and tolerance are evidence-controlled | Consumed by the terrain suite |
| tools/run_visual.py | Runs the non-headless fixed-route capture and rejects missing display, report, or image outputs | Output directory, timeout, and named route validation | `python tools/run_visual.py --output-dir artifacts/T015_visual_capture` |
| tools/test_run_visual.py | Tests visual-wrapper failure and success validation with offline fixtures | Keep missing/empty/headless cases strict | `python -m unittest tools/test_run_visual.py` |
| tools/asset_registry.py | Validates offline C06 request/catalogue records, local paths, hashes, and finite budgets before provider work | Stable IDs, lifecycle values, confined paths, and zero-job example budget | `python tools/asset_registry.py` |
| tools/test_asset_registry.py | Tests duplicate IDs, approved-file requirements, traversal, bad states/hashes, and budget safety | Add independent invalid records; never authorize real work in fixtures | `python -m unittest tools/test_asset_registry.py` |
| asset_requests/initial.json | Holds three request-only rock/tree/ground-cover examples with no claimed files | Prompts, dimensions, and hashes are reviewable request metadata | Consumed by asset_registry.py |
| game/data/asset_catalogue.json | Empty approved runtime catalogue until assets pass technical and visual review | Add only approved local assets with provenance | Consumed by later asset tasks |
| game/tests/visual_capture.gd | Waits for terrain readiness and saves the fixed route's real-renderer PNGs plus metadata report | Camera poses belong in visual_route.json; retain report fields | Invoked by run_visual.py |
| game/tests/visual_route.json | Defines seed, recipe, four named camera poses, and the return view | Change poses only with a recorded visual-review reason | Consumed by visual_capture.gd |
| tools/meshy_client.py | Performs guarded, resumable Meshy development submissions and verified GLB downloads | Keep dry-run default, explicit budget/key gates, HTTPS host and size limits, and no automatic uncertain-POST retry | `python -m unittest tools/test_meshy_client.py` |
| tools/test_meshy_client.py | Uses local fixture responses to test every Meshy client safety outcome without network access | Add independent fixture cases; never add live credentials or calls | `python -m unittest tools/test_meshy_client.py` |
| tools/fixtures/meshy_responses.json | Stores representative create, task, error, and download responses for offline tests | Keep provider-shaped data clearly fixture-only | Consumed by test_meshy_client.py |
| tools/import_asset.py | Measures and validates a local GLB and records a reproducible technical report without changing source bytes | Keep the 100 MB limit and positive wrapper scale; review collision separately | `python -m unittest tools/test_import_asset.py` |
| tools/test_import_asset.py | Tests GLB header, metadata, mesh, size, bounds, and wrapper safeguards with generated offline fixtures | Add independent malformed cases; do not use Blender or assumed production counts | `python -m unittest tools/test_import_asset.py` |
| game/tests/tools/inspect_asset.gd | Loads a candidate scene through Godot and reports actual mesh-instance bounds in a labelled review fixture | Keep it fixture-only; it must not become runtime asset loading | Godot headless fixture invocation with a local GLB |
| game/tests/tools/asset_review.tscn | Provides the scene wrapper for the Godot GLB import inspection fixture | Do not add manual catalogue assets or service calls | Used by inspect_asset.gd |
| asset_requests/initial.json | Names the finite representative rock, tree, and fern batch | Change only with a new recorded budget and technical/visual review | Consumed by the Meshy workflow and registry |
| game/data/asset_catalogue.json | Lists only assets cleared for runtime use; it remains empty while T019 is blocked | Never add an unreviewed generation | Consumed by later runtime asset tasks |
| game/tests/probes/terrain_api_probe.gd | Constructs the pinned Voxel Tools native classes, records reflected API names, and performs small generator/viewer/collision/diagnostic calls | Keep calls guarded by observed class methods; do not turn this probe into a terrain world | `godot --headless --path game --script res://tests/probes/terrain_api_probe.gd` |
| game/src/terrain/terrain_service.gd | Owns the native seeded smooth terrain, camera viewer, collision setting, readiness state, and backend diagnostics | Noise range, frequency, and view distance are metre settings; keep readiness tied to native work | Streamed ground probe |
| game/src/terrain/chunk_terrain.gd | Owns the alternative logical-coordinate heightmap chunks, worker generation, visual nodes, nearby collision, readiness states, and epoch diagnostics | Chunk size, ring size, density, noise frequency, and height range are terrain recipe values; preserve logical-space sampling and epoch checks | `chunk_terrain` suite and direct chunk probe |
| game/src/world/landform_recipe.gd | Validates the single checked-in landform recipe and passes it to the terrain adapter | Frequency is cycles per metre; vertical values and chunk size are metres; preserve the validation limits | `python tools/check_game.py --suite landform` |
| game/tests/probes/streamed_ground.gd | Waits for native ground, walks across checkpoints, and reports backend diagnostics | Checkpoints are probe distances; this script must not become production terrain logic | Streamed ground probe |
| game/tests/probes/streamed_ground.tscn | Reproducible graphical scene containing terrain, viewer, lighting, and walker | Camera start and neutral lighting only | Graphical probe |
| game/data/terrain_probe.json | Records the T009 seed, backend, budgets, and unavailable metrics | Keep aligned with the probe settings | Read by review |
| game/tests/probes/coordinate_probe.gd | Measures logical cells, native noise samples, large-distance `Vector3` precision, boundary crossings, and a candidate origin handoff | Test distances and evidence tolerances only; do not turn it into production movement logic | `godot --headless --path game --script res://tests/probes/coordinate_probe.gd` |
| game/tests/probes/coordinate_probe.tscn | Reuses the native terrain and walker in a graphical coordinate investigation scene | Camera start and neutral lighting only | Graphical coordinate probe |
| game/src/terrain/terrain_service.gd | Owns the native terrain and provides a diagnostic sample using the configured noise generator | Keep the sample diagnostic-only; native collision remains authoritative | Coordinate probe and streamed-ground probe |

T011 records the future terrain adapter boundary in
[docs/CONTRACTS.md](CONTRACTS.md). It is deliberately not described as an
implemented API: the current service owns only the probe operations above, and
T012 is blocked until an identity-preserving backend strategy exists.

T012's gate record in [docs/evidence/T012.md](evidence/T012.md) explains why the
candidate is rejected. `docs/toolchain.lock.json` remains useful as a pinned
probe record, but its `backend_gate` flag is false and later terrain work must
wait for a separately approved alternative spike.

Feature walkthroughs:
- [Toolchain and Environment Setup](features/setup.md)
- [Minimal Godot Project Shell](features/project-shell.md)
- [Comfortable First-Person Walking](features/walking.md)
- [Logical World Positions](features/logical-positions.md)
- [Deterministic World Choices](features/deterministic-world-choices.md)
- [Voxel Tools Terrain API](features/terrain-api.md)
- [Script-Defined Streamed Ground Probe](features/streamed-ground-probe.md)
- [Large-Distance Coordinate Probe](features/coordinates.md)
- [ChunkTerrain alternative backend](features/terrain-api.md#chunkterrain-alternative-backend-t012a)
- [Save and resume](features/save-resume.md)
- [Terrain consistency checks](features/terrain-consistency.md)
- [Repeatable terrain captures](features/visual-captures.md)
- [Offline asset request registry](features/asset-registry.md)

The minimal game shell, labelled walking fixture, logical position value, deterministic application-level choice helper, pinned Voxel Tools API probe, T009 native terrain probe, and T010 coordinate feasibility probe are implemented. T010 found that logical coordinates remain exact at tested distances but the candidate native-origin handoff does not preserve terrain identity; backend acceptance remains downstream work. Asset clients, sound, saves, and the full world are not implemented.
