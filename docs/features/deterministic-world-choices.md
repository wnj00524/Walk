# Deterministic world choices

## What the walker notices

There is no new visible scene element yet. The game now has a stable way to
choose an application-level asset or placement variant for a world cell, so
loading the same area in a different order cannot change that choice.

## How it works, in ordinary language

`WorldChoices` validates the seed, channel, cell coordinates, and slot before
building the exact C02 ASCII payload. It hashes that payload with SHA-256,
reads the first four bytes as an unsigned big-endian number, and maps it to a
unit interval value from zero up to (but not including) one. It uses no global
random stream and does not depend on time, frame rate, or load order.

Seeds and slots are canonical non-negative decimal strings. Cell coordinates
are canonical signed decimal strings, and channels use only lowercase ASCII
letters, digits, and underscores. Invalid identifiers return a readable error
instead of being silently normalised.

## Which files own the behaviour

- `game/src/world/world_choices.gd` owns input validation, payload construction, and SHA-256 mapping.
- `game/tests/test_world_choices.gd` reads the independent frozen seed fixture and owns order and rejection checks.
- `game/tests/run_tests.gd` registers the `deterministic` suite.
- `fixtures/seed_vectors.json` owns the expected hashes and values.

## Safe settings to change

The payload fields, separators, generator tag, byte order, and numeric limits
are contract values. Change them only through an explicit C02 contract update.
It is safe to add independent fixture vectors and invalid-input cases.

## Failure symptoms and where to look

An error in the returned dictionary means an identifier was empty, malformed,
out of range, or used disallowed channel characters. A frozen-vector mismatch
means the payload or digest interpretation changed; do not regenerate the
fixture to make that check pass.

## How it is tested

Run `python tools/check_game.py --suite deterministic`. It compares every
frozen payload, first-u32 value, and unit value, checks shuffled lookup order,
and verifies invalid identifiers fail explicitly. Also run the coordinates,
player, and smoke suites plus the helper tests and project validation.
Headless checks do not prove terrain noise, mesh identity, or visual quality;
those belong to later terrain and presentation tasks.
