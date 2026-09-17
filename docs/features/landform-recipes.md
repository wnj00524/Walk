# Configurable landform recipes

The first procedural landscape uses one checked-in recipe at
`game/data/landform_recipe.json`. It describes the existing `ChunkTerrain`
heightmap in named units: a 256 metre chunk, a 3-by-3 support ring, 32 samples
per side, noise frequency in cycles per metre, and a start plus range in metres.
The modest frequency and 48 metre vertical range make broad slopes and valleys
readable without introducing a second height model.

`LandformRecipe` validates the JSON before a service uses it. Bad schema,
chunk size, density, frequency, or height range returns an error; it does not
silently fall back to another landscape. The accepted logical-coordinate
`ChunkTerrain` remains responsible for sampling, chunk streaming, collision,
and origin-safe queries. The main walker loads this recipe before configuring
that service, so the playable prototype and tests use the same values. The
older native probe reads the same recipe for diagnostic parity but is not the
accepted backend.

Run the focused checks with:

```text
python tools/check_game.py --suite landform
```

The suite checks valid loading, invalid parameter rejection, chunk
configuration, and fixed-seed sample reproducibility. It is a data and
determinism check, not a substitute for owner visual acceptance.
