## Purpose: Starts the accepted terrain, restores the walker, and saves on clean quit.
## Why: Application glue owns resume ordering so the player never enters unready ground.
## Reads: C05 save data, the accepted ChunkTerrain readiness state, and walker motion.
## Writes: Walker transform in memory and the user://world_save.json save envelope.
## Safe changes: Save path and default identity are the intended settings; preserve readiness gating.
## Failure: Missing/corrupt saves show a readable error and do not silently reseed the world.
extends Node3D

const WorldSaveType = preload("res://src/persistence/world_save.gd")
const SAVE_PATH := "user://world_save.json"
const TERRAIN_RECIPE := {"chunk_size_m": 256.0, "view_chunks": 3, "vertices_per_side": 32}

var _terrain: ChunkTerrain
var _walker: Walker
var _position: WorldPosition
var _identity := {}
var _view := {"yaw_rad": 0.0, "pitch_rad": 0.0}
var _last_walker_position := Vector3.ZERO
var _origin_cell_x := 0
var _origin_cell_z := 0
var _started := false
var _status_label: Label

func _ready() -> void:
	_walker = $Walker as Walker
	var loaded: Dictionary = WorldSaveType.load_file(SAVE_PATH)
	if loaded.get("status") == "MISSING":
		_identity = WorldSaveType.default_identity()
		_position = WorldPosition.from_cells(0, 0, 128.0, 128.0, 0.0).position
	else:
		if loaded.get("status") != "READY":
			_show_status("Save could not be opened: %s" % loaded.get("error", "unknown error"))
			set_physics_process(false)
			return
		var data: Dictionary = loaded.data
		_identity = {
			"schema_version": data.schema_version,
			"generator_version": data.generator_version,
			"content_version": data.content_version,
			"world_seed": data.world_seed,
		}
		var saved_position: Dictionary = data.position
		_position = WorldPosition.from_cells(int(saved_position.cell_x), int(saved_position.cell_z), float(saved_position.local_x_m), float(saved_position.local_z_m), float(saved_position.y_m)).position
		_view = {"yaw_rad": float(data.view.yaw_rad), "pitch_rad": float(data.view.pitch_rad)}
		print("resume_loaded seed=%s cell_x=%s cell_z=%s local_x=%.3f local_z=%.3f" % [_identity.world_seed, saved_position.cell_x, saved_position.cell_z, _position.local_x_m, _position.local_z_m])
	_origin_cell_x = _position.cell_x
	_origin_cell_z = _position.cell_z
	_terrain = ChunkTerrain.new()
	add_child(_terrain)
	var configured := _terrain.configure(_identity, TERRAIN_RECIPE)
	if configured.get("status") != "READY":
		_show_status("Terrain could not start: %s" % configured.get("error", "unknown error"))
		set_physics_process(false)
		return
	_terrain.update_viewer(_position)
	set_physics_process(true)

func _physics_process(_delta: float) -> void:
	if not _started:
		if _terrain.get_ground_state(_position) != "READY":
			return
		_walker.position = Vector3(_position.local_x_m, _position.y_m, _position.local_z_m)
		_walker.rotation.y = float(_view.yaw_rad)
		_walker.camera.rotation.x = float(_view.pitch_rad)
		_last_walker_position = _walker.position
		_started = true
		return
	var movement := _walker.position - _last_walker_position
	_position.local_x_m += movement.x
	_position.local_z_m += movement.z
	while _position.local_x_m < 0.0:
		_position.cell_x -= 1
		_position.local_x_m += WorldPosition.CELL_WIDTH_M
	while _position.local_x_m >= WorldPosition.CELL_WIDTH_M:
		_position.cell_x += 1
		_position.local_x_m -= WorldPosition.CELL_WIDTH_M
	while _position.local_z_m < 0.0:
		_position.cell_z -= 1
		_position.local_z_m += WorldPosition.CELL_WIDTH_M
	while _position.local_z_m >= WorldPosition.CELL_WIDTH_M:
		_position.cell_z += 1
		_position.local_z_m -= WorldPosition.CELL_WIDTH_M
	_position.y_m = _walker.position.y
	if _position.cell_x != _origin_cell_x:
		_walker.position.x -= float(_position.cell_x - _origin_cell_x) * WorldPosition.CELL_WIDTH_M
		_origin_cell_x = _position.cell_x
	if _position.cell_z != _origin_cell_z:
		_walker.position.z -= float(_position.cell_z - _origin_cell_z) * WorldPosition.CELL_WIDTH_M
		_origin_cell_z = _position.cell_z
	_last_walker_position = _walker.position
	_view = {"yaw_rad": _walker.rotation.y, "pitch_rad": _walker.camera.rotation.x}
	_terrain.update_viewer(_position)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if _started:
			var result: Dictionary = WorldSaveType.save_file(SAVE_PATH, _identity, _position, _view)
			if result.get("status") != "READY":
				_show_status("Save failed: %s" % result.get("error", "unknown error"))
				return
			print("save_written seed=%s cell_x=%d cell_z=%d local_x=%.3f local_z=%.3f" % [_identity.world_seed, _position.cell_x, _position.cell_z, _position.local_x_m, _position.local_z_m])
		get_tree().quit()

func _show_status(message: String) -> void:
	if _status_label == null:
		var layer := CanvasLayer.new()
		add_child(layer)
		_status_label = Label.new()
		_status_label.position = Vector2(24.0, 20.0)
		_status_label.add_theme_font_size_override("font_size", 20)
		layer.add_child(_status_label)
	_status_label.text = message
