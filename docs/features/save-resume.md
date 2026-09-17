# Save and resume

## What the owner can notice

Closing the walking prototype writes the current world seed, logical position,
and camera view. Starting it again waits for the nearby ChunkTerrain collision
to be ready, then restores the walker to that saved location. A missing save
starts the initial world; a corrupt or unsupported save shows a readable error
and is left untouched.

## How it works, in ordinary language

`game/src/persistence/world_save.gd` owns the small C05 JSON envelope. Cell
coordinates are written as decimal strings so large signed integers cannot be
rounded by JSON consumers. Saves are written to a temporary file and the old
file is copied to a backup before replacement. Loading only reads and validates
the file, so invalid input cannot silently replace it or reseed the world.

`game/src/app/main.gd` loads the envelope before starting the accepted terrain
service. It does not place the walker until the saved position reports READY
collision. During walking it keeps cell transitions as integer/local updates,
and the window-close notification writes the current view and position.

## Safe settings to change

The default save path is `user://world_save.json`. The schema, generator, and
content versions must stay aligned with C02/C05; migrations belong in a later
task. Do not turn a corrupt save into a new random world.

## How it is tested

```text
python tools/check_game.py --suite save
```

The suite covers the contract example, a negative cell, a large in-range cell,
unsupported version input, and corrupt JSON preservation. A graphical close /
reopen check is retained in `docs/evidence/T013.md`.
