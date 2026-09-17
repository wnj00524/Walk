## Purpose: Keeps nearby approved vegetation in bounded, cell-owned scene batches.
## Why: The renderer can release distant cells without changing placement ownership.
## Reads: C04 records, approved catalogue scene paths, and the logical viewer cell.
## Writes: Main-thread Node3D batch roots and their instantiated approved scenes.
## Safe changes: Adjust MAX_RESIDENT_BATCHES only with a matching performance check.
## Failure: Stale epochs, unready terrain, bad records, or missing assets create no
##          fallback objects and return a readable status/diagnostic.
class_name VegetationBatches
extends Node3D

const PlacementRulesType = preload("res://src/world/placement_rules.gd")
const MAX_RESIDENT_BATCHES := 9
const CELL_WIDTH_M := 256.0

var _identity: Dictionary = {}
var _terrain: Node
var _habitats: Array = []
var _catalogue: Dictionary = {}
var _epoch := 0
var _viewer_cell := Vector2i.ZERO
var _has_viewer := false
var _batches: Dictionary = {}
var _last_error := ""

static func load_catalogue() -> Dictionary:
	var file := FileAccess.open("res://data/asset_catalogue.json", FileAccess.READ)
	if file == null:
		return {"catalogue": {}, "error": "could not open approved asset catalogue"}
	var parser := JSON.new()
	var parse_error := parser.parse(file.get_as_text())
	file.close()
	if parse_error != OK or not (parser.data is Array):
		return {"catalogue": {}, "error": "approved asset catalogue is not a JSON array"}
	var catalogue := {}
	for entry: Dictionary in parser.data:
		var asset_id := String(entry.get("asset_id", ""))
		if asset_id.is_empty() or String(entry.get("status", "")) != "APPROVED":
			continue
		catalogue[asset_id] = entry
	return {"catalogue": catalogue, "error": ""}

func configure_from_files(identity: Dictionary, terrain: Node) -> Dictionary:
	var habitat_result := PlacementRulesType.load_habitats()
	if not String(habitat_result.error).is_empty():
		return {"status": "ERROR", "error": habitat_result.error}
	var catalogue_result := load_catalogue()
	if not String(catalogue_result.error).is_empty():
		return {"status": "ERROR", "error": catalogue_result.error}
	return configure(identity, terrain, habitat_result.habitats, catalogue_result.catalogue)

func configure(identity: Dictionary, terrain: Node, habitats: Array, catalogue: Dictionary) -> Dictionary:
	_epoch += 1
	_release_all()
	_last_error = ""
	if terrain == null:
		_last_error = "vegetation requires a terrain adapter"
		return {"status": "ERROR", "error": _last_error}
	var habitat_error := PlacementRulesType.validate_habitats({"schema_version": 1, "habitats": habitats})
	if not habitat_error.is_empty():
		_last_error = habitat_error
		return {"status": "ERROR", "error": _last_error}
	_identity = identity.duplicate(true)
	_terrain = terrain
	_habitats = habitats.duplicate(true)
	_catalogue = catalogue.duplicate(true)
	_has_viewer = false
	return {"status": "READY", "epoch": _epoch}

func update_viewer(logical_position: WorldPosition) -> Dictionary:
	if _terrain == null:
		return {"status": "ERROR", "error": "vegetation is not configured"}
	if logical_position == null or not is_finite(logical_position.local_x_m) or not is_finite(logical_position.local_z_m):
		return {"status": "ERROR", "error": "viewer logical position must contain finite local metres"}
	_viewer_cell = Vector2i(logical_position.cell_x + int(floor(logical_position.local_x_m / CELL_WIDTH_M)), logical_position.cell_z + int(floor(logical_position.local_z_m / CELL_WIDTH_M)))
	_has_viewer = true
	var wanted := _wanted_cells()
	for key: Vector2i in _batches.keys():
		if not wanted.has(key):
			(_batches[key] as Node3D).queue_free()
			_batches.erase(key)
	for key: Vector2i in wanted:
		if _batches.has(key):
			continue
		var generated := PlacementRulesType.generate_cell(_identity, key.x, key.y, _terrain, _habitats, _catalogue)
		if generated.status != "READY":
			_last_error = String(generated.error)
			continue
		apply_batch(key, generated.records, _epoch)
	return {"status": "READY", "resident_batch_count": _batches.size(), "epoch": _epoch}

