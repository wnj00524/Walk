# Deterministic placement rules

`game/data/habitats.json` defines the first three habitat variants: forest,
meadow, and rocky. Density is objects per 256 m logical cell, cluster count
controls the broad grouping, slope limits use the terrain normal's horizontal
gradient (dimensionless rise/run), and scale is a positive multiplier. Asset
IDs are references, not substitutes; only entries whose catalogue state is
`APPROVED` may produce a record.

`PlacementRules` generates C04 records without creating scene nodes. Each cell
owns positions in the half-open range `[0, 256)` metres on both horizontal
axes. Every random-looking value comes from the C02 SHA-256 choice payload,
with separate channels for position, scale, yaw, and asset selection. Records
are sorted by stable ID, so cell load order and global random state cannot
change them.

Before accepting a candidate, the rule asks the actual terrain adapter for
ground readiness and a surface height/normal. `PENDING`, `ERROR`, and outside
support states return `DEFERRED` with no records; objects are never placed at
height zero while terrain is unavailable. Missing or unapproved catalogue IDs
return `ERROR` rather than silently selecting a different asset.

Run the focused proof with:

```text
python tools/check_game.py --suite placement
```

T024a uses bounded grouping budgets: forest is 24 objects across 5 clusters
per cell, meadow is 16 across 4 clusters, and rocky is 10 across 3 clusters.
These values preserve deterministic ownership, terrain gating, approved-asset
checks, and the nine-batch renderer bound while making habitat groups more
readable in fixed-seed captures.

This verifies valid habitat data, stable sorted records, reversed cell load
order, missing-asset rejection, and deferred terrain readiness. It uses a
labelled in-memory approved catalogue in tests; the checked-in runtime
catalogue remains empty until assets pass visual review.
