# Logical world positions

## What the walker notices

There is no visible change yet. The walking experience now has a stable way to
remember that a point just west of the origin belongs to cell `-1`, while the
renderer can later keep nearby coordinates small.

## How it works, in ordinary language

`WorldPosition` stores signed horizontal cell numbers and metre offsets inside
each 256-metre cell. A world position is split with mathematical floor, so
`-0.25 m` becomes cell `-1` and local offset `255.75 m`; exact multiples such as
`256 m` begin the next cell. Height remains a finite metre value. The class is a
plain data object and does not create scene nodes, recenter terrain, or claim
that large-world rendering is solved.

## Which files own the behaviour

- `game/src/world/world_position.gd` owns normalisation, validation, and save-safe cell strings.
- `game/tests/test_world_position.gd` reads the frozen coordinate fixture and owns contract checks.
- `game/tests/run_tests.gd` registers the `coordinates` suite.
- `fixtures/coordinate_vectors.json` owns the independent expected examples.

## Safe settings to change

The 256-metre cell width and field units are contract values, not comfort
settings. Change them only through an explicit contract update. It is safe to
add independent test vectors without changing existing expected values.

## Failure symptoms and where to look

An error from `try_from_world_meters` means an input was non-finite. An error
from `from_cells` means an offset is outside `[0, 256)` or a cell is outside
the signed 64-bit range. These functions reject bad data rather than guessing.

## How it is tested

Run `python tools/check_game.py --suite coordinates`. It checks all vectors in
`fixtures/coordinate_vectors.json`, repeated positive and negative boundaries,
non-finite world values, and invalid local offsets. Also run the player and
smoke suites, `python tools/project.py validate`, and the helper test suite.
Headless tests do not prove terrain recentering or renderer precision; those are
later terrain tasks.
