# Verification: prove separate things separately

## Commands implemented in this starter pack

```text
python tools/project.py validate
python -m unittest discover -s tools -p "test_*.py"
```

These check task metadata, plan consistency, referenced documentation, brief generation and helper behaviour. They do not test a game. The validator is not a security sandbox, a semantic code reviewer, a complete Markdown link checker or a substitute for runtime checks.

## Commands introduced later

T003 introduces `game/tests/run_tests.gd`. T004 introduces the wrapper below, and documents the pinned engine path in GODOT_BIN:

```text
python tools/check_game.py --suite smoke
python tools/check_game.py --suite coordinates
python tools/check_game.py --suite deterministic
```

Until those tasks are accepted, these are contracts for future commands, not runnable pack features. The wrapper must import resources before testing and invoke the pinned Godot editor. Conceptual native commands, checked against the selected version:

```text
godot --headless --path game --import
godot --headless --path game --script res://tests/run_tests.gd -- --suite coordinates
```

The Godot command-line documentation distinguishes importing, scripts and export; exporting requires matching templates [S02]. A project-wide parse/import check and a selected test suite are complementary. `--check-only` on one script does not prove the whole project imports or executes.

## Required test behaviour

Use a small explicit test registry, not a complex new testing framework. Every suite reports executed/passed/failed counts and exits nonzero on failure, unknown suite, empty selection or unexpected errors. Import failures, script errors, crashes and timeouts fail the run even when a subprocess returns an apparently successful code. The wrapper captures logs and reports unavailable tools distinctly, with a nonzero exit code.

Unit tests cover pure logic. Integration tests instantiate actual collaborating components. Use independent fixtures, not expected values produced by the code being tested. Keep test doubles under `game/tests/` or `tools/tests/`; production must never quietly fall back to them. At least one deliberately broken fixture/check must be shown to fail when introducing the harness.

## World correctness cases

Coordinates: origin, both sides of boundaries, negative positions, non-finite inputs and save integer limits. Seed choices: frozen vectors, channel separation, repeat load order and changed seeds. Terrain: sample shared boundaries at different detail levels; approach from opposite directions; reject stale generation completions; do not walk onto missing collision. Saves: round-trip, corruption, interrupted write, unknown versions and missing approved content. Streaming: sustained travel with resident counts, actual memory samples and cache-size measurements.

A deterministic replay route must use logical coordinates and fixed seed/settings. It must report movement blocked by missing collision separately from successful travel. A route that stood still for the whole test does not demonstrate streaming.

## GPU and owner review

T015 supplies a GPU-capable capture command and fixed viewpoints. It must run without `--headless`; a dummy renderer is not an image test. Capture an overview, ground-level walk, close ground/foliage view and the same place after a return trip. Record seed, build/version, settings, camera pose and hardware. Missing graphics access is NOT RUN. A vision-capable reviewer can triage defects, but final aesthetic acceptance belongs to the owner.

Audio needs actual listening. Check loops, loudness changes, clipping, repetition and positional behaviour. A successful audio-file parse is not a listening test. Automated waveform checks may assist but do not replace it.

## Provisional performance protocol

Before judging performance, record CPU, GPU, RAM, driver, OS, resolution, preset and whether the build is exported release/debug. Proposed target is 1080p/60 FPS; this is not a promise for unspecified hardware. Report median, p95 and p99 frame times, not only an average FPS. Separate import/shader warm-up from the measured route. Use identical seeds/routes when comparing changes.

For an initial memory-regression alarm, warm for 5 minutes, then travel for at least 30 minutes, sampling once a second. Compare the first and final five-minute steady-state medians. A rise greater than max(128 MiB, 10% of the first median) triggers investigation. This is a proposed detection threshold, not proof that smaller growth is leak-free. Also inspect the trend, resident-block caps and cache eviction. Repeat with a longer soak before release. Record unmeasured GPU memory explicitly.

If no monitor dependency is approved, collect engine counters and use documented OS-native measurements. Do not invent process RAM values from unrelated engine counters. Proposed disk cache cap: 512 MiB, configurable and measured; no generated cache is required if regeneration is sufficient.

## Evidence and completion

Every task uses `docs/evidence/Txxx.md` based on the template. Keep logs/screenshots/builds under ignored artifacts, attach them to review or retain them in an accessible location, and record hashes/paths. A local artifact path unavailable to the reviewer is incomplete evidence. Do not require the same screenshot pixels across different GPUs; use fixed numerical fixtures for logic and a qualitative rubric for presentation.

CI may run offline headless checks without secrets. GPU tests and Windows launch tests need appropriate runners or the owner's machine. A Linux headless pass must not be described as a verified Windows launch. No paid API calls in routine CI.