func apply_batch(cell: Vector2i, records: Array, batch_epoch: int) -> Dictionary:
	if batch_epoch != _epoch:
		return {"status": "STALE", "records": 0}
	if _has_viewer and not _wanted_cells().has(cell):
		return {"status": "RELEASED", "records": 0}
	if not _batches.has(cell) and _batches.size() >= MAX_RESIDENT_BATCHES:
		return {"status": "BOUND", "records": 0}
	if _batches.has(cell):
		(_batches[cell] as Node3D).queue_free()
		_batches.erase(cell)
	var batch := Node3D.new()
	batch.name = "VegetationBatch_%d_%d" % [cell.x, cell.y]
	var rendered := 0
	for record: Dictionary in records:
		var error := _validate_record(record, cell)
		if not error.is_empty():
			_last_error = error
			continue
		var asset_entry: Variant = _catalogue.get(String(record.asset_id), null)
		if not (asset_entry is Dictionary) or String(asset_entry.get("state", "")) != "APPROVED":
			_last_error = "asset %s is not approved" % record.asset_id
			continue
		var resource_path := _runtime_path(String(asset_entry.get("source_path", asset_entry.get("derivative_path", ""))))
		var packed := load(resource_path) as PackedScene
		if packed == null:
			_last_error = "approved asset %s could not load from %s" % [record.asset_id, resource_path]
			continue
		var instance := packed.instantiate() as Node3D
		if instance == null:
			_last_error = "approved asset %s did not instantiate as Node3D" % record.asset_id
			continue
		instance.position = Vector3(float(record.local_x_m), float(record.y_m), float(record.local_z_m))
		instance.rotation.y = float(record.yaw_rad)
		instance.scale = Vector3.ONE * float(record.scale)
		batch.add_child(instance)
		rendered += 1
	add_child(batch)
	_batches[cell] = batch
	return {"status": "READY", "records": records.size(), "rendered": rendered, "epoch": batch_epoch}

func get_diagnostics() -> Dictionary:
	var rendered := 0
	for batch: Node3D in _batches.values():
		rendered += batch.get_child_count()
	return {"epoch": _epoch, "resident_batch_count": _batches.size(), "rendered_instance_count": rendered, "last_error": _last_error}

func shutdown() -> void:
	_epoch += 1
	_release_all()
	_terrain = null
	_has_viewer = false

func _wanted_cells() -> Dictionary:
	var wanted := {}
	for z in range(_viewer_cell.y - 1, _viewer_cell.y + 2):
		for x in range(_viewer_cell.x - 1, _viewer_cell.x + 2):
			wanted[Vector2i(x, z)] = true
	return wanted

func _release_all() -> void:
	for batch: Node3D in _batches.values():
		batch.queue_free()
	_batches.clear()

func _validate_record(record: Dictionary, cell: Vector2i) -> String:
	if int(record.get("cell_x", cell.x)) != cell.x or int(record.get("cell_z", cell.y)) != cell.y:
		return "record owner does not match vegetation batch cell"
	var x_m := float(record.get("local_x_m", NAN))
	var z_m := float(record.get("local_z_m", NAN))
	var y_m := float(record.get("y_m", NAN))
	var scale := float(record.get("scale", NAN))
	if not is_finite(x_m) or not is_finite(z_m) or not is_finite(y_m) or not is_finite(scale):
		return "record coordinates and scale must be finite"
	if x_m < 0.0 or x_m >= CELL_WIDTH_M or z_m < 0.0 or z_m >= CELL_WIDTH_M or scale <= 0.0:
		return "record is outside its half-open cell or has non-positive scale"
	return ""

func _runtime_path(path: String) -> String:
	if path.begins_with("res://"):
		return path
	if path.begins_with("game/"):
		return "res://" + path.trim_prefix("game/")
	return "res://" + path.trim_prefix("/")
