# Headless test harness

## Reproducible project check

Run `python tools/check_game.py --suite smoke` from the repository root. The
wrapper checks the pinned Godot binary, imports the project before running the
selected suite, and retains the import and suite output in `artifacts/`.
It fails for a missing binary, a version mismatch, timeout, engine/script
error, unknown or empty suite, nonzero exit, or missing test counts. A green
result includes the executed, passed, and failed counts from the actual Godot
runner.

## What the walker notices

Nothing in the walking experience changes. This foundation feature gives the development team a small, named check that can prove the project shell is present before movement or terrain is added.

## How it works, in ordinary language

Godot starts `run_tests.gd` and passes only the arguments after `--` to it. The runner looks up an explicit suite name, executes its registered checks, prints executed/passed/failed counts, and exits with code 0 only when at least one check ran and all checks passed. Unknown and empty selections fail. The deliberately broken fixture is available only through `--self-test failure`, so it cannot make the normal smoke suite fail by accident.

## Which files own the behaviour

- `tools/check_game.py` owns binary/version discovery, import-before-suite
  ordering, error recognition, log retention, and wrapper exit codes.
- `tools/test_check_game.py` tests the wrapper with independent fake process
  results; it does not replace the real Godot smoke check.
- `game/tests/run_tests.gd` owns argument parsing, suite registration, result counting, output, and exit codes.
- `game/tests/test_smoke.gd` owns the independent main-scene smoke assertion.
- `game/tests/test_harness_failure.gd` owns the opt-in broken assertion used to test the harness itself.

## Safe settings to change, with units and suggested ranges

There are no user-facing settings. Add a suite only when it has a focused purpose and independent expectations. Keep the existing `smoke` name and exit-code meanings stable because later wrappers rely on them.

## Failure symptoms and where to look

- A smoke failure means the main scene path or project shell is missing; inspect `test_smoke.gd` and `game/scenes/main.tscn`.
- A nonzero result for unknown or empty input is expected and proves selection errors are visible.
- If the intentional failure exits 0, inspect result collection and `_finish` in `run_tests.gd`.

## How it is tested, with actual commands and known limitations

The wrapper unit tests use fake subprocess results to exercise failure handling,
then `python tools/check_game.py --suite smoke` invokes the actual Godot smoke
suite. These are headless checks; they do not prove visual quality, Windows
packaging, GPU performance, or future walking behaviour. Exact commands and
results are in `docs/evidence/T004.md`.
