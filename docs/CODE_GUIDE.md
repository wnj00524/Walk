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
| game/tests/probes/terrain_api_probe.gd | Constructs the pinned Voxel Tools native classes, records reflected API names, and performs small generator/viewer/collision/diagnostic calls | Keep calls guarded by observed class methods; do not turn this probe into a terrain world | `godot --headless --path game --script res://tests/probes/terrain_api_probe.gd` |

Feature walkthroughs:
- [Toolchain and Environment Setup](features/setup.md)
- [Minimal Godot Project Shell](features/project-shell.md)
- [Comfortable First-Person Walking](features/walking.md)
- [Logical World Positions](features/logical-positions.md)
- [Deterministic World Choices](features/deterministic-world-choices.md)
- [Voxel Tools Terrain API](features/terrain-api.md)

The minimal game shell, labelled walking fixture, logical position value, deterministic application-level choice helper, and pinned Voxel Tools API probe are implemented. Terrain generation, asset clients, sound, saves, and the full world are not. As tasks add them, update this index without implying that planned files already work.
