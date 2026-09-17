## Purpose: Proves C04 placement ownership, order independence, terrain gating, and asset safety.
## Why: Procedural objects must be repeatable and grounded before a renderer consumes them.
## Reads: Actual synchronous ChunkTerrain queries and the checked-in habitat rules.
## Writes: Temporary terrain nodes and labelled in-memory approved-catalogue test data.
## Safe changes: Add independent seed/cell cases; keep half-open and deferred assertions.
## Failure: A non-empty result names a changed record, boundary duplicate, or unsafe fallback.
extends RefCounted

const PlacementRulesType = preload("res://src/world/placement_rules.gd")
const ChunkTerrainType = preload("res://src/terrain/chunk_terrain.gd")
const LandformRecipeType = preload("res://src/world/landform_recipe.gd")

static func loads_valid_habitats() -> String:
	var result := PlacementRulesType.load_habitats()
	return "habitats failed: %s" % result.error if not String(result.error).is_empty() else ""

static func records_are_stable_and_sorted() -> String:
	var habitats: Array = PlacementRulesType.load_habitats().habitats
	var first := _generate(42, 3, 4, habitats)
	var second := _generate(42, 3, 4, habitats)
	if first.status != "READY" or second.status != "READY":
		return "placement did not become READY"
	if first.records != second.records:
		return "same seed/cell changed records"
	if first.records.is_empty():
		return "valid approved catalogue produced no placement records"
	for index in range(1, first.records.size()):
		if first.records[index - 1].stable_id >= first.records[index].stable_id:
			return "records are not sorted by stable_id"
	return ""

static func reversed_cell_load_order_is_stable() -> String:
	var habitats: Array = PlacementRulesType.load_habitats().habitats
	var forward := {}
	var reverse := {}
	for cell in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]:
		forward[cell] = _generate(42, cell.x, cell.y, habitats).records
	for cell in [Vector2i(1, 1), Vector2i(0, 1), Vector2i(1, 0), Vector2i(0, 0)]:
		reverse[cell] = _generate(42, cell.x, cell.y, habitats).records
	for cell in forward:
		if forward[cell] != reverse[cell]:
			return "cell %s changed with load order" % cell
	return ""

static func neighboring_cells_have_disjoint_owners() -> String:
	var habitats: Array = PlacementRulesType.load_habitats().habitats
	var west: Array = _generate(42, 0, 0, habitats).records
	var east: Array = _generate(42, 1, 0, habitats).records
	var owners := {}
	for record: Dictionary in west:
		owners[record.stable_id] = true
	for record: Dictionary in east:
		if owners.has(record.stable_id):
			return "neighboring cells duplicated %s" % record.stable_id
		if float(record.local_x_m) < 0.0 or float(record.local_x_m) >= 256.0 or float(record.local_z_m) < 0.0 or float(record.local_z_m) >= 256.0:
			return "record escaped its half-open cell bounds"
	return ""

static func rejects_missing_assets() -> String:
	var habitats: Array = PlacementRulesType.load_habitats().habitats
	var result := _generate_with_catalogue(42, 0, 0, habitats, {})
	return "missing catalogue IDs were silently accepted" if result.status != "ERROR" or result.records.size() != 0 else ""

static func defers_unready_terrain() -> String:
	var habitats: Array = PlacementRulesType.load_habitats().habitats
	var result := _generate_with_catalogue(42, 0, 0, habitats, _catalogue(), false)
	return "expected DEFERRED terrain state, got %s" % result.status if result.status != "DEFERRED" else ""

static func _generate(seed_value: int, cell_x: int, cell_z: int, habitats: Array) -> Dictionary:
	return _generate_with_catalogue(seed_value, cell_x, cell_z, habitats, _catalogue())

static func _generate_with_catalogue(seed_value: int, cell_x: int, cell_z: int, habitats: Array, catalogue: Dictionary, configure_terrain: bool = true) -> Dictionary:
	var holder := Node3D.new()
	var terrain := ChunkTerrainType.new()
	holder.add_child(terrain)
	if configure_terrain:
		var recipe: Dictionary = LandformRecipeType.load_default().recipe
		recipe["synchronous_generation"] = true
		terrain.configure(_identity(seed_value), recipe)
		terrain.update_viewer(WorldPosition.from_cells(cell_x, cell_z, 128.0, 128.0, 0.0).position)
	var result := PlacementRulesType.generate_cell(_identity(seed_value), cell_x, cell_z, terrain, habitats, catalogue)
	terrain.shutdown()
	holder.free()
	return result

static func _catalogue() -> Dictionary:
	return {
		"tree_temperate_01": {"status": "APPROVED"},
		"groundcover_fern_01": {"status": "APPROVED"},
		"rock_temperate_01": {"status": "APPROVED"}
	}

static func _identity(seed_value: int) -> Dictionary:
	return {"schema_version": 1, "generator_version": "g1", "content_version": "c1", "world_seed": str(seed_value)}
