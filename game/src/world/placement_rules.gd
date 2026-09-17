## Purpose: Generates deterministic, data-only plant and rock placement records.
## Why: Cells can load in any order while preserving ownership, clustering, and scale.
## Reads: C02 identity, C03 terrain queries, habitat JSON, and approved asset IDs.
## Writes: In-memory C04 record dictionaries only; it creates no scene nodes or files.
## Safe changes: Tune habitat density, slope, scale, or cluster limits in habitats.json.
## Failure: Returns DEFERRED for unready terrain and ERROR for invalid data or assets;
##          it never places an object at height zero as a fallback.
class_name PlacementRules
extends RefCounted

const WorldChoicesType = preload("res://src/world/world_choices.gd")
const HABITATS_PATH := "res://data/habitats.json"
const CELL_WIDTH_M := 256.0
const MAX_DENSITY_PER_CELL := 64
const MAX_CLUSTERS := 16

static func load_habitats() -> Dictionary:
	var file := FileAccess.open(HABITATS_PATH, FileAccess.READ)
	if file == null:
		return {"habitats": [], "error": "could not open %s" % HABITATS_PATH}
	var parser := JSON.new()
	var parse_error := parser.parse(file.get_as_text())
	file.close()
	if parse_error != OK or not (parser.data is Dictionary):
		return {"habitats": [], "error": "habitats file is not valid JSON"}
	var data: Dictionary = parser.data
	var error := validate_habitats(data)
	return {"habitats": data.get("habitats", []), "error": error}

static func validate_habitats(data: Dictionary) -> String:
	if int(data.get("schema_version", -1)) != 1:
		return "habitats schema_version must be 1"
	var habitats: Variant = data.get("habitats", [])
	if not (habitats is Array) or (habitats as Array).is_empty():
		return "habitats must be a non-empty array"
	var seen := {}
	for habitat: Dictionary in habitats:
		var habitat_id := String(habitat.get("habitat_id", ""))
		if habitat_id.is_empty() or seen.has(habitat_id):
			return "habitat IDs must be non-empty and unique"
		seen[habitat_id] = true
		var channel := String(habitat.get("channel", ""))
		if WorldChoicesType.try_unit_value("0", channel, "0", "0", "0").error != "":
			return "habitat %s has an invalid channel" % habitat_id
		var density := int(habitat.get("density_per_cell", 0))
		var clusters := int(habitat.get("cluster_count", 0))
		if density < 1 or density > MAX_DENSITY_PER_CELL or clusters < 1 or clusters > MAX_CLUSTERS:
			return "habitat %s has invalid density or cluster count" % habitat_id
		var min_slope := float(habitat.get("min_slope", NAN))
		var max_slope := float(habitat.get("max_slope", NAN))
		if not is_finite(min_slope) or not is_finite(max_slope) or min_slope < 0.0 or max_slope < min_slope:
			return "habitat %s has invalid slope limits" % habitat_id
		var scale_min := float(habitat.get("scale_min", NAN))
		var scale_max := float(habitat.get("scale_max", NAN))
		if not is_finite(scale_min) or not is_finite(scale_max) or scale_min <= 0.0 or scale_max < scale_min:
			return "habitat %s has invalid scale limits" % habitat_id
		var assets: Variant = habitat.get("asset_ids", [])
		if not (assets is Array) or (assets as Array).is_empty():
			return "habitat %s must name at least one asset ID" % habitat_id
	return ""

