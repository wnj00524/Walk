## Purpose: Proves the authored landform recipe is valid, bounded, and deterministic.
## Why: The first visual slice needs stable broad terrain inputs before placement work.
## Reads: The checked-in recipe and ChunkTerrain's public configuration/sampling API.
## Writes: Temporary in-memory terrain nodes only; no world or save data.
## Safe changes: Add independently chosen invalid cases or fixed sample coordinates.
## Failure: A non-empty result identifies the rejected parameter or changed sample.
extends RefCounted

const LandformRecipeType = preload("res://src/world/landform_recipe.gd")
const ChunkTerrainType = preload("res://src/terrain/chunk_terrain.gd")

static func loads_valid_recipe() -> String:
	var result := LandformRecipeType.load_default()
	return "default recipe failed: %s" % result.error if not String(result.error).is_empty() else ""

static func rejects_invalid_parameters() -> String:
	var result := LandformRecipeType.load_default()
	var recipe: Dictionary = result.recipe
	for field in ["frequency", "height_range_m", "chunk_size_m"]:
		var invalid := recipe.duplicate(true)
		invalid[field] = -1.0
		var error := LandformRecipeType.validate(invalid)
		if error.is_empty():
			return "invalid %s was accepted" % field
	return ""

static func configures_chunk_terrain() -> String:
	var result := LandformRecipeType.load_default()
	var terrain := ChunkTerrainType.new()
	var holder := Node3D.new()
	holder.add_child(terrain)
	var configured := terrain.configure(_identity(42), result.recipe)
	if configured.get("status") != "READY":
		holder.free()
		return "chunk terrain rejected recipe: %s" % configured
	terrain.shutdown()
	holder.free()
	return ""

static func fixed_seed_shape_is_reproducible() -> String:
	var result := LandformRecipeType.load_default()
	var first := _sample_grid(42, result.recipe)
	var second := _sample_grid(42, result.recipe)
	if first != second:
		return "same seed and recipe produced different samples"
	var minimum := 9999.0
	var maximum := -9999.0
	for value: float in first:
		minimum = min(minimum, value)
		maximum = max(maximum, value)
	return "fixed view has no landform variation" if maximum - minimum < 1.0 else ""

static func _sample_grid(seed_value: int, recipe: Dictionary) -> Array[float]:
	var terrain := ChunkTerrainType.new()
	var holder := Node3D.new()
	holder.add_child(terrain)
	var configured := recipe.duplicate(true)
	configured["synchronous_generation"] = true
	terrain.configure(_identity(seed_value), configured)
	terrain.update_viewer(WorldPosition.from_cells(0, 0, 128.0, 128.0, 0.0).position)
	var values: Array[float] = []
	for z in [32.0, 96.0, 160.0, 224.0]:
		for x in [32.0, 96.0, 160.0, 224.0]:
			var sample := terrain.query_surface(WorldPosition.from_cells(0, 0, x, z, 0.0).position)
			values.append(float(sample.get("height_m", 0.0)))
	terrain.shutdown()
	holder.free()
	return values

static func _identity(seed_value: int) -> Dictionary:
	return {"schema_version": 1, "generator_version": "g1", "content_version": "c1", "world_seed": str(seed_value)}
