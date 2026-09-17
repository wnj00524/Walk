# Bounded vegetation batches

`VegetationBatches` is the presentation layer between deterministic placement
records and scene instances. It keeps at most nine nearby logical-cell roots,
releases cells outside the three-by-three neighborhood, and creates approved
asset scenes on the main thread at the placement record's terrain height,
yaw, and scale.

The renderer never invents objects when placement is pending or an asset is
missing. It converts only `APPROVED` catalogue entries with local `res://`
resources into instances; the checked-in catalogue now contains three
approved textured local GLBs, and missing assets still produce no fallback
geometry. An epoch is attached to each batch handoff so a stale
result cannot repopulate a released or reconfigured world.

The main walker loads the habitat rules and approved catalogue before enabling
the renderer. The object layer remains bounded and disposable; logical world
identity and placement ownership stay in the world layer.

Run the lifecycle checks with:

```text
python tools/check_game.py --suite vegetation
```

The suite checks create/reuse, the nine-batch cap, stale-result rejection, and
invalid-record rejection. A real-renderer asset-contact check is retained
under `artifacts/T022_visual_capture`; final owner slice acceptance remains
T024.