static func generate_cell(identity: Dictionary, cell_x: int, cell_z: int, terrain: Node, habitats: Array, catalogue: Dictionary) -> Dictionary:
	var identity_error := _validate_identity(identity)
	if not identity_error.is_empty():
		return {"status": "ERROR", "records": [], "error": identity_error}
	var habitat_error := validate_habitats({"schema_version": 1, "habitats": habitats})
	if not habitat_error.is_empty():
		return {"status": "ERROR", "records": [], "error": habitat_error}
	var records: Array[Dictionary] = []
	for habitat: Dictionary in habitats:
		var asset_id := _choose_approved_asset(identity, cell_x, cell_z, habitat, catalogue)
		if asset_id.is_empty():
			return {"status": "ERROR", "records": [], "error": "habitat %s has no approved asset ID" % habitat.habitat_id}
		var density := int(habitat.density_per_cell)
		for slot in range(density):
			var choice := _choice(identity, String(habitat.channel), cell_x, cell_z, slot)
			var cluster_index := slot % int(habitat.cluster_count)
			var anchor := _choice(identity, String(habitat.channel) + "_cluster", cell_x, cell_z, cluster_index)
			var x_unit := clampf(float(anchor.x) + (float(choice.x) - 0.5) * 0.22, 0.001, 0.999)
			var z_unit := clampf(float(anchor.z) + (float(choice.z) - 0.5) * 0.22, 0.001, 0.999)
			var x_m := x_unit * CELL_WIDTH_M
			var z_m := z_unit * CELL_WIDTH_M
			var position_result := WorldPosition.from_cells(cell_x, cell_z, x_m, z_m, 0.0)
			var position: WorldPosition = position_result.position
			var state := String(terrain.get_ground_state(position))
			if state == "PENDING":
				return {"status": "DEFERRED", "records": [], "error": "terrain is not ready for habitat %s" % habitat.habitat_id}
			if state != "READY":
				return {"status": "DEFERRED", "records": [], "error": "terrain returned %s for habitat %s" % [state, habitat.habitat_id]}
			var surface: Dictionary = terrain.query_surface(position)
			if surface.get("status") != "READY":
				return {"status": "DEFERRED", "records": [], "error": "surface query was not READY"}
			var normal: Vector3 = surface.normal
			var slope := sqrt(normal.x * normal.x + normal.z * normal.z)
			if slope < float(habitat.min_slope) or slope > float(habitat.max_slope):
				continue
			var scale := lerpf(float(habitat.scale_min), float(habitat.scale_max), choice.scale)
			records.append({
				"stable_id": "%d:%d:%s:%d" % [cell_x, cell_z, habitat.habitat_id, slot],
				"asset_id": asset_id,
				"cell_x": cell_x,
				"cell_z": cell_z,
				"local_x_m": x_m,
				"local_z_m": z_m,
				"y_m": float(surface.height_m),
				"yaw_rad": choice.yaw,
				"scale": scale,
				"habitat_id": String(habitat.habitat_id)
			})
	records.sort_custom(_sort_records)
	return {"status": "READY", "records": records, "error": ""}

static func _choose_approved_asset(identity: Dictionary, cell_x: int, cell_z: int, habitat: Dictionary, catalogue: Dictionary) -> String:
	var assets: Array = habitat.asset_ids
	var choice := _choice(identity, String(habitat.channel) + "_asset", cell_x, cell_z, 0)
	var candidate: String = String(assets[min(int(choice.asset * assets.size()), assets.size() - 1)])
	var entry: Variant = catalogue.get(candidate, null)
	return candidate if entry is Dictionary and String(entry.get("status", "")) == "APPROVED" else ""

static func _choice(identity: Dictionary, channel: String, cell_x: int, cell_z: int, slot: int) -> Dictionary:
	var result := WorldChoicesType.try_unit_value(String(identity.world_seed), channel, str(cell_x), str(cell_z), str(slot))
	var unit := float(result.unit_value)
	var second := float(WorldChoicesType.try_unit_value(String(identity.world_seed), channel + "_second", str(cell_x), str(cell_z), str(slot)).unit_value)
	return {"x": unit, "z": second, "scale": float(WorldChoicesType.try_unit_value(String(identity.world_seed), channel + "_scale", str(cell_x), str(cell_z), str(slot)).unit_value), "yaw": unit * TAU, "asset": second}

static func _sort_records(a: Dictionary, b: Dictionary) -> bool:
	return String(a.stable_id) < String(b.stable_id)

static func _validate_identity(identity: Dictionary) -> String:
	for field in ["schema_version", "generator_version", "content_version", "world_seed"]:
		if not identity.has(field):
			return "world identity is missing %s" % field
	if int(identity.schema_version) != 1 or String(identity.generator_version) != "g1" or String(identity.content_version) != "c1":
		return "world identity version is unsupported"
	return "" if not WorldChoicesType.try_unit_value(String(identity.world_seed), "placement", "0", "0", "0").error else "world_seed is not canonical"
